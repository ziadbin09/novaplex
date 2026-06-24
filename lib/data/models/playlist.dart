import 'dart:convert';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.videoIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> videoIds;
  final DateTime createdAt;

  int get count => videoIds.length;

  Playlist copyWith({String? name, List<String>? videoIds}) => Playlist(
        id: id,
        name: name ?? this.name,
        videoIds: videoIds ?? this.videoIds,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'videoIds': videoIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        videoIds: List<String>.from(json['videoIds'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<Playlist> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<Playlist> playlists) =>
      jsonEncode(playlists.map((p) => p.toJson()).toList());
}
