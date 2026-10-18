-- Guest cash-on-delivery checkout. The database locks stock and calculates trusted prices.
alter table public.orders add column if not exists idempotency_key uuid unique;

create or replace function public.place_guest_cod_order(
 p_name text,
 p_email text,
 p_phone text,
 p_address jsonb,
 p_instructions text,
 p_items jsonb,
 p_idempotency_key uuid
) returns text
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
 v_existing text;
 v_order_number text;
 v_item record;
 v_product public.products%rowtype;
 v_subtotal integer:=0;
 v_delivery integer;
 v_total integer;
 v_lines integer:=0;
begin
 if p_idempotency_key is null then raise exception 'A checkout request key is required'; end if;
 select order_number into v_existing from public.orders where idempotency_key=p_idempotency_key;
 if found then return v_existing; end if;
 if length(trim(coalesce(p_name,''))) not between 1 and 120 then raise exception 'Enter your name'; end if;
 if length(trim(coalesce(p_email,'')))>254 or p_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then raise exception 'Enter a valid email address'; end if;
 if length(trim(coalesce(p_phone,''))) not between 7 and 32 then raise exception 'Enter a valid phone number'; end if;
 if jsonb_typeof(p_address)<>'object' or length(trim(coalesce(p_address->>'line1','')))=0 or length(trim(coalesce(p_address->>'city','')))=0 or length(trim(coalesce(p_address->>'postal_code','')))=0 then
  raise exception 'Enter a complete delivery address';
 end if;
 if length(coalesce(p_instructions,''))>500 then raise exception 'Delivery instructions are too long'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>30 then raise exception 'Your basket is empty or too large'; end if;
 if exists(select 1 from jsonb_to_recordset(p_items) as x(product_id uuid,quantity integer) where product_id is null or quantity is null or quantity<1 or quantity>99) then
  raise exception 'One or more basket quantities are invalid';
 end if;
 -- Basic contact-based throttle. Add edge-level IP throttling or CAPTCHA before public launch.
 if exists(select 1 from public.orders o where o.created_at>now()-interval '15 minutes' and o.status='pending'
   and (o.guest_email=lower(trim(p_email)) or o.guest_phone=trim(p_phone))) then
  raise exception 'A recent order already uses these contact details. Please wait before trying again';
 end if;

 v_order_number:='FM-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISS')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
 insert into public.orders(order_number,guest_name,guest_email,guest_phone,delivery_address,delivery_instructions,payment_method,currency,subtotal_cents,delivery_cents,total_cents,idempotency_key)
 values(v_order_number,trim(p_name),lower(trim(p_email)),trim(p_phone),p_address,left(coalesce(p_instructions,''),500),'cash_on_delivery','USD',0,0,0,p_idempotency_key);

 for v_item in
  select x.product_id,sum(x.quantity)::integer as quantity
  from jsonb_to_recordset(p_items) as x(product_id uuid,quantity integer)
  group by x.product_id
 loop
  if v_item.quantity>99 then raise exception 'A product quantity exceeds the order limit'; end if;
  update public.products p set stock=p.stock-v_item.quantity,updated_at=now()
   where p.id=v_item.product_id and p.status='active' and not p.demo_data and p.stock>=v_item.quantity
   returning p.* into v_product;
  if not found then raise exception 'An item is unavailable, a demo item, or out of stock. Refresh your basket and try again'; end if;
  v_lines:=v_lines+1;
  v_subtotal:=v_subtotal+(v_product.price_cents*v_item.quantity);
  insert into public.order_items(order_id,product_id,product_name,sku,unit,quantity,unit_price_cents,line_total_cents)
   values((select id from public.orders where idempotency_key=p_idempotency_key),v_product.id,v_product.name,v_product.sku,v_product.unit,v_item.quantity,v_product.price_cents,v_product.price_cents*v_item.quantity);
  insert into public.inventory_movements(product_id,quantity_delta,reason,order_id,actor_id)
   values(v_product.id,-v_item.quantity,'guest cash-on-delivery order',(select id from public.orders where idempotency_key=p_idempotency_key),null);
 end loop;
 if v_lines=0 then raise exception 'Your basket has no purchasable items'; end if;
 v_delivery:=case when v_subtotal>=4500 then 0 else 495 end;
 v_total:=v_subtotal+v_delivery;
 update public.orders set subtotal_cents=v_subtotal,delivery_cents=v_delivery,total_cents=v_total,updated_at=now()
  where idempotency_key=p_idempotency_key;
 return v_order_number;
exception when unique_violation then
 select order_number into v_existing from public.orders where idempotency_key=p_idempotency_key;
 if v_existing is not null then return v_existing; end if;
 raise;
end;
$$;

revoke all on function public.place_guest_cod_order(text,text,text,jsonb,text,jsonb,uuid) from public;
grant execute on function public.place_guest_cod_order(text,text,text,jsonb,text,jsonb,uuid) to anon,authenticated;
