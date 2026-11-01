class SuggestedFeed {
  final String title;
  final String url;
  final String category;

  const SuggestedFeed({
    required this.title,
    required this.url,
    required this.category,
  });
}

const suggestedFeeds = [
  SuggestedFeed(title: 'TechCrunch', url: 'https://techcrunch.com/feed/', category: 'Tech'),
  SuggestedFeed(title: 'The Verge', url: 'https://www.theverge.com/rss/index.xml', category: 'Tech'),
  SuggestedFeed(title: 'Wired', url: 'https://www.wired.com/feed/rss', category: 'Tech'),
  SuggestedFeed(title: 'BBC News', url: 'http://feeds.bbci.co.uk/news/rss.xml', category: 'News'),
  SuggestedFeed(title: 'Hacker News', url: 'https://hnrss.org/frontpage', category: 'Tech'),
  SuggestedFeed(title: 'NYT Top Stories', url: 'https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml', category: 'News'),
  SuggestedFeed(title: 'Harvard Business Review', url: 'https://hbr.org/rss/homepage.xml', category: 'Business'),
  SuggestedFeed(title: 'MIT Technology Review', url: 'https://www.technologyreview.com/feed/', category: 'Tech'),
  SuggestedFeed(title: 'Science Magazine', url: 'https://www.sciencemag.org/rss/news.xml', category: 'Science'),
  SuggestedFeed(title: 'Nature', url: 'https://www.nature.com/nature.rss', category: 'Science'),
];

const feedCategories = ['Tech', 'News', 'Business', 'Science', 'Health', 'Design', 'AI', 'Startups'];
