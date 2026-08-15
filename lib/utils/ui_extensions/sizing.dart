import 'package:flutter/material.dart';


extension SizingExtensions on double {
  SizedBox get height => SizedBox(height: this);
  SizedBox get width => SizedBox(width: this);
}

extension WidgetSpacing on Widget {
  Widget bottomSpacing(double height) =>
      Padding(padding: EdgeInsets.only(bottom: height), child: this);

  Widget topSpacing(double height) =>
      Padding(padding: EdgeInsets.only(top: height), child: this);

  Widget leftSpacing(double width) =>
      Padding(padding: EdgeInsets.only(left: width), child: this);

  Widget rightSpacing(double width) =>
      Padding(padding: EdgeInsets.only(right: width), child: this);
}
