// User model
class User {
  final String userId;
  final String name;
  final String username;
  final String? profilePicture;
  final String email;

  User({
    required this.userId,
    required this.name,
    required this.username,
    this.profilePicture,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      username: json['username'],
      profilePicture: json['profilePicture'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'username': username,
      'profilePicture': profilePicture,
      'email': email,
    };
  }
}
