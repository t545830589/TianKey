class AuthResult {
  final bool success;
  final String role;
  final String message;

  AuthResult({
    required this.success,
    required this.role,
    required this.message,
  });
}

class AuthService {
  AuthResult verifyAdmin(String password) {
    if (password == 'admin123') {
      return AuthResult(
        success: true,
        role: 'ADMIN',
        message: '管理员认证成功',
      );
    }

    return AuthResult(
      success: false,
      role: 'NONE',
      message: '管理员密码错误',
    );
  }

  AuthResult verifyGuest(String password) {
    if (password == 'guest123') {
      return AuthResult(
        success: true,
        role: 'GUEST',
        message: '临时授权成功',
      );
    }

    return AuthResult(
      success: false,
      role: 'NONE',
      message: '临时授权失败',
    );
  }
}
