import 'package:flutter/material.dart';

void main() {
  runApp(const TabBarDemo());
}

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noobie',
      theme: ThemeData(fontFamily: 'Raleway'),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noobie')),
      body: const Center(
        child: Text(
          'Hello, Testing for an application is here!!',
          style: TextStyle(fontFamily: 'RobotoMono'),
        ),
      ),
    );
  }
}
