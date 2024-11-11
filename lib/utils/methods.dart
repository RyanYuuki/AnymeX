import 'package:http/http.dart' as http;

Future<dynamic> fetch(String url) async {
  final resp = await http.get(Uri.parse(url));
  final data = resp.body;
  return data;
}
