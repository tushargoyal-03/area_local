import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final List<double>? coordinates;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.coordinates,
    this.role = 'User',
  });

  factory AppUser.empty() => const AppUser(id: '', email: '', role: 'User');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [id, email, name, photoUrl, coordinates, role];
}
