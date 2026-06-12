insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'dish-photos',
  'dish-photos',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "dish_photos_storage_select"
on storage.objects
for select
to authenticated
using (bucket_id = 'dish-photos');

create policy "dish_photos_storage_insert_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'dish-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "dish_photos_storage_update_own_folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'dish-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'dish-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "dish_photos_storage_delete_own_folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'dish-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
