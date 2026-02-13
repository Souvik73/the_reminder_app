import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(
  BuildContext context, {
  required String url,
  String? failureMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.tryParse(url);
  if (uri == null) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Invalid link configuration.')),
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && messenger != null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failureMessage ?? 'Unable to open link right now. Please try again.',
        ),
      ),
    );
  }
}
