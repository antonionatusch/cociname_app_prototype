-- ================================================================
-- Phase 1: Redefine accept_cook_offer — lock cook, validate no active
-- order, reject all other pending offers for this cook.
-- ================================================================

drop function if exists public.accept_cook_offer(p_offer_id uuid);

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
  v_cook_profile record;
begin
  -- Lock the offer row
  select o.* into v_offer
  from public.cook_offers o
  where o.id = p_offer_id and o.status = 'pending'
  for update;

  if v_offer is null then
    raise exception 'Oferta no disponible o ya fue respondida';
  end if;

  -- Verify consumer owns the request
  select cp.profile_id into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  join public.consumer_requests cr on cr.consumer_profile_id = cp.profile_id
  where cr.id = v_offer.request_id and p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No eres el consumidor de esta solicitud';
  end if;

  -- Lock the cook profile row — serializes acceptances for this cook
  select * into v_cook_profile
  from public.cook_profiles
  where profile_id = v_offer.cook_profile_id
  for update;

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

  -- Guard: cook must not already have an active order
  if exists (
    select 1
    from public.orders
    where cook_profile_id = v_offer.cook_profile_id
      and status = 'active'
  ) then
    raise exception 'El emprendedor ya tomó otro pedido';
  end if;

  -- Guard: cook must be available
  if not v_cook_profile.is_available then
    raise exception 'El emprendedor no está disponible actualmente';
  end if;

  -- Decrement quantity
  update public.dish_publications
  set
    available_quantity = available_quantity - v_requested_quantity,
    is_active = case when available_quantity - v_requested_quantity <= 0 then false else is_active end,
    updated_at = timezone('utc', now())
  where id = v_offer.publication_id;

  -- Accept the winning offer
  update public.cook_offers
  set status = 'accepted', updated_at = timezone('utc', now())
  where id = p_offer_id;

  -- Reject ALL other pending offers from this cook (across any request)
  -- AND reject other pending offers for this request (from other cooks)
  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where status = 'pending'
    and id <> p_offer_id
    and (
      request_id = v_offer.request_id
      or cook_profile_id = v_offer.cook_profile_id
    );

  -- Mark the consumer request as matched
  update public.consumer_requests
  set status = 'matched', updated_at = timezone('utc', now())
  where id = v_offer.request_id;

  -- Insert the order
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

  -- Mark cook as unavailable
  update public.cook_profiles
  set is_available = false, updated_at = timezone('utc', now())
  where profile_id = v_offer.cook_profile_id;

  return v_order_id;
end;
$$;


-- ================================================================
-- Phase 2: Redefine get_offers_for_request — only return offers that
-- are still actually acceptable.
-- ================================================================

drop function if exists public.get_offers_for_request(uuid);

create or replace function public.get_offers_for_request(p_request_id uuid)
returns table (
  id uuid,
  request_id uuid,
  publication_id uuid,
  cook_profile_id uuid,
  price numeric,
  estimated_minutes integer,
  requested_quantity integer,
  message text,
  status text,
  created_at timestamptz,
  dish_title text,
  dish_description text,
  dish_photo_storage_path text,
  dish_photo_public_url text,
  dish_photos jsonb,
  cook_business_name text,
  cook_rating_average numeric,
  dish_rating_average numeric,
  dish_rating_count integer,
  publication_latitude double precision,
  publication_longitude double precision,
  publication_zone_label text,
  distance_km double precision,
  allergen_codes text[],
  dish_ingredient_items jsonb,
  allergen_warnings jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request record;
begin
  select cr.*
  into v_request
  from public.consumer_requests cr
  join public.consumer_profiles cp on cp.profile_id = cr.consumer_profile_id
  join public.profiles p on p.id = cp.profile_id
  where cr.id = p_request_id
    and p.user_id = auth.uid()
  limit 1;

  if not found then
    raise exception 'No eres el consumidor de esta solicitud';
  end if;

  return query
  select
    co.id,
    co.request_id,
    co.publication_id,
    co.cook_profile_id,
    co.price,
    co.estimated_minutes,
    v_request.requested_quantity,
    co.message,
    co.status::text,
    co.created_at,
    dp.title,
    dp.description,
    photo.storage_path,
    photo.public_url,
    coalesce(photo_list.photos, '[]'::jsonb),
    cprof.business_name,
    prof.rating_average,
    dp.rating_average,
    dp.rating_count,
    dp.latitude,
    dp.longitude,
    dp.zone_label,
    case
      when dp.latitude is null or dp.longitude is null or v_request.latitude is null or v_request.longitude is null then null
      else (
        111.045 * degrees(acos(least(1.0, greatest(-1.0,
          sin(radians(v_request.latitude)) * sin(radians(dp.latitude)) +
          cos(radians(v_request.latitude)) * cos(radians(dp.latitude)) *
          cos(radians(dp.longitude - v_request.longitude))
        ))))
      )::double precision
    end as distance_km,
    coalesce(allergens.codes, '{}'::text[]),
    coalesce(ingredients.items, '[]'::jsonb),
    coalesce(allergens.warnings, '[]'::jsonb)
  from public.cook_offers co
  join public.dish_publications dp on dp.id = co.publication_id
  join public.cook_profiles cprof on cprof.profile_id = co.cook_profile_id
  join public.profiles prof on prof.id = co.cook_profile_id
  left join lateral (
    select ph.storage_path, ph.public_url
    from public.dish_photos ph
    where ph.publication_id = dp.id
    order by ph.position asc, ph.created_at asc
    limit 1
  ) photo on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'id', ph.id,
        'storage_path', ph.storage_path,
        'public_url', ph.public_url,
        'position', ph.position
      ) order by ph.position asc, ph.created_at asc
    ) as photos
    from public.dish_photos ph
    where ph.publication_id = dp.id
  ) photo_list on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'name', coalesce(i.name, di.custom_name, 'Ingrediente'),
        'source', di.source::text,
        'is_confirmed_by_cook', di.is_confirmed_by_cook
      ) order by di.created_at asc
    ) as items
    from public.dish_ingredients di
    left join public.ingredients i on i.id = di.ingredient_id
    where di.publication_id = dp.id
  ) ingredients on true
  left join lateral (
    select
      array_agg(distinct a.code order by a.code) as codes,
      jsonb_agg(
        jsonb_build_object(
          'code', a.code,
          'name', a.name,
          'ingredient_name', coalesce(i.name, di.custom_name, 'Ingrediente'),
          'warning_type', case
            when di.is_confirmed_by_cook = true and coalesce(ia.certainty, 'contains') = 'contains' then 'contains'
            else 'may_contain'
          end,
          'source', di.source::text,
          'certainty', coalesce(ia.certainty, 'contains')
        ) order by
          case
            when di.is_confirmed_by_cook = true and coalesce(ia.certainty, 'contains') = 'contains' then 0
            else 1
          end,
          a.name,
          coalesce(i.name, di.custom_name, 'Ingrediente')
      ) as warnings
    from public.dish_ingredients di
    join public.ingredients i on i.id = di.ingredient_id
    join public.ingredient_allergens ia on ia.ingredient_id = di.ingredient_id
    join public.allergens a on a.id = ia.allergen_id
    where di.publication_id = dp.id
  ) allergens on true
  where co.request_id = p_request_id
    and co.status = 'pending'
    and v_request.status = 'searching'
    and cprof.is_available = true
    and not exists (
      select 1
      from public.orders ord
      where ord.cook_profile_id = co.cook_profile_id
        and ord.status = 'active'
    )
  order by co.created_at desc;
end;
$$;


-- ================================================================
-- Phase 3: Redefine get_active_cook_offers — same defensive filter.
-- ================================================================

drop function if exists public.get_active_cook_offers();

create or replace function public.get_active_cook_offers()
returns table (
  id uuid,
  request_id uuid,
  publication_id uuid,
  cook_profile_id uuid,
  price numeric,
  estimated_minutes integer,
  message text,
  status text,
  created_at timestamptz,
  dish_title text,
  consumer_display_name text,
  consumer_query_text text,
  consumer_target_price numeric,
  requested_quantity integer,
  consumer_allergen_filters text[],
  consumer_latitude double precision,
  consumer_longitude double precision
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
begin
  select cp.profile_id
  into v_cook_profile_id
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null then
    return;
  end if;

  return query
  select
    co.id,
    co.request_id,
    co.publication_id,
    co.cook_profile_id,
    co.price,
    co.estimated_minutes,
    co.message,
    co.status::text,
    co.created_at,
    dp.title,
    ua.display_name,
    cr.query_text,
    cr.target_price,
    cr.requested_quantity,
    coalesce(cr.allergen_filters, '{}'::text[]),
    cr.latitude,
    cr.longitude
  from public.cook_offers co
  join public.dish_publications dp on dp.id = co.publication_id
  join public.consumer_requests cr on cr.id = co.request_id
  join public.consumer_profiles cprof on cprof.profile_id = cr.consumer_profile_id
  join public.profiles prof on prof.id = cprof.profile_id
  join public.user_accounts ua on ua.user_id = prof.user_id
  where co.cook_profile_id = v_cook_profile_id
    and co.status = 'pending'
    and cr.status = 'searching'
  order by co.created_at desc;
end;
$$;


-- ================================================================
-- Phase 4: Add active-order guard to create_cook_offer.
-- The cook must be available and must NOT already have an active
-- order when creating a new offer.
-- ================================================================

drop function if exists public.create_cook_offer(payload jsonb);

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

  -- Guard: cook must not already have an active order
  if exists (
    select 1
    from public.orders
    where cook_profile_id = v_cook_profile_id
      and status = 'active'
  ) then
    raise exception 'Ya tienes un pedido activo. No puedes ofertar hasta que termine.';
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

  -- Get request allergen filters (text[], not jsonb)
  select coalesce(
    array_agg(distinct trim(elem) order by trim(elem)),
    '{}'::text[]
  )
  into v_request_allergens
  from unnest(coalesce(v_request.allergen_filters, '{}'::text[])) elem;

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


-- ================================================================
-- Phase 5: Data repair — remove duplicate active orders per cook.
-- Keeps the earliest active order (by created_at) and cancels any
-- later ones that may have been created by the race-condition bug.
-- ================================================================

do $$
declare
  v_record record;
  v_dup record;
  v_requested_quantity integer;
begin
  for v_record in
    select cook_profile_id, count(*) as cnt
    from public.orders
    where status = 'active'
    group by cook_profile_id
    having count(*) > 1
  loop
    raise notice 'Fixing duplicate active orders for cook_profile_id: %', v_record.cook_profile_id;

    for v_dup in
      select ord.id, ord.publication_id, ord.created_at
      from public.orders ord
      where ord.cook_profile_id = v_record.cook_profile_id
        and ord.status = 'active'
      order by ord.created_at asc
      offset 1
    loop
      select cr.requested_quantity into v_requested_quantity
      from public.consumer_requests cr
      join public.orders o on o.request_id = cr.id
      where o.id = v_dup.id;

      -- Restore stock
      update public.dish_publications
      set
        available_quantity = available_quantity + coalesce(v_requested_quantity, 0),
        is_active = true,
        updated_at = timezone('utc', now())
      where id = v_dup.publication_id;

      -- Cancel the duplicate order
      update public.orders
      set
        status = 'cancelled',
        order_phase = 'cancelled',
        updated_at = timezone('utc', now())
      where id = v_dup.id;

      -- Reject the corresponding offer
      update public.cook_offers
      set status = 'rejected', updated_at = timezone('utc', now())
      where id = (
        select offer_id from public.orders where id = v_dup.id
      );

      -- Set the consumer request back to searching (so the other consumer can keep looking)
      update public.consumer_requests
      set status = 'searching', updated_at = timezone('utc', now())
      where id = (
        select request_id from public.orders where id = v_dup.id
      )
      and status = 'matched';
    end loop;
  end loop;
end;
$$;


-- ================================================================
-- Phase 6: Partial unique index — only one active order per cook.
-- ================================================================

drop index if exists orders_one_active_per_cook_idx;

create unique index orders_one_active_per_cook_idx
on public.orders (cook_profile_id)
where status = 'active';

