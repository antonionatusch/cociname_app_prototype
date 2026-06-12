create type public.vision_status as enum (
  'recognized',
  'low_confidence',
  'unknown',
  'manual_only'
);

create type public.ingredient_source as enum (
  'vision_suggested',
  'cook_confirmed',
  'cook_manual',
  'custom_manual'
);

create table public.dish_categories (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.dish_publications (
  id uuid primary key default gen_random_uuid(),
  cook_profile_id uuid not null references public.cook_profiles(profile_id) on delete cascade,
  category_id uuid references public.dish_categories(id),
  title text not null,
  description text not null default '',
  price numeric(10, 2) not null check (price > 0),
  available_quantity integer not null default 1 check (available_quantity >= 0),
  is_active boolean not null default true,
  latitude double precision,
  longitude double precision,
  zone_label text,
  vision_status public.vision_status not null default 'manual_only',
  vision_confidence numeric(5, 4),
  detected_label text,
  manual_food_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.dish_photos (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid not null references public.dish_publications(id) on delete cascade,
  storage_path text not null,
  public_url text,
  position integer not null default 1,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.ingredients (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  aliases text[] not null default '{}'::text[],
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.allergens (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create table public.ingredient_allergens (
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  allergen_id uuid not null references public.allergens(id) on delete cascade,
  certainty text not null default 'contains',
  primary key (ingredient_id, allergen_id)
);

create table public.dish_ingredients (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid not null references public.dish_publications(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id),
  custom_name text,
  source public.ingredient_source not null,
  is_confirmed_by_cook boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.vision_inference_logs (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid references public.dish_publications(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  image_storage_path text,
  model_version text not null default 'tecnoupsa-v1',
  predicted_label text,
  confidence numeric(5, 4),
  vision_status public.vision_status not null,
  top_predictions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create trigger set_dish_categories_updated_at
before update on public.dish_categories
for each row
execute function public.set_updated_at();

create trigger set_dish_publications_updated_at
before update on public.dish_publications
for each row
execute function public.set_updated_at();

create trigger set_ingredients_updated_at
before update on public.ingredients
for each row
execute function public.set_updated_at();

insert into public.dish_categories (code, name) values
  ('empanada_queso_frita', 'Empanada de queso frita'),
  ('empanada_queso_integral', 'Empanada de queso integral'),
  ('pizza', 'Pizza'),
  ('hamburguesa', 'Hamburguesa'),
  ('cunape', 'Cuñapé'),
  ('unknown_food', 'Alimento desconocido');

insert into public.allergens (code, name, description) values
  ('gluten', 'Gluten', 'Proteina presente en trigo y cereales'),
  ('lacteos', 'Lacteos', 'Proteinas de la leche'),
  ('huevo', 'Huevo', 'Proteinas del huevo'),
  ('frutos_secos', 'Frutos secos', 'Almendras, nueces y similares'),
  ('mani', 'Mani', 'Proteinas del mani'),
  ('soya', 'Soya', 'Proteinas de la soya');

insert into public.ingredients (code, name) values
  ('harina_trigo', 'harina de trigo'),
  ('harina_integral', 'harina integral'),
  ('pan_hamburguesa', 'pan de hamburguesa'),
  ('carne', 'carne'),
  ('almidon_yuca', 'almidon de yuca'),
  ('queso', 'queso'),
  ('leche', 'leche'),
  ('mantequilla', 'mantequilla'),
  ('huevo', 'huevo'),
  ('cacao', 'cacao'),
  ('almendra', 'almendra'),
  ('nuez', 'nuez'),
  ('mani', 'mani'),
  ('tomate', 'tomate'),
  ('levadura', 'levadura'),
  ('aceite', 'aceite'),
  ('edulcorante', 'edulcorante');

insert into public.ingredient_allergens (ingredient_id, allergen_id)
select i.id, a.id
from public.ingredients i
cross join public.allergens a
where (i.code = 'harina_trigo' and a.code = 'gluten')
   or (i.code = 'harina_integral' and a.code = 'gluten')
   or (i.code = 'pan_hamburguesa' and a.code = 'gluten')
   or (i.code = 'queso' and a.code = 'lacteos')
   or (i.code = 'leche' and a.code = 'lacteos')
   or (i.code = 'mantequilla' and a.code = 'lacteos')
   or (i.code = 'huevo' and a.code = 'huevo')
   or (i.code = 'almendra' and a.code = 'frutos_secos')
   or (i.code = 'nuez' and a.code = 'frutos_secos')
   or (i.code = 'mani' and a.code = 'mani');

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
  v_photo record;
  v_ingredient jsonb;
  v_custom_ingredient jsonb;
  v_vision_log jsonb;
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

  if payload -> 'photo' is null or (payload -> 'photo' ->> 'storage_path') is null then
    raise exception 'La foto es obligatoria';
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

  v_photo := payload -> 'photo';
  insert into public.dish_photos (publication_id, storage_path, public_url)
  values (
    v_publication_id,
    v_photo ->> 'storage_path',
    v_photo ->> 'public_url'
  );

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
      v_photo ->> 'storage_path',
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

alter table public.dish_categories enable row level security;
alter table public.dish_publications enable row level security;
alter table public.dish_photos enable row level security;
alter table public.ingredients enable row level security;
alter table public.allergens enable row level security;
alter table public.ingredient_allergens enable row level security;
alter table public.dish_ingredients enable row level security;
alter table public.vision_inference_logs enable row level security;

create policy "dish_categories_select_all"
on public.dish_categories
for select
to authenticated
using (true);

create policy "dish_publications_select_own"
on public.dish_publications
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.id = cook_profile_id
  )
);

create policy "dish_publications_insert_own"
on public.dish_publications
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.id = cook_profile_id
  )
);

create policy "dish_photos_select_own"
on public.dish_photos
for select
to authenticated
using (
  exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = publication_id
      and p.user_id = auth.uid()
  )
);

create policy "dish_photos_insert_own"
on public.dish_photos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = publication_id
      and p.user_id = auth.uid()
  )
);

create policy "ingredients_select_all"
on public.ingredients
for select
to authenticated
using (true);

create policy "allergens_select_all"
on public.allergens
for select
to authenticated
using (true);

create policy "ingredient_allergens_select_all"
on public.ingredient_allergens
for select
to authenticated
using (true);

create policy "dish_ingredients_select_own"
on public.dish_ingredients
for select
to authenticated
using (
  exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = publication_id
      and p.user_id = auth.uid()
  )
);

create policy "dish_ingredients_insert_own"
on public.dish_ingredients
for insert
to authenticated
with check (
  exists (
    select 1
    from public.dish_publications dp
    join public.profiles p on p.id = dp.cook_profile_id
    where dp.id = publication_id
      and p.user_id = auth.uid()
  )
);

create policy "vision_inference_logs_select_own"
on public.vision_inference_logs
for select
to authenticated
using (user_id = auth.uid());

create policy "vision_inference_logs_insert_own"
on public.vision_inference_logs
for insert
to authenticated
with check (user_id = auth.uid());
