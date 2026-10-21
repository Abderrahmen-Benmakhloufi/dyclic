# CLAUDE.md — Lead Engineer Rules & Project Guidelines

> **Project:** Mobile & Web Application for French Learners with Reading Difficulties (Dyslexic & Struggling Readers).  
> **Context:** Academic Thesis (*Mémoire*) Prototype for Committee Acceptance (Gate 1).  
> **Stack:** Flutter (Web PWA primary for demo, Android native priority) + Supabase Edge Functions + Claude API.

---

## 1. Core Mission & Ethical Principles
1. **Never write the text for the learner:** In F4 (Production écrite), the AI is an educational coach/tutor. It scaffolds (understands, structures, gives sentence starters, provides hints). It **never** generates or replaces the student's text.
2. **Zero medical or diagnostic claims:** The app is an *"Outil d'aide à la lecture et à l'écriture"*. Never claim to diagnose, treat, or cure dyslexia anywhere in the UI, prompts, or demo material.
3. **No vocabulary dumbing down:** In F1 (Simplification), reduce syntactic complexity and sentence length while preserving meaning and rich vocabulary. Difficult words receive a contextual gloss/definition, not a childish replacement.
4. **Child-safe, positive, encouraging tone:** Outputs must be constructive, level-adapted, and empowering.

---

## 2. Priority & Scope Architecture (Gate 1 Prototype)
Features are strictly gated in this priority order:
1. **P1 — F4 Production Écrite (Situation d'Intégration):** 5-step guided workflow (Comprendre la consigne, Organiser les idées, Étapes concrètes, Rédiger avec amorces, Évaluation avec indices pédagogiques). Correction is hidden until explicitly tapped.
2. **P2 — F1 Simplification & Résumé:** Minimal flow: text in $\to$ summary + syntactically simplified text + key vocabulary glosses.
3. **P3 — F2 Explication de Consignes:** Decomposition into "Ce qui est demandé", "Mots-clés", "Étapes", "Exemple non résolutif". (Reused in F4 step 1).
4. **P4 — F3 Synthèse Vocale (TTS):** Speech synthesis with synchronized word/line visual highlighting, pause, and rate controls.
5. **P5 — F5 Aide Visuelle à la Lecture:** Visual segmentation (short lines/chunks), live focus ruler / line focus mask, dynamic typography customization (font, size, letter/word/line spacing, color presets).
*Note:* The curated pronunciation rule table (e.g. `saisir` $s = /z/$) is low-priority/optional and built only if time permits. Voice recording and pronunciation scoring are strictly **OUT OF SCOPE**.

---

## 3. Educational Levels (Algerian System)
All AI prompts and UI interactions take into account a three-tier learner level stored in local preferences:
- `primaire` (5e AP / primary)
- `moyen` (Collège / 1e–4e AM) — *Default*
- `secondaire` (Lycée / 1e–3e AS)

Prompt parameters must include `level` (`primaire` | `moyen` | `secondaire`) to adapt sentence length, grammar concepts, and coaching depth.

---

## 4. Security, Privacy & Cost Rules (Non-Negotiable)
1. **No secrets in client or Git:** Never place Claude API keys or Supabase service keys in the Flutter codebase or repository.
2. **Edge Function proxy only:** The app communicates exclusively with the Supabase Edge Function `/ai`.
3. **Strict Zero-Data Policy in Phase 1:** No student accounts, no passwords, no personal data collection. Student level and reading preferences are saved in local device storage (`SharedPreferences`).
4. **No text persistence:** Do not store learner texts or situations d'intégration on the backend database. Log only token counts, execution latency, and error codes.
5. **Spend cap & Rate limiting:** Enforce per-IP/per-session rate limits on the Edge Function and set spending alerts in the Anthropic/Supabase dashboards.

---

## 5. Flutter & Code Quality Rules
1. **French UI only:** All visible text must be in French. UI strings must go through Flutter i18n (`.arb` files). No hard-coded strings in widgets.
2. **Central Theme injection:** All readable text must inherit styling from the central `ReadingSettings` provider (font family, font size, letter spacing, word spacing, line height, contrast colors).
3. **Web-first compatibility:** Do not use `dart:io` in shared client code. Test PWA readiness on mobile browsers (Android Chrome).
4. **Validating AI JSON:** Prompts live in `/prompts/` (versioned markdown/txt). Outputs must strictly match JSON schemas. Never render unparsed raw AI text.
5. **Fail safe on network/offline:** When offline, provide friendly French error states. Keep local settings, cached reading text, and device TTS available offline.

---

## 6. Development Workflow & Commands
- **Flutter:**
  - `flutter pub get` — Fetch dependencies
  - `flutter analyze` — Static analysis (zero warnings allowed)
  - `flutter test` — Run all unit and widget tests
  - `flutter run -d chrome` — Run on Chrome (Web target)
  - `flutter build web --pwa-strategy=offline-first` — PWA build
  - `flutter build apk --split-per-abi` — Android release APK
- **Supabase CLI:**
  - `supabase start` — Local development stack
  - `supabase functions serve ai --no-verify-jwt` — Local Edge Function testing
  - `supabase secrets set ANTHROPIC_API_KEY=...` — Production secrets
