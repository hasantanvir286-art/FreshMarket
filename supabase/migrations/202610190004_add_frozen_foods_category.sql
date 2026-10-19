-- Add a dedicated live storefront category for frozen groceries.
-- Existing product prices and stock are preserved; Frozen Paratha is moved from Bakery.
insert into public.categories(name,slug,display_order,active,featured)
values('Frozen Foods','frozen-foods',4,true,true)
on conflict(slug) do update set name=excluded.name,display_order=excluded.display_order,active=true,featured=true,updated_at=now();

update public.categories set display_order=case slug
 when 'fruits' then 1 when 'vegetables' then 2 when 'meat-seafood' then 3
 when 'frozen-foods' then 4 when 'dairy-eggs' then 5 when 'bakery' then 6
 when 'beverages' then 7 when 'snacks' then 8 when 'household' then 9
 when 'rice-grains' then 10 when 'lentils-pulses' then 11 when 'spices-essentials' then 12
 else display_order end
where slug in ('fruits','vegetables','meat-seafood','frozen-foods','dairy-eggs','bakery','beverages','snacks','household','rice-grains','lentils-pulses','spices-essentials');

update public.products
set category_id=(select id from public.categories where slug='frozen-foods'),updated_at=now()
where slug='bd-paratha';
