import 'package:flutter/material.dart';
import 'package:campus_connect/config/theme.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Function(int)? onTap;
  final bool isScrollable;
  final double indicatorWeight;
  final EdgeInsetsGeometry padding;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  const CustomTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.isScrollable = false,
    this.indicatorWeight = 3.0,
    this.padding = EdgeInsets.zero,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: isScrollable,
        indicatorWeight: indicatorWeight,
        padding: padding,
        indicatorColor: indicatorColor ?? AppTheme.primaryColor,
        labelColor: labelColor ?? AppTheme.primaryColor,
        unselectedLabelColor:
            unselectedLabelColor ?? AppTheme.textSecondaryColor,
        labelStyle:
            labelStyle ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            unselectedLabelStyle ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: indicatorColor ?? AppTheme.primaryColor,
              width: indicatorWeight,
            ),
          ),
        ),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
