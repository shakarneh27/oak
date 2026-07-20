-- Placement exam flag + the teacher→parent↔student linking flow.

-- students must pass through the placement exam once (retakes allowed)
alter table public.student_progress
  add column if not exists placement_done boolean not null default false;

-- teachers may see which of their students already have a linked parent
create policy "links_select_teacher" on public.parent_student_links
  for select using (public.is_teacher_of(student_id));

-- The teacher links a parent account (by email) to one of their
-- students. SECURITY DEFINER so it can look the parent up in auth.users
-- and write the link, with the teacher-of-student check inside.
create or replace function public.link_parent_to_student(
  parent_email text,
  target_student uuid
)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  found_parent uuid;
begin
  if not public.is_teacher_of(target_student) then
    return 'not_teacher';
  end if;
  select p.id into found_parent
  from public.profiles p
  join auth.users u on u.id = p.id
  where lower(u.email) = lower(trim(parent_email))
    and p.role = 'parent'
  limit 1;
  if found_parent is null then
    return 'parent_not_found';
  end if;
  insert into public.parent_student_links (parent_id, student_id)
  values (found_parent, target_student)
  on conflict do nothing;
  return 'ok';
end;
$$;

revoke execute on function public.link_parent_to_student(text, uuid) from public, anon;
grant execute on function public.link_parent_to_student(text, uuid) to authenticated;
