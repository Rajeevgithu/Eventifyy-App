import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvStatusOverlay extends StatelessWidget {
  const EnvStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    String stripeKey;
    String cloudName;
    String cloudPreset;

    if (kIsWeb) {
      stripeKey = const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
      cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
      cloudPreset = const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
    } else {
      stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "Not set";
      cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "Not set";
      cloudPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "Not set";
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Stripe: $stripeKey"),
          Text("Cloud Name: $cloudName"),
          Text("Upload Preset: $cloudPreset"),
        ],
      ),
    );
  }
}
