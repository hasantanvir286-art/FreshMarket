-- Adds catalog fields required by the Supabase-backed storefront.
alter table public.products add column if not exists image_url text;
alter table public.products add column if not exists demo_data boolean not null default false;
