import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// All profiles keyed by id, including placeholder members.
  Future<Map<String, Profile>> fetchAll() async {
    final rows = await _client.from('profiles').select().order('full_name');
    return {for (final p in rows.map(Profile.fromJson)) p.id: p};
  }
}
