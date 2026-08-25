import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// 現在地の取得。権限確認・要求も含めて行う。
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const LocationServiceDisabledException();
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionDeniedException();
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
});

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() => '位置情報の利用が許可されていません。';
}
