create or replace function public.is_auth_identifier_available(
  check_method text,
  identifier text
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  normalized_identifier text := nullif(trim(identifier), '');
begin
  if normalized_identifier is null then
    return false;
  end if;

  if check_method = 'email' then
    return not exists (
      select 1
      from auth.users users
      where lower(coalesce(users.email, '')) = lower(normalized_identifier)
    );
  end if;

  if check_method = 'phone' then
    return not exists (
      select 1
      from auth.users users
      where regexp_replace(coalesce(users.phone, ''), '\D', '', 'g') = regexp_replace(normalized_identifier, '\D', '', 'g')
    );
  end if;

  raise exception 'Unsupported check_method: %', check_method;
end;
$$;

grant execute on function public.is_auth_identifier_available(text, text) to anon;
grant execute on function public.is_auth_identifier_available(text, text) to authenticated;
