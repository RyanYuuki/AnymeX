import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class StreamTape {
  final String serverName = "StreamTape";
  final List<Map<String, dynamic>> sources = [];

  Future<List<Map<String, dynamic>>> extract(Uri videoUrl) async {
    try {
      // Send the HTTP GET request to the video URL
      final response = await http.get(videoUrl);

      // Check if the request was successful
      if (response.statusCode != 200) {
        throw Exception("Video not found");
      }

      // Parse the HTML content
      Document document = parser.parse(response.body);

      // Use a regex to match the 'robotlink' and extract the parts
      RegExp regExp = RegExp(r"robotlink'\).innerHTML = (.*)\+ \('(.+)'\);");
      Match? match = regExp.firstMatch(document.outerHtml);

      if (match != null) {
        // Extract the matched values
        String fh = match.group(1)!.replaceAll("'", "");
        String sh = match.group(2)!.substring(3);

        // Construct the final URL
        String url = "https:$fh$sh";

        // Add the source to the list
        sources.add({
          'url': url,
          'isM3U8': url.contains(".m3u8"),
        });

        return sources;
      } else {
        throw Exception("Failed to extract video URL");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
