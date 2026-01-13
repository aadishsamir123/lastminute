import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubCommit {
  const GithubCommit({
    required this.message,
    required this.author,
    required this.date,
    required this.shortSha,
    required this.url,
  });

  final String message;
  final String author;
  final DateTime date;
  final String shortSha;
  final String url;
}

class GithubService {
  GithubService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _commitsUri = Uri.https(
    'api.github.com',
    '/repos/aadishsamir123/lastminute/commits',
    {'per_page': '1'},
  );

  final http.Client _client;

  Future<GithubCommit> fetchLatestCommit() async {
    try {
      final response = await _client.get(
        _commitsUri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('GitHub returned ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('No commits found');
      }

      final Map<String, dynamic> commit = data.first as Map<String, dynamic>;
      final Map<String, dynamic> commitInfo =
          commit['commit'] as Map<String, dynamic>;
      final Map<String, dynamic> authorInfo =
          commitInfo['author'] as Map<String, dynamic>;

      return GithubCommit(
        message: (commitInfo['message'] as String).split('\n').first,
        author: authorInfo['name'] as String? ?? 'Unknown',
        date: DateTime.parse(authorInfo['date'] as String),
        shortSha: (commit['sha'] as String).substring(0, 7),
        url: commit['html_url'] as String,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR fetching GitHub commit: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
