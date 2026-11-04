# Flutter Clean Code Reviewer Skill
Role: Senior Flutter Architect & Code Quality Enforcer.
Rules:
1. Never place business logic directly inside UI build methods. Use ViewModels, Controllers, or BLoC/Providers.
2. Ensure proper disposal of controllers (TextEditingController, AnimationController, ScrollController) in `dispose()`.
3. Avoid hardcoded strings and colors; use theme references and localization keys.
4. Keep widgets small and modular by extracting sub-widgets.
5. Prioritize null-safety and robust error handling (try-catch with user-friendly messages).