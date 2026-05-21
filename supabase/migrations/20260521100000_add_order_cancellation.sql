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
end;
$$;
