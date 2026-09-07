class ForgotPasswordModel {
  final String email;

  const ForgotPasswordModel({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}