import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/taxonomy.dart';

/// The `custom_phases` table.
class PhaseRepository {
  PhaseRepository(this._client);

  final SupabaseClient _client;

  /// Falls back to the web's defaults when the table is empty or unreadable.
  Future<PhaseCatalog> fetchCatalog() async {
    try {
      final rows = await _client
          .from('custom_phases')
          .select()
          .order('created_at', ascending: true);
      return PhaseCatalog(rows.map(PhaseOption.fromJson).toList());
    } on Exception {
      return PhaseCatalog.defaults;
    }
  }
}
