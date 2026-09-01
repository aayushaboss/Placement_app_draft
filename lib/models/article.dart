/// Mirrors frontend/src/mockData/mockArticles.ts `Article`.
class Article {
  final String id;
  final String tag;
  final String title;
  final String image;
  final String readTime;

  const Article({
    required this.id,
    required this.tag,
    required this.title,
    required this.image,
    required this.readTime,
  });
}
