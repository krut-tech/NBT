import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any thrown object into a short, user-readable message
/// (instead of `AuthException(message: ..., statusCode: ...)` / `Exception: ...`).
String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
