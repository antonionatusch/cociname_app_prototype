create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  monthly_credits integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger set_subscription_plans_updated_at
before update on public.subscription_plans
for each row
execute function public.set_updated_at();

insert into public.subscription_plans (code, name, description, monthly_credits)
values (
  'BASE',
  'Base',
  'Plan inicial asignado durante la etapa MVP mientras la seleccion de suscripciones sigue en construccion.',
  10
)
on conflict (code) do nothing;

alter table public.cook_profiles
add column subscription_plan_id uuid references public.subscription_plans (id),
add column subscription_assigned_at timestamptz;

create or replace function public.get_base_subscription_plan_id()
returns uuid
language sql
stable
as $$
  select id
  from public.subscription_plans
  where code = 'BASE'
  limit 1;
$$;

create or replace function public.assign_default_cook_subscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.subscription_plan_id is null then
    new.subscription_plan_id = public.get_base_subscription_plan_id();
  end if;

  if new.subscription_assigned_at is null then
    new.subscription_assigned_at = timezone('utc', now());
  end if;

  return new;
end;
$$;

create trigger assign_default_cook_subscription
before insert on public.cook_profiles
for each row
execute function public.assign_default_cook_subscription();

update public.cook_profiles
set
  subscription_plan_id = public.get_base_subscription_plan_id(),
  subscription_assigned_at = coalesce(subscription_assigned_at, timezone('utc', now()))
where subscription_plan_id is null;

alter table public.cook_profiles
alter column subscription_plan_id set not null,
alter column subscription_assigned_at set not null;

create policy "subscription_plans_select_active"
on public.subscription_plans
for select
to authenticated
using (is_active = true);

alter table public.subscription_plans enable row level security;

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
  base_plan_id uuid := public.get_base_subscription_plan_id();
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
      operating_zone,
      subscription_plan_id,
      subscription_assigned_at
    )
    values (
      cook_profile_id,
      cook_business_name,
      public.jsonb_text_array(cook_payload -> 'dish_types'),
      cook_prep_lead_time,
      cook_weekly_order_volume,
      public.jsonb_text_array(cook_payload -> 'delivery_methods'),
      public.jsonb_text_array(cook_payload -> 'main_pain_points'),
      cook_operating_zone,
      base_plan_id,
      timezone('utc', now())
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
      subscription_plan_id = coalesce(public.cook_profiles.subscription_plan_id, excluded.subscription_plan_id),
      subscription_assigned_at = coalesce(public.cook_profiles.subscription_assigned_at, excluded.subscription_assigned_at),
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
