-- Public product images are readable by storefront visitors. Only catalog staff
-- can create, replace, or remove files in the products/ folder.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Product images are publicly readable" on storage.objects;
create policy "Product images are publicly readable"
on storage.objects for select
using (bucket_id = 'product-images');

drop policy if exists "Catalog staff upload product images" on storage.objects;
create policy "Catalog staff upload product images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = 'products'
  and public.has_staff_role(array['super_admin', 'store_manager']::public.staff_role[])
);

drop policy if exists "Catalog staff update product images" on storage.objects;
create policy "Catalog staff update product images"
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = 'products'
  and public.has_staff_role(array['super_admin', 'store_manager']::public.staff_role[])
)
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = 'products'
  and public.has_staff_role(array['super_admin', 'store_manager']::public.staff_role[])
);

drop policy if exists "Catalog staff delete product images" on storage.objects;
create policy "Catalog staff delete product images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = 'products'
  and public.has_staff_role(array['super_admin', 'store_manager']::public.staff_role[])
);
