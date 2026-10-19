-- Let phone-auth customers claim matching guest orders and leave verified-order reviews.
-- A phone is trusted only after Supabase sets auth.users.phone_confirmed_at.

create or replace function public.customer_list_my_orders()
returns table (
 id uuid,
 order_number text,
 status public.order_status,
 payment_method text,
 total_cents integer,
 created_at timestamptz,
 items jsonb
)
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
 v_user_id uuid:=auth.uid();
 v_email text;
 v_email_verified boolean:=false;
 v_phone text;
 v_phone_verified boolean:=false;
begin
 if v_user_id is null then raise exception 'Sign in to view your order history'; end if;
 select lower(u.email),u.email_confirmed_at is not null,u.phone,u.phone_confirmed_at is not null
 into v_email,v_email_verified,v_phone,v_phone_verified
 from auth.users u where u.id=v_user_id;

 update public.orders o set customer_id=v_user_id,updated_at=now()
 where o.customer_id is null and (
  (v_email_verified and v_email is not null and lower(o.guest_email)=v_email)
  or (v_phone_verified and v_phone is not null and
   case when left(regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g'),3)='880'
    then '0'||substr(regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g'),4)
    else regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g') end
   = case when left(regexp_replace(v_phone,'[^0-9]','','g'),3)='880'
    then '0'||substr(regexp_replace(v_phone,'[^0-9]','','g'),4)
    else regexp_replace(v_phone,'[^0-9]','','g') end)
 );

 return query
 select o.id,o.order_number,o.status,o.payment_method,o.total_cents,o.created_at,
  coalesce(jsonb_agg(jsonb_build_object(
   'product_name',oi.product_name,
   'quantity',oi.quantity,
   'unit_price_cents',oi.unit_price_cents,
   'image_url',p.image_url,
   'image_storage_path',pi.storage_path
  ) order by oi.product_name) filter(where oi.id is not null),'[]'::jsonb) as items
 from public.orders o
 left join public.order_items oi on oi.order_id=o.id
 left join public.products p on p.id=oi.product_id
 left join lateral (
  select product_image.storage_path
  from public.product_images product_image
  where product_image.product_id=oi.product_id
  order by product_image.display_order,product_image.created_at
  limit 1
 ) pi on true
 where o.customer_id=v_user_id
 group by o.id
 order by o.created_at desc
 limit 20;
end;
$$;

revoke all on function public.customer_list_my_orders() from public,anon;
grant execute on function public.customer_list_my_orders() to authenticated;

create or replace function public.submit_verified_product_review(
 p_product_id uuid,
 p_rating integer,
 p_review_text text
)
returns uuid
language plpgsql
security definer
set search_path=public,auth,pg_temp
as $$
declare
 v_user_id uuid:=auth.uid();
 v_email text;
 v_email_verified boolean:=false;
 v_phone text;
 v_phone_verified boolean:=false;
 v_display_name text;
 v_review_id uuid;
begin
 if v_user_id is null then raise exception 'Sign in to leave a review'; end if;
 if p_rating is null or p_rating<1 or p_rating>5 then raise exception 'Choose a rating from 1 to 5 stars'; end if;
 if p_review_text is null or length(trim(p_review_text))<5 or length(trim(p_review_text))>1000 then
  raise exception 'Review text must be between 5 and 1000 characters';
 end if;
 if not exists(select 1 from public.products p where p.id=p_product_id and p.status='active' and p.demo_data=false) then
  raise exception 'This product is not available for review';
 end if;

 select lower(u.email),u.email_confirmed_at is not null,u.phone,u.phone_confirmed_at is not null,
  coalesce(nullif(trim(p.full_name),''),nullif(trim(u.raw_user_meta_data->>'full_name'),''),nullif(split_part(u.email,'@',1),''),u.phone,'Customer')
 into v_email,v_email_verified,v_phone,v_phone_verified,v_display_name
 from auth.users u left join public.profiles p on p.id=u.id where u.id=v_user_id;
 if not v_email_verified and not v_phone_verified then
  raise exception 'Verify your email or mobile number before leaving a review';
 end if;

 update public.orders o set customer_id=v_user_id,updated_at=now()
 where o.customer_id is null and (
  (v_email_verified and v_email is not null and lower(o.guest_email)=v_email)
  or (v_phone_verified and v_phone is not null and
   case when left(regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g'),3)='880'
    then '0'||substr(regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g'),4)
    else regexp_replace(coalesce(o.guest_phone,''),'[^0-9]','','g') end
   = case when left(regexp_replace(v_phone,'[^0-9]','','g'),3)='880'
    then '0'||substr(regexp_replace(v_phone,'[^0-9]','','g'),4)
    else regexp_replace(v_phone,'[^0-9]','','g') end)
 );

 if not exists (
  select 1 from public.orders o join public.order_items oi on oi.order_id=o.id
  where o.customer_id=v_user_id and o.status='delivered' and oi.product_id=p_product_id
 ) then raise exception 'A delivered order containing this product is required to review it'; end if;

 insert into public.reviews(product_id,customer_id,customer_display_name,rating,review_text,moderation_status)
 values(p_product_id,v_user_id,v_display_name,p_rating,trim(p_review_text),'approved')
 on conflict (product_id,customer_id) where customer_id is not null
 do update set customer_display_name=excluded.customer_display_name,rating=excluded.rating,
  review_text=excluded.review_text,moderation_status='approved',created_at=now()
 returning id into v_review_id;
 return v_review_id;
end;
$$;

revoke all on function public.submit_verified_product_review(uuid,integer,text) from public,anon;
grant execute on function public.submit_verified_product_review(uuid,integer,text) to authenticated;


-- Permit phone-first customers to check out without an email address.
-- Allow separate legitimate orders from the same customer while preserving
-- idempotency protection for retries of the exact same checkout request.
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
 if nullif(trim(coalesce(p_email,'')),'') is not null and (length(trim(p_email))>254 or p_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') then raise exception 'Enter a valid email address'; end if;
 if length(trim(coalesce(p_phone,''))) not between 7 and 32 then raise exception 'Enter a valid phone number'; end if;
 if jsonb_typeof(p_address)<>'object' or length(trim(coalesce(p_address->>'line1','')))=0 or length(trim(coalesce(p_address->>'city','')))=0 or length(trim(coalesce(p_address->>'postal_code','')))=0 then
  raise exception 'Enter a complete delivery address';
 end if;
 if length(coalesce(p_instructions,''))>500 then raise exception 'Delivery instructions are too long'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>30 then raise exception 'Your basket is empty or too large'; end if;
 if exists(select 1 from jsonb_to_recordset(p_items) as x(product_id uuid,quantity integer) where product_id is null or quantity is null or quantity<1 or quantity>99) then
  raise exception 'One or more basket quantities are invalid';
 end if;

 v_order_number:='FM-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISS')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
 insert into public.orders(order_number,guest_name,guest_email,guest_phone,delivery_address,delivery_instructions,payment_method,currency,subtotal_cents,delivery_cents,total_cents,idempotency_key)
 values(v_order_number,trim(p_name),nullif(lower(trim(coalesce(p_email,''))),''),trim(p_phone),p_address,left(coalesce(p_instructions,''),500),'cash_on_delivery','BDT',0,0,0,p_idempotency_key);

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
 v_delivery:=case when v_subtotal>=250000 then 0 else 8000 end;
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


-- Include phone-auth customers in the existing staff-only customer directory search.
create or replace function public.admin_list_customers(p_search text default null,p_limit integer default 50,p_offset integer default 0)
returns table(customer_id uuid,email text,full_name text,phone text,joined_at timestamptz,order_count bigint,lifetime_spend_cents bigint,total_count bigint)
language plpgsql stable security definer set search_path=public,pg_temp as $$
begin
 if not public.has_staff_role(array['super_admin','store_manager']::public.staff_role[]) then
  raise exception 'Only a store manager or super admin can view customers';
 end if;
 if p_limit is null or p_limit not between 1 and 100 or p_offset is null or p_offset<0 then
  raise exception 'Invalid customer page';
 end if;
 if length(coalesce(p_search,''))>100 then raise exception 'Search text is too long'; end if;
 return query
 with customer_data as (
  select p.id,p.email,p.full_name,p.phone,p.created_at,
   count(o.id) filter(where o.status<>'cancelled') as orders,
   coalesce(sum(o.total_cents) filter(where o.status<>'cancelled'),0)::bigint as spent
  from public.profiles p
  left join public.orders o on o.customer_id=p.id
  where not exists(select 1 from public.staff_roles sr where sr.user_id=p.id and sr.active)
   and (nullif(trim(p_search),'') is null or coalesce(p.full_name,'') ilike '%'||trim(p_search)||'%'
    or coalesce(p.email,'') ilike '%'||trim(p_search)||'%' or coalesce(p.phone,'') ilike '%'||trim(p_search)||'%')
  group by p.id
 )
 select d.id,d.email,d.full_name,d.phone,d.created_at,d.orders,d.spent,count(*) over()::bigint
 from customer_data d order by d.created_at desc
 limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_list_customers(text,integer,integer) from public,anon;
grant execute on function public.admin_list_customers(text,integer,integer) to authenticated;
