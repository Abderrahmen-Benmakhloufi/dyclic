# Design System & Guidelines — docs/DESIGN.md

> **Target Audience:** French learners (children and adolescents, collège/primaire/secondaire) with reading difficulties (dyslexic / struggling readers).  
> **Core Aesthetic:** Modern, friendly, calm, accessible. Non-medical, non-infantilizing.

---

## 1. Visual Philosophy & Principles

### What we avoid:
- Crowded interfaces and excessive visual clutter.
- Pure `#000000` text on harsh `#FFFFFF` backgrounds (causes visual stress).
- Text sizes smaller than 16px for primary reading content.
- Unlabeled icons and distracting, gratuitous animations.
- Heavy gradients and intense drop shadows.

### What we embrace:
- Generous whitespace and visual breathing room.
- Clear, distinct cards with soft corners (16–20px radius).
- High contrast compliant with WCAG AA/AAA standards.
- Full card clickability with tactile, friendly feedback.
- Large, effortless touch targets (minimum 48–52px height).
- Immediate cognitive clarity: each feature's purpose is understood in under two seconds.

---

## 2. Color Palette (Visual Ergonomics)

| Token | Hex Value | Purpose |
| :--- | :--- | :--- |
| **Background** | `#F8F7F4` | Warm, soft off-white / light cream. Replaces aggressive pure white. |
| **Primary** | `#6B5B95` | Calm, muted purple. Pedagogical and modern without feeling childish. |
| **Secondary / Accent** | `#A8C3B0` | Muted sage green. Gentle positive reinforcement and accents. |
| **Text Primary** | `#252525` | Soft charcoal off-black. High contrast without the glare of `#000000`. |
| **Text Secondary** | `#666666` | Neutral gray for metadata, subtitles, and secondary labels. |
| **Surface / Card** | `#FFFFFF` | Crisp white cards resting gently on the warm `#F8F7F4` canvas. |
| **Card Border** | `#E8E5DF` | Very subtle, non-intrusive card outlines (1px solid). |

---

## 3. Typography & Hierarchy

### Primary Typeface: Atkinson Hyperlegible
*Developed by the Braille Institute specifically to maximize letter distinction (e.g., distinguishing between 'I', 'l', '1', and 'o', '0').*  
*Fallback / Alternative: Lexend.*

### Type Scale (Mobile):
- **App Title / Hero Header:** 24–28 px (Bold)
- **Page Title:** 22–24 px (Bold)
- **Card Title:** 18–20 px (SemiBold / Bold)
- **Body Text:** 16–18 px (Regular) — *Long reading texts: 18 px. Absolute minimum for any body text: 16 px.*
- **Button Labels:** 16–18 px (Bold)
- **Secondary / Meta Text:** 14–16 px (Regular)
- **Line Height:** 1.5 to 1.7 (strictly enforced to prevent line-jumping).
- **Paragraph Spacing:** 16–20 px.

---

## 4. UI Components Specification

### 4.1 Feature Cards (Home Screen)
- **Border Radius:** 16–20 px
- **Padding:** 16–20 px
- **Spacing between cards:** 12–16 px
- **Elevation / Shadow:** Flat or subtle ambient blur (`rgba(0,0,0,0.04) 0px 4px 12px`), no harsh black dropshadows.
- **Interactivity:** The entire card area is interactive and tappable.
- **Content:** Icon (prominent, 32–36px) + Feature Name (Bold) + Short, crisp one-line description.

### 4.2 Buttons
- **Height:** 48–52 px
- **Border Radius:** 12–14 px
- **Typography:** 16–18 px Bold
- **Direct Labeling:** Action-oriented, direct French verbs (e.g., *« Simplifier le texte »*, *« Voir l'indice »*).

### 4.3 Customizable Reading Settings (Dynamic Overlay/Sheet)
Allow the learner to adjust without imposing a single view:
- **Font Size:** `− A +` (14px to 28px)
- **Line Height:** `− ↕ +` (1.4 to 2.0)
- **Letter Spacing:** `− AB +` (0.0 to 2.5)
- **Typeface Choice:** Atkinson Hyperlegible, Lexend, OpenDyslexic, System.

---

## 5. Home Screen Content Layout

```text
Header:
  Bonjour 👋
  Que souhaitez-vous faire aujourd'hui ?

5 Primary Cards:
  1. 📖 M'aider à lire
     Faciliter la lecture du texte.

  2. 🔊 Écouter le texte
     Écouter le texte à voix haute.

  3. ✏️ M'aider à écrire
     Être accompagné pour réaliser une production écrite.

  4. 📝 Simplifier le texte
     Rendre le texte plus simple et plus facile à comprendre.

  5. 💡 Expliquer la consigne
     Comprendre ce qu'on me demande de faire.
```
