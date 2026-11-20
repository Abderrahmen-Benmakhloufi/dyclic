# 📘 PROJECT_HANDOVER_CONTEXT.md
> **وثيقة تسليم المشروع ودليل السياق الهندسي الكامل (Project Handover & Architecture Guide)**  
> *ملف مخصص لقراءة الذكاء الاصطناعي في أي محادثة جديدة لفهم التطبيق، بنيته، وقراراته التقنية بنسبة 100%.*

---

## 1. نبذة عن التطبيق والهدف (App Identity & Vision)
- **اسم التطبيق في الكود:** `lecture_aide` (بالهوية التجارية المقترحة: **Dyclic** أو **Assistant Français DYS**).
- **المنصة والتقنيات:** **Flutter (Dart 3.x / Flutter 3.29+)**، مستهدف منصة **Android (APK split ABI & Bundle)**.
- **الجمهور المستهدف:** تلامذة وطلاب المنهاج الجزائري الذين يعانون من صعوبات وتحديات التعلم واضطرابات الديس (Troubles DYS: *Dyslexie, Dysorthographie, Dysgraphie, Fatigue cognitive*).
- **الأطوار التعليمية المغطاة:**
  1. **Primaire (الطور الابتدائي - 5e AP):** تركيز على تفكيك الحروف المتشابهة والمقاطع والكلمات البسيطة.
  2. **Collège (الطور المتوسط - 4e AM / BEM):** تفكيك أسئلة الفهم وقواعد النحو وتوجيه الإنتاج الكتابي.
  3. **Lycée (الطور الثانوي - 3e AS / BAC):** استيعاب النصوص الفكرية وتصحيح التعبير المركب.

---

## 2. الهيكلية المعمارية للمجلدات (Architecture Overview)

المشروع يتبع بنية Feature-First النظيفة المدعومة بـ Riverpod لإدارة الحالة المحلية:

```
app/
├── assets/
│   ├── data/
│   │   ├── consignes.json           # 17 نموذج تعليمة امتحانات رسمية مفككة بيداغوجياً (Offline)
│   │   └── mock_test_samples.json   # نصوص ونماذج اختبارات قياسية
│   ├── fonts/                       # Atkinson Hyperlegible, Lexend, OpenDyslexic
│   └── images/ui/                   # 20 أيقونة وصورة شفافة (512x512 PNG) بدون خلفية
└── lib/
    ├── core/                        # النواة المشتركة (Core Engine)
    │   ├── ai/                      # إعدادات Gemini API وسلسلة الموديلات البديلة Fallbacks
    │   ├── learner_profile/         # نموذج البروفايل التشخيصي DYS وإدارته محلياً
    │   ├── reading_settings/        # إعدادات القراءة (Palette, Contrast, Fonts, Spacing)
    │   ├── services/ocr_service.dart# معالجة الصور بالكاميرا/المعرض (Google ML Kit OCR)
    │   ├── theme/                   # لوحات التباين العالي الخاصة بعسر القراءة (Crème, Sombre, etc.)
    │   ├── tts/tts_service.dart     # محرك النطق الصوتي الفرنسي (Flutter TTS)
    │   └── widgets/app_asset_icon.dart # محرك الأيقونات المركزية الشفافة AppUiAssets
    │
    └── features/                    # الموديولات والخصائص (Feature Modules)
        ├── onboarding/              # شاشة البداية واختيار الطور الدراسي
        ├── diagnostic/              # استبيان تشخيص DYS (24 سؤالاً تفاعلياً + تقييم الأبعاد)
        ├── home/                    # الصفحة الرئيسية وشبكة الخدمات
        ├── reading_support/         # [خاصية 1] M'aider à lire (تلوين المقاطع، الحروف الصامتة، التباين)
        ├── writing/                 # [خاصية 2] M'aider à écrire (تحليل وإنتاج النصوص، فئات الأخطاء الـ5)
        ├── instructions/            # [خاصية 3] Comprendre les consignes (كتالوج الـ17 تعليمة + AI Explainer)
        ├── decoding/                # [خاصية 4] Aide au décodage (كتالوج قواعد النطق وفك الترميز)
        ├── tts/                     # [خاصية 5] Écouter le texte (المحول الصوتي المباشر)
        └── simplify/                # [خاصية 6 - قيد التطوير] Simplifier le texte
```

---

## 3. تفاصيل الخصائص المكتملة وآلية عملها (Features Breakdown)

### 📌 الخاصية الأولى: المساعدة على القراءة المكيّفة (M'aider à lire)
- **المسار:** `lib/features/reading_support/`
- **آلية العمل:**
  - معالجة النصوص المدخلة أو الممسوحة بـ OCR.
  - تطبيق خطوط dyslexie-friendly مثل Atkinson Hyperlegible و Lexend مع تباعد أسطر وكلمات قابل للتعديل.
  - **خوارزميات التقطيع الفوري:**
    - `FrenchSyllableService`: تقطيع المقاطع الصوتية بالصناديق الشفافة أو التسطير.
    - `FrenchSilentLetterService`: اكتشاف الحروف الصامتة وتعتيمها بلون رمادي هادئ.
    - `FrenchPhonemeService`: تلوين الفونيمات المركبة والحروف السياقية (g/c/s).
  - **ميزة الأداء العالي:** تم تزويد هذه الخدمات بنظام **LRU Cache $O(1)$** حتى 2000 كلمة لمنع أي ثقل أو تهنيج على المعالجات الضعيفة.

### 📌 الخاصية الثانية: المساعدة على الإنتاج الكتابي والتصحيح (M'aider à écrire)
- **المسار:** `lib/features/writing/`
- **الملفات الأساسية:**
  - `writing_screen.dart`: شاشة الإدخال، حقل الموضوع الاختياري، 30 نموذجاً تجريبياً (10 لكل طور).
  - `services/writing_gemini_service.dart`: الاتصال بـ Gemini API مع معالجة الأخطاء والـ fallback.
  - `models/writing_error_profile.dart`: بروفايل تراكمي ذكي يحفظ تاريخ أخطاء التلميذ الأكثر تكراراً (`recurringErrors`) ويحقن ملخصاً مضغوطاً منها في الـ prompt ليعرف الـ AI نقاط ضعف الطالب المتكررة.
  - `writing_feedback_screen.dart`: شاشة النتائج المتكاملة (كشف النص المصحح تدريجياً، فلترة الأخطاء، نطق صوتي TTS).
- **أقسام الأخطاء الخمسة المعتمدة بيداغوجياً (DYS-Aligned):**
  1. `inversion`: الحروف المعكوسة (b/d, p/q) وتبديل مواقع الحروف.
  2. `phonetique`: الكتابة بالسمع وحذف الحروف الصامتة.
  3. `regle_lecture`: قواعد القراءة والسياق (c/ç, g/ge, s/ss).
  4. `grammaire`: تصريف الأفعال وعلامات الجمع والتأنيث والتطابق.
  5. `ponctuation`: علامات الترقيم، البداية بالحروف الكبيرة (Majuscules).
- **التحكم الصوتي في بطاقات النتائج:**
  - يوجد زر تشغيل الصوت `Écouter` وزر إيقاف فوري `Stop` بلون أحمر بارز مخصص عند بدء القراءة، بالإضافة إلى زر إيقاف عام في شريط الـ AppBar لإيقاف النطق بضغطة واحدة من أي مكان.

### 📌 الخاصية الثالثة: شرح وتفكيك تعليمات الامتحانات (Comprendre les consignes)
- **المسار:** `lib/features/instructions/`
- **النظام الهجين (Hybrid Architecture):**
  1. **الكتالوج المحلي الفوري (Offline):** 17 تعليمة نموذجية مأخوذة من الامتحانات الرسمية الجزائرية مخزنة في `consignes.json`.
  2. **خوارزمية المطابقة السريعة (`InstructionMatchingService`):** مطابقة التعليمة مع الكتالوج بدقة $\ge 70\%$ لعرض الحل الفوري دون استهلاك إنترنت.
  3. **الذكاء الاصطناعي الفوري (`InstructionAiScreen`):** في حال عدم وجود التعليمة، يتكفل Gemini بتحليلها وتفكيكها إلى 3 أو 4 خطوات إجرائية مباشرة مصاغة بأفعال أمر تناسب مستوى التلميذ.

### 📌 الخاصية الرابعة: أدوات فك الترميز وقواعد النطق (Aide au décodage)
- **المسار:** `lib/features/decoding/`
- كتالوج تفاعلي يعرض القواعد الصوتية الفرنسية الأساسية مصنفة مع بطاقات ملونة وأمثلة نطقية فورية بالصوت.

### 📌 الخاصية الخامسة: التوليد الصوتي المباشر (Écouter le texte)
- **المسار:** `lib/features/tts/`
- محول صوتي مباشر مزود بميزة **الحفظ التلقائي للنص** (`SharedPreferences`) لمنع ضياع نصوص الطالب عند إغلاق التطبيق.

---

## 4. نظام الأصول والصور والهوية البصرية (Asset System)
- **الملف المسؤول:** `lib/core/widgets/app_asset_icon.dart` و `AppUiAssets`.
- تم تحويل كافة الإيموجيز القديمة إلى **صور PNG شفافة وعالية الدقة (512x512)** متطابقة في الثيم البصري (Soft 3D Vector / Flat Pastel):
  - أيقونات الأطوار الثلاثة: `cycle_primaire.png`, `cycle_college.png`, `cycle_lycee.png`
  - الأفاتار المكيف: `avatar_primaire.png`, `avatar_college.png`, `avatar_lycee.png`
  - أيقونات الخصائص بالـ AppBar: `feat_reading.png`, `feat_writing.png`, `feat_instructions.png`, `feat_decoding.png`, `feat_tts.png`, `feat_simplify.png`
  - أيقونات فئات الأخطاء الخمسة: `err_inversion.png`, `err_phonetique.png`, `err_regle.png`, `err_grammaire.png`, `err_ponctuation.png`
  - صورة الاحتفال والنجاح: `writing_celebration.png`

---

## 5. أحدث التعديلات والتحسينات المنجزة مؤخراً (Recent Fixes)
1. **تصميم قسم الأرشيف والمفضلة (Archives & Favoris):**
   - تم الفصل التام بين منطقة العمل النشطة وبين الأرشيف في شاشتي الكتابة والتعليمات عبر هيدر فاصل **`[📁 MES ARCHIVES & FAVORIS]`** وحاوية بطاقة مخصصة وشريط تبويب منسق (`Segmented Tabs`).
   - دعم ميزة الحذف الفردي بالسحب **Swipe-to-Delete** مع حماية المفضلة.
2. **شريط الـ AppBar وزر المفضلة:**
   - ضبط عناوين الـ AppBar لتكون مرنة (`Flexible + TextOverflow.ellipsis`) لمنع تداخل شريط العنوان مع أزرار الإجراءات (المفضلة وإعدادات القراءة).
3. **التحكم الصوتي المتقدم في شاشة التعبير:**
   - إضافة زر `Stop` مخصص ومستقل يظهر فور تشغيل النطق الصوتي إلى جانب زر إيقاف عام في شريط الـ AppBar.
4. **فحوصات الجودة البرمجية:**
   - تم إجراء فحص الكود: `flutter analyze` ➔ **`No issues found!`**.
   - تم تشغيل حزمة الاختبارات بالكامل: `flutter test` ➔ **`93/93 All tests passed!`**.

---

## 6. أوامر التطوير والبناء السريعة (Developer Cheatsheet)

- **فحص الكود والتحليل:**
  ```powershell
  cd app; flutter analyze
  ```
- **تشغيل الاختبارات:**
  ```powershell
  cd app; flutter test
  ```
- **استخراج نسخ الـ APK المجهزة للتثبيت:**
  ```powershell
  .\export_apk.ps1
  ```
  *(يقوم بإنشاء نسخ split ABI في المجلد الجذري: arm64-v8a, armeabi-v7a, x86_64).*

---
*تم توليد هذا الملف ليكون مرجعاً هندسياً ثابتاً للمحادثات القادمة مع وكيل الذكاء الاصطناعي.*
