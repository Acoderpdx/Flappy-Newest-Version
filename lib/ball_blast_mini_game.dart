import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart'; // For ScrollingBackground

class BallBlastMiniGameScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final void Function()? onBitcoinCollected; // <-- Add this callback
  const BallBlastMiniGameScreen({Key? key, this.onClose, this.onBitcoinCollected}) : super(key: key);

  @override
  State<BallBlastMiniGameScreen> createState() => _BallBlastMiniGameScreenState();
}

class _BallBlastMiniGameScreenState extends State<BallBlastMiniGameScreen> {
  static const double cannonWidth = 60;
  static const double cannonHeight = 48;
  static const double projectileRadius = 8;
  static const double projectileSpeed = 9;
  static const double ballMinRadius = 22;
  static const double ballMaxRadius = 48;
  static const double gravity = 0.38;
  static const double ballGravity = 0.19; // Slower fall (was 0.38)
  static const double ballBounce = 0.92;  // Higher bounce (was 0.7)
  static const int initialBallHealth = 8;
  static const int maxRounds = 3;

  double cannonX = 0.5; // 0.0 (left) to 1.0 (right)
  double cannonVX = 0.0;
  bool movingLeft = false;
  bool movingRight = false;

  List<_Projectile> projectiles = [];
  List<_Ball> balls = [];
  int score = 0;
  bool gameOver = false;
  Timer? _timer;
  Random rand = Random();

  // For explosion particles
  List<_Particle> particles = [];

  Size? _lastSize;

  Timer? _autoShootTimer;

  int currentRound = 1;
  int ballsToClear = 0;
  bool roundTransition = false;

  int projectileColorIndex = 0; // Track which color to use next

  // --- Bitcoin collectible state ---
  List<_DroppedBitcoin> droppedBitcoins = [];
  int bitcoinCollected = 0; // <-- Track collected in this mini-game

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoShootTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      cannonX = 0.5;
      cannonVX = 0.0;
      movingLeft = false;
      movingRight = false;
      projectiles.clear();
      balls.clear();
      particles.clear();
      score = 0;
      gameOver = false;
      currentRound = 1;
      roundTransition = false;
      ballsToClear = _ballsForRound(1);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _gameLoop());

    // Start auto-shooting
    _autoShootTimer?.cancel();
    _autoShootTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!gameOver && !roundTransition) _shoot();
    });
  }

  int _ballsForRound(int round) {
    // 1st round: 3, 2nd: 4, 3rd: 6
    if (round == 1) return 3;
    if (round == 2) return 4;
    return 6;
  }

  double _gravityForRound(int round) {
    // Keep gravity constant for all rounds
    return ballGravity;
  }

  double _bounceForRound(int round) {
    // Keep bounce constant for all rounds
    return ballBounce;
  }

  void _gameLoop() {
    final size = _lastSize ?? MediaQuery.of(context).size;
    setState(() {
      if (roundTransition || gameOver) return;

      // Move cannon
      if (movingLeft) cannonVX = -0.018;
      else if (movingRight) cannonVX = 0.018;
      else cannonVX = 0.0;
      cannonX += cannonVX;
      cannonX = cannonX.clamp(0.0, 1.0);

      // Move projectiles
      for (final p in projectiles) {
        p.y -= projectileSpeed;
      }
      projectiles.removeWhere((p) => p.y < -20);

      // Move balls (all use isreal.png)
      for (final b in balls) {
        b.vy += _gravityForRound(currentRound);
        b.x += b.vx;
        b.y += b.vy;

        // Bounce off floor
        if (b.y + b.radius > size.height - cannonHeight) {
          b.y = size.height - cannonHeight - b.radius;
          b.vy = -b.vy * _bounceForRound(currentRound);
          if (b.vy.abs() < 1.5) b.vy = 0;
        }
        // Bounce off walls
        if (b.x - b.radius < 0) {
          b.x = b.radius;
          b.vx = -b.vx;
        }
        if (b.x + b.radius > size.width) {
          b.x = size.width - b.radius;
          b.vx = -b.vx;
        }
      }

      // Ball-projectile collision
      for (final b in balls) {
        for (final p in projectiles) {
          final dx = b.x - p.x;
          final dy = b.y - p.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < b.radius + projectileRadius) {
            b.health -= 1;
            b.radius = ballMinRadius + (ballMaxRadius - ballMinRadius) * (b.health / initialBallHealth);
            p.hit = true;
            if (b.health <= 0) {
              _explode(b.x, b.y, b.radius);
              b.destroyed = true;
              score += 1;
              // --- Drop a bitcoin at the ball's position ---
              droppedBitcoins.add(_DroppedBitcoin(
                x: b.x,
                y: b.y,
                vy: 2.5 + rand.nextDouble() * 1.5,
                vx: (rand.nextDouble() - 0.5) * 4, // add horizontal velocity
                collected: false,
              ));
            }
          }
        }
      }
      projectiles.removeWhere((p) => p.hit);

      // --- Move dropped bitcoins with bounce (use same logic as balls) ---
      for (final btc in droppedBitcoins) {
        if (!btc.collected) {
          btc.x += btc.vx;
          btc.y += btc.vy;
          btc.vy += _gravityForRound(currentRound);

          // Bounce off floor (same as balls)
          double floorY = size.height - cannonHeight;
          if (btc.y + 19 > floorY) { // 19 is half of bitcoin image (38x38)
            btc.y = floorY - 19;
            btc.vy = -btc.vy * _bounceForRound(currentRound);
            if (btc.vy.abs() < 1.2) btc.vy = 0;
          }

          // Bounce off walls (same as balls)
          if (btc.x - 19 < 0) {
            btc.x = 19;
            btc.vx = -btc.vx;
          }
          if (btc.x + 19 > size.width) {
            btc.x = size.width - 19;
            btc.vx = -btc.vx;
          }

          // Friction on ground
          if (btc.y + 19 >= floorY && btc.vy.abs() < 0.01) {
            btc.vx *= 0.95;
            if (btc.vx.abs() < 0.08) btc.vx = 0;
          }
        }
      }

      // --- Collect dropped bitcoins if bird.png (cannon) overlaps ---
      for (final btc in droppedBitcoins) {
        if (btc.collected) continue;
        // Cannon rectangle (bird.png)
        final cannonRect = Rect.fromLTWH(
          cannonX * size.width - cannonWidth / 2,
          size.height - cannonHeight,
          cannonWidth,
          cannonHeight,
        );
        // Bitcoin as a circle
        final btcCenter = Offset(btc.x, btc.y);
        final btcRadius = 19.0;
        // Check if the center of the bitcoin is inside the cannon rectangle
        if (cannonRect.contains(btcCenter)) {
          btc.collected = true;
          bitcoinCollected += 1;
          if (widget.onBitcoinCollected != null) widget.onBitcoinCollected!();
        } else {
          // More accurate: check if the circle overlaps the rectangle
          final closestX = btc.x.clamp(cannonRect.left, cannonRect.right);
          final closestY = btc.y.clamp(cannonRect.top, cannonRect.bottom);
          final dx = btc.x - closestX;
          final dy = btc.y - closestY;
          if ((dx * dx + dy * dy) <= (btcRadius * btcRadius)) {
            btc.collected = true;
            bitcoinCollected += 1;
            if (widget.onBitcoinCollected != null) widget.onBitcoinCollected!();
          }
        }
      }

      // Remove destroyed balls and spawn new ones up to ballsToClear
      int destroyedThisFrame = balls.where((b) => b.destroyed).length;
      balls.removeWhere((b) => b.destroyed);
      ballsToClear -= destroyedThisFrame;
      // Only allow up to ballsToClear balls at once
      while (balls.length < min(_ballsForRound(currentRound), ballsToClear) && !gameOver) {
        _spawnBall(size);
      }

      // Ball-cannon collision (game over if hit)
      for (final b in balls) {
        // Cannon rectangle (bird.png)
        final cannonRect = Rect.fromLTWH(
          cannonX * size.width - cannonWidth / 2,
          size.height - cannonHeight,
          cannonWidth,
          cannonHeight,
        );
        // Ball as a circle
        final ballCenter = Offset(b.x, b.y);
        final ballRadius = b.radius;
        // Find closest point on cannon rect to ball center
        final closestX = ballCenter.dx.clamp(cannonRect.left, cannonRect.right);
        final closestY = ballCenter.dy.clamp(cannonRect.top, cannonRect.bottom);
        final dx = ballCenter.dx - closestX;
        final dy = ballCenter.dy - closestY;
        // If distance < ball radius, collision
        if ((dx * dx + dy * dy) <= (ballRadius * ballRadius)) {
          gameOver = true;
          _timer?.cancel();
          _autoShootTimer?.cancel();
          break;
        }
      }

      // If all balls cleared, advance round or win
      if (ballsToClear <= 0 && !gameOver) {
        if (currentRound < maxRounds) {
          roundTransition = true;
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              currentRound++;
              ballsToClear = _ballsForRound(currentRound);
              roundTransition = false;
            });
          });
        } else {
          // Win game
          gameOver = true;
          _timer?.cancel();
          _autoShootTimer?.cancel();
        }
      }

      // Update particles
      for (final p in particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.18;
        p.life -= 1;
      }
      particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _spawnBall(Size size) {
    double x = rand.nextDouble() * (size.width - ballMaxRadius * 2) + ballMaxRadius;
    balls.add(_Ball(
      x: x,
      y: 0 + ballMaxRadius,
      vx: rand.nextDouble() * 4 - 2,
      vy: 0,
      radius: ballMaxRadius,
      health: initialBallHealth,
    ));
  }

  void _explode(double x, double y, double radius) {
    for (int i = 0; i < 18; i++) {
      double angle = rand.nextDouble() * 2 * pi;
      double speed = rand.nextDouble() * 4 + 2;
      particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: Colors.orangeAccent,
        life: 18 + rand.nextInt(10),
      ));
    }
  }

  void _shoot() {
    if (gameOver) return;
    final size = _lastSize ?? MediaQuery.of(context).size;
    // Alternate projectile color: 0=green, 1=red, 2=white, 3=black
    int colorIdx = projectileColorIndex % 4;
    projectileColorIndex++;
    projectiles.add(_Projectile(
      x: cannonX * size.width,
      y: size.height - cannonHeight - 10,
      colorIndex: colorIdx,
    ));
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      cannonX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    _lastSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Ball Blast Mini Game', style: TextStyle(color: Colors.white)),
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
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final cannonLeft = cannonX * size.width - cannonWidth / 2;
          final cannonTop = size.height - cannonHeight;
          return GestureDetector(
            onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, constraints),
            child: Stack(
              children: [
                // --- Add scrolling background ---
                Positioned.fill(
                  child: ScrollingBackground(scrollSpeed: 80.0),
                ),
                // Balls, projectiles, particles
                CustomPaint(
                  size: size,
                  painter: _BallBlastPainter(
                    projectiles: projectiles,
                    balls: balls,
                    particles: particles,
                  ),
                ),
                // Draw all balls as isreal.png images
                ...balls.map((b) {
                  final left = b.x - b.radius;
                  final top = b.y - b.radius;
                  final sizePx = b.radius * 2;
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        width: sizePx,
                        height: sizePx,
                        child: Image.asset(
                          'assets/images/isreal.png',
                          width: sizePx,
                          height: sizePx,
                        ),
                      ),
                      // Health counter to the right of the asset
                      Positioned(
                        left: left + sizePx + 4,
                        top: top + sizePx / 2 - (b.radius * 0.45),
                        child: Text(
                          '${b.health}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: b.radius * 0.9,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // --- Dropped bitcoins ---
                ...droppedBitcoins.where((btc) => !btc.collected).map((btc) {
                  return Positioned(
                    left: btc.x - 19,
                    top: btc.y - 19,
                    width: 38,
                    height: 38,
                    child: Image.asset(
                      'assets/images/bitcoin.png',
                      width: 38,
                      height: 38,
                    ),
                  );
                }),
                // Cannon (bird.png)
                Positioned(
                  left: cannonLeft,
                  top: cannonTop,
                  width: cannonWidth,
                  height: cannonHeight,
                  child: Image.asset(
                    'assets/images/bird.png',
                    width: cannonWidth,
                    height: cannonHeight,
                  ),
                ),
                // --- Bitcoin counter display (top right) ---
                Positioned(
                  top: 24,
                  right: 24,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/bitcoin.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.currency_bitcoin, color: Colors.amber),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$bitcoinCollected',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Score and round display
                Positioned(
                  left: 0,
                  right: 0,
                  top: 24,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Score: $score',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Round: $currentRound / $maxRounds',
                          style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (roundTransition)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'Round ${currentRound + 1} starting...',
                              style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (gameOver && currentRound == maxRounds && ballsToClear <= 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'You Win!',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Game over overlay
                if (gameOver)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (currentRound == maxRounds && ballsToClear <= 0)
                                  ? 'Victory!'
                                  : 'Game Over',
                              style: TextStyle(
                                  color: (currentRound == maxRounds && ballsToClear <= 0)
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Text('Score: $score', style: TextStyle(color: Colors.white, fontSize: 24)),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _startGame,
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

class _Projectile {
  double x, y;
  bool hit = false;
  final int colorIndex; // 0=green, 1=red, 2=white, 3=black
  _Projectile({required this.x, required this.y, required this.colorIndex});
}

class _Ball {
  double x, y, vx, vy, radius;
  int health;
  bool destroyed = false;
  _Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.health,
  });
}

class _Particle {
  double x, y, vx, vy;
  Color color;
  int life;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
  });
}

class _BallBlastPainter extends CustomPainter {
  final List<_Projectile> projectiles;
  final List<_Ball> balls;
  final List<_Particle> particles;

  _BallBlastPainter({
    required this.projectiles,
    required this.balls,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw projectiles
    for (final p in projectiles) {
      Paint projPaint;
      switch (p.colorIndex) {
        case 0:
          projPaint = Paint()..color = const Color(0xFF287f24); // green
          break;
        case 1:
          projPaint = Paint()..color = const Color(0xFFe5322c); // red
          break;
        case 2:
          projPaint = Paint()..color = Colors.white;
          break;
        case 3:
        default:
          projPaint = Paint()..color = Colors.black;
          break;
      }
      canvas.drawCircle(Offset(p.x, p.y), 8, projPaint);
    }

    // Draw particles
    for (final p in particles) {
      final partPaint = Paint()..color = p.color.withOpacity(p.life / 24.0);
      canvas.drawCircle(Offset(p.x, p.y), 5, partPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BallBlastPainter oldDelegate) => true;
}

// --- Helper class for dropped bitcoin ---
class _DroppedBitcoin {
  double x, y, vy, vx;
  bool collected;
  _DroppedBitcoin({
    required this.x,
    required this.y,
    required this.vy,
    required this.vx,
    this.collected = false,
  });
}
