import 'package:flutter/material.dart';
import 'models/npc.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.black,
          surface: Colors.black,
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<NPC> npcsInRoom = [
    NPC(
      name: 'Min-Su',
      portraitPath: 'assets/images/125.png',
      playerNumber: 125,
      dialogueOptions: [
        'I\'m just trying to survive like everyone else.',
        'These VIPs... they\'re watching our every move.',
        'Have you noticed something strange about the masked men?',
        'Maybe we can help each other make it through this.',
      ],
    ),
    NPC(
      name: 'Park Jung-Bae',
      portraitPath: 'assets/images/390.png',
      playerNumber: 390,
      dialogueOptions: [
        'I\'ve got nothing left to lose.',
        'Trust? In these games? Don\'t make me laugh.',
        'The prize money will be worth all this suffering.',
        'Everyone here is just a stepping stone to victory.',
      ],
      relationship: -0.3,
    ),
    NPC(
      name: 'Seong Gi-hun',
      portraitPath: 'assets/images/456.png',
      playerNumber: 456,
      dialogueOptions: [
        'I came back to end these games once and for all.',
        'Don\'t play by their rules - we can fight back!',
        'I won last time, but at what cost...',
        'The Front Man must be stopped.',
      ],
      relationship: 0.2,
    ),
  ];

  void _handleNPCInteraction(NPC npc) {
    setState(() {
      // Randomly affect relationship based on interaction
      double changeAmount = (Random().nextDouble() * 0.3) * (Random().nextBool() ? 1 : -1);
      npc.relationship = (npc.relationship + changeAmount).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        itemCount: npcsInRoom.length,
        itemBuilder: (context, index) {
          final npc = npcsInRoom[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(npc.portraitPath),
                radius: 25,
              ),
              title: Text(
                '#${npc.playerNumber} - ${npc.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                npc.dialogueOptions[Random().nextInt(npc.dialogueOptions.length)],
                style: TextStyle(
                  color: _getRelationshipColor(npc.relationship),
                ),
              ),
              onTap: () => _handleNPCInteraction(npc),
            ),
          );
        },
      ),
    );
  }

  Color _getRelationshipColor(double relationship) {
    if (relationship > 0.3) return Colors.green;
    if (relationship < -0.3) return Colors.red;
    return Colors.grey;
  }
}
