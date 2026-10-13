import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth. It's a [ChangeNotifier] so go_router can re-run its
/// redirect whenever the session changes (sign-in, sign-out, token expiry).
class AuthRepository extends ChangeNotifier {
  AuthRepository(this._client) {
    _sub = _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;

  bool get isSignedIn => _client.auth.currentSession != null;

  String? get currentUserId => _client.auth.currentUser?.id;

  String? get currentEmail => _client.auth.currentUser?.email;

  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signOut() => _client.auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
