class AuthResult {
  final bool success;
  final String role;
  final String message;

  AuthResult({required this.success, required this.role, required this.message});
}

class AuthService {
  static const String initialAdminPassword = '13092991951';

  AuthResult verifyAdmin(String password) {
    if (password == initialAdminPassword) {
      return AuthResult(success: true, role: 'ADMIN', message: '管理员认证成功');
    }
    return AuthResult(success: false, role: 'NONE', message: '管理员密码错误');
  }

  AuthResult verifyGuest(String password) {
    if (password.length == 6) {
      return AuthResult(success: true, role: 'GUEST', message: '临时授权密码格式正确，继续由有效期逻辑校验');
    }
    return AuthResult(success: false, role: 'NONE', message: '临时授权失败');
  }
}
