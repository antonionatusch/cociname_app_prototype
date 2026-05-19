create type public.offer_status as enum (
  'pending',
  'accepted',
  'rejected',
  'expired'
);

create type public.order_status as enum (
  'active',
  'completed',
  'cancelled'
);

create table public.cook_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.consumer_requests(id) on delete cascade,
  publication_id uuid not null references public.dish_publications(id) on delete cascade,
  cook_profile_id uuid not null references public.cook_profiles(profile_id) on delete cascade,
  price numeric(10, 2) not null check (price > 0),
  estimated_minutes integer,
  message text not null default '',
  status public.offer_status not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.consumer_requests(id),
  offer_id uuid not null references public.cook_offers(id),
  consumer_profile_id uuid not null references public.consumer_profiles(profile_id),
  cook_profile_id uuid not null references public.cook_profiles(profile_id),
  publication_id uuid not null references public.dish_publications(id),
  agreed_price numeric(10, 2) not null,
  status public.order_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.cook_offers enable row level security;
alter table public.orders enable row level security;

create policy "cook_offers_select_own"
on public.cook_offers
for select
to authenticated
using (
  exists (
    select 1 from public.cook_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = cook_profile_id and p.user_id = auth.uid()
  )
  or exists (
    select 1 from public.consumer_requests cr
    join public.consumer_profiles cp on cp.profile_id = cr.consumer_profile_id
    join public.profiles p on p.id = cp.profile_id
    where cr.id = request_id and p.user_id = auth.uid()
  )
);

create policy "cook_offers_insert_own"
on public.cook_offers
for insert
to authenticated
with check (
  exists (
    select 1 from public.cook_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = cook_profile_id and p.user_id = auth.uid()
  )
);

create policy "orders_select_participant"
on public.orders
for select
to authenticated
using (
  exists (
    select 1 from public.consumer_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = consumer_profile_id and p.user_id = auth.uid()
  )
  or exists (
    select 1 from public.cook_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = cook_profile_id and p.user_id = auth.uid()
  )
);

create policy "orders_insert_participant"
on public.orders
for insert
to authenticated
with check (
  exists (
    select 1 from public.consumer_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = consumer_profile_id and p.user_id = auth.uid()
  )
);

create trigger set_cook_offers_updated_at
before update on public.cook_offers
for each row
execute function public.set_updated_at();

create trigger set_orders_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

create or replace function public.create_cook_offer(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
  v_offer_id uuid;
begin
  select cp.profile_id
  into v_cook_profile_id
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null then
    raise exception 'No se encontro perfil emprendedor';
  end if;

  insert into public.cook_offers (
    request_id,
    publication_id,
    cook_profile_id,
    price,
    estimated_minutes,
    message
  ) values (
    (payload ->> 'request_id')::uuid,
    (payload ->> 'publication_id')::uuid,
    v_cook_profile_id,
    (payload ->> 'price')::numeric,
    (payload ->> 'estimated_minutes')::integer,
    coalesce(payload ->> 'message', '')
  ) returning id into v_offer_id;

  return v_offer_id;
end;
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
    agreed_price
  ) values (
    v_offer.request_id,
    p_offer_id,
    v_consumer_profile_id,
    v_offer.cook_profile_id,
    v_offer.publication_id,
    v_offer.price
  ) returning id into v_order_id;

  return v_order_id;
end;
$$;
