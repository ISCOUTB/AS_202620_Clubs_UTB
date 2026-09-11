import 'package:flutter/material.dart';
import 'clubs_page.dart';

void main() {
  runApp(const LinkClubApp());
}

class LinkClubApp extends StatelessWidget {
  const LinkClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkClub',
      home: const ClubsPage(),
    );
  }
}
