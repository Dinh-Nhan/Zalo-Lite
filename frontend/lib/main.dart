import 'package:flutter/material.dart';
import 'apps/router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final router = createdRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
