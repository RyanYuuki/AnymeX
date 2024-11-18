import 'package:aurora/pages/Mobile/home_page.dart';
import 'package:aurora/utils/dimensions.dart';
import 'package:flutter/material.dart';

class ResponsiveDirecctorHome extends StatefulWidget {
  const ResponsiveDirecctorHome({super.key});

  @override
  State<ResponsiveDirecctorHome> createState() => _ResponsiveDirecctorHomeState();
}

class _ResponsiveDirecctorHomeState extends State<ResponsiveDirecctorHome> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final deviceWidth = constraints.maxWidth;
      if (deviceWidth < maxMobileWidth) {
        return const HomePage();
      } else {
        return const Placeholder();
      }
    });
  }
}
