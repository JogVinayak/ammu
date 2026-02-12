import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

Widget buildNoteImage(Uri uri, String? title, String? alt, WidgetRef ref) {
  final path = uri.toString();

  // Only handle our note image URLs
  if (!path.contains('/notes/') || !path.contains('/images/')) {
    return const SizedBox.shrink();
  }

  final prefs = ref.read(sharedPreferencesProvider);
  final serverAddress = prefs.getString(StorageKeys.serverIp);
  final baseUrl = ApiConstants.baseUrl(serverAddress);
  final fullUrl = '$baseUrl$path';

  final accessToken = prefs.getString(StorageKeys.accessToken);
  final tenantId = prefs.getString(StorageKeys.tenantId);

  final headers = <String, String>{};
  if (accessToken != null && accessToken.isNotEmpty) {
    headers['Authorization'] = 'Bearer $accessToken';
  }
  if (tenantId != null && tenantId.isNotEmpty) {
    headers['X-Tenant-Id'] = tenantId;
  }
  if (baseUrl.contains('ngrok')) {
    headers['ngrok-skip-browser-warning'] = 'true';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        fullUrl,
        headers: headers,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 32, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Failed to load image',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
