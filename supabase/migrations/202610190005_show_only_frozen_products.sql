-- Hide every non-frozen real catalog product from the customer storefront.
-- Staff can restore any product from Admin -> Products using its Show action.
-- No product, order, price, or stock data is deleted or changed.
do $$
declare
  frozen_category_id uuid;
begin
  select id into frozen_category_id from public.categories where slug='frozen-foods' and active=true;
  if frozen_category_id is null then
    raise exception 'Frozen Foods category is missing. Run migration 202610190004_add_frozen_foods_category.sql first.';
  end if;

  update public.products p
  set status='archived',updated_at=now()
  where p.status='active'
    and p.category_id is distinct from frozen_category_id
    and p.demo_data=false;
end;
$$;
