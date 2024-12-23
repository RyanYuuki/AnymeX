import 'package:hive/hive.dart';

part 'MalToken.g.dart';


@HiveType(typeId: 2)
class ResponseToken {
  @HiveField(0)
  final String tokenType;
  @HiveField(1)
  int expiresIn;
  @HiveField(2)
  final String accessToken;
  @HiveField(3)
  final String refreshToken;

  ResponseToken({
    required this.tokenType,
    required this.expiresIn,
    required this.accessToken,
    required this.refreshToken,
  });

  factory ResponseToken.fromJson(Map<String, dynamic> json) {
    return ResponseToken(
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token_type": tokenType,
      "expires_in": expiresIn,
      "access_token": accessToken,
      "refresh_token": refreshToken,
    };
  }
}
