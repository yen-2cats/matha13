-- 數A 13級分特訓系統 — Supabase schema + RLS
-- 使用方式：Supabase Dashboard → SQL Editor → 貼上整份 → Run（跑一次即可，可重複執行）
--
-- 另外到 Authentication → Sign In / Providers → Email 確認：
--   1. Email provider 開啟（預設開）
--   2. 「Confirm email」建議關閉（單人使用，省去收確認信的一步；不關的話註冊後要先點信中連結才能登入）
--
-- 前端只用 publishable key（sb_publishable_...），所有資料表都開 RLS、
-- 只允許 auth.uid() = user_id 的列被讀寫；不需要也不要用 service_role key。

-- ── 主狀態文件：整包 localStorage 的鏡像（做題紀錄、錯題本、模擬成績…）──
create table if not exists public.app_state (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_state enable row level security;

drop policy if exists "own state" on public.app_state;
create policy "own state" on public.app_state
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── 手寫筆跡永久檔：每題一列，含完整筆畫時間戳與過程指標 ──
create table if not exists public.ink_sessions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  qid        text not null,
  t0         bigint not null,          -- 該次作答起始（epoch ms）
  proc       jsonb,                    -- 過程指標摘要 {fi, hes, era, tail, n}
  strokes    jsonb not null,           -- {s:[筆畫…], e:[塗改時間…]} 完整原始資料
  created_at timestamptz not null default now()
);

alter table public.ink_sessions enable row level security;

drop policy if exists "own ink" on public.ink_sessions;
create policy "own ink" on public.ink_sessions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists ink_sessions_user_time
  on public.ink_sessions (user_id, created_at desc);
