import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return AuthState(isAuthenticated: false);
  }

  void login(String name) {
    state = AuthState(isAuthenticated: true, userName: name);
  }

  void logout() {
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
