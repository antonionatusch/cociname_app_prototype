-- Dashboard context for request/order history.

drop function if exists public.get_active_consumer_requests_for_cook(integer);

create or replace function public.get_active_consumer_requests_for_cook(
  p_limit integer default 20
)
returns table (
  id uuid,
  query_text text,
  target_price numeric,
  requested_quantity integer,
  allergen_filters text[],
  max_radius_km numeric,
  current_radius_km numeric,
  latitude double precision,
  longitude double precision,
  status text,
  created_at timestamptz,
  consumer_display_name text,
  consumer_zone_label text,
  offer_count integer,
  accepted_cook_business_name text,
  accepted_dish_title text,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
  v_is_available boolean;
begin
  select cp.profile_id, cp.is_available
  into v_cook_profile_id, v_is_available
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null or v_is_available is not true then
    return;
  end if;

  return query
  select
    cr.id,
    cr.query_text,
    cr.target_price,
    cr.requested_quantity,
    coalesce(cr.allergen_filters, '{}'::text[]),
    cr.max_radius_km,
    cr.current_radius_km,
    cr.latitude,
    cr.longitude,
    cr.status::text,
    cr.created_at,
    ua.display_name,
    cprof.zone_label,
    0::integer,
    null::text,
    null::text,
    null::timestamptz
  from public.consumer_requests cr
  join public.consumer_profiles cprof on cprof.profile_id = cr.consumer_profile_id
  join public.profiles prof on prof.id = cprof.profile_id
  join public.user_accounts ua on ua.user_id = prof.user_id
  where cr.status = 'searching'
    and not exists (
      select 1
      from public.cook_offers co
      where co.request_id = cr.id
        and co.cook_profile_id = v_cook_profile_id
        and co.status = 'pending'
    )
  order by cr.created_at desc
  limit greatest(1, least(coalesce(p_limit, 20), 50));
end;
$$;

drop function if exists public.get_recent_consumer_requests(integer);

create or replace function public.get_recent_consumer_requests(
  p_limit integer default 5
)
returns table (
  id uuid,
  query_text text,
  target_price numeric,
  requested_quantity integer,
  allergen_filters text[],
  max_radius_km numeric,
  current_radius_km numeric,
  latitude double precision,
  longitude double precision,
  status text,
  created_at timestamptz,
  consumer_display_name text,
  consumer_zone_label text,
  offer_count integer,
  accepted_cook_business_name text,
  accepted_dish_title text,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consumer_profile_id uuid;
begin
  select cp.profile_id
  into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    return;
  end if;

  return query
  select
    cr.id,
    cr.query_text,
    cr.target_price,
    cr.requested_quantity,
    coalesce(cr.allergen_filters, '{}'::text[]),
    cr.max_radius_km,
    cr.current_radius_km,
    cr.latitude,
    cr.longitude,
    cr.status::text,
    cr.created_at,
    ua.display_name,
    cprof.zone_label,
    coalesce(offers.offer_count, 0)::integer,
    accepted.business_name,
    accepted.dish_title,
    accepted.completed_at
  from public.consumer_requests cr
  join public.consumer_profiles cprof on cprof.profile_id = cr.consumer_profile_id
  join public.profiles prof on prof.id = cprof.profile_id
  join public.user_accounts ua on ua.user_id = prof.user_id
  left join lateral (
    select count(*)::integer as offer_count
    from public.cook_offers co
    where co.request_id = cr.id
  ) offers on true
  left join lateral (
    select
      cook_prof.business_name,
      dp.title as dish_title,
      ord.completed_at
    from public.orders ord
    join public.cook_profiles cook_prof on cook_prof.profile_id = ord.cook_profile_id
    join public.dish_publications dp on dp.id = ord.publication_id
    where ord.request_id = cr.id
      and ord.consumer_profile_id = cr.consumer_profile_id
    order by ord.created_at desc
    limit 1
  ) accepted on true
  where cr.consumer_profile_id = v_consumer_profile_id
  order by cr.created_at desc
  limit greatest(1, least(coalesce(p_limit, 5), 20));
end;
$$;

drop function if exists public.get_completed_cook_orders(integer);

create or replace function public.get_completed_cook_orders(
  p_limit integer default 5
)
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
    'cook'::text,
    delivery_photo.storage_path,
    delivery_photo.public_url,
    ord.created_at,
    dp.title,
    cook_prof.business_name,
    ua.display_name,
    dp.latitude,
    dp.longitude,
    cr.latitude,
    cr.longitude,
    photo.storage_path,
    photo.public_url,
    now()
  from public.orders ord
  join public.consumer_requests cr on cr.id = ord.request_id
  join public.dish_publications dp on dp.id = ord.publication_id
  join public.cook_profiles cook_prof on cook_prof.profile_id = ord.cook_profile_id
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
  where ord.cook_profile_id = v_cook_profile_id
    and ord.status = 'completed'
  order by coalesce(ord.completed_at, ord.updated_at, ord.created_at) desc
  limit greatest(1, least(coalesce(p_limit, 5), 20));
end;
$$;
