// widgets/responsive_scaffold.dart
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget? mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  
  const ResponsiveScaffold({
    super.key,
    this.mobileBody,
    this.tabletBody,
    this.desktopBody,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: ResponsiveBreakpoints.of(context).isMobile
          ? mobileBody ?? const SizedBox()
          : ResponsiveBreakpoints.of(context).isTablet
              ? tabletBody ?? mobileBody ?? const SizedBox()
              : desktopBody ?? tabletBody ?? mobileBody ?? const SizedBox(),
      floatingActionButton: floatingActionButton,
    );
  }
}