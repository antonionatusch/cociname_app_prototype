create type public.request_status as enum (
  'searching',
  'matched',
  'cancelled',
  'expired'
);

create table public.consumer_requests (
  id uuid primary key default gen_random_uuid(),
  consumer_profile_id uuid not null references public.consumer_profiles(profile_id) on delete cascade,
  query_text text not null,
  target_price numeric(10, 2) not null check (target_price > 0),
  allergen_filters text[] not null default '{}'::text[],
  max_radius_km numeric(5, 2) not null default 4,
  current_radius_km numeric(5, 2) not null default 1,
  latitude double precision,
  longitude double precision,
  status public.request_status not null default 'searching',
  expires_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.consumer_requests enable row level security;

create policy "consumer_requests_select_own"
on public.consumer_requests
for select
to authenticated
using (
  exists (
    select 1
    from public.consumer_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = consumer_profile_id
      and p.user_id = auth.uid()
  )
);

create policy "consumer_requests_insert_own"
on public.consumer_requests
for insert
to authenticated
with check (
  exists (
    select 1
    from public.consumer_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = consumer_profile_id
      and p.user_id = auth.uid()
  )
);

create policy "consumer_requests_select_active_for_cook"
on public.consumer_requests
for select
to authenticated
using (
  status = 'searching'
    and exists (
      select 1
      from public.cook_profiles cp
      join public.profiles p on p.id = cp.profile_id
      where p.user_id = auth.uid()
        and cp.is_available = true
    )
);

create trigger set_consumer_requests_updated_at
before update on public.consumer_requests
for each row
execute function public.set_updated_at();

create or replace function public.create_consumer_request(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consumer_profile_id uuid;
  v_request_id uuid;
begin
  select cp.profile_id
  into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No se encontro perfil consumidor para el usuario actual';
  end if;

  insert into public.consumer_requests (
    consumer_profile_id,
    query_text,
    target_price,
    allergen_filters,
    max_radius_km,
    current_radius_km,
    latitude,
    longitude
  ) values (
    v_consumer_profile_id,
    payload ->> 'query_text',
    (payload ->> 'target_price')::numeric,
    public.jsonb_text_array(payload -> 'allergen_filters'),
    coalesce((payload ->> 'max_radius_km')::numeric, 4),
    coalesce((payload ->> 'current_radius_km')::numeric, 1),
    (payload ->> 'latitude')::double precision,
    (payload ->> 'longitude')::double precision
  ) returning id into v_request_id;

  return v_request_id;
end;
$$;
