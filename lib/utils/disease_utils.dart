// Utility for mapping disease label strings to standardized keys.
// Aligned to the 3-class DR model output: Normal, Mild, Severe.
String getDiseaseKey(String diseaseName) {
  final String normalizedName = diseaseName.toLowerCase().trim();

  // Mapping aligned to model output classes
  final Map<String, String> diseaseKeyMap = {
    'normal': 'normal',
    'mild': 'mild',
    'severe': 'severe',
  };

  for (final entry in diseaseKeyMap.entries) {
    if (normalizedName.contains(entry.key)) {
      return entry.value;
    }
  }

  // Fallback: replace spaces with underscores
  return normalizedName.replaceAll(' ', '_');
}