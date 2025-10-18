class Usermodel {
  final String id;
  final String email;
  final String? phone;
  final String? fullName;

  Usermodel({
    required this.id,
    required this.email,
    this.phone,
    this.fullName,
  });

  factory Usermodel.fromJson(Map<String, dynamic> json) {
    return Usermodel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
    };
  }
}