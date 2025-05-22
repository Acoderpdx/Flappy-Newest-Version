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
import 'garage_screen.dart'; // Add import for the garage screen
import 'crypto_market_manager.dart'; // Add this import at the top of main.dart

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

// Replace Bitcoin class with Solana class
class Solana {
  double xPosition;
  double yAlign;
  bool collected;

  Solana({required this.xPosition, required this.yAlign, this.collected = false});

  Widget build(BuildContext context) {
    if (collected) return SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;
    double yPx = screenSize.height / 2 + yAlign * (screenSize.height / 2);
    return Positioned(
      left: xPosition,
      top: yPx - 20,
      child: Image.asset(
        'assets/images/solana.png',
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

// Add after the Solana class

class BrowneCoin {
  double xPosition;
  double yAlign;
  bool collected;

  BrowneCoin({required this.xPosition, required this.yAlign, this.collected = false});

  Widget build(BuildContext context) {
    if (collected) return SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;
    double yPx = screenSize.height / 2 + yAlign * (screenSize.height / 2);
    return Positioned(
      left: xPosition,
      top: yPx - 20,
      child: Image.asset(
        'assets/images/brownecoin.png',
        width: 40,
        height: 40,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.brown,
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
  int ethereumCollected = 0;
  int solanaCollected = 0; // Keep this existing variable
  int browneCoinCollected = 0;
  List<LionsMane> lionsManes = [];
  List<RedPill> redPills = [];
  List<Solana> solanas = []; // Replace bitcoins with solanas
  List<BrowneCoin> browneCoins = [];
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
  final int _portalGapInterval = 10; // Changed from 5 to 10 to make portals twice as rare
  final Random _rand = Random();

  // --- Red Mode Cash Out logic ---
  bool _redModeCashOutEnabled = false; // Show cash out switch in red mode
  bool _redModeCashedOut = false;      // Track if player cashed out
  int _redModeCashedOutRedPills = 0;   // Amount cashed out
  int _currentRoundRedPills = 0;       // Track red pills collected this round only
  int _redPillWagerAmount = 0;         // NEW: Amount of red pills wagered (25% of total)

  // --- Add PnL history tracking ---
  List<double> lionsManePnlHistory = [0];
  List<double> redPillPnlHistory = [0];
  List<double> bitcoinPnlHistory = [0];
  List<double> ethereumPnlHistory = [0]; // Add Ethereum PnL history
  List<double> solanaPnlHistory = [0]; // Add Solana PnL history
  List<double> browneCoinPnlHistory = [0]; // For portfolio tracking
  List<double> totalWealthHistory = [0];

  // Add this field if missing:
  bool _portfolioSwitchValue = false;

  // Add USD currency to track dollars
  double usdBalance = 0.0;

  // Add property screen state
  bool _propertyScreenSwitchValue = false;
  int _currentHouseLevel = 0;  // Start with no house (level 0)
  String _currentHouseType = ""; // Start with no house type selected

  // Add garage screen state
  bool _garageScreenSwitchValue = false;
  String _currentCarId = "";  // Track current car
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the crypto market manager to run continuously in the background
    CryptoMarketManager().initialize();
    
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
    _redModeCashedOut = false;
    _redModeCashedOutRedPills = 0;
    _currentRoundRedPills = 0;
    
    // Enable cash out button if in red mode
    _redModeCashOutEnabled = redWhiteBlackFilter;

    glueSticks.clear();
    lionsManes.clear();
    redPills.clear();
    solanas.clear();
    browneCoins.clear();
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

      // Fix collectible pattern: 5 Lions Mane followed by 1 Solana
      if (collectibleCycleCounter % 6 != 5) {
        // First 5 positions (0,1,2,3,4): spawn Lions Mane
        lionsManes.add(LionsMane(
          xPosition: xPos + 70 / 2 - 20,
          yAlign: yAlign,
        ));
        solanas.add(Solana(xPosition: -1000, yAlign: 0, collected: true));
        browneCoins.add(BrowneCoin(xPosition: -1000, yAlign: 0, collected: true));
      } else {
        // Position 5 (every 6th): spawn Solana
        lionsManes.add(LionsMane(
          xPosition: xPos + 70 / 2 - 20, 
          yAlign: yAlign,
          collected: true,
        ));
        solanas.add(Solana(
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
          timer.cancel();
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
        _portalX = x;
        _portalY = y;
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
        if (!solanas[i].collected) {
          double yPx = screenSize.height / 2 + solanas[i].yAlign * (screenSize.height / 2);
          Rect solRect = Rect.fromLTWH(
            solanas[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (portalRect.overlaps(solRect)) {
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

  // Simplify updateCollectibles() to only update positions
  void updateCollectibles() {
    for (int i = 0; i < glueSticks.length; i++) {
      if (i < lionsManes.length) lionsManes[i].xPosition -= glueStickSpeed;
      if (i < solanas.length) solanas[i].xPosition -= glueStickSpeed;
      if (i < browneCoins.length) browneCoins[i].xPosition -= glueStickSpeed; // Add this line
      if (i < redPills.length) redPills[i].xPosition -= glueStickSpeed;
    }
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
        
        // Calculate gap center position
        double gapTop = MediaQuery.of(context).size.height / 2 + glueStick.verticalOffset - gap / 2;
        double gapBottom = MediaQuery.of(context).size.height / 2 + glueStick.verticalOffset + gap / 2;
        double gapCenterY = (gapTop + gapBottom) / 2;
        double yAlign = (gapCenterY - MediaQuery.of(context).size.height / 2) / (MediaQuery.of(context).size.height / 2);

        // Replace the existing collectible pattern with this new one
        if (shouldSpawnLionsMane(collectibleCycleCounter)) {
          if (i < lionsManes.length) {
            lionsManes[i] = LionsMane(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            );
          } else {
            lionsManes.add(LionsMane(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            ));
          }
          
          // Hide other collectibles
          if (i < solanas.length) {
            solanas[i] = Solana(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            solanas.add(Solana(xPosition: -1000, yAlign: 0, collected: true));
          }
          
          if (i < browneCoins.length) {
            browneCoins[i] = BrowneCoin(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            browneCoins.add(BrowneCoin(xPosition: -1000, yAlign: 0, collected: true));
          }
        } else if (shouldSpawnBrowneCoin(collectibleCycleCounter)) {
          if (i < browneCoins.length) {
            browneCoins[i] = BrowneCoin(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            );
          } else {
            browneCoins.add(BrowneCoin(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            ));
          }
          
          // Hide other collectibles
          if (i < lionsManes.length) {
            lionsManes[i] = LionsMane(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            lionsManes.add(LionsMane(xPosition: -1000, yAlign: 0, collected: true));
          }
          
          if (i < solanas.length) {
            solanas[i] = Solana(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            solanas.add(Solana(xPosition: -1000, yAlign: 0, collected: true));
          }
        } else if (shouldSpawnSolana(collectibleCycleCounter)) {
          if (i < solanas.length) {
            solanas[i] = Solana(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            );
          } else {
            solanas.add(Solana(
              xPosition: glueStick.xPosition + glueStick.width / 2 - 20,
              yAlign: yAlign,
              collected: false,
            ));
          }
          
          // Hide other collectibles
          if (i < lionsManes.length) {
            lionsManes[i] = LionsMane(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            lionsManes.add(LionsMane(xPosition: -1000, yAlign: 0, collected: true));
          }
          
          if (i < browneCoins.length) {
            browneCoins[i] = BrowneCoin(xPosition: -1000, yAlign: 0, collected: true);
          } else {
            browneCoins.add(BrowneCoin(xPosition: -1000, yAlign: 0, collected: true));
          }
        }

        collectibleCycleCounter = (collectibleCycleCounter + 1) % 6;
      }
    }
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
      solanas.clear();
      browneCoins.clear(); // Add this line
      collectibleTypes.clear();
      collectibleCycleCounter = 0;
      // lionsManeCollected, redPillCollected, bitcoinCollected, solanaCollected are NOT reset here!
      _portalVisible = false;
      _gapsSinceLastPortal = 0;
    });
  }
  @override
  void dispose() {
    // Clean up the market manager when the app closes
    CryptoMarketManager().dispose();
    
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
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                  )
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/bitcoin.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.attach_money, color: Colors.amber, size: 50);
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CASH OUT',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$_currentRoundRedPills Pills',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
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
              ethereumCollected: ethereumCollected,
              solanaCollected: solanaCollected,
              browneCoinCollected: browneCoinCollected, // Add this line
              lionsManePnlHistory: lionsManePnlHistory,
              redPillPnlHistory: redPillPnlHistory,
              bitcoinPnlHistory: bitcoinPnlHistory,
              ethereumPnlHistory: ethereumPnlHistory,
              solanaPnlHistory: solanaPnlHistory,
              browneCoinPnlHistory: browneCoinPnlHistory, // Add this line
              totalWealthHistory: totalWealthHistory,
              usdBalance: usdBalance,
              onTrade: _handleTrade,
              onClose: () {
                setState(() {
                  _portfolioSwitchValue = false;
                });
              },
            ),
          ));
        },
      ),
    );

    // --- Add red pill wager indicator ---
    List<Widget> gameStackChildren = [
      ScrollingBackground(scrollSpeed: 80.0),
      // Glue sticks
      ...glueSticks.map((glueStick) => glueStick.build(context)).toList(),
      // Collectibles
      if (redWhiteBlackFilter)
        ...redPills.map((pill) => pill.build(context)).toList()
      else
        ...[
          ...lionsManes.map((mane) => mane.build(context)).toList(),
          ...solanas.map((sol) => sol.build(context)).toList(),
          ...browneCoins.map((coin) => coin.build(context)).toList(), // Add this line
        ],
      // Bird
      Align(
        alignment: Alignment(0, birdY),
        child: Transform.rotate(
          angle: birdAngle,
          child: Image.asset(
            'assets/images/$currentBirdSkin',
            width: 70.0 * 0.7,
            height: 70.0 * 0.7,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 70.0 * 0.7,
                height: 70.0 * 0.7,
                color: Colors.red,
                child: Center(child: Text('!')),
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
                  // Lions Mane counter
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
                          offset: Offset(2, 2),
                          blurRadius: 8,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 18),
                  
                  // Red Pill counter
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
                      color: Colors.red,
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
                  
                  // Solana counter
                  Image.asset(
                    'assets/images/solana.png',
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
                    '$solanaCollected',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.purple,
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
                  
                  // ADD THIS: BrowneCoin counter
                  SizedBox(width: 18),
                  Image.asset(
                    'assets/images/brownecoin.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.brown.withOpacity(0.7),
                        width: 28,
                        height: 28,
                        child: Center(child: Text('B', style: TextStyle(color: Colors.white))),
                      );
                    },
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$browneCoinCollected',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.orange,
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
    ];

    // Add wager indicator to game UI in red mode
    if (redWhiteBlackFilter && gameHasStarted && !gameOver) {
      gameStackChildren.add(
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/red_pill.png', width: 20, height: 20),
                SizedBox(width: 5),
                Text(
                  'At Risk: $_redPillWagerAmount',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget gameStack = Stack(
      children: gameStackChildren,
    );

    // Apply color filter if enabled - updating to ensure it works properly
    if (redWhiteBlackFilter) {
      gameStack = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.0, 0.0, 0.0, 0.0, 0.0,    // Red channel - keep red
          0.0, 0.0, 0.0, 0.0, 0.0,    // Green channel - remove
          0.0, 0.0, 0.0, 0.0, 0.0,    // Blue channel - remove
          0.0, 0.0, 0.0, 1.0, 0.0,    // Alpha channel - no change
        ]),
        child: gameStack,
      );
    }
    
    // Ensure onTap works properly with simplified logic
    return GestureDetector(
      onTap: showTitleScreen ? null : onTap,
      child: Scaffold(
        body: Stack(
          children: [
            gameStack,
            if (_showMiniGame)
              Positioned.fill(
                child: CrashMiniGame(
                  redPillCollected: redPillCollected,
                  lionsManeCollected: lionsManeCollected,  // Already passing this correctly
                  onRedPillsEarned: (int amount) {
                    setState(() {
                      redPillCollected += amount;
                      _updatePnlHistory(); // Update PNL history
                    });
                  },
                  onLionsManeEarned: (int amount) {  // Add this new callback
                    setState(() {
                      lionsManeCollected += amount;
                      _updatePnlHistory();  // Update portfolio history
                    });
                  },
                  onClose: () {
                    setState(() {
                      _showMiniGame = false;
                    });
                  },
                  currentRoundRedPills: _currentRoundRedPills,
                ),
              ),
            if (_showPongMiniGame)
              PongMiniGameScreen(
                onClose: () {
                  setState(() {
                    _showPongMiniGame = false;
                    _pongMiniGameSwitchValue = false;
                  });
                },
                // Update the callback name and implementation
                onEthereumCollected: () {
                  setState(() {
                    ethereumCollected += 1;
                    _updatePnlHistory();
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
                onSolanaCollected: (int amount) {
                  setState(() {
                    solanaCollected += amount;
                    _updatePnlHistory();
                  });
                } as void Function(int)?,  // Cast to the expected nullable function type
              ),
            if (_portfolioSwitchValue)
              PortfolioScreen(
                lionsManeCollected: lionsManeCollected,
                redPillCollected: redPillCollected,
                bitcoinCollected: bitcoinCollected,
                ethereumCollected: ethereumCollected,
                solanaCollected: solanaCollected,
                browneCoinCollected: browneCoinCollected, // Add this line
                lionsManePnlHistory: lionsManePnlHistory,
                redPillPnlHistory: redPillPnlHistory,
                bitcoinPnlHistory: bitcoinPnlHistory,
                ethereumPnlHistory: ethereumPnlHistory,
                solanaPnlHistory: solanaPnlHistory,
                browneCoinPnlHistory: browneCoinPnlHistory, // Add this line
                totalWealthHistory: totalWealthHistory,
                usdBalance: usdBalance,
                onTrade: _handleTrade,
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
                // Add these two new parameters
                currentHouseLevel: _currentHouseLevel,
                currentHouseType: _currentHouseType,
                onHouseChanged: (level, type) {
                  setState(() {
                    _currentHouseLevel = level;
                    _currentHouseType = type;
                  });
                },
                onClose: () {
                  setState(() {
                    _propertyScreenSwitchValue = false;
                  });
                },
              ),
            if (_garageScreenSwitchValue)
              GarageScreen(
                usdBalance: usdBalance,
                onUpdateBalance: (delta) {
                  setState(() {
                    usdBalance += delta;
                  });
                },
                currentCarId: _currentCarId,
                onCarChanged: (carId) {
                  setState(() {
                    _currentCarId = carId;
                  });
                },
                onClose: () {
                  setState(() {
                    _garageScreenSwitchValue = false;
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
                  garageScreenSwitchValue: _garageScreenSwitchValue,
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
                  // --- Add garage switch wiring ---
                  onGarageSwitchChanged: (val) {
                    setState(() {
                      _garageScreenSwitchValue = val;
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
    ethereumPnlHistory.add(ethereumCollected.toDouble());
    solanaPnlHistory.add(solanaCollected.toDouble());
    browneCoinPnlHistory.add(browneCoinCollected.toDouble()); // Add this line
    
    // Calculate USD equivalent with all crypto included
    double bitcoinPrice = 69000.0;
    double ethereumPrice = 3500.0;
    double solanaPrice = 175.0;
    double browneCoinPrice = 350.0; // Set a price for BrowneCoin
    
    double totalValue = lionsManeCollected * 100.0 + 
                      redPillCollected * 500.0 + 
                      bitcoinCollected * bitcoinPrice +
                      ethereumCollected * ethereumPrice +
                      solanaCollected * solanaPrice +
                      browneCoinCollected * browneCoinPrice + // Add this line
                      usdBalance;
                      
    totalWealthHistory.add(totalValue);
  }
  
  // Update the handler for trading activities to include Solana
  void _handleTrade(int lionsManeDelta, int redPillDelta, int bitcoinDelta, int ethereumDelta, int solanaDelta, int browneCoinDelta, double usdDelta) {
    setState(() {
      lionsManeCollected = (lionsManeCollected + lionsManeDelta).clamp(0, 999999);
      redPillCollected = (redPillCollected + redPillDelta).clamp(0, 999999);
      bitcoinCollected = (bitcoinCollected + bitcoinDelta).clamp(0, 999999);
      ethereumCollected = (ethereumCollected + ethereumDelta).clamp(0, 999999);
      solanaCollected = (solanaCollected + solanaDelta).clamp(0, 999999);
      browneCoinCollected = (browneCoinCollected + browneCoinDelta).clamp(0, 999999); // Add this line
      usdBalance += usdDelta;
      _updatePnlHistory();
    });
  }

  // Add the missing _checkPortalCollision method:
  void _checkPortalCollision() {
    if (!_portalVisible) return;
    
    final screenSize = MediaQuery.of(context).size;
    final birdCenterX = screenSize.width / 2;
    final birdCenterY = screenSize.height / 2 + birdY * (screenSize.height / 2);
    
    // Create bird rectangle for collision detection
    Rect birdRect = Rect.fromCenter(
      center: Offset(birdCenterX, birdCenterY),
      width: 49 * 0.7,  // Approximate bird width with scaling
      height: 49 * 0.7, // Approximate bird height with scaling
    );
    
    // Create portal rectangle for collision detection
    Rect portalRect = Rect.fromCenter(
      center: Offset(_portalX, _portalY),
      width: _portalSize,
      height: _portalSize,
    );
    
    // Check if bird and portal rectangles overlap
    if (birdRect.overlaps(portalRect)) {
      setState(() {
        _portalVisible = false;
        _showPongMiniGame = true;
        _pongMiniGameSwitchValue = true;
      });
    }
  }

  // Fix the missing checkCollision method
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

    // Shrink glue stick hitbox horizontally for more forgiving collisions
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
        // Handle red mode wager loss if not cashed out
        if (redWhiteBlackFilter && !_redModeCashedOut) {
          setState(() {
            _currentRoundRedPills = 0;  // Reset the current round pills
            
            // Apply the 25% wager loss if not cashed out
            if (_redPillWagerAmount > 0) {
              redPillCollected = (redPillCollected - _redPillWagerAmount).clamp(0, 999999);
              
              // Show message about wager loss when back on end screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You lost $_redPillWagerAmount Red Pills from your wager!'),
                      backgroundColor: Colors.red.shade800,
                      duration: Duration(seconds: 5),
                    )
                  );
                }
              });
              
              // Update PNL history to reflect the loss
              _updatePnlHistory();
            }
          });
        }
        return true; // Collision detected
      }
    }
    return false; // No collision
  }

  // Add the missing checkCollectibleCollision method
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
            _currentRoundRedPills++; // Increment pills collected this round
            _updatePnlHistory();
          });
        }
      }
    } else {
      // Check Lions Mane collisions
      for (var i = 0; i < lionsManes.length; i++) {
        if (!lionsManes[i].collected) {
          double yPx = screenSize.height / 2 + lionsManes[i].yAlign * (screenSize.height / 2);
          Rect maneRect = Rect.fromLTWH(
            lionsManes[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (birdRect.overlaps(maneRect)) {
            setState(() {
              lionsManes[i].collected = true;
              lionsManeCollected++;
              _updatePnlHistory();
            });
          }
        }
      }
      
      // Check Solana collisions
      for (var i = 0; i < solanas.length; i++) {
        if (!solanas[i].collected) {
          double yPx = screenSize.height / 2 + solanas[i].yAlign * (screenSize.height / 2);
          Rect solRect = Rect.fromLTWH(
            solanas[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (birdRect.overlaps(solRect)) {
            setState(() {
              solanas[i].collected = true;
              solanaCollected++;
              _updatePnlHistory();
            });
          }
        }
      }

      // Check BrowneCoin collisions
      for (var i = 0; i < browneCoins.length; i++) {
        if (!browneCoins[i].collected) {
          double yPx = screenSize.height / 2 + browneCoins[i].yAlign * (screenSize.height / 2);
          Rect coinRect = Rect.fromLTWH(
            browneCoins[i].xPosition,
            yPx - 20,
            40,
            40,
          );
          if (birdRect.overlaps(coinRect)) {
            setState(() {
              browneCoins[i].collected = true;
              browneCoinCollected++;
              _updatePnlHistory();
            });
          }
        }
      }
    }
  }

  // Add the missing _handleRedModeCashOut method
  void _handleRedModeCashOut() {
    if (!redWhiteBlackFilter || gameOver || _redModeCashedOut) return;
    
    setState(() {
      _redModeCashedOut = true;
      _redModeCashedOutRedPills = _currentRoundRedPills;  // Store cashed out pills
      redPillCollected += _currentRoundRedPills;  // Add collected pills to total
      _currentRoundRedPills = 0;  // Reset as we've secured them
      gameOver = true;
      gameLoopTimer?.cancel();
      
      // Show cash out success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully cashed out $_redModeCashedOutRedPills Red Pills! Wager secured.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            )
          );
        }
      });
      
      // Update PNL history to reflect the gain
      _updatePnlHistory();
    });
  }

  // Add the missing onTap method to handle game interactions
  void onTap() {
    if (gameOver) {
      // If game is over, restart it
      resetGame();
      setState(() {
        gameHasStarted = false;
      });
    } else if (!gameHasStarted) {
      // If game hasn't started, start it
      startGame();
    } else {
      // If game is in progress, make the bird jump
      jump();
    }
  }

  // Add these methods to your _GameScreenState class
bool shouldSpawnLionsMane(int position) => position % 6 == 0 || position % 6 == 2 || position % 6 == 4;
bool shouldSpawnBrowneCoin(int position) => position % 6 == 1 || position % 6 == 3;
bool shouldSpawnSolana(int position) => position % 6 == 5;
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
  // Add garage screen properties
  final bool garageScreenSwitchValue;
  final ValueChanged<bool> onGarageSwitchChanged;

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
    required this.garageScreenSwitchValue,
    required this.onGarageSwitchChanged,
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
        // --- Garage Button (move to upper left) ---
        Positioned(
          left: 15,  // Position on left side
          top: 90,   // Position near top, below score display
          child: GestureDetector(
            onTap: () => widget.onGarageSwitchChanged(!widget.garageScreenSwitchValue),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.garageScreenSwitchValue ? Colors.green : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  if (widget.garageScreenSwitchValue)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Black outline
                  Icon(
                    Icons.directions_car,
                    color: Colors.black,
                    size: 42,
                  ),
                  // White car icon
                  Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 38,
                  ),
                ],
              ),
            ),
          ),
        ),
        // --- Crash Mini-game Button (position at bottom left) ---
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
        // --- Portfolio Switch (bottom right, wallet icon) ---
        Positioned(
          bottom: 40,
          right: 15, // Right alignment instead of center
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
        
        // --- Property Button (move to top right) ---
        Positioned(
          top: 90,  // Same vertical position as the garage button on the left
          right: 15, // Right align similar to the red pill button
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Black outline
                  Icon(
                    Icons.home,
                    color: Colors.black,
                    size: 42,
                  ),
                  // White house icon
                  Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 38,
                  ),
                ],
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
  late AnimationController _controller;
  double? _lastTick;
  double _offset = 0.0;
  
  @override
  void initState() {  // Missing "void initState()" 
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
  final double collectibleGravity =  0.0039;
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
