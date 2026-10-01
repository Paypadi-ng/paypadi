/// Sentry settings that differ per flavor.
class MonitoringConfig {
  const MonitoringConfig({
    required this.tracesSampleRate,
    required this.profilesSampleRate,
    required this.sendDefaultPii,
  });

  /// Every session traced and profiled, with request details, for debugging.
  static const dev = MonitoringConfig(
    tracesSampleRate: 1,
    profilesSampleRate: 1,
    sendDefaultPii: true,
  );

  /// Internal testers: enough traces to spot slow screens and requests.
  static const staging = MonitoringConfig(
    tracesSampleRate: 0.2,
    profilesSampleRate: 0,
    sendDefaultPii: true,
  );

  /// Real users: sampled traces, and no IPs, cookies or request headers.
  static const prod = MonitoringConfig(
    tracesSampleRate: 0.2,
    profilesSampleRate: 0,
    sendDefaultPii: false,
  );

  /// Share of transactions (screen loads, requests) sent to Sentry.
  final double tracesSampleRate;

  /// Share of traced transactions that are also profiled (iOS and macOS only).
  final double profilesSampleRate;

  /// Whether Sentry attaches IPs, cookies and request headers to events.
  final bool sendDefaultPii;
}
