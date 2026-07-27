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
- [ ] **Phase 3** — Urge Toolkit (all techniques) + UrgeEvents
- [ ] **Phase 4** — Motivation / Why / Benefits + dashboard integration
- [ ] **Phase 5** — Mood + Check-in + charts
- [ ] **Phase 6** — Calendar heatmap + day detail
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
