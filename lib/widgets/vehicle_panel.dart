import 'package:flutter/material.dart';

class VehiclePanel extends StatelessWidget {
  final String imageAsset;
  const VehiclePanel({super.key, this.imageAsset = 'assets/' });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover),
      ),
    );
  }
}
