import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/network/supabase_service.dart';
import 'core/storage/app_upgrade_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale data date formatting (Bahasa Indonesia) untuk library intl
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  // Optimasi cache memori gambar untuk perangkat berspesifikasi rendah (RAM 2-3 GB)
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      40 * 1024 * 1024; // 40 MB max

  final sharedPreferences = await SharedPreferences.getInstance();
  await SupabaseService.initialize();

  // Bersihkan cache dan jalankan migrasi versi otomatis pasca-update
  await AppUpgradeHandler.handleUpgradeIfNeeded(sharedPreferences);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CardlyApp(),
    ),
  );
}
