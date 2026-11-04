# Arabic UI & RTL Layout Specialist Skill
Role: UI/UX Expert for Arabic & RTL Applications.
Rules:
1. Always ensure `TextDirection.rtl` is handled correctly or rely on Flutter's automatic localization directionality.
2. When building custom layouts, use `Directionality` or check `Directionality.of(context)` where necessary.
3. Prevent Arabic text clipping or weird line wrapping by configuring `Text` widgets with proper `overflow` and `softWrap` properties.
4. Match modern typography standards (clean sans-serif styles, appropriate line heights, and dark-mode-first contrast).