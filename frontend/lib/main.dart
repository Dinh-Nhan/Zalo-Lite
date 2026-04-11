import 'package:flutter/material.dart';
import 'apps/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final router = createdRouter();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router
      );
  }
}
