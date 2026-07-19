-- Parent <-> teacher/school messaging (backs the parent dashboard's
-- "الرسائل" and "تواصل" tabs from the reference design).

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid references public.profiles (id) on delete cascade,
  body text not null check (length(body) between 1 and 2000),
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_recipient on public.messages (recipient_id, created_at desc);
create index if not exists idx_messages_sender on public.messages (sender_id, created_at desc);

alter table public.messages enable row level security;

create policy "messages_select_participants" on public.messages
  for select using (sender_id = auth.uid() or recipient_id = auth.uid());
create policy "messages_insert_own" on public.messages
  for insert with check (sender_id = auth.uid());
-- recipient may mark a message as read
create policy "messages_update_recipient" on public.messages
  for update using (recipient_id = auth.uid());

-- Parents need to see the teacher of their child's classroom to write to
-- them. SECURITY DEFINER avoids RLS recursion on profiles.
create or replace function public.is_teacher_of_my_child(target uuid)
returns boolean
language sql
security definer
set search_path = public, auth
stable
as $$
  select exists (
    select 1
    from public.profiles teacher
    join public.parent_student_links pl on pl.parent_id = auth.uid()
    join public.profiles student on student.id = pl.student_id
    where teacher.id = target
      and teacher.role = 'teacher'
      and student.classroom = any (teacher.managed_classrooms)
  );
$$;

revoke execute on function public.is_teacher_of_my_child(uuid) from public, anon;
grant execute on function public.is_teacher_of_my_child(uuid) to authenticated;

create policy "profiles_select_child_teacher" on public.profiles
  for select using (public.is_teacher_of_my_child(id));

alter publication supabase_realtime add table public.messages;
