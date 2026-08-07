-- Credenciales de prueba para el entorno local.
-- Todas las cuentas usan la contrasena: CocinaME123!
--
-- Usuarios creados:
-- - onboarding@email.com -> email confirmado, sin perfiles
-- - +59170000021 -> telefono confirmado, sin perfiles
-- - consumidor@email.com -> consumidor completo
-- - cocinero@email.com -> cocinero completo con suscripcion Base
-- - mixto@email.com -> consumidor + cocinero completos
-- - admin@email.com -> consumidor + administrador completos

with seed_users as (
  select *
  from (
    values
      (
        '11111111-1111-1111-1111-111111111111'::uuid,
        'onboarding@email.com'::text,
        null::text,
        'Onboarding Email'::text,
        'Onboarding'::text,
        'Email'::text,
        'email'::text,
        true,
        false
      ),
      (
        '22222222-2222-2222-2222-222222222222'::uuid,
        null::text,
        '59170000021'::text,
        'Onboarding Telefono'::text,
        'Onboarding'::text,
        'Telefono'::text,
        'phone'::text,
        false,
        true
      ),
      (
        '33333333-3333-3333-3333-333333333333'::uuid,
        'consumidor@email.com'::text,
        null::text,
        'Lucia Mercado'::text,
        'Lucia'::text,
        'Mercado'::text,
        'email'::text,
        true,
        false
      ),
      (
        '44444444-4444-4444-4444-444444444444'::uuid,
        'cocinero@email.com'::text,
        null::text,
        'Marco Sarten'::text,
        'Marco'::text,
        'Sarten'::text,
        'email'::text,
        true,
        false
      ),
      (
        '55555555-5555-5555-5555-555555555555'::uuid,
        'mixto@email.com'::text,
        null::text,
        'Ana Doble Perfil'::text,
        'Ana'::text,
        'Doble Perfil'::text,
        'email'::text,
        true,
        false
      ),
      (
        '66666666-6666-6666-6666-666666666666'::uuid,
        'admin@email.com'::text,
        null::text,
        'Sofia Admin'::text,
        'Sofia'::text,
        'Admin'::text,
        'email'::text,
        true,
        false
      )
  ) as data (
    user_id,
    email,
    phone,
    full_name,
    first_name,
    last_name,
    provider,
    email_verified,
    phone_verified
  )
)
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  phone_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  email_change_token_current,
  reauthentication_token,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  phone,
  is_sso_user,
  is_anonymous
)
select
  '00000000-0000-0000-0000-000000000000'::uuid,
  user_id,
  'authenticated',
  'authenticated',
  email,
  crypt('CocinaME123!', gen_salt('bf')),
  case when email_verified then timezone('utc', now()) else null end,
  case when phone_verified then timezone('utc', now()) else null end,
  '',
  '',
  '',
  '',
  '',
  '',
  jsonb_build_object(
    'provider', provider,
    'providers', jsonb_build_array(provider)
  ),
  jsonb_build_object(
    'sub', user_id::text,
    'email', email,
    'full_name', full_name,
    'first_name', first_name,
    'last_name', last_name,
    'email_verified', email_verified,
    'phone_verified', phone_verified
  ),
  timezone('utc', now()),
  timezone('utc', now()),
  phone,
  false,
  false
from seed_users
on conflict (id) do nothing;

with seed_identities as (
  select *
  from (
    values
      (
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-1111-1111-1111-111111111111'::text,
        'email'::text,
        jsonb_build_object(
          'sub', '11111111-1111-1111-1111-111111111111',
          'email', 'onboarding@email.com',
          'full_name', 'Onboarding Email',
          'first_name', 'Onboarding',
          'last_name', 'Email',
          'email_verified', true,
          'phone_verified', false
        )
      ),
      (
        '22222222-2222-2222-2222-222222222222'::uuid,
        '22222222-2222-2222-2222-222222222222'::text,
        'phone'::text,
        jsonb_build_object(
          'sub', '22222222-2222-2222-2222-222222222222',
          'full_name', 'Onboarding Telefono',
          'first_name', 'Onboarding',
          'last_name', 'Telefono',
          'phone_verified', true
        )
      ),
      (
        '33333333-3333-3333-3333-333333333333'::uuid,
        '33333333-3333-3333-3333-333333333333'::text,
        'email'::text,
        jsonb_build_object(
          'sub', '33333333-3333-3333-3333-333333333333',
          'email', 'consumidor@email.com',
          'full_name', 'Lucia Mercado',
          'first_name', 'Lucia',
          'last_name', 'Mercado',
          'email_verified', true,
          'phone_verified', false
        )
      ),
      (
        '44444444-4444-4444-4444-444444444444'::uuid,
        '44444444-4444-4444-4444-444444444444'::text,
        'email'::text,
        jsonb_build_object(
          'sub', '44444444-4444-4444-4444-444444444444',
          'email', 'cocinero@email.com',
          'full_name', 'Marco Sarten',
          'first_name', 'Marco',
          'last_name', 'Sarten',
          'email_verified', true,
          'phone_verified', false
        )
      ),
      (
        '55555555-5555-5555-5555-555555555555'::uuid,
        '55555555-5555-5555-5555-555555555555'::text,
        'email'::text,
        jsonb_build_object(
          'sub', '55555555-5555-5555-5555-555555555555',
          'email', 'mixto@email.com',
          'full_name', 'Ana Doble Perfil',
          'first_name', 'Ana',
          'last_name', 'Doble Perfil',
          'email_verified', true,
          'phone_verified', false
        )
      ),
      (
        '66666666-6666-6666-6666-666666666666'::uuid,
        '66666666-6666-6666-6666-666666666666'::text,
        'email'::text,
        jsonb_build_object(
          'sub', '66666666-6666-6666-6666-666666666666',
          'email', 'admin@email.com',
          'full_name', 'Sofia Admin',
          'first_name', 'Sofia',
          'last_name', 'Admin',
          'email_verified', true,
          'phone_verified', false
        )
      )
  ) as data (user_id, provider_id, provider, identity_data)
)
insert into auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  provider_id,
  user_id,
  identity_data,
  provider,
  timezone('utc', now()),
  timezone('utc', now()),
  timezone('utc', now())
from seed_identities
on conflict (provider_id, provider) do nothing;

insert into public.profiles (id, user_id, profile_type, onboarding_completed, rating_average, is_active)
values
  ('73333333-3333-3333-3333-333333333333'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'consumer', true, 5.0, true),
  ('84444444-4444-4444-4444-444444444444'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'cook', true, 5.0, true),
  ('95555555-5555-5555-5555-555555555551'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'consumer', true, 5.0, true),
  ('95555555-5555-5555-5555-555555555552'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'cook', true, 5.0, true),
  ('96666666-6666-6666-6666-666666666661'::uuid, '66666666-6666-6666-6666-666666666666'::uuid, 'consumer', true, 5.0, true),
  ('96666666-6666-6666-6666-666666666662'::uuid, '66666666-6666-6666-6666-666666666666'::uuid, 'admin', true, 5.0, true)
on conflict (id) do nothing;

insert into public.consumer_profiles (
  profile_id,
  zone_label,
  preferred_food_types,
  app_usage_frequency,
  order_motivations,
  allergen_filters,
  delivery_preferences,
  payment_preferences
)
values
  (
    '73333333-3333-3333-3333-333333333333'::uuid,
    'Equipetrol',
    array['Comida casera', 'Postres y snacks'],
    '1 a 2 veces por semana',
    array['Comodidad', 'Curiosidad por nuevos emprendimientos'],
    array['Gluten', 'Lactosa'],
    array['Recojo en punto acordado', 'Delivery tercerizado'],
    array['QR', 'Efectivo']
  ),
  (
    '95555555-5555-5555-5555-555555555551'::uuid,
    'Urbari',
    array['Comida rapida', 'Bebidas frias'],
    '3 a 4 veces por semana',
    array['Falta de tiempo para cocinar', 'Comodidad'],
    array['Mani'],
    array['Entrega personal del cocinero'],
    array['QR', 'Tarjeta']
  ),
  (
    '96666666-6666-6666-6666-666666666661'::uuid,
    'Centro',
    array['Comida casera', 'Comida saludable'],
    '1 vez por semana',
    array['Comodidad'],
    array['Mariscos'],
    array['Recojo en punto acordado'],
    array['QR']
  )
on conflict (profile_id) do nothing;

insert into public.cook_profiles (
  profile_id,
  business_name,
  dish_types,
  prep_lead_time,
  weekly_order_volume,
  delivery_methods,
  main_pain_points,
  operating_zone,
  subscription_plan_id,
  subscription_assigned_at
)
values
  (
    '84444444-4444-4444-4444-444444444444'::uuid,
    'Sarten de Marco',
    array['Empanadas', 'Comida casera'],
    'El mismo dia, unas horas antes',
    '6 a 10 pedidos por semana',
    array['Entrega personalmente', 'Cliente recoge el pedido'],
    array['Conseguir mas clientes', 'Coordinar pedidos y entregas'],
    'Santos Dumont',
    (select id from public.subscription_plans where code = 'BASE'),
    timezone('utc', now())
  ),
  (
    '95555555-5555-5555-5555-555555555552'::uuid,
    'Cocina de Ana',
    array['Brownies', 'Postres y snacks', 'Bebidas frias'],
    'Cuando entra el pedido',
    '11 a 20 pedidos por semana',
    array['Delivery tercerizado', 'Cliente recoge el pedido'],
    array['Organizar el tiempo de cocina', 'Conseguir mas clientes'],
    'Sirari',
    (select id from public.subscription_plans where code = 'BASE'),
    timezone('utc', now())
  )
on conflict (profile_id) do nothing;

insert into public.admin_profiles (profile_id, admin_scope)
values
  ('96666666-6666-6666-6666-666666666662'::uuid, 'operations')
on conflict (profile_id) do nothing;
