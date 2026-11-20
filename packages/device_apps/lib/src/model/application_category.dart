/// A category provided by the system (Only supported with Android 26+)
/// [https://developer.android.com/reference/kotlin/android/content/pm/ApplicationInfo]
enum ApplicationCategory {
  /// Category for apps which primarily work with audio or music, such as
  /// music players.
  audio,

  /// Category for apps which are primarily games.
  game,

  /// Category for apps which primarily work with images or photos, such as
  /// camera or gallery apps.
  image,

  /// Category for apps which are primarily maps apps, such as navigation apps.
  maps,

  /// Category for apps which are primarily news apps, such as newspapers,
  /// magazines, or sports apps.
  news,

  /// Category for apps which are primarily productivity apps, such as cloud
  /// storage or workplace apps.
  productivity,

  /// Category for apps which are primarily social apps, such as messaging,
  /// communication, email, or social network apps.
  social,

  /// Category for apps which primarily work with video or movies, such as
  /// streaming video apps.
  video,

  /// Value when category is undefined.
  undefined,
}
