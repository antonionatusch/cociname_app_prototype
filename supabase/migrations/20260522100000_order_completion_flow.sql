insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'order-delivery-photos',
  'order-delivery-photos',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "order_delivery_photos_select" on storage.objects;
create policy "order_delivery_photos_select"
on storage.objects
for select
to authenticated
using (bucket_id = 'order-delivery-photos');

drop policy if exists "order_delivery_photos_insert_own_folder" on storage.objects;
create policy "order_delivery_photos_insert_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'order-delivery-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

alter table public.orders
add column if not exists order_phase text not null default 'awaiting_preparation_confirmation',
add column if not exists estimated_preparation_minutes integer,
add column if not exists preparation_confirmation_deadline_at timestamptz,
add column if not exists preparation_confirmed_at timestamptz,
add column if not exists preparation_deadline_at timestamptz,
add column if not exists ready_at timestamptz,
add column if not exists delivery_deadline_at timestamptz,
add column if not exists delivered_at timestamptz,
add column if not exists completed_at timestamptz;

update public.orders ord
set
  order_phase = case
    when ord.status::text = 'completed' then 'completed'
    when ord.status::text = 'cancelled' then 'cancelled'
    else coalesce(nullif(ord.order_phase, ''), 'awaiting_preparation_confirmation')
  end,
  estimated_preparation_minutes = coalesce(ord.estimated_preparation_minutes, co.estimated_minutes, 15),
  preparation_confirmation_deadline_at = coalesce(
    ord.preparation_confirmation_deadline_at,
    ord.created_at + interval '5 minutes'
  )
from public.cook_offers co
where co.id = ord.offer_id;

alter table public.orders
drop constraint if exists orders_order_phase_check;

alter table public.orders
add constraint orders_order_phase_check check (
  order_phase in (
    'awaiting_preparation_confirmation',
    'preparing',
    'ready',
    'delivering',
    'delivered',
    'completed',
    'cancelled'
  )
);

create table if not exists public.order_delivery_photos (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  storage_path text not null,
  public_url text,
  uploaded_by_profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.order_delivery_photos enable row level security;

drop policy if exists "order_delivery_photos_participants_select" on public.order_delivery_photos;
create policy "order_delivery_photos_participants_select"
on public.order_delivery_photos
for select
to authenticated
using (
  exists (
    select 1
    from public.orders ord
    join public.profiles p on p.user_id = auth.uid()
    where ord.id = order_delivery_photos.order_id
      and p.id in (ord.consumer_profile_id, ord.cook_profile_id)
  )
);

create or replace function public.current_profile_id()
returns uuid
language sql
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.user_id = auth.uid()
  limit 1
$$;

create or replace function public.is_order_cook(p_order public.orders)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.cook_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = p_order.cook_profile_id
      and p.user_id = auth.uid()
  )
$$;

create or replace function public.is_order_participant(p_order public.orders)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.id in (p_order.consumer_profile_id, p_order.cook_profile_id)
  )
$$;

create or replace function public.accept_cook_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer record;
  v_consumer_profile_id uuid;
  v_order_id uuid;
begin
  select o.* into v_offer
  from public.cook_offers o
  where o.id = p_offer_id and o.status = 'pending'
  for update;

  if v_offer is null then
    raise exception 'Oferta no disponible o ya fue respondida';
  end if;

  select cp.profile_id into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  join public.consumer_requests cr on cr.consumer_profile_id = cp.profile_id
  where cr.id = v_offer.request_id and p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No eres el consumidor de esta solicitud';
  end if;

  update public.cook_offers
  set status = 'accepted', updated_at = timezone('utc', now())
  where id = p_offer_id;

  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where request_id = v_offer.request_id
    and id <> p_offer_id
    and status = 'pending';

  update public.consumer_requests
  set status = 'matched', updated_at = timezone('utc', now())
  where id = v_offer.request_id;

  insert into public.orders (
    request_id,
    offer_id,
    consumer_profile_id,
    cook_profile_id,
    publication_id,
    agreed_price,
    order_phase,
    estimated_preparation_minutes,
    preparation_confirmation_deadline_at
  ) values (
    v_offer.request_id,
    p_offer_id,
    v_consumer_profile_id,
    v_offer.cook_profile_id,
    v_offer.publication_id,
    v_offer.price,
    'awaiting_preparation_confirmation',
    coalesce(v_offer.estimated_minutes, 15),
    timezone('utc', now()) + interval '5 minutes'
  ) returning id into v_order_id;

  update public.cook_profiles
  set is_available = false, updated_at = timezone('utc', now())
  where profile_id = v_offer.cook_profile_id;

  return v_order_id;
end;
$$;

create or replace function public.confirm_order_preparation(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order
  from public.orders
  where id = p_order_id and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible';
  end if;

  if not public.is_order_cook(v_order) then
    raise exception 'Solo el cocinero puede confirmar preparación';
  end if;

  if v_order.order_phase <> 'awaiting_preparation_confirmation' then
    raise exception 'El pedido ya no está esperando confirmación de preparación';
  end if;

  update public.orders
  set
    order_phase = 'preparing',
    preparation_confirmed_at = timezone('utc', now()),
    preparation_deadline_at = timezone('utc', now()) + make_interval(mins => coalesce(estimated_preparation_minutes, 15)),
    updated_at = timezone('utc', now())
  where id = p_order_id;
end;
$$;

create or replace function public.mark_order_ready(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order
  from public.orders
  where id = p_order_id and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible';
  end if;

  if not public.is_order_cook(v_order) then
    raise exception 'Solo el cocinero puede marcar el plato como hecho';
  end if;

  if v_order.order_phase not in ('awaiting_preparation_confirmation', 'preparing') then
    raise exception 'El pedido no está en preparación';
  end if;

  update public.orders
  set
    order_phase = 'ready',
    preparation_confirmed_at = coalesce(preparation_confirmed_at, timezone('utc', now())),
    preparation_deadline_at = coalesce(preparation_deadline_at, timezone('utc', now())),
    ready_at = timezone('utc', now()),
    delivery_deadline_at = timezone('utc', now()) + interval '45 minutes',
    updated_at = timezone('utc', now())
  where id = p_order_id;
end;
$$;

create or replace function public.register_order_delivery_photo(
  p_order_id uuid,
  p_storage_path text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_profile_id uuid;
begin
  select * into v_order
  from public.orders
  where id = p_order_id and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible';
  end if;

  if not public.is_order_cook(v_order) then
    raise exception 'Solo el cocinero puede registrar evidencia de entrega';
  end if;

  if nullif(trim(p_storage_path), '') is null then
    raise exception 'La foto de entrega es obligatoria';
  end if;

  v_profile_id := public.current_profile_id();

  insert into public.order_delivery_photos (
    order_id,
    storage_path,
    public_url,
    uploaded_by_profile_id
  ) values (
    p_order_id,
    p_storage_path,
    null,
    v_profile_id
  );
end;
$$;

create or replace function public.confirm_order_delivery(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order
  from public.orders
  where id = p_order_id and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible';
  end if;

  if not public.is_order_cook(v_order) then
    raise exception 'Solo el cocinero puede confirmar entrega';
  end if;

  if v_order.order_phase not in ('ready', 'delivering') then
    raise exception 'El pedido todavía no está listo para entregar';
  end if;

  if not exists (
    select 1 from public.order_delivery_photos odp where odp.order_id = p_order_id
  ) then
    raise exception 'Debes registrar al menos una foto de entrega';
  end if;

  update public.orders
  set
    order_phase = 'delivered',
    delivered_at = timezone('utc', now()),
    completed_at = timezone('utc', now()),
    status = 'completed',
    updated_at = timezone('utc', now())
  where id = p_order_id;

  update public.cook_profiles
  set is_available = true, updated_at = timezone('utc', now())
  where profile_id = v_order.cook_profile_id;
end;
$$;

create or replace function public.cancel_active_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  select *
  into v_order
  from public.orders
  where id = p_order_id
    and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible o ya fue cerrado';
  end if;

  if not public.is_order_participant(v_order) then
    raise exception 'No participas en este pedido';
  end if;

  update public.orders
  set
    status = 'cancelled',
    order_phase = 'cancelled',
    updated_at = timezone('utc', now())
  where id = p_order_id;

  update public.consumer_requests
  set status = 'cancelled', updated_at = timezone('utc', now())
  where id = v_order.request_id
    and status in ('searching', 'matched');

  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where request_id = v_order.request_id
    and status = 'pending';

  update public.cook_profiles
  set is_available = true, updated_at = timezone('utc', now())
  where profile_id = v_order.cook_profile_id;
end;
$$;

drop function if exists public.get_active_order();

create or replace function public.get_active_order()
returns table (
  id uuid,
  request_id uuid,
  offer_id uuid,
  consumer_profile_id uuid,
  cook_profile_id uuid,
  publication_id uuid,
  agreed_price numeric,
  requested_quantity integer,
  status text,
  order_phase text,
  estimated_preparation_minutes integer,
  preparation_confirmation_deadline_at timestamptz,
  preparation_confirmed_at timestamptz,
  preparation_deadline_at timestamptz,
  ready_at timestamptz,
  delivery_deadline_at timestamptz,
  delivered_at timestamptz,
  completed_at timestamptz,
  viewer_role text,
  delivery_photo_storage_path text,
  delivery_photo_public_url text,
  created_at timestamptz,
  dish_title text,
  cook_business_name text,
  consumer_display_name text,
  publication_latitude double precision,
  publication_longitude double precision,
  consumer_latitude double precision,
  consumer_longitude double precision,
  dish_photo_storage_path text,
  dish_photo_public_url text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    ord.id,
    ord.request_id,
    ord.offer_id,
    ord.consumer_profile_id,
    ord.cook_profile_id,
    ord.publication_id,
    ord.agreed_price,
    cr.requested_quantity,
    ord.status::text,
    ord.order_phase,
    ord.estimated_preparation_minutes,
    ord.preparation_confirmation_deadline_at,
    ord.preparation_confirmed_at,
    ord.preparation_deadline_at,
    ord.ready_at,
    ord.delivery_deadline_at,
    ord.delivered_at,
    ord.completed_at,
    case
      when exists (
        select 1
        from public.cook_profiles cp
        join public.profiles p on p.id = cp.profile_id
        where cp.profile_id = ord.cook_profile_id
          and p.user_id = auth.uid()
      ) then 'cook'
      else 'consumer'
    end,
    delivery_photo.storage_path,
    delivery_photo.public_url,
    ord.created_at,
    dp.title,
    cprof.business_name,
    ua.display_name,
    dp.latitude,
    dp.longitude,
    cr.latitude,
    cr.longitude,
    photo.storage_path,
    photo.public_url
  from public.orders ord
  join public.consumer_requests cr on cr.id = ord.request_id
  join public.dish_publications dp on dp.id = ord.publication_id
  join public.cook_profiles cprof on cprof.profile_id = ord.cook_profile_id
  join public.consumer_profiles consumer_prof on consumer_prof.profile_id = ord.consumer_profile_id
  join public.profiles consumer_profile on consumer_profile.id = consumer_prof.profile_id
  join public.user_accounts ua on ua.user_id = consumer_profile.user_id
  left join lateral (
    select ph.storage_path, ph.public_url
    from public.dish_photos ph
    where ph.publication_id = dp.id
    order by ph.position asc, ph.created_at asc
    limit 1
  ) photo on true
  left join lateral (
    select odp.storage_path, odp.public_url
    from public.order_delivery_photos odp
    where odp.order_id = ord.id
    order by odp.created_at desc
    limit 1
  ) delivery_photo on true
  where ord.status = 'active'
    and public.is_order_participant(ord)
  order by ord.created_at desc
  limit 1;
end;
$$;
