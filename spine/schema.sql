-- Project Manhattan — coordination spine (minimum viable: 5 tables + control)
-- Apply with:  psql "$SUPABASE_DB_URL" -f spine/schema.sql
-- Idempotent: safe to run repeatedly. The swarm extends this schema via its own
-- PR-gated tasks (spend_ledger, pr_registry, decisions/votes, etc. — see D5).

-- ── agents: the fleet registry (heartbeat + reap) ─────────────────────────────
create table if not exists agents (
  id            text primary key,                 -- "<machine>:<role>:<uuid>"
  machine       text not null,
  role          text not null,
  status        text not null default 'alive',    -- alive | draining | dead
  current_task  bigint,
  last_seen     timestamptz not null default now(),
  started_at    timestamptz not null default now(),
  meta          jsonb not null default '{}'::jsonb
);

-- ── tasks: the work queue (claimed atomically via claim_task RPC) ─────────────
create table if not exists tasks (
  id              bigserial primary key,
  title           text not null,
  role            text not null,                  -- which role-queue this belongs to
  status          text not null default 'open',   -- open|claimed|in_review|done|blocked|abandoned
  priority        int  not null default 100,      -- lower = sooner
  idempotency_key text unique not null,           -- deterministic; dedupes task creation
  body            jsonb not null default '{}'::jsonb,  -- spec, Definition-of-Done, links
  claimed_by      text references agents(id),
  claimed_until   timestamptz,                    -- lease expiry (null when unclaimed)
  phase           text,
  created_by      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists tasks_open_idx on tasks (role, status, priority) where status = 'open';

-- ── task_deps: dependency edges (a task is eligible only when all deps done) ──
create table if not exists task_deps (
  task_id    bigint not null references tasks(id) on delete cascade,
  depends_on bigint not null references tasks(id) on delete cascade,
  primary key (task_id, depends_on),
  check (task_id <> depends_on)
);

-- ── runs: idempotency ledger (safe re-execution of external side effects) ────
create table if not exists runs (
  idempotency_key text primary key,               -- e.g. "task:42:pr_open"
  task_id         bigint references tasks(id),
  agent_id        text,
  kind            text not null,                  -- pr_open | deploy | migration | asset | ...
  result          jsonb,
  created_at      timestamptz not null default now()
);

-- ── control: singleton kill switch + global knobs (the only A2 safety net) ───
create table if not exists control (
  id                          int primary key default 1 check (id = 1),
  status                      text not null default 'running',  -- running | paused | stopped
  phase                       text not null default 'genesis',  -- genesis | planning | building
  spend_rate_limit_usd_hour   numeric not null default 20,      -- global $/hr governor
  notes                       text,
  updated_at                  timestamptz not null default now()
);
insert into control (id) values (1) on conflict (id) do nothing;

-- ══ RPCs (called over HTTPS via PostgREST — no held PG connections) ═══════════

-- claim_task: atomic, lease-protected pull of the next eligible task for a role.
-- Returns 0 or 1 rows. Honors the control kill switch. The SELECT ... FOR UPDATE
-- SKIP LOCKED guarantees two agents can never claim the same row.
create or replace function claim_task(p_agent_id text, p_role text, p_lease_seconds int default 900)
returns setof tasks
language plpgsql as $$
declare v_status text;
begin
  select status into v_status from control where id = 1;
  if v_status is distinct from 'running' then
    return;  -- paused/stopped → hand back nothing
  end if;

  return query
  update tasks t
     set status        = 'claimed',
         claimed_by    = p_agent_id,
         claimed_until = now() + make_interval(secs => p_lease_seconds),
         updated_at    = now()
   where t.id = (
     select t2.id from tasks t2
      where t2.role = p_role
        and t2.status = 'open'
        and not exists (                         -- all dependencies must be done
          select 1 from task_deps d
            join tasks dep on dep.id = d.depends_on
           where d.task_id = t2.id and dep.status is distinct from 'done')
      order by t2.priority asc, t2.id asc
        for update skip locked
      limit 1)
  returning t.*;

  -- record what this agent now holds
  update agents set current_task = (select id from tasks where claimed_by = p_agent_id
                                     order by claimed_until desc limit 1),
                    last_seen = now()
   where id = p_agent_id;
end; $$;

-- renew_lease: extend the lease on a task you still hold (call mid-work).
create or replace function renew_lease(p_agent_id text, p_task_id bigint, p_lease_seconds int default 900)
returns boolean
language plpgsql as $$
declare ok boolean;
begin
  update tasks set claimed_until = now() + make_interval(secs => p_lease_seconds), updated_at = now()
   where id = p_task_id and claimed_by = p_agent_id and status = 'claimed'
  returning true into ok;
  return coalesce(ok, false);
end; $$;

-- heartbeat: prove an agent is alive (drives the reaper).
create or replace function heartbeat(p_agent_id text)
returns void language sql as $$
  update agents set last_seen = now(),
                    status = case when status = 'dead' then 'alive' else status end
   where id = p_agent_id;
$$;

-- reap_stale: release expired leases and mark dead agents. Any agent (or a cron)
-- may call this. Returns the number of tasks released. This is what makes
-- "any agent can die anytime" hold — its work returns to the pool automatically.
create or replace function reap_stale(p_dead_after_seconds int default 300)
returns int language plpgsql as $$
declare n int;
begin
  with released as (
    update tasks set status = 'open', claimed_by = null, claimed_until = null, updated_at = now()
     where status = 'claimed' and claimed_until < now()
    returning 1)
  select count(*) into n from released;

  update agents set status = 'dead', current_task = null
   where status = 'alive' and last_seen < now() - make_interval(secs => p_dead_after_seconds);
  return n;
end; $$;
