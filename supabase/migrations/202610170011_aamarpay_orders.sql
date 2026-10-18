-- Track aamarPay payment reference and release inventory exactly once on failed payment.
alter table public.orders add column if not exists payment_provider_reference text;

create or replace function public.resolve_aamarpay_payment(
 p_order_number text,
 p_result text,
 p_provider_reference text default null
) returns boolean
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
 v_order public.orders%rowtype;
 v_item record;
begin
 if coalesce(current_setting('request.jwt.claim.role',true),'')<>'service_role' then
  raise exception 'Only the payment server can resolve gateway payments';
 end if;
 if p_result not in ('paid','failed') then raise exception 'Invalid payment result'; end if;
 select * into v_order from public.orders where order_number=p_order_number for update;
 if not found then return false; end if;
 if v_order.payment_method<>'aamarpay' then raise exception 'Order is not an aamarPay order'; end if;
 if v_order.payment_status='paid' then return true; end if;
 if v_order.status='cancelled' then return true; end if;
 if p_result='paid' then
  update public.orders set payment_status='paid',status='confirmed',payment_provider_reference=p_provider_reference,updated_at=now()
  where id=v_order.id;
  return true;
 end if;
 update public.orders set payment_status='failed',status='cancelled',payment_provider_reference=p_provider_reference,updated_at=now()
 where id=v_order.id;
 for v_item in select product_id,quantity from public.order_items where order_id=v_order.id and product_id is not null loop
  update public.products set stock=stock+v_item.quantity,updated_at=now() where id=v_item.product_id;
  insert into public.inventory_movements(product_id,quantity_delta,reason,order_id,actor_id)
  values(v_item.product_id,v_item.quantity,'aamarPay payment failed; stock restored',v_order.id,null);
 end loop;
 return true;
end;
$$;

revoke all on function public.resolve_aamarpay_payment(text,text,text) from public,anon,authenticated;
grant execute on function public.resolve_aamarpay_payment(text,text,text) to service_role;
