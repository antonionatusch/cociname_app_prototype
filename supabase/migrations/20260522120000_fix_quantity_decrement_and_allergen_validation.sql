-- ============================================================
-- Migration: Fix quantity decrement, allergen validation, server_now
-- ============================================================

-- Patch create_cook_offer: add allergen compatibility check
create or replace function public.create_cook_offer(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
  v_offer_id uuid;
  v_request public.consumer_requests%rowtype;
  v_publication public.dish_publications%rowtype;
  v_publication_allergens text[];
  v_request_allergens text[];
  v_matching_allergen text;
begin
  select cp.profile_id
  into v_cook_profile_id
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null then
    raise exception 'No se encontró perfil emprendedor';
  end if;

  select *
  into v_request
  from public.consumer_requests cr
  where cr.id = (payload ->> 'request_id')::uuid
    and cr.status = 'searching'
  limit 1;

  if v_request.id is null then
    raise exception 'La solicitud ya no está disponible';
  end if;

  select *
  into v_publication
  from public.dish_publications dp
  where dp.id = (payload ->> 'publication_id')::uuid
    and dp.cook_profile_id = v_cook_profile_id
    and dp.is_active = true
  limit 1;

  if v_publication.id is null then
    raise exception 'La publicación seleccionada no está activa o no pertenece al emprendedor';
  end if;

  if v_request.requested_quantity > v_publication.available_quantity then
    raise exception 'La publicación no tiene cantidad suficiente para esta solicitud';
  end if;

  if exists (
    select 1
    from public.cook_offers co
    where co.request_id = v_request.id
      and co.cook_profile_id = v_cook_profile_id
      and co.status in ('pending', 'accepted')
  ) then
    raise exception 'Ya enviaste una oferta para esta solicitud';
  end if;

  -- Allergen compatibility check: get publication allergens
  select coalesce(array_agg(distinct a.code order by a.code), '{}'::text[])
  into v_publication_allergens
  from public.dish_ingredients di
  join public.ingredients i on i.id = di.ingredient_id
  join public.ingredient_allergens ia on ia.ingredient_id = di.ingredient_id
  join public.allergens a on a.id = ia.allergen_id
  where di.publication_id = v_publication.id;

  -- Get request allergen filters
  select coalesce(
    array_agg(distinct trim(elem::text) order by trim(elem::text)),
    '{}'::text[]
  )
  into v_request_allergens
  from jsonb_array_elements_text(
    coalesce(v_request.allergen_filters, '[]'::jsonb)
  ) elem;

  -- Check for intersection
  if array_length(v_request_allergens, 1) > 0 then
    select a.code
    into v_matching_allergen
    from public.allergens a
    where a.code = any(v_request_allergens)
      and a.code = any(v_publication_allergens)
    limit 1;

    if v_matching_allergen is not null then
      raise exception 'La publicación contiene alérgenos restringidos por el consumidor: %', v_matching_allergen;
    end if;
  end if;

  insert into public.cook_offers (
    request_id,
    publication_id,
    cook_profile_id,
    price,
    estimated_minutes,
    message
  ) values (
    v_request.id,
    v_publication.id,
    v_cook_profile_id,
    (payload ->> 'price')::numeric,
    nullif(payload ->> 'estimated_minutes', '')::integer,
    coalesce(payload ->> 'message', '')
  ) returning id into v_offer_id;

  return v_offer_id;
end;
$$;

-- Patch accept_cook_offer: add stock decrement with lock
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
  v_publication record;
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

  -- Lock and re-validate publication quantity
  select dp.* into v_publication
  from public.dish_publications dp
  where dp.id = v_offer.publication_id
  for update;

  if v_publication.available_quantity < v_offer.requested_quantity_v2 then
    raise exception 'La publicación ya no tiene cantidad suficiente: disponible % solicitado %',
      v_publication.available_quantity, v_offer.requested_quantity_v2;
  end if;

  -- Decrement quantity
  update public.dish_publications
  set
    available_quantity = available_quantity - v_offer.requested_quantity_v2,
    is_active = case when available_quantity - v_offer.requested_quantity_v2 <= 0 then false else is_active end,
    updated_at = timezone('utc', now())
  where id = v_offer.publication_id;

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

-- Note: the above accept_cook_offer uses v_offer.requested_quantity_v2
-- which does NOT exist on cook_offers. We need the requested_quantity
-- from the consumer_request. Let me fix this properly:

drop function if exists public.accept_cook_offer(uuid);

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
  v_publication record;
  v_requested_quantity integer;
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

  -- Get requested_quantity from the consumer_request
  select cr.requested_quantity into v_requested_quantity
  from public.consumer_requests cr
  where cr.id = v_offer.request_id;

  -- Lock and re-validate publication quantity
  select dp.* into v_publication
  from public.dish_publications dp
  where dp.id = v_offer.publication_id
  for update;

  if v_publication.available_quantity < v_requested_quantity then
    raise exception 'La publicación ya no tiene cantidad suficiente: disponible % solicitado %',
      v_publication.available_quantity, v_requested_quantity;
  end if;

  -- Decrement quantity
  update public.dish_publications
  set
    available_quantity = available_quantity - v_requested_quantity,
    is_active = case when available_quantity - v_requested_quantity <= 0 then false else is_active end,
    updated_at = timezone('utc', now())
  where id = v_offer.publication_id;

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

-- Patch cancel_active_order: restore stock on cancellation
create or replace function public.cancel_active_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_requested_quantity integer;
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

  -- Get requested_quantity before updating
  select cr.requested_quantity into v_requested_quantity
  from public.consumer_requests cr
  where cr.id = v_order.request_id;

  update public.orders
  set
    status = 'cancelled',
    order_phase = 'cancelled',
    updated_at = timezone('utc', now())
  where id = p_order_id;

  -- Restore stock: only if order wasn't already completed
  update public.dish_publications
  set
    available_quantity = available_quantity + v_requested_quantity,
    is_active = true,
    updated_at = timezone('utc', now())
  where id = v_order.publication_id;

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

-- Patch get_active_order: add server_now
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
  dish_photo_public_url text,
  server_now timestamptz
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
    photo.public_url,
    timezone('utc', now()) as server_now
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

-- Helper RPC: get allergen codes for own publications (used by cook dashboard)
create or replace function public.get_own_publication_allergens()
returns table (
  publication_id uuid,
  allergen_codes text[]
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    dp.id as publication_id,
    coalesce(
      array_agg(distinct a.code order by a.code) filter (where a.code is not null),
      '{}'::text[]
    ) as allergen_codes
  from public.dish_publications dp
  join public.profiles p on p.id = dp.cook_profile_id
  left join public.dish_ingredients di on di.publication_id = dp.id
  left join public.ingredients i on i.id = di.ingredient_id
  left join public.ingredient_allergens ia on ia.ingredient_id = di.ingredient_id
  left join public.allergens a on a.id = ia.allergen_id
  where p.user_id = auth.uid()
  group by dp.id;
end;
$$;
