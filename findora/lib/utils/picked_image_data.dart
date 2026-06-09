import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageData {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const PickedImageData({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';

  ImageProvider get imageProvider => MemoryImage(bytes);

  static Future<PickedImageData> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();

    return PickedImageData(
      name: file.name,
      mimeType: file.mimeType ?? _mimeTypeFromName(file.name),
      bytes: bytes,
    );
  }

  static String _mimeTypeFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

ImageProvider? imageProviderFromStoredValue(String value) {
  if (value.startsWith('data:image/')) {
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) return null;

    try {
      return MemoryImage(base64Decode(value.substring(commaIndex + 1)));
    } catch (_) {
      return null;
    }
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  return null;
}
