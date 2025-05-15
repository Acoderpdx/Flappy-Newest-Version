import 'package:flutter/material.dart';
import 'dart:async';

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
  final double gap = 160; // Fixed vertical gap
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

class _GameScreenState extends State<GameScreen> {
  double birdY = 0; // Start in center
  double velocity = 0;
  bool gameHasStarted = false;
  bool gameOver = false; // <-- Add game over state

  // Adjusted physics constants for Align(y) system
  final double gravity = 0.007 * 0.75; // Bird falls 25% slower
  final double maxFallSpeed = 0.04; // Limit max downward velocity in Align(y) units

  Timer? gameLoopTimer;

  final List<GlueStickPair> glueSticks = [];
  final double glueStickSpacing = 280; // Horizontal spacing between pairs
  final double glueStickSpeed = 2; // Speed of movement

  final double pixelToAlignRatio = 0.002; // Adjust this based on screen height
  final double flapHeight = 24; // Flap height in pixels

  int score = 0; // <-- Add score variable

  void startGame() {
    gameHasStarted = true;
    gameOver = false; // Reset game over state
    score = 0; // Reset score

    // Initialize glue sticks
    glueSticks.clear();
    for (int i = 0; i < 3; i++) {
      glueSticks.add(GlueStickPair(
        verticalOffset: (i % 2 == 0 ? -1 : 1) * 50.0, // Example offset
        xPosition: MediaQuery.of(context).size.width + i * glueStickSpacing,
      ));
    }

    // Start game loop
    gameLoopTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        updateBirdPosition();
        updateGlueSticks();
        updateScore(); // <-- Add this
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

  void onTap() {
    if (gameOver) {
      resetGame();
      startGame();
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
    for (var glueStick in glueSticks) {
      glueStick.xPosition -= glueStickSpeed;

      // Recycle glue stick if it exits the screen
      if (glueStick.xPosition < -glueStick.width) {
        glueStick.xPosition += glueStickSpacing * glueSticks.length;
        glueStick.verticalOffset = (glueStick.verticalOffset.isNegative ? 1 : -1) * 50.0; // Example offset
        glueStick.hasScored = false; // <-- Reset flag when recycled
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
      score = 0; // <-- Reset score
      glueSticks.clear();
      // Optionally, re-initialize glue sticks here or in startGame()
    });
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Scaffold(
        body: Stack(
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
            // Bird
            Align(
              alignment: Alignment(0, birdY),
              child: Image.asset(
                'assets/images/bird.png',
                width: 70 * 0.7,   // 49.0
                height: 70 * 0.7,  // 49.0
              ),
            ),
            // Score display (show only while playing)
            if (gameHasStarted && !gameOver)
              Positioned(
                top: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 48,
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
            // "Game Over" overlay
            if (gameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'TAP TO RESTART',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
