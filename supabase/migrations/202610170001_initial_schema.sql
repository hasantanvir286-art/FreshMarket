-- Fresh Market: foundational PostgreSQL schema. Apply with Supabase CLI.
create extension if not exists pgcrypto;
create type public.staff_role as enum ('super_admin','store_manager','order_manager','inventory_manager','content_manager');
create type public.product_status as enum ('draft','active','archived');
create type public.order_status as enum ('pending','confirmed','processing','packed','out_for_delivery','delivered','cancelled');
create type public.payment_status as enum ('pending','paid','failed','refunded','partially_refunded');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', phone text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.staff_roles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role public.staff_role not null, active boolean not null default true, created_at timestamptz not null default now()
);
create table public.categories (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 description text, image_url text, parent_id uuid references public.categories(id) on delete restrict,
 display_order integer not null default 0, active boolean not null default true, featured boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.products (
 id uuid primary key default gen_random_uuid(), category_id uuid references public.categories(id) on delete restrict,
 name text not null, slug text not null unique, sku text not null unique, short_description text, description text, image_url text,
 price_cents integer not null check (price_cents >= 0), original_price_cents integer check (original_price_cents is null or original_price_cents >= price_cents),
 cost_cents integer check (cost_cents is null or cost_cents >= 0), unit text not null, stock integer not null default 0 check (stock >= 0),
 low_stock_threshold integer not null default 10 check (low_stock_threshold >= 0), status public.product_status not null default 'draft',
 featured boolean not null default false, bestseller boolean not null default false, demo_data boolean not null default false, seo_title text, seo_description text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
insert into public.categories(name,slug,display_order,active,featured) values
 ('Fruits','fruits',1,true,true),('Vegetables','vegetables',2,true,true),('Meat & Seafood','meat-seafood',3,true,true),
 ('Dairy & Eggs','dairy-eggs',4,true,true),('Bakery','bakery',5,true,true),('Beverages','beverages',6,true,true),
 ('Snacks','snacks',7,true,true),('Household','household',8,true,true)
on conflict(slug) do nothing;
create index products_category_active_idx on public.products(category_id,status) where status='active';
create index products_name_search_idx on public.products using gin(to_tsvector('simple',name));
create table public.product_images (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 storage_path text not null, alt_text text, display_order integer not null default 0, created_at timestamptz not null default now()
);
create table public.addresses (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references auth.users(id) on delete cascade,
 recipient text not null, phone text, line1 text not null, line2 text, city text not null, region text, postal_code text, country_code text not null default 'US',
 is_default boolean not null default false, created_at timestamptz not null default now()
);
create table public.carts (
 id uuid primary key default gen_random_uuid(), customer_id uuid references auth.users(id) on delete cascade,
 guest_token_hash text unique, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(customer_id is not null or guest_token_hash is not null)
);
create table public.cart_items (
 cart_id uuid not null references public.carts(id) on delete cascade, product_id uuid not null references public.products(id) on delete cascade,
 quantity integer not null check(quantity > 0), updated_at timestamptz not null default now(), primary key(cart_id,product_id)
);
create table public.wishlists (
 customer_id uuid not null references auth.users(id) on delete cascade, product_id uuid not null references public.products(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(customer_id,product_id)
);
create table public.coupons (
 id uuid primary key default gen_random_uuid(), code text not null unique, kind text not null check(kind in ('fixed','percent')),
 value integer not null check(value>0), minimum_order_cents integer not null default 0 check(minimum_order_cents>=0),
 max_discount_cents integer, starts_at timestamptz, expires_at timestamptz, usage_limit integer, per_customer_limit integer,
 uses integer not null default 0, active boolean not null default true, created_at timestamptz not null default now()
);
create table public.orders (
 id uuid primary key default gen_random_uuid(), order_number text not null unique, customer_id uuid references auth.users(id) on delete set null,
 guest_email text, guest_name text not null, guest_phone text, delivery_address jsonb not null,
 status public.order_status not null default 'pending', payment_status public.payment_status not null default 'pending',
 payment_method text not null, currency char(3) not null default 'USD', subtotal_cents integer not null check(subtotal_cents>=0),
 discount_cents integer not null default 0 check(discount_cents>=0), delivery_cents integer not null default 0 check(delivery_cents>=0),
 tax_cents integer not null default 0 check(tax_cents>=0), total_cents integer not null check(total_cents>=0),
 coupon_id uuid references public.coupons(id) on delete set null, delivery_instructions text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index orders_customer_date_idx on public.orders(customer_id,created_at desc);
create table public.order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null, product_name text not null, sku text not null, unit text not null,
 quantity integer not null check(quantity>0), unit_price_cents integer not null check(unit_price_cents>=0), line_total_cents integer not null check(line_total_cents>=0)
);
create table public.inventory_movements (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete restrict,
 quantity_delta integer not null check(quantity_delta<>0), reason text not null, order_id uuid references public.orders(id) on delete set null,
 actor_id uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table public.coupon_redemptions (
 id uuid primary key default gen_random_uuid(), coupon_id uuid not null references public.coupons(id) on delete restrict,
 customer_id uuid references auth.users(id) on delete set null, order_id uuid not null unique references public.orders(id) on delete cascade,
 redeemed_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 customer_id uuid references auth.users(id) on delete set null, customer_display_name text not null,
 rating smallint not null check(rating between 1 and 5), review_text text not null, moderation_status text not null default 'pending' check(moderation_status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create table public.promotional_banners (
 id uuid primary key default gen_random_uuid(), title text not null, body text, image_url text, button_label text, destination text,
 position text not null default 'home', display_order integer not null default 0, active boolean not null default false,
 starts_at timestamptz, ends_at timestamptz, updated_at timestamptz not null default now()
);
create table public.store_settings (
 key text primary key, value jsonb not null, updated_by uuid references auth.users(id) on delete set null, updated_at timestamptz not null default now()
);
create table public.admin_activity_logs (
 id uuid primary key default gen_random_uuid(), actor_id uuid references auth.users(id) on delete set null,
 action text not null, resource_type text not null, resource_id text, summary jsonb not null default '{}', created_at timestamptz not null default now()
);
create index audit_created_idx on public.admin_activity_logs(created_at desc);

-- Authorization helpers are security-definer to avoid recursive RLS lookups.
create or replace function public.has_staff_role(allowed public.staff_role[])
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.staff_roles r where r.user_id=auth.uid() and r.active and r.role=any(allowed));
$$;
revoke all on function public.has_staff_role(public.staff_role[]) from public;
grant execute on function public.has_staff_role(public.staff_role[]) to authenticated;

alter table public.profiles enable row level security;
alter table public.staff_roles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.addresses enable row level security;
alter table public.wishlists enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.coupons enable row level security;
alter table public.reviews enable row level security;
alter table public.promotional_banners enable row level security;
alter table public.store_settings enable row level security;
alter table public.admin_activity_logs enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.coupon_redemptions enable row level security;

create policy "active categories are public" on public.categories for select using(active);
create policy "active products are public" on public.products for select using(status='active');
create policy "active product images are public" on public.product_images for select using(exists(select 1 from public.products p where p.id=product_id and p.status='active'));
create policy "active banners are public" on public.promotional_banners for select using(active and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>now()));
create policy "approved reviews are public" on public.reviews for select using(moderation_status='approved');
create policy "customer reads own profile" on public.profiles for select using(id=auth.uid());
create policy "customer edits own profile" on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());
create policy "staff reads own role" on public.staff_roles for select using(user_id=auth.uid());
create policy "customer manages own addresses" on public.addresses for all using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy "customer manages own wishlist" on public.wishlists for all using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy "customer reads own orders" on public.orders for select using(customer_id=auth.uid());
create policy "customer reads own order items" on public.order_items for select using(exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));
create policy "customer owns cart" on public.carts for all using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy "customer owns cart items" on public.cart_items for all using(exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=auth.uid())) with check(exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=auth.uid()));
-- Staff mutation/read policies. Granular role checks are enforced by module; this policy family is the database boundary.
create policy "authorized staff manages catalog" on public.products for all using(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[]));
create policy "authorized staff manages categories" on public.categories for all using(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[]));
create policy "authorized staff manages product images" on public.product_images for all using(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[]));
create policy "order staff reads and updates orders" on public.orders for all using(public.has_staff_role(array['super_admin','order_manager','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','order_manager','store_manager']::public.staff_role[]));
create policy "order staff manages order items" on public.order_items for all using(public.has_staff_role(array['super_admin','order_manager','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','order_manager','store_manager']::public.staff_role[]));
create policy "inventory staff manages stock" on public.inventory_movements for all using(public.has_staff_role(array['super_admin','inventory_manager','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','inventory_manager','store_manager']::public.staff_role[]));
create policy "content staff manages banners" on public.promotional_banners for all using(public.has_staff_role(array['super_admin','content_manager','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','content_manager','store_manager']::public.staff_role[]));
create policy "staff manages coupons" on public.coupons for all using(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','store_manager']::public.staff_role[]));
create policy "staff moderates reviews" on public.reviews for all using(public.has_staff_role(array['super_admin','store_manager','content_manager']::public.staff_role[])) with check(public.has_staff_role(array['super_admin','store_manager','content_manager']::public.staff_role[]));
create policy "staff manages settings" on public.store_settings for all using(public.has_staff_role(array['super_admin']::public.staff_role[])) with check(public.has_staff_role(array['super_admin']::public.staff_role[]));
create policy "super admins view audit log" on public.admin_activity_logs for select using(public.has_staff_role(array['super_admin']::public.staff_role[]));
create policy "super admins write audit log" on public.admin_activity_logs for insert with check(public.has_staff_role(array['super_admin']::public.staff_role[]));

-- Initial staff assignment must be performed from a trusted server/SQL editor after auth user creation:
-- insert into public.staff_roles(user_id,role) values ('<auth-user-uuid>','super_admin');
