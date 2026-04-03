import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail View')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/');
          },
          child: Text('Go to Detail View'),
        ),
      ),
    );
  }
}
