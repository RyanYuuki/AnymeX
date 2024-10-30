const String jsFetchMangaSearchResults = """
async function fetchMangaSearchResults(query) {
  const formattedQuery = query.replace(/ /g, '_');
  const url = `https://mangakakalot.com/search/story/solo`;

  const response = await fetch(url);
  if (!response.ok) throw new Error('Failed to load manga search results');

  const html = await response.text();
  const parser = new DOMParser();
  const document = parser.parseFromString(html, 'text/html');
  
  const mangaList = [];
  document.querySelectorAll('.story_item').forEach((element) => {
    const titleElement = element.querySelector('.story_name > a');
    const title = titleElement ? titleElement.textContent.trim() : '';
    const link = titleElement ? titleElement.href : '';
    const image = element.querySelector('img') ? element.querySelector('img').src : '';

    const spans = element.querySelectorAll('span');
    const author = spans[0].textContent.replace('Author(s) : ', '').trim();
    const updated = spans[1].textContent.replace('Updated : ', '').trim();
    const views = spans[2].textContent.replace('View : ', '').trim();

    mangaList.push({
      id: link.split('/')[3],
      title: title,
      link: link,
      image: image,
      author: author,
      updated: updated,
      views: views
    });
  });

  return JSON.stringify(mangaList);
}
""";
