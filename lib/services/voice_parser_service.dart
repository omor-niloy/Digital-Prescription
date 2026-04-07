import 'package:flutter/foundation.dart';

class VoiceParserService {
  static final VoiceParserService _instance = VoiceParserService._internal();
  factory VoiceParserService() => _instance;
  VoiceParserService._internal();

  /// Parses the raw text dictated by the user to extract medicine details.
  /// Format expected: [Medicine Name] [Dosage] for [Duration] [Meal Instruction]
  Future<Map<String, dynamic>> parseMedicalVoiceText(String speechText) async {
    debugPrint("RECORDED TEXT TO PARSE: $speechText");
    String rawText = speechText.toLowerCase();

    String extractedDuration = '';
    String extractedDosage = '';
    String extractedInstruction = '';
    
    // 1. Extract Meal Instruction
    final instructionPatterns = [
      "before meal", "after meal", "with food", "empty stomach",
      "khabar aage", "khabar pore", "khawar aage", "khawar pore",
      "before food", "after food"
    ];
    for (final pattern in instructionPatterns) {
      if (rawText.contains(pattern)) {
        // Standardize the output
        if (pattern.contains("before") || pattern.contains("aage")) {
          extractedInstruction = "before meal";
        } else if (pattern.contains("with") || pattern.contains("empty")) {
           extractedInstruction = pattern; // whatever the matched string is
        } else {
          extractedInstruction = "after meal";
        }
        
        // Remove pattern from text
        rawText = rawText.replaceAll(pattern, '');
        break; // Stop after finding the first match
      }
    }

    // 2. Extract Duration
    // Looks for patterns like "5 days", "1 month", "2 weeks"
    final durationRegex = RegExp(r'(\d+)\s*(days?|weeks?|months?|din|mash|soptaho)');
    final durationMatch = durationRegex.firstMatch(rawText);
    if (durationMatch != null) {
      extractedDuration = durationMatch.group(0) ?? '';
      rawText = rawText.replaceFirst(durationMatch.group(0)!, '');
    }

    // 3. Extract Dosage
    // We check for numeric patterns first like "1 0 1", "1+0+1", "1-0-1"
    final dosageDigitRegex = RegExp(r'(\d)\s*[\+\-]?\s*(\d)\s*[\+\-]?\s*(\d)');
    final dosageMatch = dosageDigitRegex.firstMatch(rawText);
    if (dosageMatch != null) {
      final m = dosageMatch.group(1);
      final n = dosageMatch.group(2);
      final ni = dosageMatch.group(3);
      extractedDosage = '$m+$n+$ni';
      rawText = rawText.replaceFirst(dosageMatch.group(0)!, '');
    } else {
      // Look for explicit words if digits not found
      int m = 0;
      int n = 0;
      int ni = 0;
      
      if (rawText.contains('morning') || rawText.contains('sokal')) {
        m = 1;
        rawText = rawText.replaceAll(RegExp(r'\bmorning\b|\bsokal\b'), '');
      }
      if (rawText.contains('noon') || rawText.contains('dupur')) {
        n = 1;
        rawText = rawText.replaceAll(RegExp(r'\bnoon\b|\bdupur\b'), '');
      }
      if (rawText.contains('night') || rawText.contains('raat')) {
        ni = 1;
        rawText = rawText.replaceAll(RegExp(r'\bnight\b|\braat\b'), '');
      }
      
      if (m > 0 || n > 0 || ni > 0) {
        extractedDosage = '$m+$n+$ni';
      }
    }

    // Clean up remaining filler words
    final fillerWords = ["for", "continue", "jonno", "din", "and", "plus", "extract"];
    for (final filler in fillerWords) {
       rawText = rawText.replaceAll(RegExp(r'\b' + filler + r'\b'), ' ');
    }

    // The remaining text should theoretically be the medicine name
    final extractedMedicine = rawText.trim().replaceAll(RegExp(r'\s+'), ' ');

    return {
      "medicine": extractedMedicine,
      "dosage": extractedDosage,
      "duration": extractedDuration,
      "instruction": extractedInstruction
    };
  }
}
