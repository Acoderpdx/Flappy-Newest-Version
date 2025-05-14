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

class _GameScreenState extends State<GameScreen> {
  double birdY = 0; // Center of the screen
  double velocity = 0; // Bird's current velocity
  bool gameHasStarted = false; // Track whether the game has started

  // Constants for physics
  final double gravity = 0.015; // Gravity value
  final double flapStrength = -0.2; // Flap strength
  final double maxFallSpeed = 0.5; // Maximum downward velocity

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    gameHasStarted = true; // Set the game state to started
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        if (!gameHasStarted) {
          return; // Do nothing if the game hasn't started
        }

        // Apply gravity to velocity
        velocity += gravity;

        // Cap the downward velocity to maxFallSpeed
        if (velocity > maxFallSpeed) {
          velocity = maxFallSpeed;
        }

        // Update the bird's position
        birdY += velocity;

        // Prevent the bird from going off-screen
        if (birdY > 1) {
          birdY = 1; // Bottom of the screen
          velocity = 0; // Stop falling
        } else if (birdY < -1) {
          birdY = -1; // Top of the screen
          velocity = 0; // Stop rising
        }
      });
    });
  }

  void jump() {
    if (!gameHasStarted) {
      startGame(); // Start the game on the first tap
    }
    setState(() {
      velocity = flapStrength; // Apply upward velocity
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump, // Trigger jump when the screen is tapped
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
            // Bird
            Align(
              alignment: Alignment(0, birdY), // Use birdY for vertical position
              child: Image.asset(
                'assets/images/bird.png',
                width: 70, // Adjust width
                height: 70, // Adjust height
              ),
            ),
            // "Tap to Start" Message
            if (!gameHasStarted)
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
          ],
        ),
      ),
    );
  }
}
