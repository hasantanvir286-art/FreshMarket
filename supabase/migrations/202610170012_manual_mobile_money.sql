-- Manual mobile-money checkout and superadmin-managed payment destination.
alter table public.orders add column if not exists payment_provider_reference text;

create unique index if not exists orders_manual_mobile_txid_unique
  on public.orders(payment_method, payment_provider_reference)
  where payment_method in ('bkash','nagad','rocket','upay') and payment_provider_reference is not null;

insert into public.store_settings(key,value)
values ('mobile_payment_number', jsonb_build_object('number','01811111111'))
on conflict (key) do nothing;

grant select on public.store_settings to anon;
grant select, insert, update on public.store_settings to authenticated;
create policy "public reads mobile payment destination"
  on public.store_settings for select to anon, authenticated
  using (key = 'mobile_payment_number');

create or replace function public.place_guest_mobile_money_order(
  p_name text,
  p_email text,
  p_phone text,
  p_address jsonb,
  p_instructions text,
  p_items jsonb,
  p_idempotency_key uuid,
  p_payment_provider text,
  p_transaction_id text
) returns text
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  v_provider text := lower(trim(coalesce(p_payment_provider,'')));
  v_txid text := upper(trim(coalesce(p_transaction_id,'')));
  v_order_number text;
begin
  if v_provider not in ('bkash','nagad','rocket','upay') then
    raise exception 'Choose bKash, Nagad, Rocket, or Upay';
  end if;
  if v_txid !~ '^[A-Z0-9-]{5,64}$' then
    raise exception 'Enter a valid transaction ID (5–64 letters, numbers, or hyphens)';
  end if;

  v_order_number := public.place_guest_cod_order(
    p_name,p_email,p_phone,p_address,p_instructions,p_items,p_idempotency_key
  );

  update public.orders
  set payment_method=v_provider,
      payment_provider_reference=v_txid,
      payment_status='pending',
      updated_at=now()
  where order_number=v_order_number;

  if not found then raise exception 'Could not save the mobile-money payment details'; end if;
  return v_order_number;
end;
$$;

revoke all on function public.place_guest_mobile_money_order(text,text,text,jsonb,text,jsonb,uuid,text,text) from public;
grant execute on function public.place_guest_mobile_money_order(text,text,text,jsonb,text,jsonb,uuid,text,text) to anon,authenticated;


create or replace function public.admin_resolve_manual_mobile_payment(
  p_order_id uuid,
  p_result text
) returns boolean
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  v_order public.orders%rowtype;
  v_item record;
begin
  if not public.has_staff_role(array['super_admin','order_manager','store_manager']::public.staff_role[]) then
    raise exception 'You are not allowed to verify payments';
  end if;
  if p_result not in ('paid','failed') then raise exception 'Choose paid or failed'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then return false; end if;
  if v_order.payment_method not in ('bkash','nagad','rocket','upay') then
    raise exception 'This is not a manual mobile-money order';
  end if;
  if v_order.payment_status<>'pending' then return true; end if;

  if p_result='paid' then
    update public.orders set payment_status='paid',status='confirmed',updated_at=now() where id=v_order.id;
    return true;
  end if;

  update public.orders set payment_status='failed',status='cancelled',updated_at=now() where id=v_order.id;
  for v_item in select product_id,quantity from public.order_items where order_id=v_order.id and product_id is not null loop
    update public.products set stock=stock+v_item.quantity,updated_at=now() where id=v_item.product_id;
    insert into public.inventory_movements(product_id,quantity_delta,reason,order_id,actor_id)
    values(v_item.product_id,v_item.quantity,'manual mobile-money payment rejected; stock restored',v_order.id,auth.uid());
  end loop;
  return true;
end;
$$;

revoke all on function public.admin_resolve_manual_mobile_payment(uuid,text) from public,anon;
grant execute on function public.admin_resolve_manual_mobile_payment(uuid,text) to authenticated;
