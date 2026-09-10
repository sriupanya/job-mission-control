# Career Studio

The public frontend uses the existing Supabase project. Career records stay user-scoped behind Supabase authentication and RLS. The public landing page contains no private career records.

## Features

- Existing Today, Jobs, People, Applications, Companies and Projects views preserved.
- Animated responsive pink studio, depth effects, progress celebrations and reduced-motion support.
- Private editable interview scripts, 90-second rehearsal timer, 120-minute 80/20 plan.
- Contextual Claude coach via `mission-control-studio`, using private profile, STAR stories and selected saved JD; no invented candidate experience.
- Stable daily-action completion IDs, persistent XP and transactional reward redemption.
- Manual role entry, duplicate checks, transactional application stage/history updates.
- Public access requests, owner-only approval/decline, separate visitor workspaces.
- Private queued sign-in links and password setup for subsequent instant access.

## Operations

The owner's existing ChatGPT Mission Control automation now coordinates hourly access/sign-in email delivery and daily career refresh. It uses connected Gmail and Supabase. It retains the Claude high-recall baseline and requisitions, H-1B and experience filters, official-board verification, full pagination where possible, deduplication, email evidence and coverage logging. This is an agent-operated scheduled workflow, not a browser cron. A refresh button reloads saved records; Request a refresh queues work for the scheduler.

Email checks run hourly. First sign-in links may wait for that check; users can set a password after verifying email. The email worker regenerates stale links before delivery and records provider message IDs only after confirmed send. Access approval does not share the owner's records. Approval notifications link to an authenticated page; no GET link changes permission.

`activity` stores studio_profile, studio_script, studio_chat, studio_complete, studio_practice, studio_reward, studio_sync, studio_sync_request and studio_ai_request records. No new RLS grants on career tables. The two new administration/outbox tables are service-only with RLS and no anon/authenticated grants. The studio endpoint has an explicit public request/login queue boundary and verifies JWT plus owner identity for privileged actions. The preexisting scoring function gained a caller/target ownership guard.

`sql/studio.sql` records reviewed additive SQL deployed via the database connector. It is not a generated CLI migration. No CLI was available in this environment. The Edge Function uses the existing Anthropic secret and model configuration.

## Verification

- JavaScript syntax check: `node --check app.js`.
- DOM behavior checks: install jsdom 26.1.0 in a temporary QA directory, then set STUDIO_JSDOM to its package path and run `node tests/studio-ui.cjs`.
- Database: transaction rollback check of stage/history update; separate user sees zero owner jobs; insufficient XP cannot redeem.
- Live HTTP: unauthenticated coach and approvals return 401; invalid access email returns 400.
- Browser visual QA and a full authenticated browser journey were not run.
- Scheduled future executions and real visitor acceptance have not yet occurred. The initial sync log is explicitly partial, covering three verified email receipts, not an exhaustive inbox/role search.

## Hosting

Sites publishes only the four files in dist. After frontend edits, copy index.html, app.js, studio.css and config.js there before packaging. Backend code and SQL are not dist assets. Existing GitHub Pages workflow was already failing during Configure Pages, so Sites is the requested public deployment destination; the GitHub source remains the code review record.
