import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:hespress/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Future.delayed(const Duration(seconds: 2), () {
    runApp(const MyApp());
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hespress',
      theme: ThemeData(
        fontFamily: 'Tajawal',
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
      ),
      debugShowCheckedModeBanner: false,
      home: const NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List posts = [];
  List categories = [];
  List mostViewed = [];
  int page = 1;
  final int perPage = 10;
  bool isLoading = false;
  bool hasMore = true;
  String search = "";
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchCategories();
    _fetchMostViewed();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _fetchPosts();
      }
    });
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      posts.clear();
      hasMore = true;
    }

    if (!hasMore) return;

    setState(() => isLoading = true);

    final uri = Uri.https(BASE_URL, '/wp-json/myapp/v1/posts', {
      'page': '$page',
      'per_page': '$perPage',
      if (isSearching && search.isNotEmpty) 'search': search,
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        page++;
        posts.addAll(data);
        if (data.length < perPage) hasMore = false;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse(
        'https://$BASE_URL/wp-json/myapp/v1/categories'));
    if (response.statusCode == 200) {
      setState(() {
        categories = json.decode(response.body);
      });
    }
  }

  Future<void> _fetchMostViewed() async {
    final response = await http.get(Uri.parse(
        'https://$BASE_URL/wp-json/myapp/v1/most-viewed'));
    if (response.statusCode == 200) {
      setState(() {
        mostViewed = json.decode(response.body);
      });
    }
  }

  Color getCategoryColor(String slug) {
    switch (slug) {
      case 'إسلامي':
        return Colors.red;
      case 'tech':
        return Colors.blue;
      case 'sports':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }

  bool isRTL(String text) {
    final rtlChars = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\u08A0-\u08FF]');
    return rtlChars.hasMatch(text.trimLeft());
  }


  IconData getCategoryIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('tech')) return Icons.computer;
    if (lower.contains('رياضة') || lower.contains('sport')) return Icons.sports_soccer;
    if (lower.contains('إسلام') || lower.contains('islam')) return Icons.mosque;
    if (lower.contains('سياسة') || lower.contains('politic')) return Icons.account_balance;
    if (lower.contains('اقتصاد') || lower.contains('finance') || lower.contains('business')) return Icons.attach_money;
    if (lower.contains('صحة') || lower.contains('health')) return Icons.health_and_safety;
    if (lower.contains('فن') || lower.contains('art')) return Icons.palette;
    if (lower.contains('تعليم') || lower.contains('education')) return Icons.school;

    // par défaut
    return Icons.label;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e22b4),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 30),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  search = '';
                  posts.clear();
                  page = 1;
                  hasMore = true;
                });
                _fetchPosts(refresh: true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PostSearchDelegate(onSearch: (text) {
                  Future.microtask(() {
                    setState(() {
                      isSearching = text.isNotEmpty;
                      search = text;
                      posts.clear();
                      page = 1;
                      hasMore = true;
                    });
                    _fetchPosts(refresh: true);
                  });
                }),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 150,
              decoration: const BoxDecoration(color: Color(0xFF1e22b4)),
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Center( // ⬅️ Centrage vertical + horizontal
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // ⬅️ Centrage vertical
                    children: [
                      Image.asset('assets/logo.png', height: 40),
                      const SizedBox(height: 10),
                      const Text(
                        'Hespress.com',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الرئيسية'),
              onTap: () => Navigator.pop(context),
            ),
            ExpansionTile(
              leading: const Icon(Icons.category),
              title: const Text('التصنيفات'),
              children: categories.map((cat) {
                return ListTile(
                  leading: cat['icon_url'] != null && cat['icon_url'].toString().isNotEmpty
                      ? Image.network(cat['icon_url'], width: 24, height: 24)
                      : Icon(getCategoryIcon(cat['name'])),
                  title: Text(cat['name']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryPostsPage(
                          categoryId: cat['id'],
                          categoryName: cat['name'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),


            ExpansionTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('أكتر مقالات مشاهدة'),
              children: mostViewed.map((post) {
                return ListTile(
                  title: Text(post['title']),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPosts(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = posts[index];
            final image = post['image'];
            final title = post['title'] ?? '';
            final date = post['date'] ?? '';
            final commentCount = post['comment_count'] ?? 0;
            final categories = post['categories'];
            final catColor = (categories is List && categories.isNotEmpty)
                ? getCategoryColor(categories[0]['slug'])
                : Colors.grey;
            final categoryName = (categories is List && categories.isNotEmpty)
                ? categories[0]['name']
                : '';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(image,
                                width: double.infinity, height: 250, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    date,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "$commentCount تعليقات",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                post['title'] ?? '',
                                textDirection: isRTL(post['title'] ?? '')
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PostSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  PostSearchDelegate({required this.onSearch});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}


class CategoryPostsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryPostsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryPostsPage> createState() => _CategoryPostsPageState();
}



class _CategoryPostsPageState extends State<CategoryPostsPage> {
  List posts = [];
  bool isLoading = false;
  int page = 1;
  final int perPage = 10;
  bool hasMore = true;
  String search = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchCategoryPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchCategoryPosts();
      }
    });
  }

  Future<void> fetchCategoryPosts({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      posts.clear();
      hasMore = true;
    }

    if (!hasMore || isLoading) return;

    setState(() => isLoading = true);

    final uri = Uri.https(
      BASE_URL,
      '/wp-json/myapp/v1/posts',
      {
        'categories': widget.categoryId,
        'page': '$page',
        'per_page': '$perPage',
        if (search.isNotEmpty) 'search': search,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        posts.addAll(data);
        page++;
        if (data.length < perPage) hasMore = false;
      });
    }

    setState(() => isLoading = false);
  }

  bool isRTL(String text) {
    final rtlChars =
    RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\u08A0-\u08FF]');
    return rtlChars.hasMatch(text.trimLeft());
  }

  Color getCategoryColor(String slug) {
    switch (slug) {
      case 'إسلامي':
        return Colors.red;
      case 'tech':
        return Colors.blue;
      case 'sports':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1e22b4),
        actions: [
          if (search.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  search = '';
                  posts.clear();
                  page = 1;
                  hasMore = true;
                });
                fetchCategoryPosts(refresh: true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PostSearchDelegate(
                  onSearch: (text) {
                    Future.microtask(() {
                      setState(() {
                        search = text;
                        posts.clear();
                        page = 1;
                        hasMore = true;
                      });
                      fetchCategoryPosts(refresh: true);
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchCategoryPosts(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = posts[index];
            final image = post['image'];
            final title = post['title'] ?? '';
            final date = post['date'] ?? '';
            final commentCount = post['comment_count'] ?? 0;
            final categories = post['categories'];
            final catColor = (categories is List && categories.isNotEmpty)
                ? getCategoryColor(categories[0]['slug'])
                : Colors.grey;
            final categoryName = (categories is List && categories.isNotEmpty)
                ? categories[0]['name']
                : '';

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              image,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    date,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "$commentCount تعليقات",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                title,
                                textDirection: isRTL(title)
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class PostDetailPage extends StatelessWidget {
  final Map post;
  const PostDetailPage({super.key, required this.post});

  bool isRTL(String text) {
    final rtlChars = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\u08A0-\u08FF]');
    return rtlChars.hasMatch(text.trimLeft());
  }

  @override
  Widget build(BuildContext context) {
    final tags = post['tags'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e22b4),
        title: Text(post['title'] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(post['content'] ?? ''),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (post['image'] != null)
            Image.network(post['image']),
          const SizedBox(height: 10),
          Text(
            post['title'] ?? '',
            textDirection: isRTL(post['title'] ?? '')
                ? TextDirection.rtl
                : TextDirection.ltr,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (tags is List && tags.isNotEmpty)
            Wrap(
              spacing: 6,
              children: tags
                  .map<Widget>((tag) => Chip(label: Text(tag['name'] ?? '')))
                  .toList(),
            ),
          const SizedBox(height: 10),
          Text(
            post['content'] ?? '',
            textDirection: isRTL(post['content'] ?? '')
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
