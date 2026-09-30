/// Process-wide shared [HttpClient] used by every network call.
///
/// Creating a fresh client per request throws away its keep-alive connection
/// pool, so repeated update checks pay a TCP/TLS handshake every time. The
/// shared client keeps connections alive across calls; callers must NOT close
/// it (a closed client cannot be reused). Per-request timeouts are still
/// enforced with `Future.timeout()` at each call site.
///
/// Tests talk to real loopback `HttpServer`s (no `HttpOverrides`), so sharing
/// one client across tests is safe — requests are still independent.
library;

import 'dart:io';

HttpClient? _instance;

/// Returns the lazily-created, process-wide HTTP client.
HttpClient sharedHttpClient({
  Duration connectionTimeout = const Duration(seconds: 15),
}) {
  return _instance ??= () {
    final client = HttpClient()..connectionTimeout = connectionTimeout;
    // The app runs user-triggered, low-volume requests; keep the idle pool
    // conservative so sockets do not linger indefinitely.
    client.idleTimeout = const Duration(seconds: 30);
    return client;
  }();
}
