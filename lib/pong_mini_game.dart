import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class PongMiniGameScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final void Function()? onBitcoinCollected; // Optional callback for bitcoin
  const PongMiniGameScreen({Key? key, this.onClose, this.onBitcoinCollected}) : super(key: key);

  @override
  State<PongMiniGameScreen> createState() => _PongMiniGameScreenState();
}

class _PongMiniGameScreenState extends State<PongMiniGameScreen> with SingleTickerProviderStateMixin {
  double ballX = 0.0;
  double ballY = 0.0;
  double ballVX = 0.0;
  double ballVY = 0.0;
  double playerPaddleX = 0.0; // -1 (left) to 1 (right)
  double aiPaddleX = 0.0;
  int playerScore = 0;
  int aiScore = 0;
  int lives = 3; // <-- Add lives
  late Timer _timer;
  final double paddleWidth = 0.34;
  final double paddleHeight = 0.055;
  final double ballSize = 0.07;
  bool gameOver = false;

  // Bitcoin collectible
  bool bitcoinVisible = false;
  double bitcoinX = 0.0;
  double bitcoinY = 0.0;
  final double bitcoinSize = 0.10;
  int bitcoinCollected = 0;

  // --- Add for falling bitcoin ---
  bool bitcoinFalling = false;
  double bitcoinVY = 0.0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    ballX = 0.0;
    ballY = 0.0;
    double angle = (Random().nextBool() ? -1 : 1) * (pi / 2) + (Random().nextDouble() - 0.5) * (pi / 6);
    double speed = 0.025;
    ballVX = speed * cos(angle);
    ballVY = speed * sin(angle);
    playerPaddleX = 0.0;
    aiPaddleX = 0.0;
    playerScore = 0;
    aiScore = 0;
    bitcoinCollected = 0;
    lives = 3; // <-- Reset lives
    gameOver = false;
    bitcoinFalling = false;
    bitcoinVY = 0.0;
    _spawnBitcoin();
    _timer = Timer.periodic(const Duration(milliseconds: 14), (_) => _update());
  }

  void _update() {
    setState(() {
      ballX += ballVX;
      ballY += ballVY;

      // Bounce left/right walls
      if (ballX.abs() + ballSize / 2 > 1) {
        ballX = ballX.sign * (1 - ballSize / 2);
        ballVX = -ballVX * 1.03;
      }

      // --- AI paddle (top) follows ball, but with a delay and limited speed ---
      double aiTarget = ballX;
      double aiSpeed = 0.055 + (aiScore + playerScore) * 0.008; // Easier: slower AI (was 0.09)
      if (aiPaddleX < aiTarget) {
        aiPaddleX += aiSpeed;
        if (aiPaddleX > aiTarget) aiPaddleX = aiTarget;
      } else {
        aiPaddleX -= aiSpeed;
        if (aiPaddleX < aiTarget) aiPaddleX = aiTarget;
      }
      aiPaddleX = aiPaddleX.clamp(-1 + paddleWidth / 2, 1 - paddleWidth / 2);

      // --- Player paddle collision (bottom) ---
      if (ballY + ballSize / 2 > 1 - paddleHeight &&
          (ballX + ballSize / 2 > playerPaddleX - paddleWidth / 2) &&
          (ballX - ballSize / 2 < playerPaddleX + paddleWidth / 2) &&
          ballVY > 0) {
        ballY = 1 - paddleHeight - ballSize / 2;
        ballVY = -ballVY * 1.07;
        ballVX += (Random().nextDouble() - 0.5) * 0.03;
      }

      // --- AI paddle collision (top) ---
      if (ballY - ballSize / 2 < -1 + paddleHeight &&
          (ballX + ballSize / 2 > aiPaddleX - paddleWidth / 2) &&
          (ballX - ballSize / 2 < aiPaddleX + paddleWidth / 2) &&
          ballVY < 0) {
        ballY = -1 + paddleHeight + ballSize / 2;
        ballVY = -ballVY * 1.07;
        ballVX += (Random().nextDouble() - 0.5) * 0.03;
      }

      // --- Score and lives logic ---
      if (ballY < -1.1) {
        playerScore += 1;
        _resetBall(down: true);
        _maybeSpawnBitcoin();
      } else if (ballY > 1.1) {
        aiScore += 1;
        lives -= 1; // <-- Lose a life
        if (lives <= 0) {
          gameOver = true;
          _timer.cancel();
          // Auto-return to end screen after short delay
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (widget.onClose != null) widget.onClose!();
          });
        } else {
          _resetBall(down: false);
          _maybeSpawnBitcoin();
        }
      }

      // --- Bitcoin falling logic ---
      if (bitcoinVisible && bitcoinFalling) {
        bitcoinVY += 0.012; // gravity
        bitcoinY += bitcoinVY;
        // Bounce off floor
        if (bitcoinY + bitcoinSize > 1) {
          bitcoinY = 1 - bitcoinSize;
          bitcoinVY = -bitcoinVY * 0.5;
          if (bitcoinVY.abs() < 0.01) bitcoinVY = 0;
        }
        // Clamp X
        if (bitcoinX < -1 + bitcoinSize / 2) bitcoinX = -1 + bitcoinSize / 2;
        if (bitcoinX > 1 - bitcoinSize / 2) bitcoinX = 1 - bitcoinSize / 2;
      }

      // --- Bitcoin collision with player paddle (bird.png) ---
      if (bitcoinVisible && _bitcoinHitsBird()) {
        bitcoinVisible = false;
        bitcoinFalling = false;
        bitcoinCollected += 1;
        if (widget.onBitcoinCollected != null) widget.onBitcoinCollected!();
        Future.delayed(const Duration(milliseconds: 600), _spawnBitcoin);
      }

      // --- End game at 7 points (still show overlay if player wins) ---
      if ((playerScore >= 7 || aiScore >= 7) && !gameOver) {
        gameOver = true;
        _timer.cancel();
      }
    });
  }

  void _resetBall({required bool down}) {
    ballX = 0.0;
    ballY = 0.0;
    double angle = (down ? 1 : -1) * (pi / 2) + (Random().nextDouble() - 0.5) * (pi / 6);
    double speed = 0.025 + (playerScore + aiScore) * 0.002;
    ballVX = speed * cos(angle);
    ballVY = speed * sin(angle);
  }

  // --- Helper: check if bitcoin overlaps with bird.png (player paddle) ---
  bool _bitcoinHitsBird() {
    // Bird (player paddle) is at bottom: Alignment(playerPaddleX, 1)
    // Bitcoin: Alignment(bitcoinX, bitcoinY)
    // Both are rendered as squares, so use simple AABB collision

    // Bird (player paddle) rectangle
    double paddleLeft = playerPaddleX - paddleWidth / 2;
    double paddleRight = playerPaddleX + paddleWidth / 2;
    double paddleTop = 1 - paddleHeight;
    double paddleBottom = 1;

    // Bitcoin rectangle
    double btcLeft = bitcoinX - bitcoinSize / 2;
    double btcRight = bitcoinX + bitcoinSize / 2;
    double btcTop = bitcoinY - bitcoinSize / 2;
    double btcBottom = bitcoinY + bitcoinSize / 2;

    bool overlap = !(btcRight < paddleLeft ||
        btcLeft > paddleRight ||
        btcBottom < paddleTop ||
        btcTop > paddleBottom);

    return overlap;
  }

  void _spawnBitcoin() {
    setState(() {
      bitcoinX = (Random().nextDouble() * 1.6 - 0.8); // -0.8 to 0.8
      bitcoinY = -1 + bitcoinSize / 2; // Start at top
      bitcoinVisible = true;
      bitcoinFalling = true;
      bitcoinVY = 0.0;
    });
  }

  void _maybeSpawnBitcoin() {
    // 50% chance to spawn after each point
    if (!bitcoinVisible && Random().nextBool()) {
      _spawnBitcoin();
    }
  }

  bool _ballHitsBitcoin() {
    // Simple circle collision
    double dx = ballX - bitcoinX;
    double dy = ballY - bitcoinY;
    double dist = sqrt(dx * dx + dy * dy);
    return dist < (ballSize + bitcoinSize) / 2;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      final dx = details.localPosition.dx / constraints.maxWidth;
      playerPaddleX = (dx - 0.5) * 2;
      playerPaddleX = playerPaddleX.clamp(-1 + paddleWidth / 2, 1 - paddleWidth / 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Pong Mini Game', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            // Use onHorizontalDragUpdate so paddle always tracks finger/mouse
            onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, constraints),
            child: Stack(
              children: [
                // Center line (horizontal)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CenterLinePainter(),
                  ),
                ),
                // AI paddle (top)
                Align(
                  alignment: Alignment(aiPaddleX, -1),
                  child: Container(
                    width: constraints.maxWidth * paddleWidth,
                    height: constraints.maxHeight * paddleHeight,
                    color: Colors.red,
                  ),
                ),
                // Player paddle (bottom)
                Align(
                  alignment: Alignment(playerPaddleX, 1),
                  child: Container(
                    width: constraints.maxWidth * paddleWidth,
                    height: constraints.maxHeight * paddleHeight,
                    color: Colors.green,
                  ),
                ),
                // Ball (bird.png)
                Align(
                  alignment: Alignment(ballX, ballY),
                  child: Image.asset(
                    'assets/images/bird.png',
                    width: constraints.maxWidth * ballSize,
                    height: constraints.maxWidth * ballSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.sports_tennis, color: Colors.white, size: constraints.maxWidth * ballSize);
                    },
                  ),
                ),
                // Bitcoin collectible (falling)
                if (bitcoinVisible)
                  Align(
                    alignment: Alignment(bitcoinX, bitcoinY),
                    child: Image.asset(
                      'assets/images/bitcoin.png',
                      width: constraints.maxWidth * bitcoinSize,
                      height: constraints.maxWidth * bitcoinSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.currency_bitcoin, color: Colors.amber, size: constraints.maxWidth * bitcoinSize);
                      },
                    ),
                  ),
                // Score
                Positioned(
                  left: 0,
                  right: 0,
                  top: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$playerScore', style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                      SizedBox(width: 32),
                      Text('$aiScore', style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold)),
                      SizedBox(width: 32),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/bitcoin.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.currency_bitcoin, color: Colors.amber),
                          ),
                          SizedBox(width: 4),
                          Text('$bitcoinCollected', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lives display (top left)
                Positioned(
                  top: 24,
                  left: 16,
                  child: Row(
                    children: List.generate(
                      lives,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.favorite, color: Colors.red, size: 28),
                      ),
                    ),
                  ),
                ),
                // Game over overlay (only if out of lives or win/lose)
                if (gameOver && lives > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              playerScore > aiScore ? 'You Win!' : 'You Lose!',
                              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _startGame();
                                });
                              },
                              child: Text('Play Again'),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Exit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CenterLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4;
    // Draw horizontal dashed line in the middle
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 16, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
