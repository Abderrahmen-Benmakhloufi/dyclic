import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Provider diffusant l'état d'authentification Supabase en temps réel.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final stream = SupabaseService.authStateChanges;
  if (stream == null) {
    return const Stream.empty();
  }
  return stream;
});

/// Provider de l'utilisateur courant.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user ?? SupabaseService.currentUser;
});

/// Provider booléen indiquant si l'utilisateur est authentifié.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
