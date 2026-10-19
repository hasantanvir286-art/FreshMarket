-- Make Frozen Foods the only active storefront category by default.
-- Reversible from Admin -> Products -> Manage categories.
do $$
declare frozen_category_id uuid;
begin
  select id into frozen_category_id from public.categories where slug='frozen-foods';
  if frozen_category_id is null then
    raise exception 'Frozen Foods category is missing. Run migration 202610190004_add_frozen_foods_category.sql first.';
  end if;
  update public.categories
  set active=(id=frozen_category_id),updated_at=now()
  where active is distinct from (id=frozen_category_id);
end;
$$;
