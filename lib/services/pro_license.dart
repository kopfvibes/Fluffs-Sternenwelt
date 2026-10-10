import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Only the public verification key is shipped with the app.
class ProLicenseVerifier {
  const ProLicenseVerifier({this.publicKey = productionPublicKey});
  static const productionPublicKey =
      'Eyern16+lZ27+wfs9GvSecUvoNs/zHMY+4BmLuwK1l4=';
  final String publicKey;

  Future<bool> verify(String code) async {
    try {
      final clean = code.replaceAll(RegExp(r'\s'), '');
      if (clean.length > 1500) return false;
      final parts = clean.split('.');
      if (parts.length != 3 || parts[0] != 'FLUFF1') return false;
      final message = base64Url.decode(base64Url.normalize(parts[1]));
      final signature = base64Url.decode(base64Url.normalize(parts[2]));
      final key = base64.decode(publicKey);
      if (message.length > 600 || signature.length != 64 || key.length != 32) {
        return false;
      }
      final payload = jsonDecode(utf8.decode(message));
      if (payload is! Map || payload['v'] != 1 ||
          payload['product'] != 'fluff-pro' || payload['edition'] != 'family' ||
          payload['id'] is! String ||
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(payload['id'] as String)) {
        return false;
      }
      return await Ed25519().verify(message,
        signature: Signature(signature,
          publicKey: SimplePublicKey(key, type: KeyPairType.ed25519)));
    } catch (_) {
      return false;
    }
  }
}
