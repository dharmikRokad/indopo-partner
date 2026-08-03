import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../theme/text_styles.dart';

class LocationService {
  LocationService._privateConstructor();
  static final LocationService instance = LocationService._privateConstructor();

  Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Location Services Disabled',
                style: TextStyles.headingSemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              content: Text(
                'Location services are disabled on your device. Please enable them to set your address using GPS.',
                style: TextStyles.bodyRegular.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Geolocator.openLocationSettings();
                  },
                  child: Text(
                    'Open Settings',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.blue1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return null;
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Permission Required',
                  style: TextStyles.headingSemiBold.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                content: Text(
                  'Location permission is required to update your coordinates. Please grant the permission.',
                  style: TextStyles.bodyRegular.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Geolocator.requestPermission();
                    },
                    child: Text(
                      'Grant',
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.blue1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Permission Permanently Denied',
                style: TextStyles.headingSemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              content: Text(
                'Location permission is permanently denied. This permission is required to set your address using GPS. Please enable it in the app settings.',
                style: TextStyles.bodyRegular.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Geolocator.openAppSettings();
                  },
                  child: Text(
                    'Open Settings',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.blue1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return null;
      }

      // 3. Get coordinates
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('[LocationService] getCurrentLocation error: $e');
      return null;
    }
  }
}
