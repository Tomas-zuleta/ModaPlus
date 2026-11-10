-- DRAFT ONLY: review against staging schema before deployment.
-- Event outbox guarantees persistence of order status transitions, not delivery.
create table if not exists public.modaplus_email_outbox (
  id bigint generated always as identity primary key,
  sale_id bigint not null,
  event_type text not null check (event_type in ('APROBADA', 'RECHAZADA')),
  status text not null default 'pending' check (status in ('pending', 'processing', 'sent', 'failed')),
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  provider_message_id text,
  last_error text
);
create index if not exists modaplus_email_outbox_pending_idx
  on public.modaplus_email_outbox(status, next_attempt_at, id);
alter table public.modaplus_email_outbox enable row level security;
-- No policies: deny authenticated and anon users direct access.

create or replace function public.modaplus_enqueue_sale_email()
returns trigger language plpgsql security definer
set search_path = '' as $$
begin
  if new.estado in ('APROBADA', 'RECHAZADA')
     and (tg_op = 'INSERT' or old.estado is distinct from new.estado) then
    insert into public.modaplus_email_outbox(sale_id, event_type)
    values (new.id_venta, new.estado);
  end if;
  return new;
end;
$$;
revoke all on function public.modaplus_enqueue_sale_email() from public, anon, authenticated;
drop trigger if exists modaplus_sale_email_outbox on public.ventas;
create trigger modaplus_sale_email_outbox
after insert or update of estado on public.ventas
for each row execute function public.modaplus_enqueue_sale_email();

-- Worker claims events atomically. A crashed worker can be retried after 10 minutes.
create or replace function public.modaplus_claim_email_events(p_limit integer default 10)
returns setof public.modaplus_email_outbox
language plpgsql security definer set search_path = '' as $$
begin
  return query
  with selected as (
    select o.id from public.modaplus_email_outbox o
    where (o.status in ('pending', 'failed') and o.next_attempt_at <= now())
      or (o.status = 'processing' and o.locked_at < now() - interval '10 minutes')
    order by o.id
    for update skip locked
    limit least(greatest(p_limit, 1), 20)
  )
  update public.modaplus_email_outbox o
  set status = 'processing', locked_at = now(), attempts = o.attempts + 1
  from selected where o.id = selected.id
  returning o.*;
end;
$$;
revoke all on function public.modaplus_claim_email_events(integer)
  from public, anon, authenticated;
grant execute on function public.modaplus_claim_email_events(integer) to service_role;
