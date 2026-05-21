create or replace function public.get_order_status(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  select ord.status::text
  into v_status
  from public.orders ord
  where ord.id = p_order_id
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
  limit 1;

  return v_status;
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
