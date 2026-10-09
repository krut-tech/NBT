-- NOT yet applied to the database (apply_migration was cancelled). Run in Supabase SQL editor.
drop trigger if exists trg_stock_transaction on public.stock_transactions;
drop function if exists public.update_stock_after_transaction();

create or replace function public.update_stock_on_transaction()
returns trigger language plpgsql security definer set search_path to 'public' as $$
declare cur numeric;
begin
  select current_stock into cur from public.stock_items where id = new.item_id for update;
  if new.transaction_type = 'IN' then
    update public.stock_items set current_stock = current_stock + new.quantity where id = new.item_id;
  elsif new.transaction_type = 'OUT' then
    if cur is null or cur < new.quantity then
      raise exception 'Insufficient stock (available: %, requested: %)', coalesce(cur,0), new.quantity;
    end if;
    update public.stock_items set current_stock = current_stock - new.quantity where id = new.item_id;
  end if;
  return new;
end; $$;

create or replace function public.protect_profile_privileged_columns()
returns trigger language plpgsql security definer set search_path to 'public' as $$
declare caller_role text;
begin
  if auth.uid() is null then return new; end if;
  caller_role := public.current_profile_role();
  if tg_op = 'INSERT' then
    if caller_role is distinct from 'admin' then new.role := 'customer'; new.customer_id := null; end if;
    return new;
  end if;
  if caller_role = 'admin' then return new; end if;
  if new.role is distinct from old.role or new.customer_id is distinct from old.customer_id or new.is_active is distinct from old.is_active then
    if caller_role = 'manager' and old.role <> 'admin' and new.role <> 'admin' then return new; end if;
    raise exception 'Not allowed to change role, customer link or active status';
  end if;
  return new;
end; $$;

drop trigger if exists trg_profiles_protect on public.profiles;
create trigger trg_profiles_protect before insert or update on public.profiles
for each row execute function public.protect_profile_privileged_columns();

revoke execute on function public.update_stock_on_transaction() from public, anon, authenticated;
revoke execute on function public.protect_profile_privileged_columns() from public, anon, authenticated;

-- Make admin@newbharat.com a real admin
update public.profiles set role='admin', customer_id=null where id='93a11568-4f0c-4c11-98a5-5e5f1b959ede';
