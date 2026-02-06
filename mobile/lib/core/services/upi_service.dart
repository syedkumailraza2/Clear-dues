import 'package:url_launcher/url_launcher.dart';

/// UPI Deep Link Service
///
/// UPI Deep Link Format:
/// `upi://pay?pa={UPI_ID}&pn={NAME}&am={AMOUNT}&cu=INR&tn={NOTE}`
///
/// Parameters:
/// - pa (required): Payee UPI ID (e.g., name@upi, name@paytm)
/// - pn (required): Payee name
/// - am (optional): Amount (if not provided, user enters manually)
/// - cu (optional): Currency code (default: INR)
/// - tn (optional): Transaction note
/// - tr (optional): Transaction reference ID
/// - mc (optional): Merchant code
/// - url (optional): URL for additional transaction info
///
/// Example:
/// upi://pay?pa=john@upi&pn=John%20Doe&am=500.00&cu=INR&tn=ClearDues%20Settlement
class UpiService {
  UpiService._();

  /// Generate UPI deep link URL
  static String generateUpiLink({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
    String? transactionRef,
  }) {
    final params = <String, String>{
      'pa': payeeUpiId,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
    };

    if (transactionNote != null && transactionNote.isNotEmpty) {
      params['tn'] = transactionNote;
    }

    if (transactionRef != null && transactionRef.isNotEmpty) {
      params['tr'] = transactionRef;
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$queryString';
  }

  /// Launch UPI payment
  /// Returns true if UPI app was launched successfully
  static Future<UpiLaunchResult> launchUpiPayment({
    required String upiLink,
  }) async {
    try {
      final uri = Uri.parse(upiLink);

      // Check if any UPI app can handle this
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        return UpiLaunchResult(
          success: false,
          error: UpiError.noUpiApp,
          message: 'No UPI app installed on this device',
        );
      }

      // Launch UPI app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return UpiLaunchResult(
          success: true,
          message: 'UPI app launched successfully',
        );
      } else {
        return UpiLaunchResult(
          success: false,
          error: UpiError.launchFailed,
          message: 'Failed to launch UPI app',
        );
      }
    } catch (e) {
      return UpiLaunchResult(
        success: false,
        error: UpiError.unknown,
        message: 'Error launching UPI: ${e.toString()}',
      );
    }
  }

  /// Launch UPI payment with pre-built link from backend
  static Future<UpiLaunchResult> launchFromDeepLink(String deepLink) async {
    return launchUpiPayment(upiLink: deepLink);
  }

  /// Check if UPI apps are available
  static Future<bool> isUpiAvailable() async {
    try {
      // Try with a dummy UPI URL to check if any app can handle it
      final uri = Uri.parse('upi://pay?pa=test@upi&pn=Test&am=1.00&cu=INR');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}

/// Result of UPI launch attempt
class UpiLaunchResult {
  final bool success;
  final UpiError? error;
  final String message;

  UpiLaunchResult({
    required this.success,
    this.error,
    required this.message,
  });
}

/// UPI Error types
enum UpiError {
  noUpiApp,
  launchFailed,
  invalidLink,
  unknown,
}

/// UPI Payment Status (for manual confirmation)
enum UpiPaymentStatus {
  pending,
  success,
  failed,
  cancelled,
}
