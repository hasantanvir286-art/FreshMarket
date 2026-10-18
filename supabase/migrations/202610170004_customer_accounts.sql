-- Create customer profiles on signup and associate authenticated COD orders with the account.
create or replace function public.create_customer_profile()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 insert into public.profiles(id,full_name,phone)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),nullif(new.raw_user_meta_data->>'phone',''))
 on conflict(id) do nothing;
 return new;
end;
$$;

do $$
begin
 if not exists (
  select 1 from pg_trigger
  where tgname='on_auth_user_created_profile'
   and tgrelid='auth.users'::regclass
   and not tgisinternal
 ) then
  create trigger on_auth_user_created_profile after insert on auth.users
  for each row execute function public.create_customer_profile();
 end if;
end;
$$;

create or replace function public.attach_authenticated_order_customer()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is not null then new.customer_id:=auth.uid(); end if;
 return new;
end;
$$;

do $$
begin
 if not exists (
  select 1 from pg_trigger
  where tgname='attach_authenticated_order_customer'
   and tgrelid='public.orders'::regclass
   and not tgisinternal
 ) then
  create trigger attach_authenticated_order_customer before insert on public.orders
  for each row execute function public.attach_authenticated_order_customer();
 end if;
end;
$$;
