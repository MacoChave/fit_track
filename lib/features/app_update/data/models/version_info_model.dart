import 'dart:convert';

import '../../domain/entities/version_info.dart';

class VersionInfoModel extends VersionInfo {
  const VersionInfoModel({
    required super.version,
    required super.buildNumber,
    required super.url,
    required super.releaseNotes,
    super.appName,
  });

  factory VersionInfoModel.fromJson(String flavorString, String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifest JSON does not contain a valid root object');
    }
    final Map<String, dynamic> root = decoded;
    final dynamic flavorData = root[flavorString] ?? root['prod'] ?? (root.isNotEmpty ? root.values.first : null);

    if (flavorData == null || flavorData is! Map<String, dynamic>) {
      throw const FormatException('Manifest JSON does not contain valid flavor data');
    }

    return VersionInfoModel(
      version: flavorData['version']?.toString() ?? '',
      buildNumber: flavorData['buildNumber'] is int
          ? flavorData['buildNumber'] as int
          : int.tryParse(flavorData['buildNumber']?.toString() ?? '0') ?? 0,
      appName: flavorData['appName']?.toString(),
      url: flavorData['url']?.toString() ?? '',
      releaseNotes: (flavorData['release_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'appName': appName,
      'url': url,
      'release_notes': releaseNotes,
    };
  }
}
