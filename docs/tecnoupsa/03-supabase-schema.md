# Esquema Supabase Propuesto

Este archivo describe las migraciones necesarias. Los nombres pueden ajustarse a la convencion del repo, pero deben mantener la intencion funcional.

## Tipos Enum

Crear enums:

```sql
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

create type public.request_status as enum (
  'searching',
  'matched',
  'cancelled',
  'expired'
);

create type public.offer_status as enum (
  'pending',
  'accepted',
  'rejected',
  'expired'
);

create type public.order_status as enum (
  'active',
  'completed',
  'cancelled'
);

create type public.cook_availability_status as enum (
  'available',
  'busy',
  'offline'
);
```

## Tabla `dish_categories`

Categorias o etiquetas de plato para clasificacion y busqueda.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `code text not null unique`
- `name text not null`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

Semillas:

- `empanada_queso_frita`
- `empanada_queso_integral`
- `pizza`
- `hamburguesa`
- `cunape`
- `unknown_food`

## Tabla `dish_publications`

Publicaciones de platos del emprendedor.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `cook_profile_id uuid not null references public.cook_profiles(profile_id) on delete cascade`
- `category_id uuid references public.dish_categories(id)`
- `title text not null`
- `description text not null default ''`
- `price numeric(10, 2) not null check (price > 0)`
- `available_quantity integer not null default 1 check (available_quantity >= 0)`
- `is_active boolean not null default true`
- `latitude double precision`
- `longitude double precision`
- `zone_label text`
- `vision_status public.vision_status not null default 'manual_only'`
- `vision_confidence numeric(5, 4)`
- `detected_label text`
- `manual_food_name text`
- `allergen_summary jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

Nota: si se habilita PostGIS despues, reemplazar o complementar `latitude` y `longitude` con `geography(Point, 4326)`.

## Tabla `dish_photos`

Fotos asociadas a publicaciones.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `publication_id uuid not null references public.dish_publications(id) on delete cascade`
- `storage_path text not null`
- `public_url text`
- `position integer not null default 1`
- `created_at timestamptz not null default timezone('utc', now())`

## Tabla `ingredients`

Ingredientes conocidos por el sistema.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `code text not null unique`
- `name text not null`
- `aliases text[] not null default '{}'::text[]`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

Semillas minimas:

- harina de trigo
- harina integral
- pan de hamburguesa
- carne
- almidon de yuca
- queso
- leche
- mantequilla
- huevo
- cacao
- almendra
- nuez
- mani
- tomate
- levadura
- edulcorante
- aceite

## Tabla `allergens`

Catalogo de alergenos.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `code text not null unique`
- `name text not null`
- `description text not null default ''`
- `created_at timestamptz not null default timezone('utc', now())`

Semillas minimas:

- gluten
- lacteos
- huevo
- frutos secos
- mani
- soya

## Tabla `ingredient_allergens`

Relacion muchos a muchos entre ingrediente y alergeno.

Columnas:

- `ingredient_id uuid not null references public.ingredients(id) on delete cascade`
- `allergen_id uuid not null references public.allergens(id) on delete cascade`
- `certainty text not null default 'contains'`
- `primary key (ingredient_id, allergen_id)`

## Tabla `dish_ingredients`

Ingredientes asociados a una publicacion.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `publication_id uuid not null references public.dish_publications(id) on delete cascade`
- `ingredient_id uuid references public.ingredients(id)`
- `custom_name text`
- `source public.ingredient_source not null`
- `is_confirmed_by_cook boolean not null default false`
- `is_known_ingredient boolean not null default true`
- `requires_manual_allergen_review boolean not null default false`
- `created_at timestamptz not null default timezone('utc', now())`

Regla:

- Si `ingredient_id` es null, debe existir `custom_name`.
- Si `source = custom_manual`, entonces `requires_manual_allergen_review = true` salvo que el emprendedor declare alergenos manualmente.

## Tabla `vision_inference_logs`

Registro de inferencias visuales.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `publication_id uuid references public.dish_publications(id) on delete set null`
- `user_id uuid references auth.users(id) on delete set null`
- `image_storage_path text`
- `model_version text not null default 'demo-v1'`
- `predicted_label text`
- `confidence numeric(5, 4)`
- `vision_status public.vision_status not null`
- `top_predictions jsonb not null default '[]'::jsonb`
- `created_at timestamptz not null default timezone('utc', now())`

## Tabla `cook_availability`

Estado de disponibilidad del emprendedor.

Columnas:

- `cook_profile_id uuid primary key references public.cook_profiles(profile_id) on delete cascade`
- `status public.cook_availability_status not null default 'offline'`
- `latitude double precision`
- `longitude double precision`
- `last_seen_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

## Tabla `consumer_requests`

Solicitudes emitidas por consumidores.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `consumer_profile_id uuid not null references public.consumer_profiles(profile_id) on delete cascade`
- `query_text text not null`
- `target_price numeric(10, 2) not null check (target_price > 0)`
- `allergen_filters text[] not null default '{}'::text[]`
- `max_radius_km numeric(5, 2) not null default 4`
- `current_radius_km numeric(5, 2) not null default 1`
- `latitude double precision`
- `longitude double precision`
- `status public.request_status not null default 'searching'`
- `expires_at timestamptz`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

## Tabla `cook_offers`

Ofertas enviadas por emprendedores a solicitudes.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `request_id uuid not null references public.consumer_requests(id) on delete cascade`
- `publication_id uuid not null references public.dish_publications(id) on delete cascade`
- `cook_profile_id uuid not null references public.cook_profiles(profile_id) on delete cascade`
- `price numeric(10, 2) not null check (price > 0)`
- `estimated_minutes integer`
- `message text not null default ''`
- `status public.offer_status not null default 'pending'`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

## Tabla `orders`

Pedido creado cuando el consumidor acepta una oferta.

Columnas:

- `id uuid primary key default gen_random_uuid()`
- `request_id uuid not null references public.consumer_requests(id)`
- `offer_id uuid not null references public.cook_offers(id)`
- `consumer_profile_id uuid not null references public.consumer_profiles(profile_id)`
- `cook_profile_id uuid not null references public.cook_profiles(profile_id)`
- `publication_id uuid not null references public.dish_publications(id)`
- `agreed_price numeric(10, 2) not null`
- `status public.order_status not null default 'active'`
- `created_at timestamptz not null default timezone('utc', now())`
- `updated_at timestamptz not null default timezone('utc', now())`

## Extension Del Cuestionario Consumidor

Agregar campos a `consumer_profiles` o crear tabla `consumer_preferences`:

- `usual_budget numeric(10, 2)`
- `preferred_radius_km numeric(5, 2) default 4`
- `allergy_severity text default 'preventive'`
- `may_contain_tolerance text default 'ask_first'`
- `frequent_search_terms text[] default '{}'::text[]`

Opciones sugeridas:

- Severidad: `preventiva`, `moderada`, `severa`.
- Tolerancia: `acepto puede contener`, `prefiero preguntar`, `ocultar puede contener`.

## RLS Minima

Reglas necesarias:

- Usuarios autenticados pueden leer catalogos: `dish_categories`, `ingredients`, `allergens`, `ingredient_allergens`.
- Emprendedor puede crear, leer y actualizar sus publicaciones.
- Consumidor puede crear y leer sus solicitudes.
- Emprendedor disponible puede leer solicitudes activas.
- Emprendedor puede crear ofertas propias.
- Consumidor puede leer ofertas asociadas a sus solicitudes.
- Consumidor puede aceptar una oferta asociada a su solicitud.

Para avanzar rapido, se permite usar RPCs `security definer` para operaciones compuestas:

- `create_dish_publication(payload jsonb)`
- `create_consumer_request(payload jsonb)`
- `create_cook_offer(payload jsonb)`
- `accept_cook_offer(offer_id uuid)`
