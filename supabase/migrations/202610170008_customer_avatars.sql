-- Public profile images are readable by storefront visitors. Writes stay inside
-- the authenticated user's own folder: customer-avatars/<auth.uid()>/...
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('customer-avatars','customer-avatars',true,5242880,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Customer avatars are publicly readable" on storage.objects;
create policy "Customer avatars are publicly readable"
on storage.objects for select
using(bucket_id='customer-avatars');

drop policy if exists "Customers upload their own avatar" on storage.objects;
create policy "Customers upload their own avatar"
on storage.objects for insert to authenticated
with check(bucket_id='customer-avatars' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Customers update their own avatar" on storage.objects;
create policy "Customers update their own avatar"
on storage.objects for update to authenticated
using(bucket_id='customer-avatars' and (storage.foldername(name))[1]=auth.uid()::text)
with check(bucket_id='customer-avatars' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists "Customers delete their own avatar" on storage.objects;
create policy "Customers delete their own avatar"
on storage.objects for delete to authenticated
using(bucket_id='customer-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
