/// Inserts a Cloudinary delivery transformation into a stored asset URL.
///
/// Cloudinary leaves the raw `secure_url` completely untouched — including
/// EXIF orientation — unless the request goes through some transformation;
/// only then does it auto-rotate per EXIF and strip the tag. Flutter's own
/// image decoder doesn't correct for EXIF orientation on its own, so a
/// photo taken in portrait (common on phone cameras) can render sideways
/// or upside down. `f_auto,q_auto` (auto format/quality — good practice
/// for delivery anyway) has the documented side effect of fixing this, and
/// works retroactively on already-uploaded assets since Cloudinary
/// transforms on the fly, no re-upload needed.
String cloudinaryDeliveryUrl(String url, {String transform = 'f_auto,q_auto'}) {
  const marker = '/upload/';
  final index = url.indexOf(marker);
  if (index == -1) return url; // not a Cloudinary delivery URL — leave as-is
  final insertAt = index + marker.length;
  return '${url.substring(0, insertAt)}$transform/${url.substring(insertAt)}';
}
