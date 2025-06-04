import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _amountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController(text: 'your-upi-id@bank');
  bool _processing = false;

  Future<void> _payWithUPI() async {
    final amt = _amountCtrl.text.trim();
    if (amt.isEmpty) return;

    final uri = Uri.parse(
      'upi://pay?pa=${_upiCtrl.text}&pn=HinduConnectApp&am=$amt&cu=INR',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch UPI app')),
      );
    }
  }

  Future<void> _payWithStripe() async {
    final amt = _amountCtrl.text.trim();
    if (amt.isEmpty) return;

    setState(() => _processing = true);

    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (double.parse(amt) * 100).toInt()}),
      );

      final json = jsonDecode(response.body);
      final clientSecret = json['clientSecret'];

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation successful!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                prefixText: '₹',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _upiCtrl,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'example@bank',
              ),
            ),
            const SizedBox(height: 24),
            if (_processing)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Pay via UPI'),
                onPressed: _payWithUPI,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.credit_card),
                label: const Text('Pay via Card (Stripe)'),
                onPressed: _payWithStripe,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
