class SearchResult {
  final String id;
  final String title;
  final String poster;
  final String rating;
  final String type;
  final String releaseYear;

  SearchResult(this.title, this.poster, this.rating, this.type,
      this.releaseYear, this.id);

  SearchResult.fromJson(Map<String, dynamic> json, this.type)
      : id = json['id'].toString(),
        title = json['name'] ?? json['title'],
        poster = "https://image.tmdb.org/t/p/w500/${json['backdrop_path']}",
        rating = json['voting_average'],
        releaseYear = json['first_air_date'] ?? json['release_date'];
}
