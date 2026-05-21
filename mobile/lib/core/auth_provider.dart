import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userName;

  AuthState({required this.isAuthenticated, this.userName});

  AuthState copyWith({bool? isAuthenticated, String? userName}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Set initial state from current user
    final user = FirebaseAuth.instance.currentUser;
    final initialState = AuthState(
      isAuthenticated: user != null,
      userName: user?.displayName ?? user?.phoneNumber,
    );

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        state = AuthState(isAuthenticated: false);
      } else {
        state = AuthState(
          isAuthenticated: true, 
          userName: user.displayName ?? user.phoneNumber ?? "User",
        );
      }
    });

    return initialState;
  }

  Future<void> login(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      state = AuthState(isAuthenticated: true, userName: name);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
