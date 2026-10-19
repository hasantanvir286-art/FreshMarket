-- Bangladesh grocery catalog (prices in BDT; stock in units/packs).
-- This single statement creates missing categories, inserts/activates products, and returns its row count.
-- Confirm quantities and prices against your actual inventory before accepting orders.
with category_seed(name,slug,display_order) as (values
 ('Fruits','fruits',1),('Vegetables','vegetables',2),('Meat & Seafood','meat-seafood',3),
 ('Frozen Foods','frozen-foods',4),('Dairy & Eggs','dairy-eggs',5),('Bakery','bakery',6),('Beverages','beverages',7),
 ('Snacks','snacks',8),('Household','household',9),('Rice & Grains','rice-grains',10),
 ('Lentils & Pulses','lentils-pulses',11),('Spices & Essentials','spices-essentials',12)
), upserted_categories as (
 insert into public.categories(name,slug,display_order,active,featured)
 select name,slug,display_order,true,true from category_seed
 on conflict(slug) do update set active=true
 returning id,name
), catalog(category_slug,name,slug,sku,unit,price_tk,stock,featured,image_url) as (values
 ('Fruits','Bananas','bd-bananas','FM-BD-001','1 dozen',120,300,true,'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Seasonal Mangoes','bd-mangoes','FM-BD-002','1 kg',180,240,true,'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Guava','bd-guava','FM-BD-003','1 kg',100,220,false,'https://images.unsplash.com/photo-1536511132770-e5058c7e8c46?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Papaya','bd-papaya','FM-BD-004','1 pc · approx. 1 kg',90,180,false,'https://images.unsplash.com/photo-1517282009859-f000ec3b26fe?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Pineapple','bd-pineapple','FM-BD-005','1 pc',80,150,false,'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Green Coconut','bd-green-coconut','FM-BD-006','1 pc',75,160,false,'https://images.unsplash.com/photo-1550828520-4cb496926fc9?auto=format&fit=crop&w=680&q=82'),
 ('Fruits','Sweet Limes','bd-sweet-lime','FM-BD-007','1 kg',140,140,false,'https://images.unsplash.com/photo-1513558161293-cf1b6fc9b5d8?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Potatoes','bd-potatoes','FM-BD-008','1 kg',45,800,true,'https://images.unsplash.com/photo-1518977676601-b53f82abba655?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Red Onions','bd-red-onions','FM-BD-009','1 kg',85,700,true,'https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Tomatoes','bd-tomatoes','FM-BD-010','1 kg',80,500,true,'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Green Chillies','bd-green-chillies','FM-BD-011','250 g',35,400,false,'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Eggplant (Begun)','bd-eggplant','FM-BD-012','1 kg',70,300,false,'https://images.unsplash.com/photo-1659261208412-481d96c74a0e?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Cauliflower','bd-cauliflower','FM-BD-013','1 pc',55,180,false,'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Spinach (Palong Shak)','bd-spinach','FM-BD-014','1 bunch',30,260,false,'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Cucumber','bd-cucumber','FM-BD-015','1 kg',60,280,false,'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?auto=format&fit=crop&w=680&q=82'),
 ('Vegetables','Carrots','bd-carrots','FM-BD-016','1 kg',90,240,false,'https://images.unsplash.com/photo-1445282768818-728615cc910a?auto=format&fit=crop&w=680&q=82'),
 ('Meat & Seafood','Rohu Fish (Rui)','bd-rohu','FM-BD-017','1 kg · cleaned',380,120,true,'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=680&q=82'),
 ('Meat & Seafood','Hilsa Fish (Ilish)','bd-hilsa','FM-BD-018','1 kg',1200,60,false,'https://images.unsplash.com/photo-1498654077810-12c21d4d6dc3?auto=format&fit=crop&w=680&q=82'),
 ('Meat & Seafood','Tilapia','bd-tilapia','FM-BD-019','1 kg · cleaned',240,100,false,'https://images.unsplash.com/photo-1535399831218-d5bd36d1a6b3?auto=format&fit=crop&w=680&q=82'),
 ('Meat & Seafood','Fresh Chicken','bd-chicken','FM-BD-020','1 kg · cut',290,160,true,'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=680&q=82'),
 ('Meat & Seafood','Beef','bd-beef','FM-BD-021','1 kg · boneless',780,90,false,'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=680&q=82'),
 ('Dairy & Eggs','Farm Eggs','bd-eggs','FM-BD-022','12 pcs',150,350,true,'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=680&q=82'),
 ('Dairy & Eggs','Pasteurized Milk','bd-milk','FM-BD-023','1 litre',100,400,true,'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=680&q=82'),
 ('Dairy & Eggs','Plain Yogurt (Doi)','bd-yogurt','FM-BD-024','500 g',90,180,false,'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=680&q=82'),
 ('Dairy & Eggs','Butter','bd-butter','FM-BD-025','200 g',220,140,false,'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=680&q=82'),
 ('Bakery','White Bread','bd-white-bread','FM-BD-026','1 loaf',65,180,false,'https://images.unsplash.com/photo-1598373182133-52452f7691ef?auto=format&fit=crop&w=680&q=82'),
 ('Frozen Foods','Frozen Paratha','bd-paratha','FM-BD-027','20 pcs',240,120,false,'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=680&q=82'),
 ('Rice & Grains','Miniket Rice','bd-miniket-rice','FM-BD-028','1 kg',78,900,true,'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=680&q=82'),
 ('Rice & Grains','Najirshail Rice','bd-najirshail-rice','FM-BD-029','1 kg',85,650,false,'https://images.unsplash.com/photo-1516684732162-798a0062be99?auto=format&fit=crop&w=680&q=82'),
 ('Rice & Grains','Chinigura Aromatic Rice','bd-chinigura-rice','FM-BD-030','1 kg',145,280,false,'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=680&q=82'),
 ('Rice & Grains','Atta (Whole Wheat Flour)','bd-atta','FM-BD-031','2 kg',130,320,false,'https://images.unsplash.com/photo-1627485937980-221c88ac04f9?auto=format&fit=crop&w=680&q=82'),
 ('Rice & Grains','Muri (Puffed Rice)','bd-muri','FM-BD-032','500 g',55,260,false,'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&w=680&q=82'),
 ('Lentils & Pulses','Masoor Dal (Red Lentils)','bd-masoor-dal','FM-BD-033','1 kg',145,500,true,'https://images.unsplash.com/photo-1515543904379-3d757es6f5a2?auto=format&fit=crop&w=680&q=82'),
 ('Lentils & Pulses','Mung Dal','bd-mung-dal','FM-BD-034','1 kg',160,280,false,'https://images.unsplash.com/photo-1515543904379-3d757es6f5a2?auto=format&fit=crop&w=680&q=82'),
 ('Lentils & Pulses','Chickpeas (Chola)','bd-chickpeas','FM-BD-035','1 kg',125,240,false,'https://images.unsplash.com/photo-1515543904379-3d757es6f5a2?auto=format&fit=crop&w=680&q=82'),
 ('Spices & Essentials','Soybean Oil','bd-soybean-oil','FM-BD-036','1 litre',175,420,true,'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=680&q=82'),
 ('Spices & Essentials','Sugar','bd-sugar','FM-BD-037','1 kg',125,500,false,'https://images.unsplash.com/photo-1581441363689-1f3c3c414635?auto=format&fit=crop&w=680&q=82'),
 ('Spices & Essentials','Iodized Salt','bd-salt','FM-BD-038','1 kg',42,650,false,'https://images.unsplash.com/photo-1518110925495-5fe2fda0442f?auto=format&fit=crop&w=680&q=82'),
 ('Spices & Essentials','Turmeric Powder','bd-turmeric','FM-BD-039','200 g',75,300,false,'https://images.unsplash.com/photo-1615485500704-8e990f9900f0?auto=format&fit=crop&w=680&q=82'),
 ('Spices & Essentials','Red Chilli Powder','bd-red-chilli-powder','FM-BD-040','200 g',95,280,false,'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=680&q=82'),
 ('Beverages','Bangladeshi Tea','bd-tea','FM-BD-041','200 g',160,240,false,'https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=680&q=82'),
 ('Snacks','Chanachur','bd-chanachur','FM-BD-042','350 g',95,220,false,'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&w=680&q=82')
),
upserted_products as (
 insert into public.products(category_id,name,slug,sku,unit,price_cents,stock,status,featured,bestseller,demo_data,image_url,short_description)
 select c.id,v.name,v.slug,v.sku,v.unit,v.price_tk*100,v.stock,'active',v.featured,false,false,v.image_url,'Bangladesh grocery item · price in BDT'
 from catalog v join upserted_categories c on c.name=v.category_slug
 on conflict(slug) do update set demo_data=false
 returning id
)
select count(*) as active_real_bd_products from upserted_products;
