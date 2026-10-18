-- Read-only customer directory for authorized store managers and super admins.
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
   and (nullif(trim(p_search),'') is null or coalesce(p.full_name,'') ilike '%'||trim(p_search)||'%' or coalesce(p.email,'') ilike '%'||trim(p_search)||'%')
  group by p.id
 )
 select d.id,d.email,d.full_name,d.phone,d.created_at,d.orders,d.spent,count(*) over()::bigint
 from customer_data d order by d.created_at desc
 limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_list_customers(text,integer,integer) from public;
grant execute on function public.admin_list_customers(text,integer,integer) to authenticated;
