class ExampleWord {
  final String word;
  final List<int> highlightIndices;
  final String? note;

  const ExampleWord({
    required this.word,
    required this.highlightIndices,
    this.note,
  });
}

class DecodingSubRule {
  final String soundIpa;
  final String conditionFr;
  final List<ExampleWord> examples;

  const DecodingSubRule({
    required this.soundIpa,
    required this.conditionFr,
    required this.examples,
  });
}

class DecodingRule {
  final String id;
  final String letter;
  final String titleFr;
  final String overviewFr;
  final List<DecodingSubRule> subRules;

  const DecodingRule({
    required this.id,
    required this.letter,
    required this.titleFr,
    required this.overviewFr,
    required this.subRules,
  });
}
