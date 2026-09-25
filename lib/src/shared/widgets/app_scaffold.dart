import 'package:flutter/material.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/src/shared/widgets/custom_appbar.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    super.key,
    this.title,
    this.appBar,
    this.bgColor,
    this.padding,
    this.showAppBar = true,
    this.makeScrollable = false,
    this.bottomNavigationBar,
    this.onRefresh,
  });

  final Widget child;
  final bool makeScrollable;
  final bool showAppBar;
  final String? title;
  final Color? bgColor;
  final EdgeInsets? padding;
  final Future<void> Function()? onRefresh;
  final PreferredSizeWidget? appBar;
  final BottomNavigationBar? bottomNavigationBar;

  bool get _canRefresh => onRefresh != null && makeScrollable;

  @override
  Widget build(BuildContext context) {
    const defaultPadding = EdgeInsets.symmetric(horizontal: Values.v16);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: showAppBar ? CustomAppbarWithTitle(title: title) : appBar,
      body: makeScrollable
          ? RefreshIndicator.adaptive(
              onRefresh: () async {
                await onRefresh?.call();
              },
              child: SingleChildScrollView(
                physics: _canRefresh
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: padding ?? defaultPadding,
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? defaultPadding,
              child: SafeArea(child: child),
            ),
    );
  }
}
