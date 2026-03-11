import 'dart:typed_data';

class AvatarUploadData {
  const AvatarUploadData({
    required this.bytes,
    this.mimeType = 'image/png',
    this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? fileName;
}
