class NewsItem {
  final String title;
  final String url;
  final DateTime? date;

  NewsItem({required this.title, required this.url, this.date});

  factory NewsItem.fromMangaBaka(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      date: json['published_at'] != null 
          ? DateTime.tryParse(json['published_at']) 
          : null,
    );
  }

  factory NewsItem.fromKuroiru(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? '',
      url: json['link'] ?? '',
      date: json['time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000) 
          : null,
    );
  }
}
