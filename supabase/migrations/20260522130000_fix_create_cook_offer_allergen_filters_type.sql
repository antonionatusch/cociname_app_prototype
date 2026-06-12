-- Fix allergen_filters type mismatch in create_cook_offer
-- consumer_requests.allergen_filters is text[], not jsonb
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
