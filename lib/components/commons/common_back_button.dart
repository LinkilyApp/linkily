import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';

class CommonBackButton extends StatelessWidget {
  final Map<String, dynamic>? sx;

  const CommonBackButton({super.key, this.sx});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        margin: sx?['margin'] ?? EdgeInsets.zero,
        child: const Center(child: Icon(material.Icons.arrow_back, size: 20)),
      ),
    );
  }
}
