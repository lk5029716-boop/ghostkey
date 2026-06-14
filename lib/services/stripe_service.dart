import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static Future<void> init() async {
    Stripe.publishableKey = 'pk_test_YOUR_KEY';
    await Stripe.instance.applySettings();
  }

  static Future<bool> createCheckoutSession(String priceId) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}