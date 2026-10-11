import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  const UrlLauncherService();

  Future<void> launchWebUrl(String? url) async {
    if (url == null) {
      throw const ClientException(message: 'File Url is Invalid');
    }

    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) {
      throw ClientException(message: 'Could not launch $url');
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
