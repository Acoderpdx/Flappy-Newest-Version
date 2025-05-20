import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // Import for ScrollingBackground

// Ball class for tracking properties
class Ball {
  double x, y, size;
  double speedX, speedY;
  
  Ball({
    required this.x, 
    required this.y, 
    required this.size,
    required this.speedX,
    required this.speedY
  });
}

// Move the enum outside of any class - this fixes the error
enum SoundEffect { paddleHit, wallHit, score, ethCollected }

class PongMiniGameScreen extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onEthereumCollected;

  const PongMiniGameScreen({
    Key? key,
    required this.onClose,
    required this.onEthereumCollected,
  }) : super(key: key);

  @override
  State<PongMiniGameScreen> createState() => _PongMiniGameScreenState();
}

class _PongMiniGameScreenState extends State<PongMiniGameScreen> with TickerProviderStateMixin {
  // Game state variables
  bool _gameStarted = false;
  bool _gameOver = false;
  int _playerScore = 0;
  int _computerScore = 0;
  
  // Game size - will be set in initState based on screen size
  late double _gameWidth;
  late double _gameHeight;
  
  // Ball properties - classic Pong has constant speed
  late Ball _ball;
  final double _ballSize = 15.0;
  final double _ballSpeed = 5.0;  // Constant ball speed
  
  // Paddle properties - fixed sizes for classic feel
  late double _playerPaddleX;
  late double _playerPaddleY;
  final double _paddleWidth = 100.0;   // Fixed width for both paddles
  final double _paddleHeight = 15.0;
  
  // Computer paddle properties
  late double _computerPaddleX;
  late double _computerPaddleY;
  final double _computerAiSpeed = 0.7;  // Speed multiplier for computer paddle movement
  
  // Ethereum collectible properties
  bool _ethVisible = false;
  late double _ethX;
  late double _ethY;
  final double _ethSize = 30.0;
  Timer? _ethSpawnTimer;
  
  // Visual effects
  bool _showHitEffect = false;
  double _hitEffectX = 0;
  double _hitEffectY = 0;
  double _hitEffectSize = 0;
  Timer? _hitEffectTimer;
  
  // Animation controllers
  late AnimationController _gameLoopController;
  late AnimationController _countdownController;
  late AnimationController _ethBounceController;
  
  // Camera shake
  bool _cameraShaking = false;
  double _cameraOffsetX = 0;
  double _cameraOffsetY = 0;
  Timer? _cameraShakeTimer;
  
  // Random number generator
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controllers
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _ethBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Initialize game state after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }
  
  void _initializeGame() {
    // Get screen dimensions for game size
    final size = MediaQuery.of(context).size;
    _gameWidth = size.width;
    _gameHeight = size.height - 200; // Leave some space for UI
    
    // Initialize positions
    _resetPositions();
    
    // Start countdown to game start
    _startCountdown();
  }
  
  void _resetPositions() {
    // Start the ball in the center with a random direction
    double angle = (_random.nextDouble() * 0.5 + 0.25) * pi; // 45° to 135° (more vertical)
    if (_random.nextBool()) angle = pi - angle; // Flip direction randomly
    
    _ball = Ball(
      x: _gameWidth / 2 - _ballSize / 2,
      y: _gameHeight / 2 - _ballSize / 2,
      size: _ballSize,
      speedX: _ballSpeed * cos(angle),
      speedY: _ballSpeed * sin(angle),
    );
    
    // Position player paddle at bottom center
    _playerPaddleX = _gameWidth / 2 - _paddleWidth / 2;
    _playerPaddleY = _gameHeight - 40;
    
    // Position computer paddle at top center
    _computerPaddleX = _gameWidth / 2 - _paddleWidth / 2;
    _computerPaddleY = 40;
    
    // Hide ETH initially
    _ethVisible = false;
  }
  
  void _startCountdown() {
    // Reset the countdown controller
    _countdownController.reset();
    
    // Add a listener to start the game when countdown finishes
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startGame();
      }
    });
    
    // Start the countdown
    _countdownController.forward();
  }
  
  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _playerScore = 0;
      _computerScore = 0;
    });
    
    // Start the game loop
    _gameLoopController.repeat();
    
    // Schedule Ethereum spawn
    _scheduleEthereumSpawn();
  }
  
  void _scheduleEthereumSpawn() {
    // Cancel any existing timer
    _ethSpawnTimer?.cancel();
    
    // Schedule a new spawn in 5-15 seconds
    _ethSpawnTimer = Timer(
      Duration(seconds: 5 + _random.nextInt(10)),
      _spawnEthereum,
    );
  }
  
  void _spawnEthereum() {
    if (!mounted || _gameOver) return;
    
    setState(() {
      // Position Ethereum randomly, away from edges
      _ethX = 50 + _random.nextDouble() * (_gameWidth - 100);
      _ethY = 100 + _random.nextDouble() * (_gameHeight - 200);
      _ethVisible = true;
    });
  }
  
  void _gameLoop() {
    if (!_gameStarted || _gameOver || !mounted) return;
    
    setState(() {
      // Update ball position
      _ball.x += _ball.speedX;
      _ball.y += _ball.speedY;
      
      // Check wall collisions (sides)
      if (_ball.x <= 0 || _ball.x + _ball.size >= _gameWidth) {
        _ball.speedX = -_ball.speedX;
        _playSound(SoundEffect.wallHit);
      }
      
      // Check if ball hits top (player scores)
      if (_ball.y <= 0) {
        _playerScore++;
        _resetPositions();
        _playSound(SoundEffect.score);
        
        // Spawn new Ethereum collectible when player scores
        _spawnEthereum();
        
        // Check for win
        if (_playerScore >= 11) {
          _gameOver = true;
          _gameLoopController.stop();
        }
        return;
      }
      
      // Check if ball hits bottom (computer scores)
      if (_ball.y + _ball.size >= _gameHeight) {
        _computerScore++;
        _resetPositions();
        _playSound(SoundEffect.score);
        
        // Check for game over
        if (_computerScore >= 11) {
          _gameOver = true;
          _gameLoopController.stop();
        }
        return;
      }
      
      // Check collision with player paddle - SIMPLIFIED CLASSIC PHYSICS
      if (_ball.y + _ball.size >= _playerPaddleY &&
          _ball.y <= _playerPaddleY + _paddleHeight &&
          _ball.x + _ball.size >= _playerPaddleX &&
          _ball.x <= _playerPaddleX + _paddleWidth) {
        
        // Show hit effect
        _showBallHitEffect(_ball.x + _ball.size/2, _playerPaddleY);
        
        // Apply camera shake on hit
        _applyCameraShake(1.0);
        
        // Play paddle hit sound
        _playSound(SoundEffect.paddleHit);
        
        // Classic Pong: Bounce angle depends on where the ball hits the paddle
        double hitPosition = (_ball.x + _ball.size/2 - _playerPaddleX) / _paddleWidth; // 0.0 to 1.0
        
        // Transform hitPosition to -1.0 to 1.0 range (left to right)
        hitPosition = (hitPosition * 2.0) - 1.0;
        
        // Maximum angle in radians (approx 60 degrees)
        double maxAngle = pi / 3.0;
        
        // Calculate new angle based on hit position (-maxAngle to maxAngle)
        double angle = hitPosition * maxAngle;
        
        // Set new velocity components while maintaining constant speed
        _ball.speedY = -_ballSpeed * cos(angle); // Negative to go upward
        _ball.speedX = _ballSpeed * sin(angle);
        
        // Ensure the ball doesn't get stuck in the paddle
        _ball.y = _playerPaddleY - _ball.size - 1;
      }
      
      // Check collision with computer paddle - SIMPLIFIED CLASSIC PHYSICS
      if (_ball.y <= _computerPaddleY + _paddleHeight &&
          _ball.y + _ball.size >= _computerPaddleY &&
          _ball.x + _ball.size >= _computerPaddleX &&
          _ball.x <= _computerPaddleX + _paddleWidth) {
        
        // Show hit effect
        _showBallHitEffect(_ball.x + _ball.size/2, _computerPaddleY + _paddleHeight);
        
        // Apply camera shake on hit
        _applyCameraShake(1.0);
        
        // Play paddle hit sound
        _playSound(SoundEffect.paddleHit);
        
        // Classic Pong: Bounce angle depends on where the ball hits the paddle
        double hitPosition = (_ball.x + _ball.size/2 - _computerPaddleX) / _paddleWidth; // 0.0 to 1.0
        
        // Transform hitPosition to -1.0 to 1.0 range (left to right)
        hitPosition = (hitPosition * 2.0) - 1.0;
        
        // Maximum angle in radians (approx 60 degrees)
        double maxAngle = pi / 3.0;
        
        // Calculate new angle based on hit position (-maxAngle to maxAngle)
        double angle = hitPosition * maxAngle;
        
        // Set new velocity components while maintaining constant speed
        _ball.speedY = _ballSpeed * cos(angle); // Positive to go downward 
        _ball.speedX = _ballSpeed * sin(angle);
        
        // Ensure the ball doesn't get stuck in the paddle
        _ball.y = _computerPaddleY + _paddleHeight + 1;
      }
      
      // Move computer paddle - SIMPLIFIED AI
      _moveComputerPaddle();
      
      // Check collision with Ethereum collectible
      if (_ethVisible) {
        // Create hit boxes for ball and ETH
        final ballRect = Rect.fromLTWH(_ball.x, _ball.y, _ball.size, _ball.size);
        final ethRect = Rect.fromLTWH(_ethX, _ethY, _ethSize, _ethSize);
        
        if (ballRect.overlaps(ethRect)) {
          // Collect Ethereum
          _ethVisible = false;
          widget.onEthereumCollected();
          
          // Show hit effect
          _showBallHitEffect(_ethX + _ethSize/2, _ethY + _ethSize/2);
          
          // Play collect sound
          _playSound(SoundEffect.ethCollected);
          
          // Schedule next spawn
          _scheduleEthereumSpawn();
        }
      }
    });
  }
  
  void _moveComputerPaddle() {
    // Simple AI: Track the ball's horizontal position
    
    // Predict where the ball will be to make AI competitive
    double targetX = _ball.x + _ball.size/2 - _paddleWidth/2;
    
    // Only move when ball is coming toward computer (moving upward)
    if (_ball.speedY < 0) {
      double diff = targetX - _computerPaddleX;
      
      // Move toward target at limited speed
      _computerPaddleX += diff * _computerAiSpeed;
      
      // Keep paddle within game bounds
      _computerPaddleX = _computerPaddleX.clamp(0, _gameWidth - _paddleWidth);
    }
  }
  
  void _movePlayerPaddle(double dx) {
    if (!_gameStarted || _gameOver) return;
    
    setState(() {
      _playerPaddleX += dx;
      // Keep paddle within bounds
      _playerPaddleX = _playerPaddleX.clamp(0, _gameWidth - _paddleWidth);
    });
  }
  
  void _showBallHitEffect(double x, double y) {
    setState(() {
      _showHitEffect = true;
      _hitEffectX = x;
      _hitEffectY = y;
      _hitEffectSize = 10.0;
    });
    
    _hitEffectTimer?.cancel();
    _hitEffectTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _hitEffectSize += 2.0;
        if (_hitEffectSize > 40) {
          _showHitEffect = false;
          timer.cancel();
        }
      });
    });
  }
  
  void _applyCameraShake(double intensity) {
    // Don't apply if already shaking
    if (_cameraShaking) return;
    
    _cameraShaking = true;
    
    // Cancel any existing timer
    _cameraShakeTimer?.cancel();
    
    // Create new timer for camera shake
    int shakeDuration = 150; // ms
    int steps = shakeDuration ~/ 16; // ~60fps
    int currentStep = 0;
    
    _cameraShakeTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        _cameraShaking = false;
        return;
      }
      
      setState(() {
        if (currentStep < steps) {
          // Calculate shake intensity that decreases over time
          double progress = currentStep / steps;
          double decreasingIntensity = intensity * (1.0 - progress);
          
          // Random offsets
          _cameraOffsetX = (_random.nextDouble() * 2 - 1) * decreasingIntensity * 5;
          _cameraOffsetY = (_random.nextDouble() * 2 - 1) * decreasingIntensity * 5;
          
          currentStep++;
        } else {
          // End shake
          _cameraOffsetX = 0;
          _cameraOffsetY = 0;
          _cameraShaking = false;
          timer.cancel();
        }
      });
    });
  }
  
  void _restartGame() {
    _resetPositions();
    _startCountdown();
  }
  
  // Simple sound effect player - removed the enum declaration
  void _playSound(SoundEffect effect) {
    // Play haptic feedback as a substitute for sound
    switch (effect) {
      case SoundEffect.paddleHit:
        HapticFeedback.lightImpact();
        break;
      case SoundEffect.wallHit:
        HapticFeedback.selectionClick();
        break;
      case SoundEffect.score:
        HapticFeedback.mediumImpact();
        break;
      case SoundEffect.ethCollected:
        HapticFeedback.heavyImpact();
        break;
    }
    // In a real game, you would use something like:
    // audioPlayer.play('sounds/${effect.toString().split('.').last}.wav');
  }
  
  @override
  void dispose() {
    _gameLoopController.dispose();
    _countdownController.dispose();
    _ethBounceController.dispose();
    _hitEffectTimer?.cancel();
    _ethSpawnTimer?.cancel();
    _cameraShakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Ethereum Pong', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onClose,
        ),
      ),
      body: Stack(
        children: [
          // Scrolling background
          Positioned.fill(
            child: ScrollingBackground(scrollSpeed: 80.0),
          ),
          
          // Game area with camera shake
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(_cameraOffsetX, _cameraOffsetY),
              child: Column(
                children: [
                  // Score display
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Computer: $_computerScore',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 30),
                        Text(
                          'You: $_playerScore',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Game board
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        _movePlayerPaddle(details.delta.dx * 1.3); // 1.3x multiplier for responsive control
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            // Center line
                            Positioned(
                              left: 0,
                              right: 0,
                              top: _gameHeight / 2,
                              child: Container(
                                height: 2,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            
                            // Ball
                            Positioned(
                              left: _ball.x,
                              top: _ball.y,
                              child: Container(
                                width: _ball.size,
                                height: _ball.size,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white70,
                                      blurRadius: 10.0,
                                      spreadRadius: 2.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Hit effect
                            if (_showHitEffect)
                              Positioned(
                                left: _hitEffectX - _hitEffectSize/2,
                                top: _hitEffectY - _hitEffectSize/2,
                                width: _hitEffectSize,
                                height: _hitEffectSize,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(1.0 - _hitEffectSize/40),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Player paddle
                            Positioned(
                              left: _playerPaddleX,
                              top: _playerPaddleY,
                              child: Container(
                                width: _paddleWidth,
                                height: _paddleHeight,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Computer paddle
                            Positioned(
                              left: _computerPaddleX,
                              top: _computerPaddleY,
                              child: Container(
                                width: _paddleWidth,
                                height: _paddleHeight,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.red.shade400, Colors.red.shade700],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Ethereum collectible with bounce animation
                            if (_ethVisible)
                              Positioned(
                                left: _ethX,
                                top: _ethY,
                                child: AnimatedBuilder(
                                  animation: _ethBounceController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 0.9 + 0.2 * sin(_ethBounceController.value * 3.14),
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/images/eth.png',
                                    width: _ethSize,
                                    height: _ethSize,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: _ethSize,
                                      height: _ethSize,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'ETH',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Countdown overlay
                            if (!_gameStarted && !_gameOver)
                              Center(
                                child: AnimatedBuilder(
                                  animation: _countdownController,
                                  builder: (context, child) {
                                    // Calculate countdown number (3,2,1)
                                    int countdown = 3 - (_countdownController.value * 3).floor();
                                    
                                    // Show "GO" when countdown reaches 0
                                    String text = countdown > 0 ? countdown.toString() : 'GO!';
                                    
                                    return Text(
                                      text,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: countdown > 0 ? 72 : 64,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.blue.withOpacity(0.8),
                                            blurRadius: 10.0,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            
                            // Game over overlay
                            if (_gameOver)
                              Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'GAME OVER',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _playerScore > _computerScore 
                                            ? 'You Win! $_playerScore - $_computerScore' 
                                            : 'Computer Wins $_computerScore - $_playerScore',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      ElevatedButton(
                                        onPressed: _restartGame,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 15,
                                          ),
                                        ),
                                        child: const Text(
                                          'Play Again',
                                          style: TextStyle(
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Game instructions (only before first game)
                            if (!_gameStarted && !_gameOver)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 50,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Swipe left/right to move your paddle\n'
                                      'First to 11 points wins\n'
                                      'Collect Ethereum for bonus rewards',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // ETH collectible hint
                            if (_ethVisible)
                              Positioned(
                                top: _ethY - 30,
                                left: _ethX - 10,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ETH',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
