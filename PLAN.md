# Clean Tracker — Build Plan

A local-first abstinence & recovery app. No backend, no account, no cloud, no
analytics. All data stays on the device; the app works fully offline (the
release build ships **without** the `INTERNET` permission).

Language of the app: German (via `flutter_localizations` + ARB). Code language:
English.

## Phase progress

- [x] **Phase 0 — Project setup**
  - [x] Folder structure (feature-first, `core/` + `features/`)
  - [x] Design tokens (`core/theme/tokens.dart`) — full brand palette, spacing,
        radius, motion, fonts. WCAG AA ratios documented in-file.
  - [x] Hand-built `ColorScheme` + `TextTheme` (no `ColorScheme.fromSeed`),
        light + dark, `useMaterial3: true`.
  - [x] Local font bundling (Space Grotesk + Inter, no network fetch).
  - [x] `go_router` with a `StatefulShellRoute` bottom-nav shell.
  - [x] Drift schema v1 (all tables from the data model) + migration strategy,
        foreign keys enabled.
  - [x] `Clock` abstraction — no `DateTime.now()` in domain logic.
  - [x] Pure streak logic (`features/tracker/domain`) + unit tests
        (incl. DST/absolute-time invariant).
  - [x] Localization scaffold (`app_de.arb`, `app_en.arb`).
  - [x] Empty dashboard, `flutter analyze` clean, tests green.
  - [x] GitHub Action building the release APK.
- [x] **Phase 1 — Onboarding + Habit + QuitAttempt + Time Tracker**
  - [x] `SharedPreferences` gate + go_router redirect into onboarding on first run
  - [x] Multi-step onboarding (welcome + disclaimer → habit type/name/unit →
        start time), with the alcohol medical-taper warning
  - [x] `HabitRepository` — create habit + first quit attempt in one
        transaction, reactive streams (unit-tested)
  - [x] Riverpod code-gen providers (clock, repository, active habits, attempts)
  - [x] Live `StreakTicker` — 1s tick, lifecycle-aware (no background timer),
        gold→sand gradient, days-only toggle, reduce-motion aware
  - [x] Dashboard renders the ticker per habit (single card / swipeable
        carousel for multiple); survives restart via drift
  - [x] Widget tests: fresh install → onboarding; onboarded → live streak
- [ ] **Phase 1 follow-ups (deferred by design, noted for later phases):**
      onboarding steps for baseline (Phase 7) and the first "why" (Phase 4).
- [x] **Phase 2 — Relapse flow + history + "clean days total"**
  - [x] `RelapseRepository`: close active attempt, record event, open a new
        attempt — all in one transaction (unit-tested)
  - [x] Pure `cleanStats` (clean days / tracked days / %) — never resets to
        zero; unit-tested across a relapse gap
  - [x] Colourless relapse flow (neutrals only, no signal colour, no red):
        pause + optional 15-min timer → capture (time, trigger, situation,
        amount, mood, note, planned) + new-start picker → non-shaming close
  - [x] Reached via a low-key card overflow menu (not a button by the streak)
  - [x] "Gesamt clean: X von Y Tagen (Z %)" shown once there's history
  - [x] Tests: attempt close/open, clean-total across attempts, flow open +
        cancel. Fixed onboarding bug (type switch now refreshes name/unit) with
        a regression test. analyze clean, 19 tests green.
- [ ] **Phase 2** — Relapse flow + history + "clean days total"
- [x] **Phase 3 — Urge Toolkit (all techniques) + UrgeEvents**
  - [x] Persistent berry FAB ("Verlangen") on every main screen — berry's
        exclusive home; opens `/urge`
  - [x] Before/after measurement: intensity slider (1–10) starts a UrgeEvent →
        technique → intensity slider ends it (`intensityEnd`, `survived`)
  - [x] All seven techniques: urge surfing (3-min guided), 4-7-8 breathing
        (animated circle + haptics), 15-minute rule (countdown), 5-4-3-2-1
        grounding (wizard), play-the-tape (Phase 4 will inject real reasons),
        distraction (random suggestion), emergency contact (tel: via
        url_launcher, DE help numbers in `core/safety`)
  - [x] Reward loop: "Du hast eine Welle überstanden. Das war Nr. N."
  - [x] Pure `urge_stats` (waves ridden, per-technique effectiveness) — tested
  - [x] Tests: stats domain, repository start/complete, FAB opens flow.
        analyze clean, 25 tests green.
- [ ] **Phase 3 follow-ups:** OS notification for the 15-min rule (Phase 8),
      user-defined distraction list (Phase 4/settings), per-habit urge tagging.
- [x] **Phase 4 — Motivation / Why / Benefits + flow integration**
  - [x] Schema **v2** migration: `Motivations.noticedAt` (addColumn onUpgrade)
  - [x] `MotivationRepository`: add / edit / pin / reorder / delete; benefits
        markable "noticed" with date (unit-tested)
  - [x] Manage screen: Why / Benefits / Consequences tabs, drag-reorder, pin,
        benefit presets per habit type (tap to adopt) + "already noticed" list
  - [x] "Letter to my future self" (free text in shared_preferences)
  - [x] Daily "your why" quote card on the dashboard (deterministic per day —
        pure `pickDaily`, tested)
  - [x] **Integration (DoD):** the person's own words appear in the relapse
        pause (why + benefits) and the urge "play the tape" technique
        (consequences + why)
  - [x] "More" tab is now a real menu (Motivation, Future letter)
  - [x] Tests: daily-pick, repository add/pin/reorder/notice, relapse-flow shows
        why, MotivationRecall lists why+consequences. analyze clean, 33 green.
- [ ] **Phase 4 follow-ups:** optional photo per motivation (deferred to keep
      the no-extra-permissions guarantee), user-defined distraction list.
- [x] **Phase 5 — Mood + Check-in + charts**
  - [x] `MoodRepository`: one entry per calendar day (query-then-upsert around
        the `date` UNIQUE key), reactive + one-shot reads (unit-tested)
  - [x] `CheckinRepository`: one check-in per habit per day, back-datable
        (`date` = the day, `completedAt` = now); re-save updates in place (tested)
  - [x] Pure domain: `checkin_questions` (typed, configurable set incl. the
        1–10 urge scale), `checkin_streak` (gentle, DST-safe), `mood_stats`
        (series, averages, urge-vs-calm and around-relapse observations) — tested
  - [x] Mood entry screen: 1–5 faces (face + colour + label, never colour
        alone), energy/sleep scales, tags, note; last-7-days back-fill selector
  - [x] Check-in flow: one short form; a "no" to "clean today?" gently offers
        the relapse flow (never forces it); last-7-days back-fill
  - [x] Stats tab (replaces placeholder): mood line chart (`fl_chart`, 7/30/90),
        average, gentle check-in streak, honest non-clinical observations with a
        "not a diagnosis" note, and the urge insights (waves + what works)
  - [x] Dashboard: 7-day mood sparkline card (hand-drawn) + check-in card
        (done/open + streak)
  - [x] Tests: mood_stats, checkin_streak, mood & check-in repositories, stats
        empty-state widget smoke test
- [ ] **Phase 5 follow-ups:** low-mood safety nudge to the help screen (Phase 9,
      once the help screen lands), notification for the daily check-in (Phase 8).
- [x] **Phase 6 — Calendar heatmap + day detail**
  - [x] Pure `buildCalendarMonth` (clean / relapse / none per day, streak-length
        warmth tier, mood score, check-in flag) — DST-safe, unit-tested
  - [x] Hand-built heatmap grid (no `table_calendar`): clean = gold, warmer with
        a longer streak (25/45/70/100 %); relapse = outlined, no fill, no red;
        mood dot; check-in sky ring. Colour never the only signal.
  - [x] Swipe (and arrows) between months via an infinite `PageView`; cells
        sized to the space so it never overflows
  - [x] Compact year overview (12 mini-months), tap a month to jump to it
  - [x] Habit selector for multi-habit users (calendar is per-habit for
        clean/relapse; mood + check-in are app-wide)
  - [x] Day-detail bottom sheet showing **all event types** of the day: relapse,
        mood (faces + tags + note), check-in answers, urges (DoD)
  - [x] Fix: Motivation screen now wraps its body in `SafeArea` so the add
        button and last item clear the system navigation bar
  - [x] Tests: calendar domain (clean run, relapse precedence, warmth tiers)
- [ ] **Phase 7** — Savings + calories + saving goals (versioned baselines)
- [ ] **Phase 8** — Milestones + notifications + share graphic
- [ ] **Phase 9** — Export/import, app lock, settings, polish, A11y pass

## Architecture notes & trade-offs

- **State: Riverpod.** Business logic testable without `BuildContext`. The DB
  provider is hand-written (a parameterless singleton gains nothing from
  code-gen); feature repositories will use `@riverpod` code-gen where they carry
  real logic.
- **Persistence: Drift (SQLite).** Relational data (attempts, events, versioned
  baselines) with reactive streams and real migrations. Alternative considered:
  Isar/Hive — rejected because the savings/streak/relapse model is genuinely
  relational and benefits from SQL + foreign keys.
- **No `ColorScheme.fromSeed`.** Seed generation tonally shifts the fixed brand
  hexes; every role is mapped by hand to preserve exact colours. Trade-off: more
  verbose, loses automatic tonal harmony — colour fidelity wins here.
- **Generated code is git-ignored** (`*.g.dart`, `*.freezed.dart`, generated
  l10n) and rebuilt in CI, so the repo never carries stale generated output.

## Local development

```bash
flutter pub get                                   # also generates l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run                                        # needs a device/emulator
```

## CI

`.github/workflows/build-apk.yml` runs on every push to `main` / `claude/**`,
on PRs to `main`, and manually. It runs codegen → analyze → test →
`flutter build apk --release` (plus per-ABI APKs) and uploads them as artifacts.
