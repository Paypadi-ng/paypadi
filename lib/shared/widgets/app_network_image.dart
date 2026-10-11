import 'package:flutter/material.dart';
import 'package:paypadi/app/theme.dart';

/// A photo from a URL, clipped to [borderRadius] (or a circle).
///
/// Shows a neutral tile while loading and when the photo can't be loaded,
/// instead of leaving an empty shape and logging an error.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    required this.size,
    super.key,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double size;

  /// Null makes the image a circle.
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox.square(
      dimension: size,
      child: ColoredBox(color: context.palette.disabled),
    );
    final image = Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );

    return borderRadius == null
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
