import 'package:connectivity_plus/connectivity_plus.dart';

/// Network type checks for the Wi-Fi-only upload setting.
class ConnectivityRepository {
  ConnectivityRepository([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Wi-Fi and wired connections don't use cellular data.
  static bool isUnmetered(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);

  Future<bool> isOnUnmeteredNetwork() async =>
      isUnmetered(await _connectivity.checkConnectivity());
}
