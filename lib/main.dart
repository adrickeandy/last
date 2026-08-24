import 'package:flutter/material.dart';
import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase must initialize successfully before any provider accesses
  // Supabase.instance.client. Swallowing this error leaves the app running
  // with a broken client and produces misleading auth/API errors.
  await SupabaseService.initialize();

  runApp(const CampusXApp());
}
