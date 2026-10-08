/// Where a saved link opens (E2, Plan decision 61).
enum LinkService { youtube, youtubeMusic, spotify }

/// The service for [uri], or null when Navmaas doesn't take links from it.
LinkService? serviceOf(Uri uri) {
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  return switch (uri.host.toLowerCase()) {
    'music.youtube.com' => .youtubeMusic,
    'youtube.com' ||
    'www.youtube.com' ||
    'm.youtube.com' ||
    'youtu.be' => .youtube,
    'open.spotify.com' || 'spotify.link' => .spotify,
    _ => null,
  };
}

/// The link she pasted, as an `https` address, or null when it isn't a
/// YouTube, YouTube Music or Spotify link. `https://` is added when missing.
Uri? parseMediaLink(String text) {
  final t = text.trim();
  if (t.isEmpty || t.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(t.contains('://') ? t : 'https://$t');
  if (uri == null || serviceOf(uri) == null) return null;
  return uri.replace(scheme: 'https');
}
