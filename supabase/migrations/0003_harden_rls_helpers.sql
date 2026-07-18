-- Pin search_path and restrict who may execute the RLS helper functions.
-- `authenticated` keeps EXECUTE because the RLS policies evaluate these
-- functions as the calling user; `anon` and `public` have no reason to.

alter function public.is_teacher_of(uuid) set search_path = public, auth;
alter function public.is_parent_of(uuid) set search_path = public, auth;

revoke execute on function public.is_teacher_of(uuid) from public, anon;
revoke execute on function public.is_parent_of(uuid) from public, anon;
grant execute on function public.is_teacher_of(uuid) to authenticated;
grant execute on function public.is_parent_of(uuid) to authenticated;