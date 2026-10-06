/// Base URL of the admin panel backend (caregiver-admin `server`), including
/// the `/api` suffix. Used e.g. to email the admins about new picto requests.
///
/// Can be overridden at build time with
/// `--dart-define=ADMIN_API_BASE_URL=...`; an empty value disables the calls.
const String adminApiBaseUrl = String.fromEnvironment(
  'ADMIN_API_BASE_URL',
  defaultValue: 'https://caregiver-admin-server.vercel.app/api',
);
