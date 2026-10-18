-- Secure, audited stock adjustment for store and inventory staff.
create or replace function public.admin_adjust_inventory_stock(
  p_product_id uuid,
  p_new_stock integer,
  p_reason text default 'Admin stock adjustment'
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_stock integer;
  v_delta integer;
begin
  if auth.uid() is null or not public.has_staff_role(array['super_admin','store_manager','inventory_manager']::public.staff_role[]) then
    raise exception 'You are not authorized to adjust inventory';
  end if;
  if p_new_stock is null or p_new_stock < 0 then
    raise exception 'Stock must be zero or greater';
  end if;
  select stock into v_old_stock from public.products where id = p_product_id for update;
  if not found then raise exception 'Product not found'; end if;
  v_delta := p_new_stock - v_old_stock;
  if v_delta = 0 then return p_new_stock; end if;
  update public.products set stock = p_new_stock, updated_at = now() where id = p_product_id;
  insert into public.inventory_movements(product_id, quantity_delta, reason, actor_id)
  values(p_product_id, v_delta, left(coalesce(nullif(trim(p_reason), ''), 'Admin stock adjustment'), 200), auth.uid());
  return p_new_stock;
end;
$$;

revoke all on function public.admin_adjust_inventory_stock(uuid,integer,text) from public, anon;
grant execute on function public.admin_adjust_inventory_stock(uuid,integer,text) to authenticated;
