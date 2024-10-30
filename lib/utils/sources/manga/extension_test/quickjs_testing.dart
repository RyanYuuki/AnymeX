import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';

const jsFetchMangaSearchResults = '''
async function fetchMangaSearchResults() {
  try {
    const url = 'https://mangakakalot.com/search/story/solo';
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to load manga search results');
    
    const html = await response.text();
    const mangaList = [];
    
    // Find all story items using regex
    const storyItemRegex = /<div class="story_item">([\s\S]*?)<\/div>\s*<\/div>/g;
    const storyMatches = html.matchAll(storyItemRegex);
    
    for (const match of storyMatches) {
      const storyHtml = match[0];
      
      // Extract title and link
      const titleMatch = storyHtml.match(/<a[^>]*class="story_name"[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/);
      const link = titleMatch ? titleMatch[1] : '';
      const title = titleMatch ? titleMatch[2].replace(/<[^>]*>/g, '').trim() : '';
      
      // Extract image
      const imageMatch = storyHtml.match(/<img[^>]*src="([^"]*)"[^>]*>/);
      const image = imageMatch ? imageMatch[1] : '';
      
      // Extract spans information
      const spanRegex = /<span[^>]*>(.*?)<\/span>/g;
      const spans = [...storyHtml.matchAll(spanRegex)].map(m => m[1]);
      
      const author = spans[0] ? spans[0].replace('Author(s) : ', '').trim() : '';
      const updated = spans[1] ? spans[1].replace('Updated : ', '').trim() : '';
      const views = spans[2] ? spans[2].replace('View : ', '').trim() : '';
      
      if (title && link) {
        mangaList.push({
          id: link.split('/')[3] || '',
          title: title,
          link: link,
          image: image,
          author: author,
          updated: updated,
          views: views
        });
      }
    }
    
    return JSON.stringify(mangaList);
  } catch (error) {
    console.log('Error:', error);
    return JSON.stringify([]);
  }
}''';

class MangaSearchPage extends StatefulWidget {
  const MangaSearchPage({super.key});

  @override
  _MangaSearchPageState createState() => _MangaSearchPageState();
}

class _MangaSearchPageState extends State<MangaSearchPage> {
  late final JavascriptRuntime runtime;
  String searchResult = 'No results';

  @override
  void initState() {
    super.initState();
    runtime = getJavascriptRuntime(forceJavascriptCoreOnAndroid: true);
    runtime.evaluate(jsFetchMangaSearchResults);
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }

  Future<void> fetchMangaSearch(String query) async {
    try {
      const jsCode = 'fetchMangaSearchResults()';
      final result = await runtime.evaluateAsync(jsCode);

      setState(() {
        searchResult = result.stringResult ?? 'No results found';
      });
    } catch (e) {
      setState(() {
        searchResult = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manga Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onSubmitted: (query) => fetchMangaSearch(query),
              decoration: const InputDecoration(
                labelText: 'Enter manga title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(searchResult),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
