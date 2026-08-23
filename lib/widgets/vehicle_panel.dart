import 'package:flutter/material.dart';

class VehiclePanel extends StatelessWidget {
  final String imageAsset;
  final double height;

  const VehiclePanel({
    super.key,
    this.imageAsset = 'assets/home_car_bg.jpg',
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 1,
            color: Color(0x551595FF),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(imageAsset),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
