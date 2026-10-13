import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/taxonomy.dart';

/// The `custom_statuses` table.
class StatusRepository {
  StatusRepository(this._client);

  final SupabaseClient _client;

  /// Falls back to the web's defaults when the table is empty or unreadable.
  /// Unlike the website, the app never seeds the table — it only reads it.
  Future<StatusCatalog> fetchCatalog() async {
    try {
      final rows = await _client
          .from('custom_statuses')
          .select()
          .order('column_order', ascending: true);
      return StatusCatalog(rows.map(StatusOption.fromJson).toList());
    } on Exception {
      return StatusCatalog.defaults;
    }
  }
}
