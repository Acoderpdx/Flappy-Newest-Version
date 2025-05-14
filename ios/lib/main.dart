import 'package:flutter/material.dart';
import 'dart:async';

bool debugMode = true; // Set to false to disable logs

void log(String message) {
  if (debugMode) {
    print(message);
  }
}

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
  double birdY = 0; // Bird's vertical position (centered initially)
  double gravity = 0.01; // Gravity value
  double velocity = 0; // Bird's current velocity
  bool gameStarted = false; // Flag to track if the game has started

  void startGame() {
    gameStarted = true;
    log("Game started!"); // Log when the game starts

    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!gameStarted) {
        timer.cancel();
        log("Game stopped. Timer canceled."); // Log when the timer is canceled
        return;
      }

      setState(() {
        velocity += gravity;
        birdY += velocity;

        log("Bird position updated: birdY = $birdY, velocity = $velocity"); // Log bird's position and velocity

        if (birdY > 1 || birdY < -1) {
          timer.cancel();
          log("Bird out of bounds. Resetting game."); // Log when the bird goes out of bounds
          resetGame();
        }
      });
    });
  }

  void jump() {
    if (!gameStarted) {
      log("First tap detected. Starting game."); // Log when the first tap starts the game
      startGame();
    }

    setState(() {
      velocity = -0.2; // Move the bird up
      log("Jump triggered. Velocity set to $velocity"); // Log when the bird jumps
    });
  }

  void resetGame() {
    setState(() {
      birdY = 0; // Reset bird's position to the center
      velocity = 0; // Reset velocity
      gameStarted = false; // Reset game state
      log("Game reset. birdY = $birdY, velocity = $velocity, gameStarted = $gameStarted"); // Log game reset state
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) {
      velocity = 0; // Ensure velocity is 0 before the game starts
    }

    return GestureDetector(
      onTap: jump, // Trigger jump on tap
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
              alignment: Alignment(0, birdY), // Centered horizontally and vertically
              child: Image.asset(
                'assets/images/bird.png',
                width: 90,
                height: 90,
              ),
            ),
            // Tap to Start Text
            if (!gameStarted)
              Center(
                child: Text(
                  "TAP TO START",
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
