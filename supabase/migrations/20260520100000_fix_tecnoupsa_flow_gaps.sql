create or replace function public.create_consumer_request(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consumer_profile_id uuid;
  v_request_id uuid;
begin
  select cp.profile_id
  into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No se encontro perfil consumidor para el usuario actual';
  end if;

  update public.consumer_requests
  set status = 'cancelled', updated_at = timezone('utc', now())
  where consumer_profile_id = v_consumer_profile_id
    and status = 'searching';

  update public.cook_offers co
  set status = 'rejected', updated_at = timezone('utc', now())
  where co.status = 'pending'
    and exists (
      select 1
      from public.consumer_requests cr
      where cr.id = co.request_id
        and cr.consumer_profile_id = v_consumer_profile_id
        and cr.status = 'cancelled'
    );

  insert into public.consumer_requests (
    consumer_profile_id,
    query_text,
    target_price,
    allergen_filters,
    max_radius_km,
    current_radius_km,
    latitude,
    longitude,
    expires_at
  ) values (
    v_consumer_profile_id,
    payload ->> 'query_text',
    (payload ->> 'target_price')::numeric,
    public.jsonb_text_array(payload -> 'allergen_filters'),
    coalesce((payload ->> 'max_radius_km')::numeric, 4),
    coalesce((payload ->> 'current_radius_km')::numeric, 1),
    (payload ->> 'latitude')::double precision,
    (payload ->> 'longitude')::double precision,
    timezone('utc', now()) + interval '15 minutes'
  ) returning id into v_request_id;

  return v_request_id;
end;
$$;

create or replace function public.cancel_consumer_request(p_request_id uuid)
returns void
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
  join public.consumer_requests cr on cr.consumer_profile_id = cp.profile_id
  where cr.id = p_request_id
    and p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No eres el consumidor de esta solicitud';
  end if;

  update public.consumer_requests
  set status = 'cancelled', updated_at = timezone('utc', now())
  where id = p_request_id
    and consumer_profile_id = v_consumer_profile_id
    and status in ('searching', 'matched');

  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where request_id = p_request_id
    and status = 'pending';
end;
$$;

create or replace function public.create_cook_offer(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
  v_offer_id uuid;
  v_request_id uuid;
  v_publication_id uuid;
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

  v_request_id := (payload ->> 'request_id')::uuid;
  v_publication_id := (payload ->> 'publication_id')::uuid;

  if exists (
    select 1
    from public.cook_offers co
    where co.request_id = v_request_id
      and co.cook_profile_id = v_cook_profile_id
      and co.status in ('pending', 'accepted')
  ) then
    raise exception 'Ya enviaste una oferta para esta solicitud';
  end if;

  if not exists (
    select 1
    from public.dish_publications dp
    where dp.id = v_publication_id
      and dp.cook_profile_id = v_cook_profile_id
      and dp.is_active = true
  ) then
    raise exception 'La publicacion seleccionada no esta activa o no pertenece al emprendedor';
  end if;

  if not exists (
    select 1
    from public.consumer_requests cr
    where cr.id = v_request_id
      and cr.status = 'searching'
  ) then
    raise exception 'La solicitud ya no esta disponible';
  end if;

  insert into public.cook_offers (
    request_id,
    publication_id,
    cook_profile_id,
    price,
    estimated_minutes,
    message
  ) values (
    v_request_id,
    v_publication_id,
    v_cook_profile_id,
    (payload ->> 'price')::numeric,
    nullif(payload ->> 'estimated_minutes', '')::integer,
    coalesce(payload ->> 'message', '')
  ) returning id into v_offer_id;

  return v_offer_id;
end;
$$;

create or replace function public.get_offers_for_request(p_request_id uuid)
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
  dish_description text,
  dish_photo_storage_path text,
  dish_photo_public_url text,
  cook_business_name text,
  cook_rating_average numeric,
  publication_latitude double precision,
  publication_longitude double precision,
  publication_zone_label text,
  distance_km double precision,
  allergen_codes text[]
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
    co.message,
    co.status::text,
    co.created_at,
    dp.title,
    dp.description,
    photo.storage_path,
    photo.public_url,
    cprof.business_name,
    prof.rating_average,
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
    coalesce(allergens.codes, '{}'::text[])
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
    select array_agg(distinct a.code order by a.code) as codes
    from public.dish_ingredients di
    join public.ingredient_allergens ia on ia.ingredient_id = di.ingredient_id
    join public.allergens a on a.id = ia.allergen_id
    where di.publication_id = dp.id
  ) allergens on true
  where co.request_id = p_request_id
  order by co.created_at desc;
end;
$$;

create or replace function public.get_active_order()
returns table (
  id uuid,
  request_id uuid,
  offer_id uuid,
  consumer_profile_id uuid,
  cook_profile_id uuid,
  publication_id uuid,
  agreed_price numeric,
  status text,
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
    ord.status::text,
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
  where ord.status = 'active'
    and (
      exists (
        select 1
        from public.consumer_profiles cp
        join public.profiles p on p.id = cp.profile_id
        where cp.profile_id = ord.consumer_profile_id
          and p.user_id = auth.uid()
      )
      or exists (
        select 1
        from public.cook_profiles cp
        join public.profiles p on p.id = cp.profile_id
        where cp.profile_id = ord.cook_profile_id
          and p.user_id = auth.uid()
      )
    )
  order by ord.created_at desc
  limit 1;
end;
$$;
