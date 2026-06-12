alter table public.consumer_requests
add column if not exists requested_quantity integer not null default 1 check (requested_quantity > 0);

alter table public.dish_publications
add column if not exists rating_average numeric(2, 1) not null default 5.0 check (rating_average >= 0 and rating_average <= 5),
add column if not exists rating_count integer not null default 0 check (rating_count >= 0);

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
    raise exception 'No se encontró perfil consumidor para el usuario actual';
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
    requested_quantity,
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
    coalesce((payload ->> 'requested_quantity')::integer, 1),
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
  order by co.created_at desc;
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

create or replace function public.add_dish_publication_photo(
  p_publication_id uuid,
  p_storage_path text,
  p_position integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_photo_count integer;
begin
  if not exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = p_publication_id
      and p.user_id = auth.uid()
  ) then
    raise exception 'No puedes modificar esta publicación';
  end if;

  if nullif(trim(p_storage_path), '') is null then
    raise exception 'La ruta de la foto es obligatoria';
  end if;

  select count(*)::integer into v_photo_count
  from public.dish_photos
  where publication_id = p_publication_id;

  if v_photo_count >= 3 then
    raise exception 'La publicación ya tiene el máximo de 3 fotos';
  end if;

  insert into public.dish_photos (publication_id, storage_path, public_url, position)
  values (p_publication_id, p_storage_path, null, coalesce(p_position, v_photo_count + 1));
end;
$$;

create or replace function public.delete_dish_publication_photo(
  p_publication_id uuid,
  p_storage_path text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_photo_count integer;
  v_deleted_path text;
begin
  if not exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = p_publication_id
      and p.user_id = auth.uid()
  ) then
    raise exception 'No puedes modificar esta publicación';
  end if;

  select count(*)::integer into v_photo_count
  from public.dish_photos
  where publication_id = p_publication_id;

  if v_photo_count <= 1 then
    raise exception 'La publicación debe conservar al menos una foto';
  end if;

  delete from public.dish_photos
  where publication_id = p_publication_id
    and storage_path = p_storage_path
  returning storage_path into v_deleted_path;

  if v_deleted_path is null then
    raise exception 'Foto no encontrada';
  end if;

  with ordered as (
    select id, (row_number() over (order by position asc, created_at asc))::integer as new_position
    from public.dish_photos
    where publication_id = p_publication_id
  )
  update public.dish_photos ph
  set position = ordered.new_position
  from ordered
  where ph.id = ordered.id;

  return v_deleted_path;
end;
$$;

create or replace function public.reorder_dish_publication_photos(
  p_publication_id uuid,
  p_storage_paths jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expected_count integer;
  v_received_count integer;
begin
  if not exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = p_publication_id
      and p.user_id = auth.uid()
  ) then
    raise exception 'No puedes modificar esta publicación';
  end if;

  select count(*)::integer into v_expected_count
  from public.dish_photos
  where publication_id = p_publication_id;

  select count(*)::integer into v_received_count
  from jsonb_array_elements_text(coalesce(p_storage_paths, '[]'::jsonb));

  if v_expected_count <> v_received_count then
    raise exception 'Debes enviar todas las fotos para reordenar';
  end if;

  with ordered as (
    select value as storage_path, ordinality::integer as new_position
    from jsonb_array_elements_text(p_storage_paths) with ordinality
  )
  update public.dish_photos ph
  set position = ordered.new_position
  from ordered
  where ph.publication_id = p_publication_id
    and ph.storage_path = ordered.storage_path;
end;
$$;

create or replace function public.get_available_cook_markers()
returns table (
  id uuid,
  business_name text,
  latitude double precision,
  longitude double precision
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  return query
  select
    cprof.profile_id,
    cprof.business_name,
    avg(dp.latitude)::double precision,
    avg(dp.longitude)::double precision
  from public.cook_profiles cprof
  join public.profiles prof on prof.id = cprof.profile_id
  join public.dish_publications dp on dp.cook_profile_id = cprof.profile_id
  where cprof.is_available = true
    and prof.is_active = true
    and dp.is_active = true
    and dp.latitude is not null
    and dp.longitude is not null
  group by cprof.profile_id, cprof.business_name
  order by cprof.business_name asc;
end;
$$;
