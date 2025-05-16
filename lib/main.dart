import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'shop_screen.dart';

void main() {
  runApp(FlappyBirdClone());
}

class FlappyBirdClone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class GlueStickPair {
  double verticalOffset; // Made mutable to allow updates
  final double gap = 280; // Increased vertical gap by 40% (was 200)
  final double width = 70; // Fixed width
  double xPosition; // Horizontal position
  bool hasScored = false; // <-- Add this flag

  GlueStickPair({required this.verticalOffset, required this.xPosition});

  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top glue stick
        Positioned(
          top: 0,
          left: xPosition,
          child: Image.asset(
            'assets/images/glue_stick_top.png',
            width: width,
            height: MediaQuery.of(context).size.height / 2 + verticalOffset - gap / 2,
            fit: BoxFit.fill,
          ),
        ),
        // Bottom glue stick
        Positioned(
          bottom: 0,
          left: xPosition,
          child: Image.asset(
            'assets/images/glue_stick_bottom.png',
            width: width,
            height: MediaQuery.of(context).size.height / 2 - verticalOffset - gap / 2,
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}

class LionsMane {
  double xPosition;
  double yAlign; // Centered in the gap (Align y coordinate)
  bool collected;

  LionsMane({required this.xPosition, required this.yAlign, this.collected = false});

  Widget build(BuildContext context) {
    if (collected) return SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;
    // Convert yAlign (-1..1) to pixel position
    double yPx = screenSize.height / 2 + yAlign * (screenSize.height / 2);
    return Positioned(
      left: xPosition,
      top: yPx - 20, // Center the image (assuming 40x40)
      child: Image.asset(
        'assets/images/lions_mane.png',
        width: 40,
        height: 40,
      ),
    );
  }
}

class RedPill {
  double xPosition;
  double yAlign;
  bool collected;

  RedPill({required this.xPosition, required this.yAlign, this.collected = false});

  Widget build(BuildContext context) {
    if (collected) return SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;
    double yPx = screenSize.height / 2 + yAlign * (screenSize.height / 2);
    return Positioned(
      left: xPosition,
      top: yPx - 17, // Center the image (assuming 34x34)
      child: Image.asset(
        'assets/images/red_pill.png',
        width: 34,
        height: 34,
      ),
    );
  }
}

class Bitcoin {
  double xPosition;
  double yAlign;
  bool collected;

  Bitcoin({required this.xPosition, required this.yAlign, this.collected = false});

  Widget build(BuildContext context) {
    if (collected) return SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;
    double yPx = screenSize.height / 2 + yAlign * (screenSize.height / 2);
    return Positioned(
      left: xPosition,
      top: yPx - 20,
      child: Image.asset(
        'assets/images/bitcoin.png',
        width: 40,
        height: 40,
      ),
    );
  }
}

class _GameScreenState extends State<GameScreen> {
  double birdY = 0; // Start in center
  double velocity = 0;
  bool gameHasStarted = false;
  bool gameOver = false; // <-- Add game over state
  bool showTitleScreen = true; // <-- Add this line
  bool redWhiteBlackFilter = false; // <-- Add this line
  bool canRestart = true; // Add this flag

  String currentBirdSkin = 'bird.png';
  Set<String> unlockedSkins = {'bird.png'};

  // Adjusted physics constants for Align(y) system
  final double gravity = 0.007 * 0.5; // Bird falls 50% slower (was 0.7 for 30%)
  final double maxFallSpeed = 0.035; // Slightly lower max fall speed

  Timer? gameLoopTimer;

  final List<GlueStickPair> glueSticks = [];
  final double glueStickSpacing = 280; // Horizontal spacing between pairs
  final double glueStickSpeed = 2; // Speed of movement

  final double pixelToAlignRatio = 0.002; // Adjust this based on screen height
  final double flapHeight = 22; // Flap height in pixels (was 24)

  int score = 0;
  int lionsManeCollected = 0;
  int redPillCollected = 0;
  int bitcoinCollected = 0;
  List<LionsMane> lionsManes = [];
  List<RedPill> redPills = [];
  List<Bitcoin> bitcoins = [];
  int collectibleCycleCounter = 0; // 0..5, 0-4 = lions mane, 5 = bitcoin
  List<int> collectibleTypes = []; // 0 = lions mane, 1 = bitcoin

  @override
  void initState() {
    super.initState();
    _loadSkinPrefs();
    // Show title screen for 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        showTitleScreen = false;
      });
    });
  }

  Future<void> _loadSkinPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentBirdSkin = prefs.getString('currentBirdSkin') ?? 'bird.png';
      unlockedSkins = (prefs.getStringList('unlockedSkins') ?? ['bird.png']).toSet();
    });
  }

  Future<void> _saveSkinPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentBirdSkin', currentBirdSkin);
    await prefs.setStringList('unlockedSkins', unlockedSkins.toList());
  }

  void _openShop() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShopScreen(
        lionsManeCollected: lionsManeCollected,
        redPillCollected: redPillCollected,
        bitcoinCollected: bitcoinCollected,
        unlockedSkins: unlockedSkins,
        currentBirdSkin: currentBirdSkin,
        onUnlock: (skin, collectible) {
          setState(() {
            if (collectible == 'RedPill' && redPillCollected >= 10) {
              redPillCollected -= 10;
              unlockedSkins.add(skin);
            } else if (collectible == 'LionsMane' && lionsManeCollected >= 10) {
              lionsManeCollected -= 10;
              unlockedSkins.add(skin);
            } else if (collectible == 'Bitcoin' && bitcoinCollected >= 10) {
              bitcoinCollected -= 10;
              unlockedSkins.add(skin);
            }
            _saveSkinPrefs();
          });
        },
        onEquip: (skin) {
          setState(() {
            currentBirdSkin = skin;
            _saveSkinPrefs();
          });
        },
      ),
    ));
  }

  void startGame() {
    gameHasStarted = true;
    gameOver = false;
    score = 0;

    glueSticks.clear();
    lionsManes.clear();
    redPills.clear();
    bitcoins.clear();
    collectibleCycleCounter = 0;

    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 3; i++) {
      double verticalOffset = (i % 2 == 0 ? -1 : 1) * 50.0;
      double xPos = MediaQuery.of(context).size.width + i * glueStickSpacing;
      glueSticks.add(GlueStickPair(
        verticalOffset: verticalOffset,
        xPosition: xPos,
      ));

      // --- Center collectible in the gap ---
      final gap = 280.0; // Increased gap by 40% (was 200)
      final screenHeight = MediaQuery.of(context).size.height;
      double gapTop = screenHeight / 2 + verticalOffset - gap / 2;
      double gapBottom = screenHeight / 2 + verticalOffset + gap / 2;
      double gapCenterY = (gapTop + gapBottom) / 2;
      double yAlign = (gapCenterY - screenHeight / 2) / (screenHeight / 2);

      if (collectibleCycleCounter < 5) {
        lionsManes.add(LionsMane(
          xPosition: xPos + 70 / 2 - 20,
          yAlign: yAlign,
        ));
        bitcoins.add(Bitcoin(
          xPosition: -1000,
          yAlign: 0,
          collected: true,
        ));
      } else {
        lionsManes.add(LionsMane(
          xPosition: -1000,
          yAlign: 0,
          collected: true,
        ));
        bitcoins.add(Bitcoin(
          xPosition: xPos + 70 / 2 - 20,
          yAlign: yAlign,
        ));
      }
      redPills.add(RedPill(
        xPosition: xPos + 70 / 2 - 17,
        yAlign: yAlign,
      ));

      collectibleCycleCounter = (collectibleCycleCounter + 1) % 6;
    }

    // Start game loop
    gameLoopTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        updateBirdPosition();
        updateGlueSticks();
        updateCollectibles();
        updateScore();
        checkCollectibleCollision();
        if (checkCollision()) {
          gameOver = true;
          gameLoopTimer?.cancel();
        }
      });
    });
  }

  void updateScore() {
    final screenSize = MediaQuery.of(context).size;
    final birdCenterX = screenSize.width / 2;
    for (var glueStick in glueSticks) {
      // Only score once per pair, when bird passes the right edge
      if (!glueStick.hasScored &&
          birdCenterX > glueStick.xPosition + glueStick.width) {
        glueStick.hasScored = true;
        score += 1;
      }
    }
  }

  void updateCollectibles() {
    final gap = 280.0; // Increased gap by 40% (was 200)
    final screenHeight = MediaQuery.of(context).size.height;
    for (int i = 0; i < glueSticks.length; i++) {
      lionsManes[i].xPosition -= glueStickSpeed;
      redPills[i].xPosition -= glueStickSpeed;
      bitcoins[i].xPosition -= glueStickSpeed;

      bool collectibleOffscreen = (lionsManes[i].xPosition < -40 && bitcoins[i].xPosition < -40);

      if (collectibleOffscreen) {
        int stickIdx = i;
        double newX = glueSticks[stickIdx].xPosition + glueStickSpacing * glueSticks.length;
        double verticalOffset = glueSticks[stickIdx].verticalOffset;

        // --- Center collectible in the gap ---
        double gapTop = screenHeight / 2 + verticalOffset - gap / 2;
        double gapBottom = screenHeight / 2 + verticalOffset + gap / 2;
        double gapCenterY = (gapTop + gapBottom) / 2;
        double yAlign = (gapCenterY - screenHeight / 2) / (screenHeight / 2);

        if (collectibleCycleCounter < 5) {
          lionsManes[i] = LionsMane(
            xPosition: newX + 70 / 2 - 20,
            yAlign: yAlign,
            collected: false,
          );
          bitcoins[i] = Bitcoin(
            xPosition: -1000,
            yAlign: 0,
            collected: true,
          );
        } else {
          lionsManes[i] = LionsMane(
            xPosition: -1000,
            yAlign: 0,
            collected: true,
          );
          bitcoins[i] = Bitcoin(
            xPosition: newX + 70 / 2 - 20,
            yAlign: yAlign,
            collected: false,
          );
        }
        redPills[i] = RedPill(
          xPosition: newX + 70 / 2 - 17,
          yAlign: yAlign,
          collected: false,
        );

        collectibleCycleCounter = (collectibleCycleCounter + 1) % 6;
      }
    }
  }

  void checkCollectibleCollision() {
    final screenSize = MediaQuery.of(context).size;
    final birdWidth = 70.0 * 0.7;
    final birdHeight = 70.0 * 0.7;
    final birdHitboxPadding = 0.2;
    final birdHitboxWidth = birdWidth * (1 - birdHitboxPadding);
    final birdHitboxHeight = birdHeight * (1 - birdHitboxPadding);

    final birdCenterX = screenSize.width / 2;
    final birdCenterY = screenSize.height / 2 + birdY * (screenSize.height / 2);
    final birdRect = Rect.fromCenter(
      center: Offset(birdCenterX, birdCenterY),
      width: birdHitboxWidth,
      height: birdHitboxHeight,
    );

    if (redWhiteBlackFilter) {
      for (var redPill in redPills) {
        if (redPill.collected) continue;
        double yPx = screenSize.height / 2 + redPill.yAlign * (screenSize.height / 2);
        Rect pillRect = Rect.fromLTWH(
          redPill.xPosition,
          yPx - 17,
          34,
          34,
        );
        if (birdRect.overlaps(pillRect)) {
          setState(() {
            redPill.collected = true;
            redPillCollected += 1;
          });
        }
      }
    } else {
      for (var i = 0; i < lionsManes.length; i++) {
        if (!lionsManes[i].collected) {
          double yPx = screenSize.height / 2 + lionsManes[i].yAlign * (screenSize.height / 2);
          Rect maneRect = Rect.fromLTWH(
            lionsManes[i].xPosition,
            yPx - 17,
            34,
            34,
          );
          if (birdRect.overlaps(maneRect)) {
            setState(() {
              lionsManes[i].collected = true;
              lionsManeCollected += 1;
            });
          }
        }
        // Bitcoin collision (only if not collected)
        if (!bitcoins[i].collected) {
          double yPx = screenSize.height / 2 + bitcoins[i].yAlign * (screenSize.height / 2);
          Rect btcRect = Rect.fromLTWH(
            bitcoins[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (birdRect.overlaps(btcRect)) {
            setState(() {
              bitcoins[i].collected = true;
              bitcoinCollected += 1;
            });
          }
        }
      }
    }
  }

  void onTap() {
    if (gameOver) {
      if (canRestart) {
        resetGame();
        startGame();
      }
      return;
    }
    if (!gameHasStarted) {
      startGame();
      return;
    }
    jump();
  }

  void jump() {
    setState(() {
      velocity = -flapHeight * pixelToAlignRatio; // Convert pixels to Align(y) units
    });
  }

  void updateBirdPosition() {
    // Apply gravity and limit downward velocity
    velocity += gravity;
    if (velocity > maxFallSpeed) velocity = maxFallSpeed;

    // Update bird position
    birdY += velocity;

    // Clamp position to stay within screen bounds
    if (birdY > 1) {
      birdY = 1;
      velocity = 0;
    } else if (birdY < -1) {
      birdY = -1;
      velocity = 0;
    }
  }

  void updateGlueSticks() {
    for (int i = 0; i < glueSticks.length; i++) {
      var glueStick = glueSticks[i];
      glueStick.xPosition -= glueStickSpeed;

      // Recycle glue stick if it exits the screen
      if (glueStick.xPosition < -glueStick.width) {
        glueStick.xPosition += glueStickSpacing * glueSticks.length;
        glueStick.verticalOffset = (glueStick.verticalOffset.isNegative ? 1 : -1) * 50.0;
        glueStick.hasScored = false;
        // Also recycle collectibles
        lionsManes[i] = LionsMane(
          xPosition: glueStick.xPosition + glueStick.width / 2 - 17,
          yAlign: (glueStick.verticalOffset / (MediaQuery.of(context).size.height / 2)),
          collected: false,
        );
        redPills[i] = RedPill(
          xPosition: glueStick.xPosition + glueStick.width / 2 - 17,
          yAlign: (glueStick.verticalOffset / (MediaQuery.of(context).size.height / 2)),
          collected: false,
        );
      }
    }
  }

  // --- Collision Detection ---
  bool checkCollision() {
    final screenSize = MediaQuery.of(context).size;

    // Bird's visual size in the game (scaled)
    final birdWidth = 70.0 * 0.7;  // 49.0
    final birdHeight = 70.0 * 0.7; // 49.0

    // Shrink bird hitbox for tighter collision (e.g., 20% padding)
    final birdHitboxPadding = 0.2; // 20% inset
    final birdHitboxWidth = birdWidth * (1 - birdHitboxPadding);
    final birdHitboxHeight = birdHeight * (1 - birdHitboxPadding);

    final birdCenterX = screenSize.width / 2;
    final birdCenterY = screenSize.height / 2 + birdY * (screenSize.height / 2);
    final birdRect = Rect.fromCenter(
      center: Offset(birdCenterX, birdCenterY),
      width: birdHitboxWidth,
      height: birdHitboxHeight,
    );

    // Shrink glue stick hitbox horizontally (e.g., 15% inset)
    final glueStickHitboxPadding = 0.15; // 15% inset
    for (var glueStick in glueSticks) {
      final stickX = glueStick.xPosition + glueStick.width * glueStickHitboxPadding / 2;
      final stickWidth = glueStick.width * (1 - glueStickHitboxPadding);

      // Top glue stick
      final topRect = Rect.fromLTWH(
        stickX,
        0,
        stickWidth,
        screenSize.height / 2 + glueStick.verticalOffset - glueStick.gap / 2,
      );
      // Bottom glue stick
      final bottomRect = Rect.fromLTWH(
        stickX,
        screenSize.height - (screenSize.height / 2 - glueStick.verticalOffset - glueStick.gap / 2),
        stickWidth,
        screenSize.height / 2 - glueStick.verticalOffset - glueStick.gap / 2,
      );
      if (birdRect.overlaps(topRect) || birdRect.overlaps(bottomRect)) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      velocity = 0;
      gameHasStarted = false;
      gameOver = false;
      score = 0;
      glueSticks.clear();
      lionsManes.clear();
      redPills.clear();
      bitcoins.clear();
      collectibleTypes.clear();
      // lionsManeCollected, redPillCollected, bitcoinCollected are NOT reset here!
    });
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = 127 / 512 * 2 - 1; // ~-0.504
    final safeBottom = 1 - (94 / 512 * 2); // ~0.633
    final safeLeft = 75.0;
    final safeRight = MediaQuery.of(context).size.width - 75.0;

    Widget gameStack = Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Glue sticks
        ...glueSticks.map((glueStick) => glueStick.build(context)).toList(),
        // Collectibles
        if (redWhiteBlackFilter)
          ...redPills.map((pill) => pill.build(context)).toList()
        else
          ...[
            for (int i = 0; i < lionsManes.length; i++)
              if (!bitcoins[i].collected && bitcoins[i].xPosition > 0)
                bitcoins[i].build(context)
              else
                lionsManes[i].build(context)
          ],
        // Bird
        Align(
          alignment: Alignment(0, birdY),
          child: Image.asset(
            'assets/images/$currentBirdSkin',
            width: 49,
            height: 49,
          ),
        ),
        // Collectibles display (show only while playing or game over, but not title screen)
        if ((gameHasStarted || gameOver) && !showTitleScreen)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Lions Mane
                  Image.asset(
                    'assets/images/lions_mane.png',
                    width: 28,
                    height: 28,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$lionsManeCollected',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 18),
                  // Red Pill
                  Image.asset(
                    'assets/images/red_pill.png',
                    width: 28,
                    height: 28,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$redPillCollected',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 28),
                  // Bitcoin
                  Image.asset(
                    'assets/images/bitcoin.png',
                    width: 28,
                    height: 28,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$bitcoinCollected',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // "Tap to Start" overlay
        if (!gameHasStarted && !gameOver)
          Center(
            child: Text(
              'TAP TO START',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // Title screen overlay
        if (showTitleScreen)
          Positioned.fill(
            child: Image.asset(
              'assets/images/title_screen.png',
              fit: BoxFit.cover,
            ),
          ),
      ],
    );

    // Apply color filter if enabled
    if (redWhiteBlackFilter) {
      gameStack = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          // Red channel
          1, 0, 0, 0, 0,
          // Green channel
          0, 0, 0, 0, 0,
          // Blue channel
          0, 0, 0, 0, 0,
          // Alpha channel
          0, 0, 0, 1, 0,
        ]),
        child: gameStack,
      );
    }

    return GestureDetector(
      onTap: showTitleScreen
          ? null
          : (gameOver
              ? () {
                  if (canRestart) {
                    resetGame();
                    startGame();
                  }
                }
              : onTap),
      child: Scaffold(
        body: Stack(
          children: [
            gameStack,
            // End screen (full screen, replaces overlay)
            if (gameOver)
              Positioned.fill(
                child: EndScreenOverlay(
                  score: score,
                  canRestart: canRestart,
                  onShowRestart: () {
                    setState(() {
                      canRestart = true;
                    });
                  },
                  onStartDelay: () {
                    setState(() {
                      canRestart = false;
                    });
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted && gameOver) {
                        setState(() {
                          canRestart = true;
                        });
                      }
                    });
                  },
                  // Pass these for the new switch:
                  shopSwitchValue: _shopSwitchValue,
                  onShopSwitchChanged: (val) {
                    setState(() {
                      _shopSwitchValue = val;
                    });
                    if (val) _openShop();
                  },
                  redWhiteBlackFilter: redWhiteBlackFilter,
                  onRedModeChanged: (val) {
                    setState(() {
                      redWhiteBlackFilter = val;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Add this field to _GameScreenState:
  bool _shopSwitchValue = false;
}

// Add this widget at the end of the file:
class EndScreenOverlay extends StatefulWidget {
  final int score;
  final bool canRestart;
  final VoidCallback onShowRestart;
  final VoidCallback onStartDelay;
  final bool shopSwitchValue;
  final ValueChanged<bool> onShopSwitchChanged;
  final bool redWhiteBlackFilter;
  final ValueChanged<bool> onRedModeChanged;

  const EndScreenOverlay({
    required this.score,
    required this.canRestart,
    required this.onShowRestart,
    required this.onStartDelay,
    required this.shopSwitchValue,
    required this.onShopSwitchChanged,
    required this.redWhiteBlackFilter,
    required this.onRedModeChanged,
  });

  @override
  State<EndScreenOverlay> createState() => _EndScreenOverlayState();
}

class _EndScreenOverlayState extends State<EndScreenOverlay> {
  bool delayStarted = false;

  @override
  void didUpdateWidget(covariant EndScreenOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!delayStarted && !widget.canRestart) {
      delayStarted = true;
      widget.onStartDelay();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!delayStarted && !widget.canRestart) {
      delayStarted = true;
      widget.onStartDelay();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/end_screen.png',
          fit: BoxFit.cover,
        ),
        // Score number only, centered in top 60 pixels
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Center(
            child: Text(
              '${widget.score}',
              style: TextStyle(
                fontSize: 44,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black54,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Red/White/Black Filter Switch (right side)
        Positioned(
          right: 15,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: Switch(
                value: widget.redWhiteBlackFilter,
                onChanged: widget.onRedModeChanged,
                activeColor: Colors.red,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black,
              ),
            ),
          ),
        ),
        // Matrix Shop Switch (left side, identical style)
        Positioned(
          left: 15,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: Switch(
                value: widget.shopSwitchValue,
                onChanged: widget.onShopSwitchChanged,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black,
              ),
            ),
          ),
        ),
        // Only show restart hint/button after delay
        if (widget.canRestart)
          Center(
            child: Text(
              'Tap to Restart',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black54,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
