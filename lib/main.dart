import 'package:flutter/material.dart';
import 'app.dart';
import 'core/sync/sync_queue_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase must initialize successfully before any provider accesses
  // Supabase.instance.client.
  await SupabaseService.initialize();

  // Restore queued offline writes before the application starts.
  //
  // ChatProvider registers the actual message handler when it is created.
  // If the queue contains messages from a previous session, ChatProvider
  // will trigger processing again after registering its handler.
  await SyncQueueService.instance.init();

  runApp(const CampusXApp());
}
