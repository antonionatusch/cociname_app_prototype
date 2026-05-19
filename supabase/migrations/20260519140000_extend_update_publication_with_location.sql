create or replace function public.update_dish_publication(
  p_publication_id uuid,
  payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if payload ->> 'title' is null or trim(payload ->> 'title') = '' then
    raise exception 'El titulo del plato es obligatorio';
  end if;

  if (payload ->> 'price')::numeric <= 0 then
    raise exception 'El precio debe ser mayor a 0';
  end if;

  if (payload ->> 'available_quantity')::integer <= 0 then
    raise exception 'La cantidad debe ser mayor a 0';
  end if;

  update public.dish_publications dp
  set
    title = payload ->> 'title',
    description = coalesce(payload ->> 'description', ''),
    price = (payload ->> 'price')::numeric,
    available_quantity = (payload ->> 'available_quantity')::integer,
    latitude = coalesce((payload ->> 'latitude')::double precision, dp.latitude),
    longitude = coalesce((payload ->> 'longitude')::double precision, dp.longitude),
    zone_label = coalesce(payload ->> 'zone_label', dp.zone_label),
    updated_at = timezone('utc', now())
  where dp.id = p_publication_id
    and exists (
      select 1
      from public.profiles p
      where p.id = dp.cook_profile_id
        and p.user_id = auth.uid()
    );

  if not found then
    raise exception 'No se encontro la publicacion para el usuario actual';
  end if;
end;
$$;
