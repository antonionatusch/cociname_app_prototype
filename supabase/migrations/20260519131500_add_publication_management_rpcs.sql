create or replace function public.set_cook_availability(p_is_available boolean)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated_count integer := 0;
begin
  update public.cook_profiles cp
  set
    is_available = p_is_available,
    updated_at = timezone('utc', now())
  from public.profiles p
  where p.id = cp.profile_id
    and p.user_id = auth.uid();

  get diagnostics v_updated_count = row_count;

  if v_updated_count = 0 then
    raise exception 'No se encontro perfil emprendedor para el usuario actual';
  end if;

  return p_is_available;
end;
$$;

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

create or replace function public.delete_paused_dish_publication(p_publication_id uuid)
returns text[]
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_active boolean;
  v_storage_paths text[] := '{}';
begin
  select dp.is_active
  into v_is_active
  from public.dish_publications dp
  where dp.id = p_publication_id
    and exists (
      select 1
      from public.profiles p
      where p.id = dp.cook_profile_id
        and p.user_id = auth.uid()
    );

  if v_is_active is null then
    raise exception 'No se encontro la publicacion para el usuario actual';
  end if;

  if v_is_active then
    raise exception 'Pausa la publicacion antes de eliminarla';
  end if;

  select coalesce(array_agg(storage_path order by position), '{}')
  into v_storage_paths
  from public.dish_photos
  where publication_id = p_publication_id;

  delete from public.dish_publications
  where id = p_publication_id;

  return v_storage_paths;
end;
$$;
