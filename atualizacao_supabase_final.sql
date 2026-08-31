-- JOLI FINAL — MIGRAÇÃO COMPLETA

alter table public.transactions add column if not exists issue_type text;
alter table public.transactions add column if not exists refund_provider text;
alter table public.transactions add column if not exists refund_status text;
alter table public.transactions add column if not exists refund_amount numeric(14,2) not null default 0;
alter table public.transactions add column if not exists refund_date date;
-- Execute no Supabase > SQL Editor antes de publicar o aplicativo.
-- Não apaga os dados existentes.

alter table public.transactions add column if not exists subcategory text;
alter table public.transactions add column if not exists status text not null default 'paid';
alter table public.transactions add column if not exists location text;
alter table public.transactions add column if not exists module text not null default 'Geral';
alter table public.transactions add column if not exists source_key text;
alter table public.transactions add column if not exists card_id uuid references public.credit_cards(id) on delete set null;
alter table public.transactions add column if not exists trip_id uuid;
alter table public.transactions add column if not exists installment_number integer not null default 1;
alter table public.transactions add column if not exists installment_total integer not null default 1;
alter table public.transactions add column if not exists recurring_bill_id uuid references public.recurring_bills(id) on delete set null;

create unique index if not exists transactions_user_source_unique
on public.transactions(user_id, source_key) where source_key is not null;

create table if not exists public.apartments (
 user_id uuid primary key references auth.users(id) on delete cascade,
 name text not null, property_value numeric(14,2) not null default 0,
 down_payment numeric(14,2) not null default 0, financed_amount numeric(14,2) not null default 0,
 outstanding_balance numeric(14,2) not null default 0, monthly_installment numeric(14,2) not null default 0,
 total_installments integer, paid_installments integer not null default 0, updated_at timestamptz not null default now()
);

create table if not exists public.trips (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 name text not null, destination text, budget numeric(14,2) not null default 0,
 start_date date, end_date date, created_at timestamptz not null default now()
);

create table if not exists public.story_events (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 source_key text, event_date date not null, title text not null, description text, icon text default '✦',
 module text default 'Geral', amount numeric(14,2) not null default 0, created_at timestamptz not null default now()
);
create unique index if not exists story_events_user_source_unique
on public.story_events(user_id, source_key) where source_key is not null;

alter table public.apartments enable row level security;
alter table public.trips enable row level security;
alter table public.story_events enable row level security;

drop policy if exists "user apartments" on public.apartments;
create policy "user apartments" on public.apartments for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists "user trips" on public.trips;
create policy "user trips" on public.trips for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists "user story" on public.story_events;
create policy "user story" on public.story_events for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

grant select,insert,update,delete on public.apartments,public.trips,public.story_events to authenticated;

do $$
begin
 if not exists(select 1 from pg_constraint where conname='transactions_trip_id_fkey') then
  alter table public.transactions add constraint transactions_trip_id_fkey foreign key(trip_id) references public.trips(id) on delete set null;
 end if;
end $$;


-- Arquivo fiel da planilha original, sem interferir nos cálculos financeiros
create table if not exists public.spreadsheet_archive (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 source_key text not null,
 sheet_name text not null,
 month_key text,
 month_label text,
 row_number integer,
 category text,
 vargem_amount numeric(14,2),
 vargem_date_raw text,
 vargem_paid boolean,
 vargem_person text,
 botafogo_amount numeric(14,2),
 botafogo_date_raw text,
 botafogo_paid boolean,
 botafogo_person text,
 total_amount numeric(14,2),
 notes text,
 raw_row jsonb,
 created_at timestamptz not null default now(),
 unique(user_id, source_key)
);

create table if not exists public.reimbursement_claims (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 source_key text not null,
 transaction_source_key text not null,
 provider text not null,
 amount numeric(14,2) not null default 0,
 status text,
 received_date date,
 notes text,
 created_at timestamptz not null default now(),
 unique(user_id, source_key)
);

alter table public.spreadsheet_archive enable row level security;
alter table public.reimbursement_claims enable row level security;

drop policy if exists "user spreadsheet archive" on public.spreadsheet_archive;
create policy "user spreadsheet archive" on public.spreadsheet_archive for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

drop policy if exists "user reimbursement claims" on public.reimbursement_claims;
create policy "user reimbursement claims" on public.reimbursement_claims for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

grant select,insert,update,delete on public.spreadsheet_archive,public.reimbursement_claims to authenticated;
