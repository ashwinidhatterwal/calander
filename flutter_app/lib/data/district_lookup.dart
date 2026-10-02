import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loaded only when an explicit location lookup returns no usable district.
/// Parsing and geometry tests run off the UI isolate; no GPS or network here.
Future<String?> offlineDistrict(double latitude, double longitude) async {
  final raw = await rootBundle.loadString('assets/data/district_boundaries.json');
  return compute(findDistrict, (raw, latitude, longitude));
}

bool isDivisionLabel(String label) => RegExp(
      r'(^|[\s,/-])(?:division|संभाग|मंडल|ड[िी]व[िी](?:ज़|ज)न)(?=$|[\s,/-])',
      caseSensitive: false,
    ).hasMatch(label);

String? findDistrict((String, double, double) input) {
  final (raw, latitude, longitude) = input;
  for (final row in jsonDecode(raw) as List<dynamic>) {
    final bounds = row[1] as List<dynamic>;
    if (longitude < bounds[0] || longitude > bounds[2] ||
        latitude < bounds[1] || latitude > bounds[3]) {
      continue;
    }
    for (final polygon in row[2] as List<dynamic>) {
      if (_inside(polygon[0] as List<dynamic>, latitude, longitude) &&
          !(polygon as List<dynamic>).skip(1).any(
                (hole) => _inside(hole as List<dynamic>, latitude, longitude),
              )) {
        return row[0] as String;
      }
    }
  }
  return null;
}

bool _inside(List<dynamic> ring, double latitude, double longitude) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i] as List<dynamic>;
    final b = ring[j] as List<dynamic>;
    if ((a[1] > latitude) != (b[1] > latitude) &&
        longitude < (b[0] - a[0]) * (latitude - a[1]) /
                (b[1] - a[1]) + a[0]) {
      inside = !inside;
    }
  }
  return inside;
}
