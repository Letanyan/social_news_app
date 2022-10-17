class User {
  final int ID;
  final String Name;
  final String Email;
  final String Password;
  final DateTime RegisterDate;
  final double Upvotes;
  final double Downvotes;
  final int Credits;
  final int ValidationKey;

  const User({
    required this.ID,
    required this.Name,
    required this.Email,
    required this.Password,
    required this.RegisterDate,
    required this.Upvotes,
    required this.Downvotes,
    required this.Credits,
    required this.ValidationKey,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      ID: json["ID"],
      Name: json["Name"],
      Email: json["Email"],
      Password: json["Password"],
      RegisterDate: DateTime.parse(json["RegisterDate"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
      Credits: json["Credits"],
      ValidationKey: json["ValidationKey"],
    );
  }

  static User? current;
}

class Author {
  final int ID;
  final String Name;
  final DateTime RegisterDate;
  final double Upvotes;
  final double Downvotes;

  const Author({
    required this.ID,
    required this.Name,
    required this.RegisterDate,
    required this.Upvotes,
    required this.Downvotes,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      ID: json["ID"],
      Name: json["Name"],
      RegisterDate: DateTime.parse(json["RegisterDate"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
    );
  }
}
