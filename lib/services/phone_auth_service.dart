// lib/services/phone_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Starts phone number verification.
  /// onCodeSent: called with the verificationId when SMS is sent.
  /// onFailed: called if sending SMS fails.
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-retrieval or instant verification
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto‑retrieval timed out
      },
    );
  }

  /// Completes sign‑in with the SMS code supplied by the user.
  Future<UserCredential> signInWithSms({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }
}
