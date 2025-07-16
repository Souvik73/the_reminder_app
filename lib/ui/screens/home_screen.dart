import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("The Reminder App"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          'Welcome to The Reminder App!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}