import 'package:flutter/material.dart';

import '../constants.dart';

class Customiconbutton extends StatelessWidget{
  final Function()? onPressed;
  final Icon icon;
  bool isButtonSelected;

  Customiconbutton({super.key, required this.onPressed,required this.icon, required this.isButtonSelected });

  @override
  Widget build(BuildContext context) {
    Color color  = Theme.of(context).colorScheme.inversePrimary;
    return IconButton(
        onPressed: onPressed,
        icon: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color:
                  isButtonSelected ? color : Colors.transparent,
                  width: 5),
              color: isButtonSelected ? color : Colors.transparent),
          child: icon
          ),
        );
  }
}