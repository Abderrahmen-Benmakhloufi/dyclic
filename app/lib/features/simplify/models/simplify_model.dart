/// Represents a single difficult vocabulary word with its in-context simple gloss/definition.
class SimplifyWordGloss {
  final String word;
  final String definitionSimple;

  const SimplifyWordGloss({
    required this.word,
    required this.definitionSimple,
  });

  factory SimplifyWordGloss.fromJson(Map<String, dynamic> json) {
    return SimplifyWordGloss(
      word: json['word'] as String? ?? '',
      definitionSimple: json['definitionSimple'] as String? ??
          json['definition'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'definitionSimple': definitionSimple,
      };
}

/// Represents the full simplification result returned by Gemini AI.
class SimplifyResult {
  final String id;
  final String cycle; // 'primaire' | 'college' | 'lycee'
  final String originalText;
  final String summary; // 2 to 4 clear sentences
  final String simplifiedText; // FALC-structured text (SVO, short sentences)
  final List<SimplifyWordGloss> glosses; // Key difficult vocabulary with definitions
  final DateTime createdAt;

  const SimplifyResult({
    required this.id,
    required this.cycle,
    required this.originalText,
    required this.summary,
    required this.simplifiedText,
    required this.glosses,
    required this.createdAt,
  });

  factory SimplifyResult.fromJson(Map<String, dynamic> json) {
    final rawGlosses = json['glosses'] as List<dynamic>? ??
        json['key_vocabulary_with_glosses'] as List<dynamic>? ??
        [];

    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return SimplifyResult(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycle: json['cycle'] as String? ?? 'college',
      originalText: json['originalText'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      simplifiedText: json['simplifiedText'] as String? ??
          json['simplified_text'] as String? ??
          '',
      glosses: rawGlosses
          .map((g) => SimplifyWordGloss.fromJson(g as Map<String, dynamic>))
          .toList(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cycle': cycle,
        'originalText': originalText,
        'summary': summary,
        'simplifiedText': simplifiedText,
        'glosses': glosses.map((g) => g.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
