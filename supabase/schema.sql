-- Tarot in Time — playtest tables
-- Paste this whole file into Supabase → SQL Editor → New query, then Run.

create table if not exists public.runs (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  run_id        uuid not null,
  player_id     uuid,                 -- anonymous, random per browser
  build         text,                 -- e.g. 'v7'
  source        text,                 -- hostname: your vercel.app domain, itch.zone, or 'local'
  start_deck    text,                 -- blade / vigil / verdict
  draft_pick    text,
  floor_reached int,                  -- 1-5 (5 = the Chronarch)
  won           boolean,
  died_to       text,
  kills         int,
  gold          int,
  deck          jsonb,                -- final deck, card ids ('*' = exalted)
  readings      jsonb,                -- per floor: spread order, reversed, fixed, echo, omens
  gear          jsonb,
  duration_s    int,
  constraint runs_size check (pg_column_size(deck) + pg_column_size(readings) + coalesce(pg_column_size(gear),0) < 20000)
);

create table if not exists public.feedback (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  run_id      uuid,                   -- links to runs.run_id
  player_id   uuid,
  build       text,
  interest    text check (interest in ('yes','maybe','no')),
  message     text check (char_length(message) <= 2000)
);

-- Players can only add rows. They cannot read, edit or delete anything.
alter table public.runs     enable row level security;
alter table public.feedback enable row level security;

drop policy if exists "playtesters insert runs" on public.runs;
drop policy if exists "playtesters insert feedback" on public.feedback;
create policy "playtesters insert runs"     on public.runs     for insert to anon with check (true);
create policy "playtesters insert feedback" on public.feedback for insert to anon with check (true);

grant insert on public.runs, public.feedback to anon;


-- ===== Handy queries (run these later, one at a time) =====

-- Win rate and depth by build and starting deck:
-- select build, start_deck, count(*) runs,
--        round(100.0*avg(won::int),1) win_pct,
--        round(avg(floor_reached),2) avg_floor
-- from runs group by 1,2 order by 1,2;

-- Where people die:
-- select build, floor_reached, died_to, count(*) from runs where not won group by 1,2,3 order by 1,2,4 desc;

-- Unique players, and how many came back for more than one run:
-- select count(distinct player_id) players,
--        count(*) filter (where n > 1) repeat_players
-- from (select player_id, count(*) n from runs group by 1) t;

-- Interest in a full game:
-- select interest, count(*) from feedback where interest is not null group by 1;

-- Latest written feedback, with how that run went:
-- select f.created_at, f.interest, f.message, r.floor_reached, r.won, r.start_deck
-- from feedback f left join runs r on r.run_id = f.run_id
-- where f.message is not null order by f.created_at desc;

-- Most-played cards in final decks:
-- select replace(card,'*','') card, count(*) from runs, jsonb_array_elements_text(deck) card group by 1 order by 2 desc;
