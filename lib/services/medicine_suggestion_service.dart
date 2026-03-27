class MedicineSuggestionService {
  static const Map<String, List<String>> _conditionSuggestions = {
    'blood pressure': ['Amlodipine', 'Losartan', 'Telmisartan'],
    'bp': ['Amlodipine', 'Losartan', 'Telmisartan'],
    'sugar': ['Metformin', 'Glimepiride', 'Insulin'],
    'diabetes': ['Metformin', 'Glimepiride', 'Insulin'],
    'fever': ['Paracetamol', 'Ibuprofen'],
    'pain': ['Paracetamol', 'Ibuprofen', 'Diclofenac'],
    'cold': ['Cetirizine', 'Levocetirizine'],
  };

  static List<String> getSuggestions(String condition) {
    final query = condition.trim().toLowerCase();
    if (query.isEmpty) {
      return const [];
    }

    final matches = <String>{};
    _conditionSuggestions.forEach((key, values) {
      if (query.contains(key) || key.contains(query)) {
        matches.addAll(values);
      }
    });

    return matches.toList()..sort();
  }
}


