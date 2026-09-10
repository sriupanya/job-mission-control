-- Additive Career Studio changes. Existing career data is preserved.
create table if not exists public.studio_access_requests (
 id uuid primary key default gen_random_uuid(),
 email text not null unique check (email = lower(email) and length(email) <= 254),
 status text not null default 'pending' check(status in ('pending','approved','denied')),
 created_at timestamptz not null default now(),
 decided_at timestamptz,
 owner_notified_at timestamptz,
 applicant_notified_at timestamptz,
 notification_message_id text,
 ip_hash text
);
alter table public.studio_access_requests enable row level security;
revoke all on public.studio_access_requests from anon, authenticated;
grant all on public.studio_access_requests to service_role;
-- Reward deduction is transactional and user-scoped. No elevated privileges.
create or replace function public.studio_redeem_reward(reward_id text)
returns integer language plpgsql security invoker set search_path=public as $$
declare cost integer; balance integer; u uuid:=auth.uid();
begin
 if u is null then raise exception 'Sign in required'; end if;
 cost:=case reward_id when 'reset' then 100 when 'music' then 200 when 'tennis' then 350 when 'treat' then 500 end;
 if cost is null then raise exception 'Unknown reward'; end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,0));
 select coalesce(sum(points),0) into balance from public.activity where user_id=u;
 if balance<cost then raise exception 'Not enough XP yet'; end if;
 insert into public.activity(user_id,activity_type,points,metadata) values(u,'studio_reward',-cost,jsonb_build_object('reward_id',reward_id,'title','Reward: '||reward_id));
 return balance-cost;
end $$;
revoke all on function public.studio_redeem_reward(text) from public,anon;
grant execute on function public.studio_redeem_reward(text) to authenticated;
create or replace function public.studio_update_stage(job_id uuid,new_stage text,event_note text default '')
returns void language plpgsql security invoker set search_path=public as $$
declare u uuid:=auth.uid(); previous text;
begin
 if u is null then raise exception 'Sign in required'; end if;
 if new_stage not in ('Review','Saved','Applied','Recruiter Screen','Hiring Manager','Interview','Final Interview','Offer','Rejected','Withdrawn','Pass','Closed') then raise exception 'Invalid stage'; end if;
 select status into previous from public.jobs where id=job_id and user_id=u for update;
 if not found then raise exception 'Role not found'; end if;
 update public.jobs set status=new_stage,updated_at=now(),applied_at=case when new_stage='Applied' then coalesce(applied_at,now()) else applied_at end where id=job_id and user_id=u;
 insert into public.application_updates(user_id,job_id,stage,notes) values(u,job_id,new_stage,'Manual update from '||previous||': '||left(event_note,5000));
end $$;
revoke all on function public.studio_update_stage(uuid,text,text) from public,anon;
grant execute on function public.studio_update_stage(uuid,text,text) to authenticated;
create table if not exists public.studio_email_outbox (
 id uuid primary key default gen_random_uuid(),
 email text not null unique,
 login_url text,
 requested_at timestamptz not null default now(),
 sent_at timestamptz,
 sent_message_id text
);
alter table public.studio_email_outbox enable row level security;
revoke all on public.studio_email_outbox from anon,authenticated;
grant all on public.studio_email_outbox to service_role;

-- Existing refresh routine is SECURITY DEFINER: scope its user argument before admitting new users.
do $fix$ declare src text; begin
 select pg_get_functiondef(oid) into src from pg_proc where proname='refresh_mission_control_scoring' and pronamespace='public'::regnamespace;
 if position('studio_owner_guard' in src)=0 then
 src:=replace(src,E'begin\n',E'begin\n  -- studio_owner_guard\n  if auth.uid() is distinct from p_user_id and coalesce(auth.role(),\'\') <> \'service_role\' and session_user not in (\'postgres\',\'supabase_admin\') then raise exception \'Unauthorized workspace\'; end if;\n');
 execute src; end if;
end $fix$;
