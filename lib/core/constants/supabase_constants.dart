class SupabaseConstants {
  // NBT Supabase project. Both values are public client credentials (publishable key,
  // protected by Row Level Security) and can be overridden at build time:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://snsvvqhnfveorxiaafps.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_j4-VLFw9hDWZ7ATUrosLxQ_q0l6kyEo',
  );

  // Bucket names
  static const String tyrePhotosBucket = 'tyre-photos';
  static const String receiptsBucket = 'receipts';
  static const String signaturesBucket = 'signatures';
}
