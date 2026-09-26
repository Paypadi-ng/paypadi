# Security Policy

PayPadi handles payments and personal data, so we take security reports
seriously and appreciate responsible disclosure.

## Reporting a vulnerability

**Please do not open a public issue, pull request or discussion for security
problems.**

Report privately through GitHub:
**[Report a vulnerability](https://github.com/Paypadi-ng/paypadi/security/advisories/new)**
(Security tab → "Report a vulnerability").

Include as much as you can:

- what the issue is and where (file, screen, API endpoint)
- steps to reproduce or a proof of concept
- the impact you think it has
- the app version / build flavor and platform

Don't include real customer data, and don't access, modify or delete data
that isn't yours while investigating.

## What to expect

| Step | Target |
| --- | --- |
| Acknowledgement | within 3 business days |
| Initial assessment and severity | within 7 business days |
| Fix for critical/high issues | as fast as possible, normally within 30 days |

We'll keep you updated, agree on a disclosure date with you, and credit you
in the advisory unless you'd rather stay anonymous.

## Supported versions

Only the latest release published to the App Store / Play Store receives
security fixes.

## Scope

In scope: this repository (the PayPadi mobile app), its CI/CD workflows and
build configuration.

Out of scope: backend services and infrastructure not in this repository
(report those through the same channel and we'll route them), social
engineering, and denial-of-service testing.

Note: Firebase client configuration (`google-services.json`,
`GoogleService-Info.plist`, `firebase_options*.dart`) is public by design and
is not a vulnerability on its own; the keys in it are restricted to our app
identifiers.
