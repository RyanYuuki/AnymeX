import 'dart:math' as Math;

String findBestMatch(String query, dynamic mangaList) {
  double bestSimilarity = 0.0;
  String bestMatchId = '';

  for (var manga in mangaList) {
    final title = manga?['title'] ?? manga?['name'] ?? '';
    double similarity = jaroWinkler(query.toLowerCase(), title.toLowerCase());
    if (similarity > bestSimilarity) {
      bestSimilarity = similarity;
      bestMatchId = manga['id']!;
    }
  }

  return bestMatchId;
}

double jaroWinkler(String s1, String s2) {
  if (s1 == s2) return 1.0;
  int len1 = s1.length;
  int len2 = s2.length;
  if (len1 == 0 || len2 == 0) return 0.0;
  int matchDistance = (Math.max(len1, len2) ~/ 2) - 1;
  List<bool> s1Matches = List.filled(len1, false);
  List<bool> s2Matches = List.filled(len2, false);
  int matches = 0;
  int transpositions = 0;
  for (int i = 0; i < len1; i++) {
    int start = Math.max(0, i - matchDistance);
    int end = Math.min(i + matchDistance + 1, len2);
    for (int j = start; j < end; j++) {
      if (s2Matches[j]) continue;
      if (s1[i] != s2[j]) continue;
      s1Matches[i] = true;
      s2Matches[j] = true;
      matches++;
      break;
    }
  }

  if (matches == 0) return 0.0;

  int k = 0;
  for (int i = 0; i < len1; i++) {
    if (!s1Matches[i]) continue;
    while (!s2Matches[k]) {
      k++;
    }
    if (s1[i] != s2[k]) transpositions++;
    k++;
  }

  double jaro = ((matches / len1) +
          (matches / len2) +
          ((matches - transpositions / 2) / matches)) /
      3.0;

  double prefixLength = 0;
  for (int i = 0; i < Math.min(4, Math.min(len1, len2)); i++) {
    if (s1[i] == s2[i]) {
      prefixLength++;
    } else {
      break;
    }
  }

  const winklerThreshold = 0.7;
  const winklerScalingFactor = 0.1;

  if (jaro > winklerThreshold) {
    jaro = jaro + (prefixLength * winklerScalingFactor * (1 - jaro));
  }

  return jaro;
}
