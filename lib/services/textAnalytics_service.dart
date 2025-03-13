import 'dart:math' as math;
import 'dart:core';

class TextanalyticsService {

  int countSyllables(String word) {
    RegExp vowelPattern = RegExp(r'[aeiouáéíóöõúüű]', caseSensitive: false);
    Iterable<RegExpMatch> matches = vowelPattern.allMatches(word);
    return matches.isNotEmpty ? matches.length : 1;
  }

  int countWords(String text) {
    List<String> words = text.split(RegExp(r'\s+'));
    return words.length;
  }

  int countSentences(String text) {
    List<String> sentences = text.split(RegExp(r'[.!?]+'));
    return sentences.isNotEmpty ? sentences.length : 1;
  }

  double calculateSMOGIndex(String text) {
    int sentenceCount = countSentences(text);
    int polysyllableCount = text
        .split(RegExp(r'\s+'))
        .map(countSyllables)
        .where((syllableCount) => syllableCount >= 3)
        .length;

    double score = 1.0430 * math.sqrt((30 * polysyllableCount / sentenceCount)) + 3.1291;
    print('SMOG Index (Hun): $score');
    return score;
  }

  double calculateColemanLiauIndex(String text) {
    int letterCount = text.replaceAll(RegExp(r'\s+'), '').length;
    int wordCount = countWords(text);
    int sentenceCount = countSentences(text);

    double l = letterCount / wordCount * 100;
    double s = sentenceCount / wordCount * 100;

    double score = 0.0588 * l - 0.296 * s - 15.8;
    print('Coleman-Liau Index (Hun): $score');
    return score;
  }
}
