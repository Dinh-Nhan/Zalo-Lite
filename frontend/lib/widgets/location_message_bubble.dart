import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/views/chat/location_map_screen.dart';

class LocationMessageBubble extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final bool isMine;
  final String senderName;

  const LocationMessageBubble({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.isMine,
    required this.senderName,
  });

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Xem vị trí',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            const Divider(height: 1),

            // Option 1: Xem trong app
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0068FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map,
                  color: Color(0xFF0068FF),
                  size: 22,
                ),
              ),
              title: const Text(
                'Xem trong Zalo Lite',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Mở bản đồ ngay trong ứng dụng',
                style: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationMapScreen(
                      latitude: latitude,
                      longitude: longitude,
                      address: address,
                      senderName: senderName,
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Option 2: Mở app ngoài (google map)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_new,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              title: const Text(
                'Mở trong Google Maps',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Chuyển sang ứng dụng bản đồ',
                style: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
              ),
              onTap: () {
                Navigator.pop(context);
                _openExternalMap();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalMap() async {
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    } else if (Platform.isIOS) {
      final googleMaps = Uri.parse('comgooglemaps://?q=$latitude,$longitude');
      if (await canLaunchUrl(googleMaps)) {
        await launchUrl(googleMaps, mode: LaunchMode.externalApplication);
        return;
      }
      uri = Uri.parse('maps://?q=$latitude,$longitude');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? const Color(0xFF0068FF) : Colors.white;
    final titleColor = isMine ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isMine ? Colors.white70 : const Color(0xFF65676B);
    final coordText =
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

    return GestureDetector(
      onTap: () => _showLocationOptions(context),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map thumbnail ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://staticmap.openstreetmap.de/staticmap.php'
                    '?center=$latitude,$longitude'
                    '&zoom=15&size=220x120'
                    '&markers=$latitude,$longitude,red-marker',
                    width: 220,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 220,
                      height: 120,
                      color: const Color(0xFFE8F0FE),
                      child: const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Color(0xFF0068FF),
                      ),
                    ),
                  ),
                  // Pin icon overlay
                  const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 36,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ],
              ),
            ),

            // ── Info row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí hiện tại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address != null && address!.isNotEmpty
                              ? address!
                              : coordText,
                          style: TextStyle(fontSize: 11, color: subColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}