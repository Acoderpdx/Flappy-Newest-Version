import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_screen.dart'; // (Make sure this import is present)
import 'crash_mini_game.dart';
import 'pong_mini_game.dart'; // <-- Add this import
import 'ball_blast_mini_game.dart';
import 'dart:math'; // <-- Add this import
import 'dart:io'; // <-- Add this import
import 'portfolio_screen.dart';
import 'property_screen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print(details.exceptionAsString());
  };
  runApp(FlappyBirdClone());
}

class FlappyBirdClone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ErrorBoundary(child: GameScreen()),
    );
  }
}

// Add this widget to catch errors in the widget tree.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({required this.child});
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Do NOT call setState here!
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Error: ${details.exception}',
            style: TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Error: $_error',
            style: TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return widget.child;
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class GlueStickPair {
  double verticalOffset; // Made mutable to allow updates
  final double gap = 364; // Increased vertical gap by 30% (was 280)
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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red,
                child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
              );
            },
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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red,
                child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
              );
            },
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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red,
            child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
          );
        },
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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red,
            child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
          );
        },
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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red,
            child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
          );
        },
      ),
    );
  }
}

class _GameScreenState extends State<GameScreen> {
  double birdY = 0;
  double velocity = 0;
  // --- PHYSICS TUNING ---
  final double gravity = 0.0039; // keep as is for slow jump
  final double maxFallSpeed = 0.025;
  final double flapHeight = 29.0; // 10% less than previous 32.2
  // --- END PHYSICS TUNING ---

  bool gameHasStarted = false;
  bool gameOver = false;
  bool showTitleScreen = true;
  bool redWhiteBlackFilter = false;
  bool canRestart = true;

  String currentBirdSkin = 'bird.png';
  Set<String> unlockedSkins = {'bird.png'};

  final double glueStickSpacing = 280;
  final double glueStickSpeed = 2;

  final double pixelToAlignRatio = 0.002;

  int score = 0;
  int lionsManeCollected = 0;
  int redPillCollected = 0;
  int bitcoinCollected = 0;
  List<LionsMane> lionsManes = [];
  List<RedPill> redPills = [];
  List<Bitcoin> bitcoins = [];
  int collectibleCycleCounter = 0;
  List<int> collectibleTypes = [];

  bool _shopSwitchValue = false;
  bool _miniGameSwitchValue = false;
  bool _showMiniGame = false;
  bool _pongMiniGameSwitchValue = false;
  bool _showPongMiniGame = false;
  bool _ballBlastMiniGameSwitchValue = false;
  bool _showBallBlastMiniGame = false;

  // --- ROTATION STATE ---
  double birdAngle = 0.0; // Radians, for smooth rotation
  // --- END ROTATION STATE ---

  // Add this field to fix the error:
  Timer? gameLoopTimer;

  // Add this field to fix the error:
  final List<GlueStickPair> glueSticks = [];

  // Portal state
  bool _portalVisible = false;
  double _portalX = -1000; // start offscreen
  double _portalY = 0.0;
  final double _portalSize = 49.0;
  int _gapsSinceLastPortal = 0;
  final int _portalGapInterval = 5;
  final Random _rand = Random();

  // --- Red Mode Cash Out logic ---
  bool _redModeCashOutEnabled = false; // Show cash out switch in red mode
  bool _redModeCashedOut = false;      // Track if player cashed out
  int _redModeCashedOutRedPills = 0;   // Amount cashed out

  // --- Add PnL history tracking ---
  List<double> lionsManePnlHistory = [0];
  List<double> redPillPnlHistory = [0];
  List<double> bitcoinPnlHistory = [0];
  List<double> totalWealthHistory = [0];

  // Add this field if missing:
  bool _portfolioSwitchValue = false;

  // Add USD currency to track dollars
  double usdBalance = 0.0;

  // Add property screen state
  bool _propertyScreenSwitchValue = false;

  @override
  void initState() {
    super.initState();
    _loadSkinPrefs();
    // Only run the Timer if not in test mode
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          showTitleScreen = false;
        });
      });
    }
  }

  Future<void> _loadSkinPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentBirdSkin = prefs.getString('currentBirdSkin') ?? 'bird.png';
      unlockedSkins = (prefs.getStringList('unlockedSkins') ?? ['bird.png']).toSet();
    });
  }

  // --- Dynamic Difficulty Getters ---
  double get currentGlueStickSpacing {
    // Tighten spacing from 280 to 140 as score increases
    // In red mode, halve the spacing for double difficulty
    double base = glueStickSpacing - (score * 8).clamp(0, glueStickSpacing - 140).toDouble();
    if (redWhiteBlackFilter) {
      return (base / 2).clamp(70, base); // never less than 70
    }
    return base;
  }

  double get currentGapMin {
    // Make gaps tighter: from 364 to 140
    // In red mode, halve the min gap and add more randomness
    double base = 364 - (score * 7).clamp(0, 224).toDouble(); // 364-224 = 140
    if (redWhiteBlackFilter) {
      return (base / 2).clamp(60, base); // never less than 60
    }
    return base;
  }

  double get currentGapMax {
    // Reduce max gap over time: from 364 to 180
    // In red mode, halve the max gap and add more randomness
    double base = 364 - (score * 5).clamp(0, 184).toDouble(); // 364-184 = 180
    if (redWhiteBlackFilter) {
      return (base / 2).clamp(80, base); // never less than 80
    }
    return base;
  }
  // --- End Dynamic Difficulty ---

  void startGame() {
    gameHasStarted = true;
    gameOver = false;
    score = 0;
    _redModeCashOutEnabled = false;
    _redModeCashedOut = false;
    _redModeCashedOutRedPills = 0;

    glueSticks.clear();
    lionsManes.clear();
    redPills.clear();
    bitcoins.clear();
    collectibleCycleCounter = 0;
    _portalVisible = false;
    _portalX = -1000;
    _portalY = 0.0;
    _gapsSinceLastPortal = 0;

    // --- Adaptive initial obstacle count and spacing ---
    int initialObstacleCount = 3;
    double initialSpacing = currentGlueStickSpacing;

    // In red mode, start with 3 obstacles but with slightly closer spacing
    if (redWhiteBlackFilter) {
      initialObstacleCount = 3;
      initialSpacing = currentGlueStickSpacing * 0.8;
    }

    for (int i = 0; i < initialObstacleCount; i++) {
      double verticalOffset;
      if (redWhiteBlackFilter) {
        verticalOffset = (_rand.nextDouble() * 2 - 1) * 120.0;
      } else {
        verticalOffset = (i % 2 == 0 ? -1 : 1) * 50.0;
      }
      // In red mode, start obstacles a bit further left for instant appearance
      double xPos = MediaQuery.of(context).size.width * (redWhiteBlackFilter ? 0.7 : 1.0) + i * initialSpacing;
      double gap;
      if (redWhiteBlackFilter) {
        gap = currentGapMin + _rand.nextDouble() * (currentGapMax - currentGapMin) * 1.2;
      } else {
        gap = currentGapMin + _rand.nextDouble() * (currentGapMax - currentGapMin);
      }
      glueSticks.add(GlueStickPair(
        verticalOffset: verticalOffset,
        xPosition: xPos,
      ));

      double gapTop = MediaQuery.of(context).size.height / 2 + verticalOffset - gap / 2;
      double gapBottom = MediaQuery.of(context).size.height / 2 + verticalOffset + gap / 2;
      double gapCenterY = (gapTop + gapBottom) / 2;
      double yAlign = (gapCenterY - MediaQuery.of(context).size.height / 2) / (MediaQuery.of(context).size.height / 2);

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

    // --- RED MODE: Make gameplay 30% slower by increasing timer interval ---
    int timerMs = 16;
    if (redWhiteBlackFilter) {
      timerMs = (16 * 1.3).round(); // ~21ms per tick
    }

    gameLoopTimer = Timer.periodic(Duration(milliseconds: timerMs), (timer) {
      setState(() {
        updateBirdPosition();
        updateGlueSticks();
        updateCollectibles();
        updatePortalPosition();
        updateScore();
        checkCollectibleCollision();
        if (checkCollision()) {
          gameOver = true;
          gameLoopTimer?.cancel();
        }
      });
    });

    // Always show the portal.png at a fixed, visible position when the game starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      // Place the portal at 1/3 from the left, vertically centered
      double x = screenSize.width * 0.33;
      double y = screenSize.height / 2;
      setState(() {
        _portalVisible = true;
      });
    });
  }

  void updateScore() {
    final screenSize = MediaQuery.of(context).size;
    final birdCenterX = screenSize.width / 2;
    for (var i = 0; i < glueSticks.length; i++) {
      var glueStick = glueSticks[i];
      if (!glueStick.hasScored &&
          birdCenterX > glueStick.xPosition + glueStick.width) {
        glueStick.hasScored = true;
        score += 1;
        // --- Portal spawn logic ---
        _gapsSinceLastPortal++;
        if (_gapsSinceLastPortal >= _portalGapInterval && !_portalVisible) {
          _trySpawnPortal();
          _gapsSinceLastPortal = 0;
        }
      }
    }
  }

  void _trySpawnPortal() {
    final screenSize = MediaQuery.of(context).size;
    // Try up to 10 times to find a safe spot
    for (int attempt = 0; attempt < 10; attempt++) {
      // X: spawn just off the right edge, like obstacles
      double x = screenSize.width + 70;
      // Y: anywhere between 15% and 85% of screen height
      double y = screenSize.height * (0.15 + 0.7 * _rand.nextDouble());

      Rect portalRect = Rect.fromLTWH(
        x - _portalSize / 2,
        y - _portalSize / 2,
        _portalSize,
        _portalSize,
      );

      // Avoid obstacles (glue sticks)
      bool overlapsObstacle = false;
      for (var glueStick in glueSticks) {
        // Top glue stick
        Rect topRect = Rect.fromLTWH(
          glueStick.xPosition,
          0,
          glueStick.width,
          screenSize.height / 2 + glueStick.verticalOffset - glueStick.gap / 2,
        );
        // Bottom glue stick
        Rect bottomRect = Rect.fromLTWH(
          glueStick.xPosition,
          screenSize.height - (screenSize.height / 2 - glueStick.verticalOffset - glueStick.gap / 2),
          glueStick.width,
          screenSize.height / 2 - glueStick.verticalOffset - glueStick.gap / 2,
        );
        if (portalRect.overlaps(topRect) || portalRect.overlaps(bottomRect)) {
          overlapsObstacle = true;
          break;
        }
      }
      if (overlapsObstacle) continue;

      // Avoid collectibles
      bool overlapsCollectible = false;
      for (var i = 0; i < lionsManes.length; i++) {
        if (!lionsManes[i].collected) {
          double yPx = screenSize.height / 2 + lionsManes[i].yAlign * (screenSize.height / 2);
          Rect maneRect = Rect.fromLTWH(
            lionsManes[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (portalRect.overlaps(maneRect)) {
            overlapsCollectible = true;
            break;
          }
        }
        if (!bitcoins[i].collected) {
          double yPx = screenSize.height / 2 + bitcoins[i].yAlign * (screenSize.height / 2);
          Rect btcRect = Rect.fromLTWH(
            bitcoins[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (portalRect.overlaps(btcRect)) {
            overlapsCollectible = true;
            break;
          }
        }
        if (!redPills[i].collected) {
          double yPx = screenSize.height / 2 + redPills[i].yAlign * (screenSize.height / 2);
          Rect pillRect = Rect.fromLTWH(
            redPills[i].xPosition,
            yPx - 17,
            34,
            34,
          );
          if (portalRect.overlaps(pillRect)) {
            overlapsCollectible = true;
            break;
          }
        }
      }
      if (overlapsCollectible) continue;

      // If we get here, it's a safe spot
      setState(() {
        _portalX = x;
        _portalY = y;
        _portalVisible = true;
      });
      break;
    }
  }

  void updatePortalPosition() {
    if (_portalVisible) {
      _portalX -= glueStickSpeed;
      // Remove portal if it goes off screen
      if (_portalX < -_portalSize) {
        _portalVisible = false;
      }
    }
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

    // --- ROTATION LOGIC ---
    // Calculate target angle based on velocity
    double targetAngle = velocity * 18.0; // Increased scale for more dramatic rotation
    targetAngle = targetAngle.clamp(-0.5, 1.57); // -0.5 rad (~-28deg) to 1.57 rad (~90deg)
    // Smoothly interpolate current angle toward target
    birdAngle += (targetAngle - birdAngle) * 0.18; // smoothing factor
    // --- END ROTATION LOGIC ---
    _checkPortalCollision();
  }

  void updateGlueSticks() {
    for (int i = 0; i < glueSticks.length; i++) {
      var glueStick = glueSticks[i];
      glueStick.xPosition -= glueStickSpeed;

      // Recycle glue stick if it exits the screen
      if (glueStick.xPosition < -glueStick.width) {
        // Progressive difficulty: decrease spacing as score increases
        double spacing = currentGlueStickSpacing;
        glueStick.xPosition += spacing * glueSticks.length;
        // --- Use dynamic gap ---
        double gap;
        if (redWhiteBlackFilter) {
          gap = currentGapMin + _rand.nextDouble() * (currentGapMax - currentGapMin) * 1.2;
        } else {
          gap = currentGapMin + _rand.nextDouble() * (currentGapMax - currentGapMin);
        }
        // In red mode, increase randomness of verticalOffset
        if (redWhiteBlackFilter) {
          glueStick.verticalOffset = (_rand.nextDouble() * 2 - 1) * 120.0;
        } else {
          glueStick.verticalOffset = (glueStick.verticalOffset.isNegative ? 1 : -1) * 50.0;
        }
        glueStick.hasScored = false;
        // Also recycle collectibles
        double gapTop = MediaQuery.of(context).size.height / 2 + glueStick.verticalOffset - gap / 2;
        double gapBottom = MediaQuery.of(context).size.height / 2 + glueStick.verticalOffset + gap / 2;
        double gapCenterY = (gapTop + gapBottom) / 2;
        double yAlign = (gapCenterY - MediaQuery.of(context).size.height / 2) / (MediaQuery.of(context).size.height / 2);

        lionsManes[i] = LionsMane(
          xPosition: glueStick.xPosition + glueStick.width / 2 - 17,
          yAlign: yAlign,
          collected: false,
        );
        redPills[i] = RedPill(
          xPosition: glueStick.xPosition + glueStick.width / 2 - 17,
          yAlign: yAlign,
          collected: false,
        );
      }
    }
  }

  // Only ONE updateCollectibles method should exist:
  void updateCollectibles() {
    final gap = 364.0;
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
        // --- Red Mode: lose all red pills if not cashed out ---
        if (redWhiteBlackFilter && !_redModeCashedOut) {
          setState(() {
            redPillCollected = 0;
          });
        }
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
      _portalVisible = false;
      _gapsSinceLastPortal = 0;
    });
  }
  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building GameScreen');

    // --- Red Mode Cash Out Button: bitcoin.png image at far left, same position as shop button on end screen ---
    Widget cashOutButton = SizedBox.shrink();
    if (redWhiteBlackFilter && gameHasStarted && !gameOver && !_redModeCashedOut) {
      cashOutButton = Positioned(
        left: 15,
        top: 0,
        bottom: 0,
        child: Center(
          child: GestureDetector(
            onTap: _handleRedModeCashOut,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/bitcoin.png',
                width: 38,
                height: 38,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.currency_bitcoin, color: Colors.amber, size: 38),
              ),
            ),
          ),
        ),
      );
    }

    Widget portfolioButton = Positioned(
      right: 15,
      bottom: 100,
      child: FloatingActionButton(
        heroTag: 'portfolio',
        backgroundColor: Colors.green,
        child: Icon(Icons.account_balance_wallet, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PortfolioScreen(
              lionsManeCollected: lionsManeCollected,
              redPillCollected: redPillCollected,
              bitcoinCollected: bitcoinCollected,
              lionsManePnlHistory: lionsManePnlHistory,
              redPillPnlHistory: redPillPnlHistory,
              bitcoinPnlHistory: bitcoinPnlHistory,
              totalWealthHistory: totalWealthHistory,
              usdBalance: usdBalance,
              onTrade: _handleTrade,
            ),
          ));
        },
      ),
    );

    Widget gameStack = Stack(
      children: [
        ScrollingBackground(
          scrollSpeed: 80.0,
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
          child: Transform.rotate(
            angle: birdAngle,
            child: Image.asset(
              'assets/images/$currentBirdSkin',
              width: 49,
              height: 49,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.red,
                  child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                );
              },
            ),
          ),
        ),
        // Portal (portal.png image) -- now rendered AFTER the bird so it's in front
        if (_portalVisible)
          Positioned(
            left: _portalX - _portalSize / 2,
            top: _portalY - _portalSize / 2,
            child: Image.asset(
              'assets/images/portal.png',
              width: _portalSize,
              height: _portalSize,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: _portalSize,
                  height: _portalSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                );
              },
            ),
          ),
        // Collectibles display (show only while playing or game over, but not title screen)
        if ((gameHasStarted || gameOver) && !showTitleScreen)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lions Mane
                    Image.asset(
                      'assets/images/lions_mane.png',
                      width: 28,
                      height: 28,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red,
                          child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                        );
                      },
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
                            offset: Offset(2, 2),
                            blurRadius: 8,
                            color: Colors.black54,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red,
                          child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                        );
                      },
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
                            offset: Offset(2, 2),
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 18),
                    // Bitcoin
                    Image.asset(
                      'assets/images/bitcoin.png',
                      width: 28,
                      height: 28,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.red,
                          child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                        );
                      },
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
                            offset: Offset(2, 2),
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // --- Red Mode Cash Out Switch ---
                if (redWhiteBlackFilter && gameHasStarted && !gameOver && !_redModeCashedOut)
                  SizedBox(height: 60), // Add spacing so collectibles row doesn't overlap with center cashout
              ],
            ),
          ),
        // --- Red Mode Cash Out Button (bitcoin image at far left) ---
        if (redWhiteBlackFilter && gameHasStarted && !gameOver && !_redModeCashedOut)
          cashOutButton,
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/title_screen.png', // <-- use the new image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.red,
                      child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                    );
                  },
                ),
                Center(
                  child: _TitleScreenContent(),
                ),
              ],
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
          // Alpha channel,  0, 0, 0, 1, 0,
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
            if (_showMiniGame)
              CrashMiniGameScreen(
                lionsManeCollected: lionsManeCollected,
                redPillCollected: redPillCollected,
                bitcoinCollected: bitcoinCollected,
                onCollectibleChange: (collectible, delta) {
                  setState(() {
                    if (collectible == 'LionsMane') lionsManeCollected += delta;
                    if (collectible == 'RedPill') redPillCollected += delta;
                    if (collectible == 'Bitcoin') bitcoinCollected += delta;
                    _updatePnlHistory(); // <-- Add this
                  });
                },
                onClose: () {
                  setState(() {
                    _showMiniGame = false;
                    _miniGameSwitchValue = false;
                  });
                },
              ),
            if (_showPongMiniGame)
              PongMiniGameScreen(
                onClose: () {
                  setState(() {
                    _showPongMiniGame = false;
                    _pongMiniGameSwitchValue = false;
                  });
                },
                onBitcoinCollected: () {
                  setState(() {
                    bitcoinCollected += 1;
                    _updatePnlHistory(); // <-- Add this
                  });
                },
              ),
            if (_showBallBlastMiniGame)
              BallBlastMiniGameScreen(
                onClose: () {
                  setState(() {
                    _showBallBlastMiniGame = false;
                    _ballBlastMiniGameSwitchValue = false;
                  });
                },
                onBitcoinCollected: () {
                  setState(() {
                    bitcoinCollected += 1;
                    _updatePnlHistory(); // <-- Add this
                  });
                },
              ),
            if (_portfolioSwitchValue)
              PortfolioScreen(
                lionsManeCollected: lionsManeCollected,
                redPillCollected: redPillCollected,
                bitcoinCollected: bitcoinCollected,
                lionsManePnlHistory: lionsManePnlHistory,
                redPillPnlHistory: redPillPnlHistory,
                bitcoinPnlHistory: bitcoinPnlHistory,
                totalWealthHistory: totalWealthHistory,
                onClose: () {
                  setState(() {
                    _portfolioSwitchValue = false;
                  });
                },
              ),
            if (_propertyScreenSwitchValue)
              PropertyScreen(
                usdBalance: usdBalance,
                onUpdateBalance: (usdDelta) {
                  setState(() {
                    usdBalance += usdDelta;
                    _updatePnlHistory();
                  });
                },
              ),
            if (gameOver && !_showMiniGame && !_showPongMiniGame && !_showBallBlastMiniGame && !_portfolioSwitchValue && !_propertyScreenSwitchValue)
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
                  shopSwitchValue: _shopSwitchValue,
                  redWhiteBlackFilter: redWhiteBlackFilter,
                  miniGameSwitchValue: _miniGameSwitchValue,
                  ballBlastMiniGameSwitchValue: _ballBlastMiniGameSwitchValue,
                  propertySwitchValue: _propertyScreenSwitchValue,
                  onRedModeChanged: (val) {
                    setState(() {
                      redWhiteBlackFilter = val;
                    });
                  },
                  onShopSwitchChanged: (val) {
                    if (val) {
                      _openShop();
                    } else {
                      setState(() {
                        _shopSwitchValue = false;
                      });
                    }
                  },
                  onMiniGameSwitchChanged: (val) {
                    setState(() {
                      _miniGameSwitchValue = val;
                      _showMiniGame = val;
                    });
                  },
                  onBallBlastMiniGameSwitchChanged: (val) {
                    setState(() {
                      _ballBlastMiniGameSwitchValue = val;
                      _showBallBlastMiniGame = val;
                    });
                  },
                  // --- Add portfolio switch wiring ---
                  portfolioSwitchValue: _portfolioSwitchValue,
                  onPortfolioSwitchChanged: (val) {
                    setState(() {
                      _portfolioSwitchValue = val;
                    });
                  },
                  // --- Add property switch wiring ---
                  onPropertySwitchChanged: (val) {
                    setState(() {
                      _propertyScreenSwitchValue = val;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Move this method inside the class
  Future<void> _openShop() async {
    setState(() {
      _shopSwitchValue = false;
    });
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
              _updatePnlHistory(); // <-- Add this
            } else if (collectible == 'LionsMane' && lionsManeCollected >= 10) {
              lionsManeCollected -= 10;
              unlockedSkins.add(skin);
              _updatePnlHistory(); // <-- Add this
            } else if (collectible == 'Bitcoin' && bitcoinCollected >= 10) {
              bitcoinCollected -= 10;
              unlockedSkins.add(skin);
              _updatePnlHistory(); // <-- Add this
            }
          });
        },
        onEquip: (skin) {
          setState(() {
            currentBirdSkin = skin;
          });
        },
      ),
    ));
  }

  // Add this method to fix the error:
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
            _updatePnlHistory(); // <-- Add this
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
              _updatePnlHistory(); // <-- Add this
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
              _updatePnlHistory(); // <-- Add this
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

  // --- Red Mode Cash Out logic ---
  void _handleRedModeCashOut() {
    if (!redWhiteBlackFilter || gameOver || _redModeCashedOut) return;
    setState(() {
      _redModeCashedOut = true;
      _redModeCashedOutRedPills = redPillCollected;
      gameOver = true;
      gameLoopTimer?.cancel();
    });
  }

  // Add the missing _checkPortalCollision method:
  void _checkPortalCollision() {
    if (!_portalVisible) return;
    final screenSize = MediaQuery.of(context).size;
    final birdCenterX = screenSize.width / 2;
    final birdCenterY = screenSize.height / 2 + birdY * (screenSize.height / 2);
    Rect birdRect = Rect.fromCenter(
      center: Offset(birdCenterX, birdCenterY),
      width: 49 * 0.7,
      height: 49 * 0.7,
    );
    Rect portalRect = Rect.fromCenter(
      center: Offset(_portalX, _portalY),
      width: _portalSize,
      height: _portalSize,
    );
    if (birdRect.overlaps(portalRect)) {
      setState(() {
        _portalVisible = false;
        _showPongMiniGame = true;
        _pongMiniGameSwitchValue = true;
      });
    }
  }

  // Add the missing jump() method:
  void jump() {
    setState(() {
      velocity = -flapHeight * pixelToAlignRatio;
    });
  }

  // --- Add PnL history tracking ---
  void _updatePnlHistory() {
    lionsManePnlHistory.add(lionsManeCollected.toDouble());
    redPillPnlHistory.add(redPillCollected.toDouble());
    bitcoinPnlHistory.add(bitcoinCollected.toDouble());
    
    // Calculate USD equivalent (using Bitcoin price from somewhere in your game)
    double bitcoinPrice = 69000.0; // This should come from your Bitcoin simulation
    double totalValue = lionsManeCollected * 100.0 + 
                        redPillCollected * 500.0 + 
                        bitcoinCollected * bitcoinPrice +
                        usdBalance;
                        
    totalWealthHistory.add(totalValue);
  }
  
  // Add a handler for trading activities
  void _handleTrade(int lionsManeDelta, int redPillDelta, int bitcoinDelta, double usdDelta) {
    setState(() {
      lionsManeCollected += lionsManeDelta;
      redPillCollected += redPillDelta;
      bitcoinCollected += bitcoinDelta;
      usdBalance += usdDelta;
      _updatePnlHistory();
    });
  }
}

class EndScreenOverlay extends StatefulWidget {
  final int score;
  final bool canRestart;
  final VoidCallback onShowRestart;
  final VoidCallback onStartDelay;
  final bool shopSwitchValue;
  final ValueChanged<bool> onShopSwitchChanged;
  final bool redWhiteBlackFilter;
  final ValueChanged<bool> onRedModeChanged;
  final bool miniGameSwitchValue;
  final ValueChanged<bool> onMiniGameSwitchChanged;
  final bool ballBlastMiniGameSwitchValue;
  final ValueChanged<bool> onBallBlastMiniGameSwitchChanged;
  // --- Add portfolio switch value and callback ---
  final bool portfolioSwitchValue;
  final ValueChanged<bool> onPortfolioSwitchChanged;
  // --- Add property switch value and callback ---
  final bool propertySwitchValue;
  final ValueChanged<bool> onPropertySwitchChanged;

  const EndScreenOverlay({
    Key? key,
    required this.score,
    required this.canRestart,
    required this.onShowRestart,
    required this.onStartDelay,
    required this.shopSwitchValue,
    required this.onShopSwitchChanged,
    required this.redWhiteBlackFilter,
    required this.onRedModeChanged,
    required this.miniGameSwitchValue,
    required this.onMiniGameSwitchChanged,
    required this.ballBlastMiniGameSwitchValue,
    required this.onBallBlastMiniGameSwitchChanged,
    required this.portfolioSwitchValue,
    required this.onPortfolioSwitchChanged,
    required this.propertySwitchValue,
    required this.onPropertySwitchChanged,
  }) : super(key: key);

  @override
  State<EndScreenOverlay> createState() => _EndScreenOverlayState();
}

class _EndScreenOverlayState extends State<EndScreenOverlay> {
  bool delayStarted = false;

  void didUpdateWidget(covariant EndScreenOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!delayStarted && !widget.canRestart) {
      delayStarted = true;
      widget.onStartDelay();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Add property switch value and callback ---
    final bool propertySwitchValue = false;
    final ValueChanged<bool> onPropertySwitchChanged;

    // --- Ground under everything ---
    return Stack(
      fit: StackFit.expand,
      children: [
        // --- Scrolling background under everything ---
        Positioned.fill(
          child: ScrollingBackground(scrollSpeed: 80.0),
        ),
        // --- End screen overlay image (tate_endscreen.png) ---
        Positioned.fill(
          child: Image.asset(
            'assets/images/tate_endscreen.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red,
                child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
              );
            },
          ),
        ),
        // --- All the collectible/mini-game/shop buttons and overlays ---
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
                    offset: Offset(2, 2),
                    blurRadius: 8,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Red/White/Black Filter Toggle (Red Pill image, right side)
        Positioned(
          right: 15,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => widget.onRedModeChanged(!widget.redWhiteBlackFilter),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.redWhiteBlackFilter ? Colors.green : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: [
                    if (widget.redWhiteBlackFilter)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/red_pill.png',
                  width: 38,
                  height: 38,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.medication, color: Colors.red, size: 38),
                ),
              ),
            ),
          ),
        ),
        // Matrix Shop Button (left side, bitcoin image)
        Positioned(
          left: 15,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => widget.onShopSwitchChanged(true),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.shopSwitchValue ? Colors.green : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: [
                    if (widget.shopSwitchValue)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/bitcoin.png',
                  width: 38,
                  height: 38,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.currency_bitcoin, color: Colors.amber, size: 38),
                ),
              ),
            ),
          ),
        ),
        // --- Crash Mini-game Button (gamble.png image, bottom left) ---
        Positioned(
          left: 15,
          bottom: 40,
          child: GestureDetector(
            onTap: () => widget.onMiniGameSwitchChanged(!widget.miniGameSwitchValue),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.miniGameSwitchValue ? Colors.green : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  if (widget.miniGameSwitchValue)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/gamble.png',
                width: 38,
                height: 38,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.casino, color: Colors.blue, size: 38),
              ),
            ),
          ),
        ),
        // --- Ball Blast Mini-game Button (isreal.png image, bottom right) ---
        Positioned(
          right: 15,
          bottom: 40,
          child: GestureDetector(
            onTap: () => widget.onBallBlastMiniGameSwitchChanged(!widget.ballBlastMiniGameSwitchValue),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.ballBlastMiniGameSwitchValue ? Colors.green : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  if (widget.ballBlastMiniGameSwitchValue)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/isreal.png',
                width: 38,
                height: 38,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.sports_baseball, color: Colors.deepPurple, size: 38),
              ),
            ),
          ),
        ),
        // --- Game Over Text (move up slightly) ---
        Positioned(
          top: MediaQuery.of(context).size.height * 0.19, // was 0.25, now higher
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(
                  'Game Over\nYou are not a lion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Flappybirdy',
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                // --- Tap to Restart text, now directly under Game Over text ---
                if (widget.canRestart)
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: Text(
                      'Tap to Restart',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // --- Portfolio Switch (center bottom, wallet icon) ---
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => widget.onPortfolioSwitchChanged(!widget.portfolioSwitchValue),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.portfolioSwitchValue ? Colors.green : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: [
                    if (widget.portfolioSwitchValue)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ),
        // --- Property Switch (next to Portfolio Switch, house icon) ---
        Positioned(
          bottom: 40,
          right: 0,
          child: GestureDetector(
            onTap: () => widget.onPropertySwitchChanged(!widget.propertySwitchValue),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.propertySwitchValue ? Colors.green : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  if (widget.propertySwitchValue)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/house1.png',
                width: 38,
                height: 38,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.home, color: Colors.white, size: 38),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScrollingBackground extends StatefulWidget {
  final double scrollSpeed; // pixels per second

  const ScrollingBackground({Key? key, this.scrollSpeed = 80.0}) : super(key: key);
  
  @override
  State<ScrollingBackground> createState() => _ScrollingBackgroundState();
}

class _ScrollingBackgroundState extends State<ScrollingBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _offset = 0.0;
  double? _lastTick;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Set a duration for repeat
    )..addListener(_tick)
     ..repeat();
  }
  
  void _tick() {
    final now = _controller.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0.0;
    if (_lastTick == null) {
      _lastTick = now;
      return;
    }
    final dt = (now - _lastTick!) / 1000.0;
    _lastTick = now;
    _offset += widget.scrollSpeed * (dt > 0 && dt < 1 ? dt : 1 / 60.0);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double imageWidth = constraints.maxWidth;
        final double imageHeight = constraints.maxHeight;
        final double effectiveOffset = _offset % imageHeight;

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: effectiveOffset - imageHeight,
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                'assets/images/background.png',
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: Colors.red,
                    child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              top: effectiveOffset,
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                'assets/images/background.png',
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: Colors.red,
                    child: Center(child: Text('Image not found', style: TextStyle(color: Colors.white))),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TitleScreenContent extends StatefulWidget {
  @override
  State<_TitleScreenContent> createState() => _TitleScreenContentState();
}

class _TitleScreenContentState extends State<_TitleScreenContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double birdY = 0.0;
  double velocity = 0.0;
  final double gravity = 0.007 * 0.5;
  final double flapVelocity = -0.11;
  final double maxFallSpeed = 0.035;
  final double baseY = 0.0; // baseline for bird's Y position
  
  // Flap 3 times per second as bird moves left to right
  final int flapsPerSecond = 3;
  late double flapInterval;
  double lastFlapX = -1.2;

  // --- Lions Mane collectibles for title screen ---
  final List<_TitleScreenLionsMane> _lionsManes = [];
  double _lastDropTime = 0.0;
  final double _dropIntervalSec = 1.0 / 3.0; // 3 per second

  // Use the same gravity and maxFallSpeed as the main game bird
  final double collectibleGravity = 0.0039;
  final double collectibleMaxFallSpeed = 0.025;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    flapInterval = 2.4 / (flapsPerSecond * 3);
    birdY = baseY;
    velocity = 0.0;
    lastFlapX = -1.2;
    _lastDropTime = 0.0;
    _controller.addListener(() {
      setState(() {
        double x = _animation.value;
        double t = _controller.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0.0;
        t /= 1000.0; // seconds

        // Flap if we've moved enough horizontally
        if (x - lastFlapX >= flapInterval) {
          velocity = flapVelocity;
          lastFlapX = x;
        }
        velocity += gravity;
        if (velocity > maxFallSpeed) velocity = maxFallSpeed;
        birdY += velocity;
        // Clamp Y so it doesn't go off the visible area
        if (birdY > 0.25) birdY = 0.25;
        if (birdY < -0.25) birdY = -0.25;

        // --- Drop lions mane collectibles at 3 per second ---
        if (t - _lastDropTime >= _dropIntervalSec) {
          // Drop at bird's current x, but always start at bird's current y
          _lionsManes.add(_TitleScreenLionsMane(
            x: x,
            y: birdY,
            vy: 0,
          ));
          _lastDropTime = t;
        }
        
        // --- Animate lions mane collectibles falling with gravity like bird ---
        for (final mane in _lionsManes) {
          mane.vy += collectibleGravity;
          if (mane.vy > collectibleMaxFallSpeed) mane.vy = collectibleMaxFallSpeed;
          mane.y += mane.vy;
        }
        
        // Remove collectibles that fall off the bottom
        _lionsManes.removeWhere((mane) => mane.y > 1.2);
      });
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        birdY = baseY;
        velocity = 0.0;
        lastFlapX = -1.2;
        _lionsManes.clear();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final birdSize = screenWidth * 0.18;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Flappy',
          style: TextStyle(
            fontFamily: 'FlappyBirdy',
            fontSize: 84,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 8,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        Text(
          'Poet',
          style: TextStyle(
            fontFamily: 'FlappyBirdy',
            fontSize: 84,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 8,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: Stack(
            children: [
              // --- Lions Mane collectibles falling straight down from bird ---
              ..._lionsManes.map((mane) {
                return Align(
                  alignment: Alignment(mane.x, mane.y),
                  child: Image.asset(
                    'assets/images/lions_mane.png',
                    width: birdSize * 0.45,
                    height: birdSize * 0.45,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.circle, color: Colors.amber, size: birdSize * 0.45);
                    },
                  ),
                );
              }),
              // --- Bird ---
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(_animation.value, birdY),
                    child: Image.asset(
                      'assets/images/bird.png',
                      width: birdSize,
                      height: birdSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, color: Colors.red, size: birdSize);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // --- Subheading: move up by another 20px (was 29, now 9) ---
        SizedBox(height: 9), // was 29, now 9 to move up by 20px
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'help the poet\nescape the matrix',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'FlappyBirdy',
              fontSize: 44,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 1.18,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Helper class for title screen lions mane collectible ---
class _TitleScreenLionsMane {
  double x, y, vy;
  _TitleScreenLionsMane({required this.x, required this.y, required this.vy});
}
