-- Fix get_active_order: timezone('utc', now()) returns timestamp without time zone
-- but the RETURNS TABLE declares server_now as timestamptz.
-- now() already returns timestamptz, so use it directly.

drop function if exists public.get_active_order();

create or replace function public.get_active_order()
returns table (
  id uuid,
  request_id uuid,
  offer_id uuid,
  consumer_profile_id uuid,
  cook_profile_id uuid,
  publication_id uuid,
  agreed_price numeric,
  requested_quantity integer,
  status text,
  order_phase text,
  estimated_preparation_minutes integer,
  preparation_confirmation_deadline_at timestamptz,
  preparation_confirmed_at timestamptz,
  preparation_deadline_at timestamptz,
  ready_at timestamptz,
  delivery_deadline_at timestamptz,
  delivered_at timestamptz,
  completed_at timestamptz,
  viewer_role text,
  delivery_photo_storage_path text,
  delivery_photo_public_url text,
  created_at timestamptz,
  dish_title text,
  cook_business_name text,
  consumer_display_name text,
  publication_latitude double precision,
  publication_longitude double precision,
  consumer_latitude double precision,
  consumer_longitude double precision,
  dish_photo_storage_path text,
  dish_photo_public_url text,
  server_now timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    ord.id,
    ord.request_id,
    ord.offer_id,
    ord.consumer_profile_id,
    ord.cook_profile_id,
    ord.publication_id,
    ord.agreed_price,
    cr.requested_quantity,
    ord.status::text,
    ord.order_phase,
    ord.estimated_preparation_minutes,
    ord.preparation_confirmation_deadline_at,
    ord.preparation_confirmed_at,
    ord.preparation_deadline_at,
    ord.ready_at,
    ord.delivery_deadline_at,
    ord.delivered_at,
    ord.completed_at,
    case
      when exists (
        select 1
        from public.cook_profiles cp
        join public.profiles p on p.id = cp.profile_id
        where cp.profile_id = ord.cook_profile_id
          and p.user_id = auth.uid()
      ) then 'cook'
      else 'consumer'
    end,
    delivery_photo.storage_path,
    delivery_photo.public_url,
    ord.created_at,
    dp.title,
    cprof.business_name,
    ua.display_name,
    dp.latitude,
    dp.longitude,
    cr.latitude,
    cr.longitude,
    photo.storage_path,
    photo.public_url,
    now() as server_now
  from public.orders ord
  join public.consumer_requests cr on cr.id = ord.request_id
  join public.dish_publications dp on dp.id = ord.publication_id
  join public.cook_profiles cprof on cprof.profile_id = ord.cook_profile_id
  join public.consumer_profiles consumer_prof on consumer_prof.profile_id = ord.consumer_profile_id
  join public.profiles consumer_profile on consumer_profile.id = consumer_prof.profile_id
  join public.user_accounts ua on ua.user_id = consumer_profile.user_id
  left join lateral (
    select ph.storage_path, ph.public_url
    from public.dish_photos ph
    where ph.publication_id = dp.id
    order by ph.position asc, ph.created_at asc
    limit 1
  ) photo on true
  left join lateral (
    select odp.storage_path, odp.public_url
    from public.order_delivery_photos odp
    where odp.order_id = ord.id
    order by odp.created_at desc
    limit 1
  ) delivery_photo on true
  where ord.status = 'active'
    and public.is_order_participant(ord)
  order by ord.created_at desc
  limit 1;
end;
$$;
