-- Include Auth user details when a staff account has no populated profile row.
-- Access remains restricted to authenticated super admins by this RPC.
create or replace function public.superadmin_list_staff()
returns table(user_id uuid,email text,full_name text,role public.staff_role,active boolean,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$
begin
 if not public.has_staff_role(array['super_admin']::public.staff_role[]) then
  raise exception 'Only a super admin can manage staff access';
 end if;
 return query
  select r.user_id,
         coalesce(nullif(p.email,''),lower(u.email)),
         coalesce(nullif(p.full_name,''),nullif(u.raw_user_meta_data->>'full_name',''),''),
         r.role,
         r.active,
         r.created_at
  from public.staff_roles r
  left join public.profiles p on p.id=r.user_id
  left join auth.users u on u.id=r.user_id
  order by r.created_at;
end;
$$;

revoke all on function public.superadmin_list_staff() from public;
grant execute on function public.superadmin_list_staff() to authenticated;
