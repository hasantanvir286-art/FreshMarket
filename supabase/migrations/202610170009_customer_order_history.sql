-- Secure order history for the signed-in customer.
-- Previously placed guest orders can be claimed only when the account email is verified.
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
begin
 if v_user_id is null then raise exception 'Sign in to view your order history'; end if;
 select lower(u.email),u.email_confirmed_at is not null
 into v_email,v_email_verified
 from auth.users u where u.id=v_user_id;

 -- Attach only unclaimed orders matching this customer's verified email.
 if v_email_verified and v_email is not null then
  update public.orders o set customer_id=v_user_id,updated_at=now()
  where o.customer_id is null and lower(o.guest_email)=v_email;
 end if;

 return query
 select o.id,o.order_number,o.status,o.payment_method,o.total_cents,o.created_at,
  coalesce(jsonb_agg(jsonb_build_object(
   'product_name',oi.product_name,
   'quantity',oi.quantity,
   'unit_price_cents',oi.unit_price_cents
  ) order by oi.product_name) filter(where oi.id is not null),'[]'::jsonb) as items
 from public.orders o
 left join public.order_items oi on oi.order_id=o.id
 where o.customer_id=v_user_id
 group by o.id
 order by o.created_at desc
 limit 20;
end;
$$;

revoke all on function public.customer_list_my_orders() from public,anon;
grant execute on function public.customer_list_my_orders() to authenticated;
