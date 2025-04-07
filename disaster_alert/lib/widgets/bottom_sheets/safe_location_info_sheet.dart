import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeLocationInfoSheet extends StatelessWidget {
  final SafeLocationModel safeLocation;

  const SafeLocationInfoSheet({
    Key? key,
    required this.safeLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.safeZone,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SAFE ZONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  safeLocation.type ?? 'Safe Location',
                  style: AppTextStyles.headline3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            safeLocation.description ??
                'This location has been designated as a safe zone for the current emergency.',
            style: AppTextStyles.body1,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Open map with directions to the safe location
                  final latitude = safeLocation.latitude;
                  final longitude = safeLocation.longitude;
                  final url =
                      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
                  final uri = Uri.parse(url);

                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open maps application'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening maps: ${e.toString()}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('GET DIRECTIONS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
