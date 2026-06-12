create or replace function public.accept_cook_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer record;
  v_consumer_profile_id uuid;
  v_order_id uuid;
begin
  select o.* into v_offer
  from public.cook_offers o
  where o.id = p_offer_id and o.status = 'pending'
  for update;

  if v_offer is null then
    raise exception 'Oferta no disponible o ya fue respondida';
  end if;

  select cp.profile_id into v_consumer_profile_id
  from public.consumer_profiles cp
  join public.profiles p on p.id = cp.profile_id
  join public.consumer_requests cr on cr.consumer_profile_id = cp.profile_id
  where cr.id = v_offer.request_id and p.user_id = auth.uid()
  limit 1;

  if v_consumer_profile_id is null then
    raise exception 'No eres el consumidor de esta solicitud';
  end if;

  update public.cook_offers
  set status = 'accepted', updated_at = timezone('utc', now())
  where id = p_offer_id;

  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where request_id = v_offer.request_id
    and id <> p_offer_id
    and status = 'pending';

  update public.consumer_requests
  set status = 'matched', updated_at = timezone('utc', now())
  where id = v_offer.request_id;

  insert into public.orders (
    request_id,
    offer_id,
    consumer_profile_id,
    cook_profile_id,
    publication_id,
    agreed_price
  ) values (
    v_offer.request_id,
    p_offer_id,
    v_consumer_profile_id,
    v_offer.cook_profile_id,
    v_offer.publication_id,
    v_offer.price
  ) returning id into v_order_id;

  update public.cook_profiles
  set is_available = false, updated_at = timezone('utc', now())
  where profile_id = v_offer.cook_profile_id;

  return v_order_id;
end;
$$;

create or replace function public.cancel_active_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_is_participant boolean;
begin
  select *
  into v_order
  from public.orders
  where id = p_order_id
    and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible o ya fue cerrado';
  end if;

  select exists (
    select 1
    from public.consumer_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = v_order.consumer_profile_id
      and p.user_id = auth.uid()
  ) or exists (
    select 1
    from public.cook_profiles cp
    join public.profiles p on p.id = cp.profile_id
    where cp.profile_id = v_order.cook_profile_id
      and p.user_id = auth.uid()
  )
  into v_is_participant;

  if not coalesce(v_is_participant, false) then
    raise exception 'No participas en este pedido';
  end if;

  update public.orders
  set status = 'cancelled', updated_at = timezone('utc', now())
  where id = p_order_id;

  update public.consumer_requests
  set status = 'cancelled', updated_at = timezone('utc', now())
  where id = v_order.request_id
    and status in ('searching', 'matched');

  update public.cook_offers
  set status = 'rejected', updated_at = timezone('utc', now())
  where request_id = v_order.request_id
    and status = 'pending';

  update public.cook_profiles
  set is_available = true, updated_at = timezone('utc', now())
  where profile_id = v_order.cook_profile_id;
end;
$$;
