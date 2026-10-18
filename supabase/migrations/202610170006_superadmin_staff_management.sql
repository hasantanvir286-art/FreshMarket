-- Superadmin staff provisioning for existing customer accounts.
-- Customer accounts are created through storefront signup; this migration only grants/revokes staff access.
alter table public.profiles add column if not exists email text;

create or replace function public.create_customer_profile()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 insert into public.profiles(id,email,full_name,phone)
 values(new.id,lower(new.email),coalesce(new.raw_user_meta_data->>'full_name',''),nullif(new.raw_user_meta_data->>'phone',''))
 on conflict(id) do update set email=excluded.email;
 return new;
end;
$$;

update public.profiles p set email=lower(u.email)
from auth.users u where p.id=u.id and p.email is distinct from lower(u.email);

create or replace function public.superadmin_list_staff()
returns table(user_id uuid,email text,full_name text,role public.staff_role,active boolean,created_at timestamptz)
language plpgsql stable security definer set search_path=public,pg_temp as $$
begin
 if not public.has_staff_role(array['super_admin']::public.staff_role[]) then
  raise exception 'Only a super admin can manage staff access';
 end if;
 return query
  select r.user_id,p.email,p.full_name,r.role,r.active,r.created_at
  from public.staff_roles r left join public.profiles p on p.id=r.user_id
  order by r.created_at;
end;
$$;

create or replace function public.superadmin_set_staff_role(p_email text,p_role public.staff_role,p_active boolean default true)
returns void
language plpgsql security definer set search_path=public,pg_temp as $$
declare
 v_target uuid;
 v_superadmin_count integer;
begin
 if not public.has_staff_role(array['super_admin']::public.staff_role[]) then
  raise exception 'Only a super admin can manage staff access';
 end if;
 if length(trim(coalesce(p_email,''))) not between 3 and 254 or p_role is null or p_active is null then
  raise exception 'Enter a valid account email and staff role';
 end if;
 select id into v_target from auth.users where lower(email)=lower(trim(p_email)) limit 1;
 if v_target is null then
  raise exception 'No account exists for that email. Ask the user to create an account first.';
 end if;
 if v_target=auth.uid() and (not p_active or p_role<>'super_admin') then
  select count(*) into v_superadmin_count from public.staff_roles where active and role='super_admin';
  if v_superadmin_count<=1 then raise exception 'You cannot remove the last active super admin'; end if;
 end if;
 insert into public.staff_roles(user_id,role,active)
 values(v_target,p_role,p_active)
 on conflict(user_id) do update set role=excluded.role,active=excluded.active;
end;
$$;

revoke all on function public.superadmin_list_staff() from public;
revoke all on function public.superadmin_set_staff_role(text,public.staff_role,boolean) from public;
grant execute on function public.superadmin_list_staff() to authenticated;
grant execute on function public.superadmin_set_staff_role(text,public.staff_role,boolean) to authenticated;
