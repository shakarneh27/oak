-- Additive: emoji avatar chosen at sign-up (students pick theirs).
alter table public.profiles add column if not exists avatar text;
