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
  double birdY = 0; // Bird's vertical position
  double gravity = 0.01; // Gravity value
  double velocity = 0; // Bird's current velocity

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        velocity += gravity; // Apply gravity to velocity
        birdY += velocity; // Update bird's position
      });
    });
  }

  void jump() {
    setState(() {
      velocity = -0.2; // Move the bird up
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
                width: 50,
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
