create type public.profile_type as enum ('consumer', 'cook', 'admin');

create table public.user_accounts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_accounts (user_id) on delete cascade,
  profile_type public.profile_type not null,
  onboarding_completed boolean not null default false,
  rating_average numeric(2, 1) not null default 5.0 check (rating_average >= 0 and rating_average <= 5),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, profile_type)
);

create table public.consumer_profiles (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  zone_label text not null,
  preferred_food_types text[] not null default '{}'::text[],
  app_usage_frequency text not null,
  order_motivations text[] not null default '{}'::text[],
  allergen_filters text[] not null default '{}'::text[],
  delivery_preferences text[] not null default '{}'::text[],
  payment_preferences text[] not null default '{}'::text[],
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.cook_profiles (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  business_name text not null,
  dish_types text[] not null default '{}'::text[],
  prep_lead_time text not null,
  weekly_order_volume text not null,
  delivery_methods text[] not null default '{}'::text[],
  main_pain_points text[] not null default '{}'::text[],
  operating_zone text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.admin_profiles (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  admin_scope text not null default 'operations',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.resolve_account_display_name(
  metadata jsonb,
  account_email text,
  account_phone text
)
returns text
language sql
immutable
as $$
  select coalesce(
    nullif(trim(metadata ->> 'full_name'), ''),
    nullif(trim(concat_ws(' ', metadata ->> 'first_name', metadata ->> 'last_name')), ''),
    nullif(trim(account_email), ''),
    nullif(trim(account_phone), ''),
    'Usuario CocinaME'
  );
$$;

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.user_accounts (user_id, display_name)
  values (
    new.id,
    public.resolve_account_display_name(new.raw_user_meta_data, new.email, new.phone)
  )
  on conflict (user_id) do update
  set
    display_name = excluded.display_name,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

create trigger set_user_accounts_updated_at
before update on public.user_accounts
for each row
execute function public.set_updated_at();

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger set_consumer_profiles_updated_at
before update on public.consumer_profiles
for each row
execute function public.set_updated_at();

create trigger set_cook_profiles_updated_at
before update on public.cook_profiles
for each row
execute function public.set_updated_at();

create trigger set_admin_profiles_updated_at
before update on public.admin_profiles
for each row
execute function public.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_auth_user_created();

create or replace function public.enforce_profile_type_match()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  expected_type public.profile_type;
begin
  expected_type = tg_argv[0]::public.profile_type;

  if not exists (
    select 1
    from public.profiles p
    where p.id = new.profile_id
      and p.profile_type = expected_type
  ) then
    raise exception 'Profile % is not a % profile', new.profile_id, expected_type;
  end if;

  return new;
end;
$$;

create trigger enforce_consumer_profile_type
before insert or update on public.consumer_profiles
for each row
execute function public.enforce_profile_type_match('consumer');

create trigger enforce_cook_profile_type
before insert or update on public.cook_profiles
for each row
execute function public.enforce_profile_type_match('cook');

create trigger enforce_admin_profile_type
before insert or update on public.admin_profiles
for each row
execute function public.enforce_profile_type_match('admin');

create or replace function public.jsonb_text_array(input jsonb)
returns text[]
language sql
immutable
as $$
  select coalesce(array_agg(value), '{}'::text[])
  from jsonb_array_elements_text(coalesce(input, '[]'::jsonb)) as items(value);
$$;

alter table public.user_accounts enable row level security;
alter table public.profiles enable row level security;
alter table public.consumer_profiles enable row level security;
alter table public.cook_profiles enable row level security;
alter table public.admin_profiles enable row level security;

create policy "user_accounts_select_own"
on public.user_accounts
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_accounts_update_own"
on public.user_accounts
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = user_id);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "consumer_profiles_select_own"
on public.consumer_profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create policy "consumer_profiles_update_own"
on public.consumer_profiles
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create policy "cook_profiles_select_own"
on public.cook_profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create policy "cook_profiles_update_own"
on public.cook_profiles
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create policy "admin_profiles_select_own"
on public.admin_profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create policy "admin_profiles_update_own"
on public.admin_profiles
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = profile_id
      and p.user_id = auth.uid()
  )
);

create or replace function public.complete_profile_onboarding(
  selected_roles text[],
  consumer_payload jsonb default '{}'::jsonb,
  cook_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_roles text[] := '{}';
  selected_role text;
  consumer_profile_id uuid;
  cook_profile_id uuid;
  consumer_zone text;
  consumer_app_usage text;
  cook_business_name text;
  cook_prep_lead_time text;
  cook_weekly_order_volume text;
  cook_operating_zone text;
begin
  if current_user_id is null then
    raise exception 'No authenticated user available';
  end if;

  if selected_roles is null or array_length(selected_roles, 1) is null then
    raise exception 'At least one public role must be selected';
  end if;

  insert into public.user_accounts (user_id, display_name)
  select
    users.id,
    public.resolve_account_display_name(users.raw_user_meta_data, users.email, users.phone)
  from auth.users users
  where users.id = current_user_id
  on conflict (user_id) do nothing;

  foreach selected_role in array selected_roles loop
    selected_role := lower(trim(selected_role));

    if selected_role not in ('consumer', 'cook') then
      raise exception 'Role % is not available from onboarding', selected_role;
    end if;

    if not (selected_role = any(normalized_roles)) then
      normalized_roles := array_append(normalized_roles, selected_role);
    end if;
  end loop;

  if 'consumer' = any(normalized_roles) then
    consumer_zone := nullif(trim(consumer_payload ->> 'zone_label'), '');
    consumer_app_usage := nullif(trim(consumer_payload ->> 'app_usage_frequency'), '');

    if consumer_zone is null or consumer_app_usage is null then
      raise exception 'Consumer profile requires zone_label and app_usage_frequency';
    end if;

    insert into public.profiles (user_id, profile_type, onboarding_completed)
    values (current_user_id, 'consumer', true)
    on conflict (user_id, profile_type) do update
    set
      onboarding_completed = true,
      is_active = true,
      updated_at = timezone('utc', now())
    returning id into consumer_profile_id;

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
    values (
      consumer_profile_id,
      consumer_zone,
      public.jsonb_text_array(consumer_payload -> 'preferred_food_types'),
      consumer_app_usage,
      public.jsonb_text_array(consumer_payload -> 'order_motivations'),
      public.jsonb_text_array(consumer_payload -> 'allergen_filters'),
      public.jsonb_text_array(consumer_payload -> 'delivery_preferences'),
      public.jsonb_text_array(consumer_payload -> 'payment_preferences')
    )
    on conflict (profile_id) do update
    set
      zone_label = excluded.zone_label,
      preferred_food_types = excluded.preferred_food_types,
      app_usage_frequency = excluded.app_usage_frequency,
      order_motivations = excluded.order_motivations,
      allergen_filters = excluded.allergen_filters,
      delivery_preferences = excluded.delivery_preferences,
      payment_preferences = excluded.payment_preferences,
      updated_at = timezone('utc', now());
  end if;

  if 'cook' = any(normalized_roles) then
    cook_business_name := nullif(trim(cook_payload ->> 'business_name'), '');
    cook_prep_lead_time := nullif(trim(cook_payload ->> 'prep_lead_time'), '');
    cook_weekly_order_volume := nullif(trim(cook_payload ->> 'weekly_order_volume'), '');
    cook_operating_zone := nullif(trim(cook_payload ->> 'operating_zone'), '');

    if cook_business_name is null
      or cook_prep_lead_time is null
      or cook_weekly_order_volume is null
      or cook_operating_zone is null then
      raise exception 'Cook profile requires business_name, prep_lead_time, weekly_order_volume and operating_zone';
    end if;

    insert into public.profiles (user_id, profile_type, onboarding_completed)
    values (current_user_id, 'cook', true)
    on conflict (user_id, profile_type) do update
    set
      onboarding_completed = true,
      is_active = true,
      updated_at = timezone('utc', now())
    returning id into cook_profile_id;

    insert into public.cook_profiles (
      profile_id,
      business_name,
      dish_types,
      prep_lead_time,
      weekly_order_volume,
      delivery_methods,
      main_pain_points,
      operating_zone
    )
    values (
      cook_profile_id,
      cook_business_name,
      public.jsonb_text_array(cook_payload -> 'dish_types'),
      cook_prep_lead_time,
      cook_weekly_order_volume,
      public.jsonb_text_array(cook_payload -> 'delivery_methods'),
      public.jsonb_text_array(cook_payload -> 'main_pain_points'),
      cook_operating_zone
    )
    on conflict (profile_id) do update
    set
      business_name = excluded.business_name,
      dish_types = excluded.dish_types,
      prep_lead_time = excluded.prep_lead_time,
      weekly_order_volume = excluded.weekly_order_volume,
      delivery_methods = excluded.delivery_methods,
      main_pain_points = excluded.main_pain_points,
      operating_zone = excluded.operating_zone,
      updated_at = timezone('utc', now());
  end if;

  return jsonb_build_object(
    'roles', normalized_roles,
    'consumer_profile_id', consumer_profile_id,
    'cook_profile_id', cook_profile_id
  );
end;
$$;

grant execute on function public.complete_profile_onboarding(text[], jsonb, jsonb) to authenticated;
