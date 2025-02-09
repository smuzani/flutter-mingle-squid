import 'package:flutter/material.dart';
import 'models/npc.dart';
import 'dart:math';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

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

  bool isSpinning = false;
  bool isGrouping = false;
  int requiredGroupSize = 0;
  int timeRemaining = 30;
  Timer? gameTimer;
  Map<int, List<NPC>> rooms = {}; // room number -> list of NPCs
  Map<NPC, int> invitations = {}; // NPC -> room number they're inviting to
  int? playerRoom;
  bool isPlayerEliminated = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Load the audio file
    _audioPlayer.setAsset('assets/audio/carousel.mp3');
  }

  void _handleNPCInteraction(NPC npc) {
    setState(() {
      if (isGrouping) {
        if (playerRoom != null) {
          // Invite NPC to our room
          if (rooms[playerRoom]!.length < requiredGroupSize) {
            invitations[npc] = playerRoom!;
          }
        } else if (invitations.containsKey(npc)) {
          // Accept their invitation
          playerRoom = invitations[npc];
          rooms.putIfAbsent(playerRoom!, () => []).add(npc);
          invitations.remove(npc);
        }
      }
      
      double changeAmount = (Random().nextDouble() * 0.5) * (Random().nextBool() ? 1 : -1);
      npc.relationship = (npc.relationship + changeAmount).clamp(-1.0, 1.0);
    });
  }

  void _updateNPCBehavior() {
    if (!isGrouping || timeRemaining > 10) return;
    
    setState(() {
      for (var npc in npcsInRoom) {
        if (npc.isEliminated) continue;  // Skip eliminated NPCs
        
        // Accept invitation if not in a room
        if (invitations.containsKey(npc) && !rooms.values.any((room) => room.contains(npc))) {
          int roomNumber = invitations[npc]!;
          rooms.putIfAbsent(roomNumber, () => []).add(npc);
          invitations.remove(npc);
          continue;
        }

        // Check if NPC needs to move
        bool needsNewRoom = true;
        for (var entry in rooms.entries) {
          if (entry.value.contains(npc)) {
            int totalInRoom = entry.value.length + (playerRoom == entry.key ? 1 : 0);
            if (totalInRoom == requiredGroupSize) {
              needsNewRoom = false;  // Stay in current room if it has correct size
              break;
            }
            // Leave room if size is wrong
            entry.value.remove(npc);
            if (entry.value.isEmpty) {
              rooms.remove(entry.key);
            }
            break;
          }
        }

        // Find new room if needed
        if (needsNewRoom) {
          for (var entry in rooms.entries) {
            int totalInRoom = entry.value.length + (playerRoom == entry.key ? 1 : 0);
            if (totalInRoom == requiredGroupSize - 1) {
              entry.value.add(npc);
              needsNewRoom = false;
              break;
            }
          }
          
          // Create new room if couldn't find suitable one
          if (needsNewRoom) {
            int newRoom = (rooms.keys.isEmpty ? 0 : rooms.keys.reduce(max) + 1);
            rooms[newRoom] = [npc];
          }
        }
      }
    });
  }

  void startMingleRound() {
    if (isPlayerEliminated) return;
    
    setState(() {
      isSpinning = true;
      isGrouping = false;
      timeRemaining = 30;
      rooms.clear();
      playerRoom = null;
    });

    // Play music during spinning
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Stop music when timer starts
        _audioPlayer.stop();
        
        setState(() {
          isSpinning = false;
          isGrouping = true;
          requiredGroupSize = Random().nextInt(3) + 2;
          startTimer();
        });
      }
    });
  }

  void _checkElimination() {
    if (!isGrouping || timeRemaining > 0) return;
    
    setState(() {
      // Check player elimination
      if (playerRoom == null) {
        isPlayerEliminated = true;
      } else {
        int totalInRoom = (rooms[playerRoom]?.length ?? 0) + 1;
        if (totalInRoom != requiredGroupSize) {
          isPlayerEliminated = true;
          // Remove player from room count
          playerRoom = null;
        }
      }

      // Check NPC elimination
      for (var npc in npcsInRoom) {
        if (npc.isEliminated) continue;  // Skip already eliminated NPCs
        
        bool isInValidRoom = false;
        for (var entry in rooms.entries) {
          if (entry.value.contains(npc)) {
            int totalInRoom = entry.value.length + (playerRoom == entry.key ? 1 : 0);
            if (totalInRoom == requiredGroupSize) {
              isInValidRoom = true;
              break;
            }
          }
        }
        
        if (!isInValidRoom) {
          npc.isEliminated = true;
          print('${npc.name} eliminated!'); // Debug print
        }
      }

      // Clear rooms and invitations for next round
      rooms.clear();
      invitations.clear();
    });
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeRemaining > 0) {
            timeRemaining--;
            _updateNPCBehavior();
          } else {
            timer.cancel();
            isGrouping = false;
            _checkElimination();
          }
        });
      }
    });
  }

  void _joinRoom(int roomNumber) {
    if (!isGrouping || isPlayerEliminated) return;
    
    setState(() {
      // Leave current room if in one
      if (playerRoom != null) {
        rooms[playerRoom]?.removeWhere((npc) => invitations.containsKey(npc));
        if (rooms[playerRoom]?.isEmpty ?? false) {
          rooms.remove(playerRoom);
        }
      }
      
      playerRoom = roomNumber;
      rooms.putIfAbsent(roomNumber, () => []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColorFiltered(
        colorFilter: isPlayerEliminated
            ? const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.matrix([
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 1, 0,
              ]),
        child: AbsorbPointer(
          absorbing: isPlayerEliminated,
          child: Stack(
            children: [
              // Carousel-like background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    colors: [
                      Color(0xFFFAE3D9), // Light pink
                      Color(0xFFFFB6B6), // Darker pink
                    ],
                    radius: 1.2,
                  ),
                ),
                child: CustomPaint(
                  painter: CarouselPainter(),
                  child: Container(),
                ),
              ),
              
              // Game content
              Column(
                children: [
                  // Game status
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 50),
                    color: Colors.black87,
                    child: Column(
                      children: [
                        if (isSpinning)
                          const Text('🎠 Platform Spinning...', 
                            style: TextStyle(color: Colors.white, fontSize: 24)),
                        if (isGrouping)
                          Text(
                            '⚠️ Form groups of $requiredGroupSize! Time: $timeRemaining',
                            style: TextStyle(
                              color: timeRemaining < 10 ? Colors.red : Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Colored doors around the edge
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final colors = [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                        ];
                        
                        bool isPlayerInThisRoom = playerRoom == index;
                        int peopleInRoom = (rooms[index]?.length ?? 0) + (isPlayerInThisRoom ? 1 : 0);
                        
                        return GestureDetector(
                          onTap: () => _joinRoom(index),
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPlayerInThisRoom ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isGrouping ? Center(
                              child: Text(
                                '$peopleInRoom',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ) : null,
                          ),
                        );
                      },
                    ),
                  ),

                  // NPCs list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: npcsInRoom.length,
                      itemBuilder: (context, index) {
                        final npc = npcsInRoom[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.black87,
                          child: ListTile(
                            leading: ColorFiltered(
                              colorFilter: npc.isEliminated
                                  ? const ColorFilter.matrix([
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ])
                                  : const ColorFilter.matrix([
                                      1, 0, 0, 0, 0,
                                      0, 1, 0, 0, 0,
                                      0, 0, 1, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ]),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(npc.portraitPath),
                                radius: 25,
                              ),
                            ),
                            title: Text(
                              '#${npc.playerNumber} - ${npc.name}${npc.isEliminated ? ' ☠️' : ''}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: npc.isEliminated ? Colors.red : Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  npc.dialogueOptions[Random().nextInt(npc.dialogueOptions.length)],
                                  style: TextStyle(color: _getRelationshipColor(npc.relationship)),
                                ),
                                if (isGrouping) ...[
                                  if (invitations.containsKey(npc))
                                    Text(
                                      'Inviting you to Room ${invitations[npc]}',
                                      style: const TextStyle(color: Colors.yellow),
                                    ),
                                  if (rooms.values.any((room) => room.contains(npc)))
                                    Text(
                                      'In Room ${rooms.entries.firstWhere((entry) => entry.value.contains(npc)).key}',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                ],
                              ],
                            ),
                            onTap: () => _handleNPCInteraction(npc),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Start game button
              if (!isSpinning && !isGrouping)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: startMingleRound,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text(
                        'Start Mingle Round',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

              // Elimination overlay
              if (isPlayerEliminated)
                Container(
                  color: Colors.red.withOpacity(0.5),
                  child: const Center(
                    child: Text(
                      '❌ ELIMINATED ❌',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Add player status near game status
              if (isGrouping && !isPlayerEliminated)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 120),
                  color: Colors.black87,
                  child: Text(
                    playerRoom == null 
                        ? '⚠️ You need to join a room!'
                        : '✅ You are in Room $playerRoom with ${rooms[playerRoom]?.length ?? 0} others',
                    style: TextStyle(
                      color: playerRoom == null ? Colors.red : Colors.green,
                      fontSize: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    gameTimer?.cancel();
    super.dispose();
  }

  Color _getRelationshipColor(double relationship) {
    if (relationship > 0.3) return Colors.green;
    if (relationship < -0.3) return Colors.red;
    return Colors.grey;
  }
}

// Custom painter for the carousel design
class CarouselPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw circular platform
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      paint,
    );

    // Draw decorative lines
    for (var i = 0; i < 12; i++) {
      final angle = (i * pi / 6);
      final startX = size.width / 2 + cos(angle) * (size.width * 0.2);
      final startY = size.height / 2 + sin(angle) * (size.width * 0.2);
      final endX = size.width / 2 + cos(angle) * (size.width * 0.4);
      final endY = size.height / 2 + sin(angle) * (size.width * 0.4);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
