/// Fill these in after creating a free Cloudinary account
/// (https://cloudinary.com/users/register/free — no card required) and an
/// *unsigned* upload preset:
///   Console → Settings (gear icon) → Upload → Upload presets → Add upload
///   preset → set "Signing Mode" to "Unsigned" → Save.
///
/// Both values are meant to be public/embedded in client code, same as
/// Firebase's own config in firebase_options.dart — the preset's own
/// settings (allowed formats, max file size, folder) are what constrain an
/// unsigned upload, not secrecy of these strings.
const cloudinaryCloudName = 'dgl2xfke';
const cloudinaryUploadPreset = 'expeditioneer';

bool get isCloudinaryConfigured =>
    cloudinaryCloudName != 'YOUR_CLOUD_NAME' && cloudinaryUploadPreset != 'YOUR_UPLOAD_PRESET';
