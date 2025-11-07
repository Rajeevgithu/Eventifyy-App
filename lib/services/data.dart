// services/data.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

String publishedkey = dotenv.env["STRIPE_PUBLISHABLE_KEY"] ?? "";
String secretkey = dotenv.env["STRIPE_SECRET_KEY"] ?? "";
