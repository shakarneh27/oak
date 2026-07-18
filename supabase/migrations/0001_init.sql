-- Digital Oak (السنديانة الرقمية) — initial schema
-- Backend: Supabase (PostgreSQL + Auth + Realtime), replacing the Socket.io
-- events from the original spec with Postgres Changes / Realtime Channels.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- profiles: one row per auth.users entry, carries role + display data
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  role text not null check (role in ('student', 'teacher', 'parent')),
  classroom text,               -- students: the classroom they belong to
  managed_classrooms text[],    -- teachers: classrooms they can see
  created_at timestamptz not null default now()
);

-- links a parent account to the student(s) they may view
create table if not exists public.parent_student_links (
  parent_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  primary key (parent_id, student_id)
);

-- ---------------------------------------------------------------------------
-- reference data: units and the adaptive games catalog
-- ---------------------------------------------------------------------------
create table if not exists public.units (
  unit_key text primary key,
  name_ar text not null,
  sort_order int not null default 0
);

create table if not exists public.games_catalog (
  game_key text primary key,
  unit_key text not null references public.units (unit_key),
  lesson_name text not null,
  game_name text not null,
  weak_content text not null,
  medium_content text not null,
  advanced_content text not null,
  points_reward int not null default 0,
  badge_reward text
);

-- ---------------------------------------------------------------------------
-- student_progress: tree growth, level, cumulative rewards
-- ---------------------------------------------------------------------------
create table if not exists public.student_progress (
  student_id uuid primary key references public.profiles (id) on delete cascade,
  current_level text not null default 'Weak' check (current_level in ('Weak', 'Medium', 'Advanced')),
  oak_leaves int not null default 0,
  tree_growth_stage int not null default 0,
  badges_unlocked text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- game_sessions: one row per play attempt, feeds the remedial engine
-- ---------------------------------------------------------------------------
create table if not exists public.game_sessions (
  session_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  game_key text not null references public.games_catalog (game_key),
  level text not null check (level in ('Weak', 'Medium', 'Advanced')),
  attempts_count int not null default 0,
  consecutive_fails int not null default 0,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'failed', 'paused_for_remediation')),
  is_remediation boolean not null default false,
  remediation_of_game_key text references public.games_catalog (game_key),
  realtime_payload jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

-- ---------------------------------------------------------------------------
-- remedial_events: audit trail of every adaptive/remedial action taken
-- ---------------------------------------------------------------------------
create table if not exists public.remedial_events (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  game_key text not null references public.games_catalog (game_key),
  event_type text not null check (
    event_type in ('repeated_failure', 'adaptive_downgrade', 'teacher_alert', 'remediation_passed')
  ),
  trigger_condition text not null,
  action_taken text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- realtime_logs: durable log backing the teacher/parent live dashboards
-- ---------------------------------------------------------------------------
create table if not exists public.realtime_logs (
  log_id uuid primary key default gen_random_uuid(),
  student_id uuid references public.profiles (id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_game_sessions_student on public.game_sessions (student_id);
create index if not exists idx_realtime_logs_created on public.realtime_logs (created_at desc);
create index if not exists idx_remedial_events_student on public.remedial_events (student_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.parent_student_links enable row level security;
alter table public.units enable row level security;
alter table public.games_catalog enable row level security;
alter table public.student_progress enable row level security;
alter table public.game_sessions enable row level security;
alter table public.remedial_events enable row level security;
alter table public.realtime_logs enable row level security;

-- helper: is the current user a teacher who manages this student's classroom?
create or replace function public.is_teacher_of(target_student uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from public.profiles teacher, public.profiles student
    where teacher.id = auth.uid()
      and teacher.role = 'teacher'
      and student.id = target_student
      and student.classroom = any (teacher.managed_classrooms)
  );
$$;

-- helper: is the current user a parent linked to this student?
create or replace function public.is_parent_of(target_student uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.parent_student_links
    where parent_id = auth.uid() and student_id = target_student
  );
$$;

-- profiles
create policy "profiles_select_own_or_related" on public.profiles
  for select using (
    id = auth.uid() or public.is_teacher_of(id) or public.is_parent_of(id)
  );
create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid());

-- parent_student_links
create policy "links_select_own" on public.parent_student_links
  for select using (parent_id = auth.uid());

-- reference tables: readable by any authenticated user
create policy "units_read_all" on public.units for select using (auth.role() = 'authenticated');
create policy "games_catalog_read_all" on public.games_catalog for select using (auth.role() = 'authenticated');

-- student_progress
create policy "progress_select_own_or_related" on public.student_progress
  for select using (
    student_id = auth.uid() or public.is_teacher_of(student_id) or public.is_parent_of(student_id)
  );
create policy "progress_upsert_own" on public.student_progress
  for insert with check (student_id = auth.uid());
create policy "progress_update_own" on public.student_progress
  for update using (student_id = auth.uid());

-- game_sessions
create policy "sessions_select_own_or_related" on public.game_sessions
  for select using (
    student_id = auth.uid() or public.is_teacher_of(student_id) or public.is_parent_of(student_id)
  );
create policy "sessions_insert_own" on public.game_sessions
  for insert with check (student_id = auth.uid());
create policy "sessions_update_own" on public.game_sessions
  for update using (student_id = auth.uid());

-- remedial_events
create policy "remedial_select_own_or_related" on public.remedial_events
  for select using (
    student_id = auth.uid() or public.is_teacher_of(student_id) or public.is_parent_of(student_id)
  );
create policy "remedial_insert_own" on public.remedial_events
  for insert with check (student_id = auth.uid());

-- realtime_logs
create policy "logs_select_own_or_related" on public.realtime_logs
  for select using (
    student_id = auth.uid() or public.is_teacher_of(student_id) or public.is_parent_of(student_id)
  );
create policy "logs_insert_own" on public.realtime_logs
  for insert with check (student_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime publication (Supabase Realtime channels replace Socket.io events)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.game_sessions;
alter publication supabase_realtime add table public.student_progress;
alter publication supabase_realtime add table public.remedial_events;
alter publication supabase_realtime add table public.realtime_logs;
