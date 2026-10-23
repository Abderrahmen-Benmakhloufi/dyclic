# Architecture Decision Records (ADRs) — docs/DECISIONS.md

This document tracks all foundational architectural, technical, and pedagogical decisions.

---

## ADR-001: Monorepo & Technology Stack Selection
- **Status:** Accepted
- **Context:** The prototype must serve as a credible academic demonstration and evolve into a full-scale mobile and web product. The project owner has Flutter experience.
- **Decision:**
  - **Client Framework:** Flutter & Dart (Single codebase for Web PWA and Android Native APK).
  - **State Management:** Riverpod (Compile-safe, testable, decoupled dependency injection and reactive state).
  - **Backend / API Gateway:** Supabase Edge Functions (Deno / TypeScript) acting as an authenticated proxy.
  - **AI Engine:** Anthropic Claude API (Haiku-class model for high speed, low cost, and strict structured JSON output adherence).
- **Consequences:** Eliminates code duplication between web and mobile. Protects API keys from client-side reverse engineering.

---

## ADR-002: Web-First Delivery & PWA Strategy for Committee Review
- **Status:** Accepted (Updated per Change Request #1)
- **Context:** The evaluation committee needs instant access to test the prototype via a URL link without requiring APK sideloading or app store installations. Android remains the native priority.
- **Decision:**
  - Build and deploy Flutter Web with PWA capabilities (manifest, service worker for shell caching) hosted on Netlify (100% free, zero credit card requirement, instant deploy via Netlify Drop or CLI).
  - Conduct an early Week 1 spike on browser-specific constraints (mobile Chrome TTS voices, boundary progress events, font rendering).
- **Consequences:** Fast feedback loop for non-technical evaluators. Zero friction deployment without requiring payment credentials. Requires careful handling of web-specific limitations (avoiding `dart:io`, handling browser speech synthesis quirks).

---

## ADR-003: Pedagogical "Scaffolding & Hint-First" Architecture for F4
- **Status:** Accepted (Updated per Change Request #1)
- **Context:** In educational settings and academic evaluation, an AI that writes essays on behalf of the student is counter-productive and unacceptable. The client explicitly mandates that the AI must never write the text for the learner.
- **Decision:**
  - Structure F4 as a 5-step guided journey:
    1. Task understanding (Situation d'intégration decomposition).
    2. Idea brainstorm & structured outline (questions tailored to the prompt).
    3. Actionable step-by-step checklist.
    4. Text editor with optional sentence starters (*amorces de phrases*), strictly forbidding full paragraph generation.
    5. Formative error analysis returning: `span`, `category`, `rule_explanation`, and `hint`. The exact `correction` is sent in the payload but rendered only upon explicit user request (*« Voir la correction »*).
- **Consequences:** Reinforces learner agency and metacognitive reflection. Aligns directly with pedagogical thesis standards.

---

## ADR-004: F1 Simplification via Syntactic Restructuring & Lexical Glossing
- **Status:** Accepted (Updated per Change Request #1)
- **Context:** Simplification in reading pedagogy must not lead to lexical impoverishment ("dumbing down" words). French curriculum vocabulary must be acquired, not erased.
- **Decision:**
  - Prompts for F1 will shorten compound sentences, convert passive to active voice, and reduce subordinate clauses.
  - Rather than replacing domain-specific or academic words with childish synonyms, key vocabulary is preserved and provided with concise in-context glosses/definitions (`key_vocabulary_with_glosses`).
- **Consequences:** Text readability scores improve without degrading semantic nuance or curricular standards.

---

## ADR-005: Visual-First Reading Support (F5) and Voice Scoring Exclusion
- **Status:** Accepted (Updated per Change Request #1)
- **Context:** The original idea suggested pronunciation scoring and voice analysis. Change Request #1 reframed F5 to focus strictly on visual ergonomics, with no voice recording or pronunciation analysis.
- **Decision:**
  - F5 delivers:
    - Text chunking / short lines.
    - Synchronized visual highlighting (during TTS and manual reading).
    - An interactive focus ruler (règle de lecture) / line-focus mask.
    - Local typography customizer (Lexend, Atkinson, OpenDyslexic; font size, letter/word/line spacing, background/text contrast presets).
  - Phonetic rule lookup (e.g. *saisir* $s = /z/$) is relegated to a low-priority optional module. Voice recording and phonetic scoring are strictly out of scope.
- **Consequences:** Maximizes visual UX impact for committee demo while eliminating speech recognition risks, permissions complexity, and privacy hazards for minors.

---

## ADR-006: Three-Tier Educational Level Setting (Primaire, Moyen, Secondaire)
- **Status:** Accepted (Per Change Request #1 & Owner Confirmation)
- **Context:** The Algerian education system spans Primary (5e AP), Collège/Moyen (1e–4e AM), and Lycée/Secondaire (1e–3e AS). A single prompt tone cannot fit all three.
- **Decision:**
  - The app introduces a learner level setting persisted locally via `SharedPreferences`.
  - **Mandatory on First Launch:** The onboarding screen requires an explicit level choice before accessing the main dashboard. There is no skip option.
  - The chosen level can be modified at any time in the settings screen.
  - Prompt payloads pass `level: "primaire" | "moyen" | "secondaire"`.
- **Consequences:** Guarantees that every AI request is adapted to the exact educational cycle of the learner from the very first interaction.

---

## ADR-007: Strict Zero-Data Persistence & Anonymous Session Policy (Gate 1)
- **Status:** Accepted (Per Change Request #1)
- **Context:** The app targets minors. While the client noted minors might use the app without parental consent, handling minor accounts without verified consent presents legal liability under Algerian Law 18-07 and GDPR.
- **Decision:**
  - Gate 1 requires **zero user registration** and collects **zero personally identifiable information (PII)**.
  - Learner level, reading settings, and cached texts reside solely on the local client device (`SharedPreferences` / browser `localStorage`).
  - Edge Functions operate ephemerally: user text is processed in-memory and never written to a database table. Only token counts, latency, and sanitized error codes are logged.
  - Gate 2 will formally resolve the parental consent and data protection compliance framework.
- **Consequences:** Eliminates legal risk for the prototype demo while providing a frictionless onboarding experience.

---

## ADR-008: Multi-Provider LLM Gateway (Gemini Flash Free Tier & Claude Swappable)
- **Status:** Accepted (Per Owner Confirmation)
- **Context:** Testing and demonstration require a reliable, high-speed LLM with structured JSON support without incurring high costs or requiring a credit card for the developer.
- **Decision:**
  - Build the backend Edge Function `/ai` with a modular provider architecture.
  - Development and initial prototype validation use Google Gemini (via Google AI Studio Free Tier: 1,500 requests/day, 100% free, zero credit card requirement).
  - The provider is configurable via environment variables (`AI_PROVIDER="gemini" | "claude"`), allowing instant switching to Claude Haiku/Sonnet for official presentation if desired, with zero changes to Flutter client code.
- **Consequences:** Zero cost during prototype development and testing, high throughput, and zero client code coupling to a single AI vendor.
