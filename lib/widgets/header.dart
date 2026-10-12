import 'package:flutter/material.dart';

class DealHeader extends StatelessWidget {
  const DealHeader({super.key, this.showSubtitle = true});

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Center(
          child: Image.asset(
            'assets/branding/deal-logo1.png',
            width: 170,
            height: 60,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
