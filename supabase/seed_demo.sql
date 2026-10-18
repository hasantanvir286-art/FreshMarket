-- Optional Fresh Market sample catalog for development only.
-- Run in Supabase SQL Editor after the initial migration. Every row is marked DEMO.
begin;
alter table public.products add column if not exists image_url text;
alter table public.products add column if not exists demo_data boolean not null default false;
insert into public.categories(name,slug,display_order,active,featured) values
 ('Fruits','fruits',1,true,true),('Vegetables','vegetables',2,true,true),('Meat & Seafood','meat-seafood',3,true,true),
 ('Dairy & Eggs','dairy-eggs',4,true,true),('Bakery','bakery',5,true,true),('Beverages','beverages',6,true,true),
 ('Snacks','snacks',7,true,true),('Household','household',8,true,true) on conflict(slug) do nothing;
insert into public.products(category_id,name,slug,sku,unit,price_cents,original_price_cents,stock,low_stock_threshold,status,featured,bestseller,demo_data,image_url,short_description)
select c.id,v.name,v.slug,v.sku,v.unit,v.price_cents,v.original_price_cents,v.stock,10,'active',v.featured,v.bestseller,true,'https://images.unsplash.com/'||v.image_id||'?auto=format&fit=crop&w=680&q=82','DEMO SAMPLE — Replace with real product details before launch.'
from (values
 ('fruits','Organic Avocados','organic-avocados','DEMO-FR-001','2 pcs · approx. 400g',349,420,24,true,false,'photo-1523049673857-eb18f1d7b578'),
 ('fruits','Strawberries','strawberries','DEMO-FR-002','250g pack',425,null,18,true,true,'photo-1464965911861-746a04b4bca6'),
 ('vegetables','Baby Spinach','baby-spinach','DEMO-VE-001','150g bag',220,275,31,true,false,'photo-1576045057995-568f588f82fb'),
 ('vegetables','Vine Tomatoes','vine-tomatoes','DEMO-VE-002','500g punnet',285,null,4,true,false,'photo-1546094096-0df4bcaaa337'),
 ('dairy-eggs','Free-range Eggs','free-range-eggs','DEMO-DA-001','12 pack · large',560,null,26,true,true,'photo-1506976785307-8732e854ad03'),
 ('bakery','Sourdough Loaf','sourdough-loaf','DEMO-BA-001','700g · baked today',480,null,12,true,false,'photo-1585478259715-876acc5be8eb'),
 ('meat-seafood','Atlantic Salmon','atlantic-salmon','DEMO-ME-001','2 fillets · 300g',1290,1550,8,true,false,'photo-1519708227418-c8fd9a32b7a2'),
 ('dairy-eggs','Whole Milk','whole-milk','DEMO-DA-002','1 litre · fresh',215,null,40,true,false,'photo-1563636619-e9143da7973b'),
 ('fruits','Sweet Blueberries','sweet-blueberries','DEMO-FR-003','125g punnet',380,null,16,false,false,'photo-1498557850523-fd3d118b962e'),
 ('vegetables','Rainbow Carrots','rainbow-carrots','DEMO-VE-003','500g bunch',270,null,22,false,false,'photo-1445282768818-728615cc910a'),
 ('dairy-eggs','Creamy Greek Yogurt','creamy-greek-yogurt','DEMO-DA-003','500g tub',420,null,14,false,false,'photo-1488477181946-6428a0291777'),
 ('fruits','Golden Bananas','golden-bananas','DEMO-FR-004','6 pcs · approx. 900g',195,null,0,false,false,'photo-1571771894821-ce9b6c11b08e'),
 ('fruits','Navel Oranges','navel-oranges','DEMO-FR-005','1kg bag',399,null,30,false,false,'photo-1547514701-42782101795e'),
 ('vegetables','Green Broccoli','green-broccoli','DEMO-VE-004','1 head',249,null,17,false,false,'photo-1459411621453-7b03977f4bfc'),
 ('vegetables','Crisp Cucumbers','crisp-cucumbers','DEMO-VE-005','2 pcs',199,null,21,false,false,'photo-1604977042946-1eecc30f269e'),
 ('meat-seafood','Chicken Breast','chicken-breast','DEMO-ME-002','500g pack',799,null,13,false,true,'photo-1604503468506-a8da13d82791'),
 ('meat-seafood','Lean Ground Beef','lean-ground-beef','DEMO-ME-003','500g pack',849,null,9,false,false,'photo-1607623814075-e51df1bdc82f'),
 ('dairy-eggs','Mature Cheddar','mature-cheddar','DEMO-DA-004','250g block',475,null,19,false,false,'photo-1618164436241-4473940d1f5c'),
 ('dairy-eggs','Salted Butter','salted-butter','DEMO-DA-005','200g block',365,null,11,false,false,'photo-1589985270826-4b7bb135bc9d'),
 ('bakery','Wholegrain Sandwich Bread','wholegrain-bread','DEMO-BA-002','680g loaf',329,null,15,false,false,'photo-1598373182133-52452f7691ef'),
 ('beverages','Fresh Orange Juice','fresh-orange-juice','DEMO-BE-001','1 litre bottle',450,null,20,false,false,'photo-1600271886742-f049cd451bba'),
 ('beverages','Sparkling Mineral Water','sparkling-water','DEMO-BE-002','6 × 500ml',599,null,25,false,false,'photo-1600271886742-f049cd451bba'),
 ('snacks','Honey Oat Granola','honey-oat-granola','DEMO-SN-001','350g pouch',525,null,18,false,false,'photo-1517093157656-b9eccef91cb1'),
 ('household','Gentle Dish Soap','gentle-dish-soap','DEMO-HO-001','500ml bottle',315,null,10,false,false,'photo-1585421514284-efb74c2b69ba')
) as v(category_slug,name,slug,sku,unit,price_cents,original_price_cents,stock,featured,bestseller,image_id)
join public.categories c on c.slug=v.category_slug
on conflict(sku) do update set category_id=excluded.category_id,name=excluded.name,slug=excluded.slug,unit=excluded.unit,
 price_cents=excluded.price_cents,original_price_cents=excluded.original_price_cents,stock=excluded.stock,status=excluded.status,
 featured=excluded.featured,bestseller=excluded.bestseller,demo_data=true,image_url=excluded.image_url,short_description=excluded.short_description;
commit;
