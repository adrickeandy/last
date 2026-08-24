class PollModel {
  final String id;
  final String authorId;
  final String question;
  final List<String> options;
  final String? closesAt;
  final String createdAt;
  final Map<int, int> voteResults;
  final int? myVoteIndex;

  PollModel({
    required this.id,
    required this.authorId,
    required this.question,
    required this.options,
    this.closesAt,
    required this.createdAt,
    this.voteResults = const {},
    this.myVoteIndex,
  });

  int get totalVotes => voteResults.values.fold(0, (sum, count) => sum + count);

  factory PollModel.fromJson(Map<String, dynamic> json, {Map<int, int> voteResults = const {}, int? myVoteIndex}) {
    final rawOptions = json['options'];
    List<String> optionsList = [];
    if (rawOptions is List) {
      optionsList = rawOptions.map((e) => e.toString()).toList();
    }

    return PollModel(
      id: json['id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: optionsList,
      closesAt: json['closes_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      voteResults: voteResults,
      myVoteIndex: myVoteIndex,
    );
  }

  PollModel copyWith({
    Map<int, int>? voteResults,
    int? myVoteIndex,
  }) {
    return PollModel(
      id: id,
      authorId: authorId,
      question: question,
      options: options,
      closesAt: closesAt,
      createdAt: createdAt,
      voteResults: voteResults ?? this.voteResults,
      myVoteIndex: myVoteIndex ?? this.myVoteIndex,
    );
  }
}
