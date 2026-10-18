-- Public storefront branding, managed by superadmins.
insert into public.store_settings(key, value)
values ('store_brand', '{"name":"Fresh Market","logo_url":""}'::jsonb)
on conflict (key) do nothing;

grant select on public.store_settings to anon, authenticated;
drop policy if exists "public can view store brand" on public.store_settings;
create policy "public can view store brand" on public.store_settings
  for select to anon, authenticated using (key = 'store_brand');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('store-assets', 'store-assets', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Public can view store branding assets" on storage.objects;
create policy "Public can view store branding assets" on storage.objects
  for select to anon, authenticated using (bucket_id = 'store-assets');
drop policy if exists "Superadmins can upload store branding assets" on storage.objects;
create policy "Superadmins can upload store branding assets" on storage.objects
  for insert to authenticated with check (bucket_id = 'store-assets' and public.has_staff_role(array['super_admin']::public.staff_role[]));
drop policy if exists "Superadmins can update store branding assets" on storage.objects;
create policy "Superadmins can update store branding assets" on storage.objects
  for update to authenticated using (bucket_id = 'store-assets' and public.has_staff_role(array['super_admin']::public.staff_role[]))
  with check (bucket_id = 'store-assets' and public.has_staff_role(array['super_admin']::public.staff_role[]));
drop policy if exists "Superadmins can delete store branding assets" on storage.objects;
create policy "Superadmins can delete store branding assets" on storage.objects
  for delete to authenticated using (bucket_id = 'store-assets' and public.has_staff_role(array['super_admin']::public.staff_role[]));
