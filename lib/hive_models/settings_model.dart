import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 2) //typeId should be unique for each model

class SettingsModel{

  // S E T T I N G S
  @HiveField(1)
  late bool isDarkMode = false;

  @HiveField(2)
  late String selectedSorting;

  @HiveField(3)
  late Directory root;

}