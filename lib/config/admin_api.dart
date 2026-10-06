/// Base URL of the admin panel backend (caregiver-admin `server`), including
/// the `/api` suffix, e.g. `https://caregiver-admin-server.vercel.app/api`.
///
/// Can be overridden at build time with
/// `--dart-define=ADMIN_API_BASE_URL=...`. When empty, the app skips calls to
/// the admin backend (e.g. the email for new picto requests).
const String adminApiBaseUrl = String.fromEnvironment(
  'ADMIN_API_BASE_URL',
  defaultValue: '',
);
