import 'dart:async';

import 'package:flutter/foundation.dart';

/// Turns any [Stream] into a [Listenable] so GoRouter can re-evaluate its
/// `redirect` callback whenever Supabase's auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
