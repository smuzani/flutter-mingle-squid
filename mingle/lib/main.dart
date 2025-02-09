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
        colorScheme: ColorScheme.light(
          primary: Colors.pink.shade300,
          surface: Colors.pink.shade100,
          background: Colors.pink.shade50,
        ),
        scaffoldBackgroundColor: Colors.pink.shade50,
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
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
    NPC(
      name: 'Lee Yeon-joo',
      portraitPath: 'assets/images/288.jpeg',
      playerNumber: 288,
      dialogueOptions: [
        'We need to be smart about this.',
        'The VIPs are watching our every move.',
        'I\'ve figured out a pattern to these games.',
        'Choose your allies carefully in here.',
      ],
      relationship: 0.1,
    ),
    NPC(
      name: 'Choi Sang-woo',
      portraitPath: 'assets/images/218.jpg',
      playerNumber: 218,
      dialogueOptions: [
        'Sometimes you have to make hard choices.',
        'Don\'t let emotions cloud your judgment.',
        'There can only be one winner.',
        'Trust is a luxury we can\'t afford.',
      ],
      relationship: -0.2,
    ),
    NPC(
      name: 'Kang Sae-byeok',
      portraitPath: 'assets/images/067.jpg',
      playerNumber: 067,
      dialogueOptions: [
        'Stay alert. Watch everyone.',
        'I work better alone.',
        'These alliances won\'t last.',
        'Keep your distance if you want to survive.',
      ],
      relationship: 0.0,
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
  List<String> _debugMessages = [];

  // Update animation controller duration and behavior
  late AnimationController _spinController;
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  
  // Add this property
  bool showDebugInfo = false;

  // Add flash animation controller
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;

  // Add list of audio players for gunfire
  final List<AudioPlayer> _gunfirePlayers = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer.setAsset('assets/audio/carousel.mp3');
    
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scrollController = ScrollController();

    // Initialize flash animation
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _flashAnimation = ColorTween(
      begin: Colors.purple.withOpacity(0.1),
      end: Colors.pink.withOpacity(0.3),
    ).animate(_flashController);
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_scrollController.hasClients) {
        double newPosition = _scrollController.offset + 5;
        if (newPosition > _scrollController.position.maxScrollExtent) {
          newPosition = 0;
        }
        _scrollController.jumpTo(newPosition);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _updateDebugInfo(List<String> newMessages) {
    setState(() {
      _debugMessages = newMessages;
    });
  }

  void _handleNPCInteraction(NPC npc) {
    setState(() {
      List<String> debugInfo = [];
      if (isGrouping) {
        if (playerRoom != null) {
          if (rooms[playerRoom]!.length < requiredGroupSize) {
            invitations[npc] = playerRoom!;
            debugInfo.add('Invited ${npc.name} to Room $playerRoom');
          } else {
            debugInfo.add('Room $playerRoom is full');
          }
        } else if (invitations.containsKey(npc)) {
          playerRoom = invitations[npc];
          rooms.putIfAbsent(playerRoom!, () => []).add(npc);
          invitations.remove(npc);
          debugInfo.add('Accepted invitation to Room $playerRoom');
        }
      }
      
      double changeAmount = (Random().nextDouble() * 0.5) * (Random().nextBool() ? 1 : -1);
      npc.relationship = (npc.relationship + changeAmount).clamp(-1.0, 1.0);
      _updateDebugInfo(debugInfo);
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
      timeRemaining = 15;
      rooms.clear();
      playerRoom = null;
      _updateDebugInfo(['Starting new round...']);
    });

    _startAutoScroll();  // Start auto-scrolling
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();

    int spinDuration = Random().nextInt(21) + 10;

    Future.delayed(Duration(seconds: spinDuration), () {
      if (mounted) {
        _stopAutoScroll();  // Stop auto-scrolling
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

  void _playGunfire() {
    final player = AudioPlayer();
    _gunfirePlayers.add(player);
    player.setAsset('assets/audio/gunfire.mp3').then((_) {
      player.play().then((_) {
        _gunfirePlayers.remove(player);
        player.dispose();
      });
    });
  }

  void _checkElimination() {
    setState(() {
      List<String> debugInfo = [];
      List<Future> eliminationDelays = [];
      int eliminationCount = 0;
      
      // Check player elimination
      if (playerRoom == null) {
        isPlayerEliminated = true;
        debugInfo.add('Player eliminated: No room');
        eliminationCount++;
      } else {
        int totalInRoom = (rooms[playerRoom]?.length ?? 0) + 1;
        debugInfo.add('Player room $playerRoom has $totalInRoom people (need $requiredGroupSize)');
        if (totalInRoom != requiredGroupSize) {
          isPlayerEliminated = true;
          playerRoom = null;
          debugInfo.add('Player eliminated: Wrong group size');
          eliminationCount++;
        }
      }

      // Check NPC elimination
      for (var npc in npcsInRoom) {
        if (npc.isEliminated) {
          debugInfo.add('${npc.name} already eliminated');
          continue;
        }
        
        bool isInValidRoom = false;
        for (var entry in rooms.entries) {
          if (entry.value.contains(npc)) {
            int totalInRoom = entry.value.length + (playerRoom == entry.key ? 1 : 0);
            debugInfo.add('${npc.name} in room ${entry.key} with $totalInRoom people');
            if (totalInRoom == requiredGroupSize) {
              isInValidRoom = true;
              break;
            }
          }
        }
        
        if (!isInValidRoom) {
          npc.isEliminated = true;
          debugInfo.add('${npc.name} eliminated!');
          eliminationCount++;
        }
      }

      // Play gunfire sounds with slight delays
      for (int i = 0; i < eliminationCount; i++) {
        Future.delayed(Duration(milliseconds: i * 200), _playGunfire);
      }

      _debugMessages = debugInfo;
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
            _updateDebugInfo(['Time remaining: $timeRemaining']);
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
      List<String> debugInfo = ['Attempting to join Room $roomNumber'];
      
      if (playerRoom != null) {
        debugInfo.add('Leaving Room $playerRoom');
        rooms[playerRoom]?.removeWhere((npc) => invitations.containsKey(npc));
        if (rooms[playerRoom]?.isEmpty ?? false) {
          rooms.remove(playerRoom);
        }
      }
      
      playerRoom = roomNumber;
      rooms.putIfAbsent(roomNumber, () => []);
      debugInfo.add('Joined Room $roomNumber');
      debugInfo.add('Room has ${rooms[roomNumber]?.length ?? 0} NPCs');
      
      _updateDebugInfo(debugInfo);
    });
  }

  // Add this method
  void _toggleDebugInfo() {
    setState(() {
      showDebugInfo = !showDebugInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(  // Change to Stack to properly layer debug info
        children: [
          ColorFiltered(
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
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: 50,
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
                              color: Colors.pink.shade100.withOpacity(0.9),
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
                                    color: npc.isEliminated ? Colors.red : Colors.black,
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
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ELIMINATED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isPlayerEliminated = false;
                                  // Reset all NPCs
                                  for (var npc in npcsInRoom) {
                                    npc.isEliminated = false;
                                  }
                                  // Clear rooms and invitations
                                  rooms.clear();
                                  invitations.clear();
                                  playerRoom = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: const Text(
                                'Play Again',
                                style: TextStyle(fontSize: 20, color: Colors.red),
                              ),
                            ),
                          ],
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
          
          // Debug info overlay - now with visibility toggle
          if (showDebugInfo)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 200),
              color: Colors.black.withOpacity(0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Debug Info:',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_debugMessages.map((msg) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      msg,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ))),
                ],
              ),
            ),

          // Add flashing overlay during grouping
          if (isGrouping && !isPlayerEliminated)
            IgnorePointer(  // Add this wrapper
              child: AnimatedBuilder(
                animation: _flashAnimation,
                builder: (context, child) => Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      colors: [
                        _flashAnimation.value ?? Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                      radius: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all gunfire players
    for (var player in _gunfirePlayers) {
      player.dispose();
    }
    _flashController.dispose();
    _spinController.dispose();
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
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

