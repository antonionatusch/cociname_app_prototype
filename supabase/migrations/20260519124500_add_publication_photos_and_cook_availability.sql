alter table public.cook_profiles
add column if not exists is_available boolean not null default true;

create policy "dish_publications_update_own"
on public.dish_publications
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.id = cook_profile_id
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.id = cook_profile_id
  )
);

create or replace function public.create_dish_publication(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
  v_publication_id uuid;
  v_category_id uuid;
  v_photo jsonb;
  v_photo_count integer;
  v_ingredient jsonb;
  v_custom_ingredient jsonb;
  v_vision_log jsonb;
  v_first_photo_path text;
begin
  select cp.profile_id
  into v_cook_profile_id
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null then
    raise exception 'No se encontro perfil emprendedor para el usuario actual';
  end if;

  if payload ->> 'title' is null or trim(payload ->> 'title') = '' then
    raise exception 'El titulo del plato es obligatorio';
  end if;

  if (payload ->> 'price')::numeric <= 0 then
    raise exception 'El precio debe ser mayor a 0';
  end if;

  if (payload ->> 'available_quantity')::integer <= 0 then
    raise exception 'La cantidad debe ser mayor a 0';
  end if;

  v_photo_count := jsonb_array_length(coalesce(payload -> 'photos', '[]'::jsonb));
  if v_photo_count < 1 or v_photo_count > 3 then
    raise exception 'Debes subir entre 1 y 3 fotos';
  end if;

  select dc.id into v_category_id
  from public.dish_categories dc
  where dc.code = payload ->> 'category_code';

  insert into public.dish_publications (
    cook_profile_id,
    category_id,
    title,
    description,
    price,
    available_quantity,
    latitude,
    longitude,
    zone_label,
    vision_status,
    vision_confidence,
    detected_label,
    manual_food_name
  ) values (
    v_cook_profile_id,
    v_category_id,
    payload ->> 'title',
    coalesce(payload ->> 'description', ''),
    (payload ->> 'price')::numeric,
    (payload ->> 'available_quantity')::integer,
    (payload ->> 'latitude')::double precision,
    (payload ->> 'longitude')::double precision,
    payload ->> 'zone_label',
    (payload ->> 'vision_status')::public.vision_status,
    (payload -> 'vision_confidence')::numeric,
    payload ->> 'detected_label',
    payload ->> 'manual_food_name'
  ) returning id into v_publication_id;

  for v_photo in select * from jsonb_array_elements(payload -> 'photos') loop
    if nullif(v_photo ->> 'storage_path', '') is null then
      raise exception 'La ruta de la foto es obligatoria';
    end if;

    insert into public.dish_photos (publication_id, storage_path, public_url, position)
    values (
      v_publication_id,
      v_photo ->> 'storage_path',
      v_photo ->> 'public_url',
      coalesce((v_photo ->> 'position')::integer, 1)
    );
  end loop;

  select dp.storage_path
  into v_first_photo_path
  from public.dish_photos dp
  where dp.publication_id = v_publication_id
  order by dp.position asc, dp.created_at asc
  limit 1;

  for v_ingredient in select * from jsonb_array_elements(coalesce(payload -> 'ingredients', '[]'::jsonb)) loop
    insert into public.dish_ingredients (
      publication_id,
      ingredient_id,
      source,
      is_confirmed_by_cook
    ) values (
      v_publication_id,
      (select id from public.ingredients where code = v_ingredient ->> 'code'),
      (v_ingredient ->> 'source')::public.ingredient_source,
      (v_ingredient ->> 'is_confirmed_by_cook')::boolean
    );
  end loop;

  for v_custom_ingredient in select * from jsonb_array_elements(coalesce(payload -> 'custom_ingredients', '[]'::jsonb)) loop
    insert into public.dish_ingredients (
      publication_id,
      custom_name,
      source,
      is_confirmed_by_cook
    ) values (
      v_publication_id,
      v_custom_ingredient ->> 'name',
      (v_custom_ingredient ->> 'source')::public.ingredient_source,
      true
    );
  end loop;

  v_vision_log := payload -> 'vision_log';
  if v_vision_log is not null then
    insert into public.vision_inference_logs (
      publication_id,
      user_id,
      image_storage_path,
      model_version,
      predicted_label,
      confidence,
      vision_status,
      top_predictions
    ) values (
      v_publication_id,
      auth.uid(),
      v_first_photo_path,
      v_vision_log ->> 'model_version',
      v_vision_log ->> 'predicted_label',
      (v_vision_log ->> 'confidence')::numeric,
      (v_vision_log ->> 'vision_status')::public.vision_status,
      v_vision_log -> 'top_predictions'
    );
  end if;

  return v_publication_id;
end;
$$;
