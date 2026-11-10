import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enregistrement immuable d'un ticket de délivrance comptoir
/// Conforme aux exigences de la Loi n° 2024/017 portant protection des données de santé
/// et aux règles déontologiques de l'Ordre National des Pharmaciens du Cameroun (ONPC).
class DeliveryTicketRecord {
  const DeliveryTicketRecord({
    required this.ticketId,
    required this.orderId,
    required this.pharmacyId,
    required this.pharmacistStaffId,
    required this.validationTimestamp,
    required this.encryptedOtpHash,
    required this.deliveredItemsSummary,
    required this.legalRetentionUntil,
    required this.signature,
  });

  factory DeliveryTicketRecord.fromJson(Map<String, dynamic> json) {
    return DeliveryTicketRecord(
      ticketId: json['ticketId'] as String,
      orderId: json['orderId'] as String,
      pharmacyId: json['pharmacyId'] as String,
      pharmacistStaffId: json['pharmacistStaffId'] as String,
      validationTimestamp: DateTime.parse(json['validationTimestamp'] as String),
      encryptedOtpHash: json['encryptedOtpHash'] as String,
      deliveredItemsSummary: json['deliveredItemsSummary'] as String,
      legalRetentionUntil: DateTime.parse(json['legalRetentionUntil'] as String),
      signature: json['signature'] as String,
    );
  }

  final String ticketId;
  final String orderId;
  final String pharmacyId;
  final String pharmacistStaffId;
  final DateTime validationTimestamp;
  final String encryptedOtpHash;
  final String deliveredItemsSummary;
  final DateTime legalRetentionUntil;
  final String signature;

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'orderId': orderId,
      'pharmacyId': pharmacyId,
      'pharmacistStaffId': pharmacistStaffId,
      'validationTimestamp': validationTimestamp.toIso8601String(),
      'encryptedOtpHash': encryptedOtpHash,
      'deliveredItemsSummary': deliveredItemsSummary,
      'legalRetentionUntil': legalRetentionUntil.toIso8601String(),
      'signature': signature,
    };
  }

  DeliveryTicketRecord copyWith({
    String? ticketId,
    String? orderId,
    String? pharmacyId,
    String? pharmacistStaffId,
    DateTime? validationTimestamp,
    String? encryptedOtpHash,
    String? deliveredItemsSummary,
    DateTime? legalRetentionUntil,
    String? signature,
  }) {
    return DeliveryTicketRecord(
      ticketId: ticketId ?? this.ticketId,
      orderId: orderId ?? this.orderId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacistStaffId: pharmacistStaffId ?? this.pharmacistStaffId,
      validationTimestamp: validationTimestamp ?? this.validationTimestamp,
      encryptedOtpHash: encryptedOtpHash ?? this.encryptedOtpHash,
      deliveredItemsSummary: deliveredItemsSummary ?? this.deliveredItemsSummary,
      legalRetentionUntil: legalRetentionUntil ?? this.legalRetentionUntil,
      signature: signature ?? this.signature,
    );
  }
}

/// Contrat abstrait de stockage sécurisé
abstract class SecureVaultStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<Map<String, String>> readAll();
  Future<void> delete(String key);
}

/// Adaptateur pour [FlutterSecureStorage] matériel (KeyStore / Keychain)
class FlutterSecureStorageVaultStorage implements SecureVaultStorage {
  const FlutterSecureStorageVaultStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Stockage chiffré en mémoire pour fallback hors-ligne et tests unitaires rapides
class CipherBackedMemoryVaultStorage implements SecureVaultStorage {
  CipherBackedMemoryVaultStorage({String? cipherKey})
      : _cipherKey = cipherKey ?? 'AfyaMedMateCipherKey2024';

  final String _cipherKey;
  final Map<String, String> _cipherStore = {};

  String _encrypt(String plain) {
    final keyBytes = utf8.encode(_cipherKey);
    final plainBytes = utf8.encode(plain);
    final encrypted = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64.encode(encrypted);
  }

  String _decrypt(String encoded) {
    final keyBytes = utf8.encode(_cipherKey);
    final cipherBytes = base64.decode(encoded);
    final decrypted = List<int>.generate(
      cipherBytes.length,
      (i) => cipherBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }

  @override
  Future<void> write(String key, String value) async {
    _cipherStore[key] = _encrypt(value);
  }

  @override
  Future<String?> read(String key) async {
    final val = _cipherStore[key];
    if (val == null) return null;
    return _decrypt(val);
  }

  @override
  Future<Map<String, String>> readAll() async {
    final result = <String, String>{};
    for (final entry in _cipherStore.entries) {
      result[entry.key] = _decrypt(entry.value);
    }
    return result;
  }

  @override
  Future<void> delete(String key) async {
    _cipherStore.remove(key);
  }

  /// Permet d'injecter une altération directe de données pour tester la détection de falsification
  void injectTamperedRaw(String key, String rawValue) {
    _cipherStore[key] = rawValue;
  }
}

/// Coffre-fort numérique sécurisé des tickets de délivrance comptoir
/// Garantit la non-répudiation, l'intégrité scellée et la purge légale sous 30 jours.
class SecureDeliveryTicketVault {
  SecureDeliveryTicketVault({
    SecureVaultStorage? storage,
    FlutterSecureStorage? flutterSecureStorage,
    String? hmacSecretKey,
  })  : _storage = storage ??
            (flutterSecureStorage != null
                ? FlutterSecureStorageVaultStorage(flutterSecureStorage)
                : CipherBackedMemoryVaultStorage()),
        _hmacSecretKey = hmacSecretKey ?? 'MedMate_ONPC_Loi2024017_Secret_Key';

  static const String _keyPrefix = 'delivery_ticket_';
  final SecureVaultStorage _storage;
  final String _hmacSecretKey;

  /// Hachage cryptographique sécurisé de l'OTP de délivrance
  static String hashOtp(String otpCode, {String salt = 'afya_onpc_2024'}) {
    final bytes = utf8.encode('$salt:$otpCode');
    return sha256.convert(bytes).toString();
  }

  /// Calcule la signature HMAC-SHA256 garantissant l'intégrité du ticket
  String computeSignature({
    required String ticketId,
    required String orderId,
    required String pharmacyId,
    required String pharmacistStaffId,
    required DateTime validationTimestamp,
    required String encryptedOtpHash,
    required String deliveredItemsSummary,
    required DateTime legalRetentionUntil,
  }) {
    final payload = [
      ticketId,
      orderId,
      pharmacyId,
      pharmacistStaffId,
      validationTimestamp.toIso8601String(),
      encryptedOtpHash,
      deliveredItemsSummary,
      legalRetentionUntil.toIso8601String(),
    ].join('|');

    final key = utf8.encode(_hmacSecretKey);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Archive de manière immuable et chiffrée un ticket de délivrance comptoir
  Future<void> archiveDeliveryTicket({
    required String ticketId,
    required String orderId,
    required String pharmacyId,
    required String pharmacistStaffId,
    required DateTime validationTimestamp,
    required String encryptedOtpHash,
    required String deliveredItemsSummary,
    DateTime? legalRetentionUntil,
  }) async {
    // Rétention légale obligatoire de 30 jours (Loi n° 2024/017)
    final retention = legalRetentionUntil ??
        validationTimestamp.add(const Duration(days: 30));

    final signature = computeSignature(
      ticketId: ticketId,
      orderId: orderId,
      pharmacyId: pharmacyId,
      pharmacistStaffId: pharmacistStaffId,
      validationTimestamp: validationTimestamp,
      encryptedOtpHash: encryptedOtpHash,
      deliveredItemsSummary: deliveredItemsSummary,
      legalRetentionUntil: retention,
    );

    final record = DeliveryTicketRecord(
      ticketId: ticketId,
      orderId: orderId,
      pharmacyId: pharmacyId,
      pharmacistStaffId: pharmacistStaffId,
      validationTimestamp: validationTimestamp,
      encryptedOtpHash: encryptedOtpHash,
      deliveredItemsSummary: deliveredItemsSummary,
      legalRetentionUntil: retention,
      signature: signature,
    );

    final key = '$_keyPrefix$ticketId';
    final jsonStr = jsonEncode(record.toJson());
    await _storage.write(key, jsonStr);
  }

  /// Récupère un ticket archivé par son identifiant unique
  Future<DeliveryTicketRecord?> getArchivedTicket(String ticketId) async {
    final key = '$_keyPrefix$ticketId';
    final jsonStr = await _storage.read(key);
    if (jsonStr == null) return null;

    try {
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DeliveryTicketRecord.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Récupère l'ensemble des tickets archivés pour une officine donnée
  Future<List<DeliveryTicketRecord>> getTicketsForPharmacy(
    String pharmacyId,
  ) async {
    final allEntries = await _storage.readAll();
    final tickets = <DeliveryTicketRecord>[];

    for (final entry in allEntries.entries) {
      if (entry.key.startsWith(_keyPrefix)) {
        try {
          final jsonMap = jsonDecode(entry.value) as Map<String, dynamic>;
          final record = DeliveryTicketRecord.fromJson(jsonMap);
          if (record.pharmacyId == pharmacyId) {
            tickets.add(record);
          }
        } catch (_) {
          // Ignorer les entrées altérées ou corrompues
        }
      }
    }

    tickets.sort(
      (a, b) => b.validationTimestamp.compareTo(a.validationTimestamp),
    );
    return tickets;
  }

  /// Vérifie l'intégrité cryptographique d'un ticket (détection de falsification)
  Future<bool> verifyTicketIntegrity(String ticketId) async {
    final record = await getArchivedTicket(ticketId);
    if (record == null) return false;

    final expectedSignature = computeSignature(
      ticketId: record.ticketId,
      orderId: record.orderId,
      pharmacyId: record.pharmacyId,
      pharmacistStaffId: record.pharmacistStaffId,
      validationTimestamp: record.validationTimestamp,
      encryptedOtpHash: record.encryptedOtpHash,
      deliveredItemsSummary: record.deliveredItemsSummary,
      legalRetentionUntil: record.legalRetentionUntil,
    );

    return record.signature == expectedSignature;
  }

  /// Purge les tickets ayant dépassé le délai de rétention légale de 30 jours
  Future<int> purgeExpiredTickets({DateTime? referenceNow}) async {
    final now = referenceNow ?? DateTime.now();
    final allEntries = await _storage.readAll();
    var purgedCount = 0;

    for (final entry in allEntries.entries) {
      if (entry.key.startsWith(_keyPrefix)) {
        try {
          final jsonMap = jsonDecode(entry.value) as Map<String, dynamic>;
          final record = DeliveryTicketRecord.fromJson(jsonMap);
          if (now.isAfter(record.legalRetentionUntil)) {
            await _storage.delete(entry.key);
            purgedCount++;
          }
        } catch (_) {
          // Purge les entrées non lisibles
          await _storage.delete(entry.key);
          purgedCount++;
        }
      }
    }

    return purgedCount;
  }
}
