-- RPC: get pending offers for the authenticated cook, with consumer + request info

create or replace function public.get_active_cook_offers()
returns table (
  id uuid,
  request_id uuid,
  publication_id uuid,
  cook_profile_id uuid,
  price numeric,
  estimated_minutes integer,
  message text,
  status text,
  created_at timestamptz,
  dish_title text,
  consumer_display_name text,
  consumer_query_text text,
  consumer_target_price numeric,
  requested_quantity integer,
  consumer_allergen_filters text[],
  consumer_latitude double precision,
  consumer_longitude double precision
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cook_profile_id uuid;
begin
  select cp.profile_id
  into v_cook_profile_id
  from public.cook_profiles cp
  join public.profiles p on p.id = cp.profile_id
  where p.user_id = auth.uid()
  limit 1;

  if v_cook_profile_id is null then
    return;
  end if;

  return query
  select
    co.id,
    co.request_id,
    co.publication_id,
    co.cook_profile_id,
    co.price,
    co.estimated_minutes,
    co.message,
    co.status::text,
    co.created_at,
    dp.title,
    ua.display_name,
    cr.query_text,
    cr.target_price,
    cr.requested_quantity,
    coalesce(cr.allergen_filters, '{}'::text[]),
    cr.latitude,
    cr.longitude
  from public.cook_offers co
  join public.dish_publications dp on dp.id = co.publication_id
  join public.consumer_requests cr on cr.id = co.request_id
  join public.consumer_profiles cprof on cprof.profile_id = cr.consumer_profile_id
  join public.profiles prof on prof.id = cprof.profile_id
  join public.user_accounts ua on ua.user_id = prof.user_id
  where co.cook_profile_id = v_cook_profile_id
    and co.status = 'pending'
  order by co.created_at desc;
end;
$$;
