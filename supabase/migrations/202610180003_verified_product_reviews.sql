-- Let a signed-in customer leave one public rating per product after delivery.
-- Existing approved-review read policies remain the public visibility boundary.
create unique index if not exists reviews_one_per_customer_per_product
  on public.reviews(product_id, customer_id)
  where customer_id is not null;

create or replace function public.submit_verified_product_review(
  p_product_id uuid,
  p_rating integer,
  p_review_text text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_display_name text;
  v_review_id uuid;
begin
  if v_user_id is null then
    raise exception 'Sign in to leave a review';
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 then
    raise exception 'Choose a rating from 1 to 5 stars';
  end if;
  if p_review_text is null or length(trim(p_review_text)) < 5 or length(trim(p_review_text)) > 1000 then
    raise exception 'Review text must be between 5 and 1000 characters';
  end if;
  if not exists (
    select 1 from public.products p
    where p.id = p_product_id and p.status = 'active' and p.demo_data = false
  ) then
    raise exception 'This product is not available for review';
  end if;

  select lower(u.email), coalesce(
    nullif(trim(p.full_name), ''),
    nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(u.email, '@', 1), ''),
    'Customer'
  )
  into v_email, v_display_name
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = v_user_id and u.email_confirmed_at is not null;

  if v_email is null then
    raise exception 'Verify your account email before leaving a review';
  end if;

  -- Claim matching guest checkouts only after Supabase has verified this email.
  update public.orders o
  set customer_id = v_user_id, updated_at = now()
  where o.customer_id is null and lower(o.guest_email) = v_email;

  if not exists (
    select 1
    from public.orders o
    join public.order_items oi on oi.order_id = o.id
    where o.customer_id = v_user_id
      and o.status = 'delivered'
      and oi.product_id = p_product_id
  ) then
    raise exception 'A delivered order containing this product is required to review it';
  end if;

  insert into public.reviews(product_id, customer_id, customer_display_name, rating, review_text, moderation_status)
  values (p_product_id, v_user_id, v_display_name, p_rating, trim(p_review_text), 'approved')
  on conflict (product_id, customer_id) where customer_id is not null
  do update set
    customer_display_name = excluded.customer_display_name,
    rating = excluded.rating,
    review_text = excluded.review_text,
    moderation_status = 'approved',
    created_at = now()
  returning id into v_review_id;

  return v_review_id;
end;
$$;

revoke all on function public.submit_verified_product_review(uuid, integer, text) from public, anon;
grant execute on function public.submit_verified_product_review(uuid, integer, text) to authenticated;
