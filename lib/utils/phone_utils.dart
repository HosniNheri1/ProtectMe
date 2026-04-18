// CRÉER CE NOUVEAU FICHIER :
class PhoneUtils {
  static String normalizeTunisianPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return '';
    }

    // Supprimer tous les caractères non numériques sauf +
    String normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    print('📞 Normalisation: "$phoneNumber" → "$normalized"');

    // Cas 1: Déjà formaté internationalement (+216...)
    if (normalized.startsWith('+216') && normalized.length == 13) {
      return normalized; // +21653506407
    }

    // Cas 2: 00216... (format international alternatif)
    if (normalized.startsWith('00216') && normalized.length == 14) {
      return '+${normalized.substring(2)}'; // Convertir 00216 en +216
    }

    // Cas 3: 216... sans le +
    if (normalized.startsWith('216') && normalized.length == 12) {
      return '+$normalized'; // +21653506407
    }

    // Cas 4: Numéro local tunisien (commence par 0)
    if (normalized.startsWith('0') && normalized.length == 9) {
      return '+216${normalized.substring(1)}'; // 053506407 → +21653506407
    }

    // Cas 5: Numéro court (8 chiffres)
    if (normalized.length == 8 &&
        RegExp(r'^[2-9][0-9]{7}$').hasMatch(normalized)) {
      return '+216$normalized'; // 53506407 → +21653506407
    }

    // Cas 6: Autres formats - retourner tel quel avec avertissement
    print('⚠️ Format de numéro non reconnu: $phoneNumber');
    return phoneNumber;
  }

  static bool isValidTunisianPhone(String phoneNumber) {
    final normalized = normalizeTunisianPhone(phoneNumber);
    return RegExp(r'^\+216[2-9][0-9]{7}$').hasMatch(normalized);
  }

  static String formatForDisplay(String phoneNumber) {
    final normalized = normalizeTunisianPhone(phoneNumber);
    if (normalized.startsWith('+216') && normalized.length == 13) {
      // Format: +216 XX XXX XXX
      final part1 = normalized.substring(4, 6); // 53
      final part2 = normalized.substring(6, 9); // 506
      final part3 = normalized.substring(9); // 407
      return '+216 $part1 $part2 $part3';
    }
    return phoneNumber;
  }
}
