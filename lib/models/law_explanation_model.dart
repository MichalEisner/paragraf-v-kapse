class LawExplanation {
  final String id;
  final String title;
  final String statuteRef;
  final String shortStatute;
  final String category;
  final String practicalMeaning;
  final String employerTrick;
  final String fullStatuteText;
  final String videoTitle;
  final String videoDuration;
  final String videoThumbnailUrl;
  final String youtubeUrl;
  final String safeClauseSuggestion;

  const LawExplanation({
    required this.id,
    required this.title,
    required this.statuteRef,
    required this.shortStatute,
    required this.category,
    required this.practicalMeaning,
    required this.employerTrick,
    required this.fullStatuteText,
    required this.videoTitle,
    required this.videoDuration,
    this.videoThumbnailUrl = '',
    this.youtubeUrl = 'https://www.youtube.com',
    this.safeClauseSuggestion = '',
  });
}
