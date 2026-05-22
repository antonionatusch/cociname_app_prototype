update public.consumer_requests cr
set status = 'expired', updated_at = timezone('utc', now())
where cr.status = 'matched'
  and exists (
    select 1
    from public.orders ord
    where ord.request_id = cr.id
      and ord.status = 'completed'
  );

create or replace function public.confirm_order_delivery(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order
  from public.orders
  where id = p_order_id and status = 'active'
  for update;

  if v_order.id is null then
    raise exception 'Pedido no disponible';
  end if;

  if not public.is_order_cook(v_order) then
    raise exception 'Solo el cocinero puede confirmar entrega';
  end if;

  if v_order.order_phase not in ('ready', 'delivering') then
    raise exception 'El pedido todavía no está listo para entregar';
  end if;

  if not exists (
    select 1 from public.order_delivery_photos odp where odp.order_id = p_order_id
  ) then
    raise exception 'Debes registrar al menos una foto de entrega';
  end if;

  update public.orders
  set
    order_phase = 'delivered',
    delivered_at = timezone('utc', now()),
    completed_at = timezone('utc', now()),
    status = 'completed',
    updated_at = timezone('utc', now())
  where id = p_order_id;

  update public.consumer_requests
  set status = 'expired', updated_at = timezone('utc', now())
  where id = v_order.request_id
    and status in ('searching', 'matched');

  update public.cook_offers
  set status = 'expired', updated_at = timezone('utc', now())
  where request_id = v_order.request_id
    and status = 'pending';

  update public.cook_profiles
  set is_available = true, updated_at = timezone('utc', now())
  where profile_id = v_order.cook_profile_id;
end;
$$;
