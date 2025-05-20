import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class CrashMiniGame extends StatefulWidget {
  final int redPillCollected;
  final int lionsManeCollected;  // Add this to support Lions Mane collectable
  final Function(int) onRedPillsEarned;
  final VoidCallback onClose;
  final int currentRoundRedPills;

  const CrashMiniGame({
    Key? key,
    required this.redPillCollected,
    this.lionsManeCollected = 0,  // Default value, but allow passing
    required this.onRedPillsEarned,
    required this.onClose,
    this.currentRoundRedPills = 0,
  }) : super(key: key);

  @override
  _CrashMiniGameState createState() => _CrashMiniGameState();
}

class _CrashMiniGameState extends State<CrashMiniGame> {
  double _multiplier = 1.0;
  bool _isCrashed = false;
  bool _hasStarted = false;
  bool _hasCashedOut = false;
  double _cashedOutAt = 0.0;
  int _betAmount = 5; // Default bet amount
  int _redPillsAvailable = 0;
  int _lionsManeAvailable = 0;  // Add Lions Mane tracking
  Timer? _gameTimer;
  Random _random = Random();
  
  // Used for collectible type switching
  bool _useRedPills = true;  // Default to red pills
  
  // Streak tracking for more engaging gameplay patterns
  int _winningStreak = 0;
  int _losingStreak = 0;
  bool _isHotStreak = false;
  
  // Game balance and difficulty parameters - adjusted for more fun
  final double _baseHouseEdge = 0.01; // Dramatically reduced for more wins
  final double _maxHouseEdge = 0.04;
  double _currentHouseEdge = 0.01;
  
  // Growth parameters - more exciting curve
  double _baseGrowthPerSec = 1.0;
  final double _maxGrowthPerSec = 3.5;
  
  // Special round chances
  final double _luckyRoundChance = 0.15; // 15% chance of a lucky round
  final double _jackpotRoundChance = 0.05; // 5% chance of a huge multiplier potential
  final double _guaranteedMinChance = 0.35; // 35% chance of guaranteed 2x+
  
  // Excitement tracking
  bool _isHighRiskMode = false;
  bool _isAccelerating = false;
  
  // Round type flags
  bool _isLuckyRound = false;
  bool _isJackpotRound = false;
  bool _isGuaranteedWinRound = false;
  double? _presetCrashPoint;
  
  // Thresholds for visual effects
  final double _excitementThreshold = 3.0;
  final double _dangerThreshold = 5.0;
  
  // History of previous crashes
  List<double> _crashHistory = [];
  int _roundsPlayed = 0;
  int _roundsWon = 0;
  
  // UI animation variables
  double _shakeIntensity = 0.0;
  Timer? _shakeTimer;
  Color _crashLineColor = Colors.green;
  double _pulseAnimation = 0.0;
  Timer? _pulseTimer;
  
  @override
  void initState() {
    super.initState();
    _redPillsAvailable = widget.redPillCollected + widget.currentRoundRedPills;
    _lionsManeAvailable = widget.lionsManeCollected;
    _betAmount = _calculateDefaultBet();
    
    // Start with some realistic history data for display purposes
    _crashHistory = [
      1.15, 1.87, 3.54, 2.21, 1.34, 4.32, 10.78, 1.92, 1.05, 2.65
    ];
    
    // Start pulse animation for UI elements
    _startPulseAnimation();
    _determineRoundType();
  }

  int _calculateDefaultBet() {
    if (_useRedPills) {
      return _redPillsAvailable > 0 ? (_redPillsAvailable ~/ 10).clamp(1, 25) : 5;
    } else {
      return _lionsManeAvailable > 0 ? (_lionsManeAvailable ~/ 10).clamp(1, 25) : 5;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shakeTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }
  
  // Toggle between Red Pills and Lions Mane
  void _toggleCollectibleType() {
    if (_hasStarted) return; // Don't allow switching during a game
    
    setState(() {
      _useRedPills = !_useRedPills;
      _betAmount = _calculateDefaultBet();
    });
  }
  
  // Determine if this will be a special round
  void _determineRoundType() {
    // Reset round flags
    _isLuckyRound = false;
    _isJackpotRound = false;
    _isGuaranteedWinRound = false;
    _presetCrashPoint = null;
    
    double rand = _random.nextDouble();
    
    // Implement "hot streak" mechanics
    if (_winningStreak >= 2) {
      // During hot streaks, increase chance of another good round
      _isLuckyRound = rand < 0.25; // 25% chance during hot streak
      _isHotStreak = true;
    } else {
      // Normal lucky round chance
      _isLuckyRound = rand < _luckyRoundChance;
      _isHotStreak = false;
    }
    
    // Jackpot round implementation
    if (_random.nextDouble() < _jackpotRoundChance) {
      _isJackpotRound = true;
      _isLuckyRound = false; // Jackpot overrides lucky round
    }
    
    // Guaranteed win implementation (especially after losses)
    if (_losingStreak >= 3 || _random.nextDouble() < _guaranteedMinChance) {
      _isGuaranteedWinRound = true;
      // Set a minimum crash point between 2.0 and 3.5
      _presetCrashPoint = 2.0 + _random.nextDouble() * 1.5;
    }
    
    // Adaptive difficulty based on player performance
    _adjustDifficulty();
  }
  
  // Adjust game difficulty based on player performance
  void _adjustDifficulty() {
    // If player is on a winning streak, slightly increase difficulty
    if (_winningStreak > 3) {
      _currentHouseEdge = (_baseHouseEdge + (_winningStreak * 0.005)).clamp(_baseHouseEdge, _maxHouseEdge);
    } 
    // If player is on a losing streak, make the game easier
    else if (_losingStreak >= 2) {
      _currentHouseEdge = (_baseHouseEdge - (_losingStreak * 0.003)).clamp(0.001, _baseHouseEdge);
    }
    // Otherwise use base house edge
    else {
      _currentHouseEdge = _baseHouseEdge;
    }
  }
  
  void _startPulseAnimation() {
    _pulseTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _pulseAnimation = (_pulseAnimation + 0.1) % (2 * pi);
      });
    });
  }
  
  // Start shake animation when getting close to crash
  void _startShakeAnimation() {
    if (_shakeTimer != null) return;
    
    _shakeTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!_hasStarted || _isCrashed || _hasCashedOut) {
        _shakeTimer?.cancel();
        _shakeTimer = null;
        setState(() {
          _shakeIntensity = 0.0;
        });
        return;
      }
      
      // Increase shake as multiplier increases
      double intensity = ((_multiplier - _dangerThreshold) / 10).clamp(0.0, 1.0);
      setState(() {
        _shakeIntensity = intensity * 5.0 * _random.nextDouble();
      });
    });
  }
  
  void _startGame() {
    // Check if bet amount is valid
    if (_betAmount <= 0) return;
    
    // Check if player has enough of the selected collectible
    int availableAmount = _useRedPills ? _redPillsAvailable : _lionsManeAvailable;
    if (_betAmount > availableAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough ${_useRedPills ? 'Red Pills' : 'Lions Mane'} for this bet'))
      );
      return;
    }
    
    // Determine what type of round this will be
    _determineRoundType();
    
    // Deduct bet amount immediately
    setState(() {
      if (_useRedPills) {
        _redPillsAvailable -= _betAmount;
      } else {
        _lionsManeAvailable -= _betAmount;
      }
      _hasStarted = true;
      _isCrashed = false;
      _hasCashedOut = false;
      _multiplier = 1.0;
      _isAccelerating = false;
      _isHighRiskMode = false;
      _baseGrowthPerSec = _isLuckyRound ? 1.2 : 1.0;
      _shakeIntensity = 0.0;
    });
    
    // Calculate crash point before game starts for fairness
    final crashPoint = _calculateCrashPoint();
    print("DEBUG: Crash point for this round: $crashPoint");
    
    // Determine game timing parameters
    int updateFrequencyMs = 50; // 20 updates per second for smooth animation
    
    // Start the game loop
    _gameTimer?.cancel(); // Make sure any existing timer is canceled
    _gameTimer = Timer.periodic(Duration(milliseconds: updateFrequencyMs), (timer) {
      if (_multiplier >= crashPoint) {
        // Game crashes
        setState(() {
          _isCrashed = true;
          _crashHistory.add(_multiplier);
          if (_crashHistory.length > 10) {
            _crashHistory.removeAt(0);
          }
          
          // Update streak tracking
          _losingStreak++;
          _winningStreak = 0;
          
          // Update round statistics
          _roundsPlayed++;
          
          // Update UI colors
          _crashLineColor = Colors.red;
        });
        timer.cancel();
        
      } else if (!_isCrashed) {
        // Increase multiplier
        setState(() {
          // Get base growth for this tick
          double growthPerTick = _baseGrowthPerSec * updateFrequencyMs / 1000;
          
          // Accelerating growth curve for excitement
          if (_multiplier > 1.5 && _multiplier < 3.0) {
            growthPerTick *= 1.05 + (_multiplier - 1.5) * 0.1;
          } else if (_multiplier >= 3.0) {
            growthPerTick *= 1.2 + (_multiplier - 3.0) * 0.05;
            _isAccelerating = true;
            
            // Make it riskier-looking past danger threshold
            if (_multiplier >= _dangerThreshold) {
              _isHighRiskMode = true;
              // Start shake animation when getting risky
              if (_shakeTimer == null) {
                _startShakeAnimation();
              }
            }
          }
          
          // Apply growth
          _multiplier += growthPerTick;
          
          // Increase base growth rate over time to create excitement
          if (_baseGrowthPerSec < _maxGrowthPerSec) {
            _baseGrowthPerSec += 0.002;
          }
        });
      }
    });
  }

  // NEW: Reset game state to allow playing again
  void _resetGame() {
    setState(() {
      // Reset game state variables
      _isCrashed = false;
      _hasStarted = false;
      _hasCashedOut = false;
      _multiplier = 1.0;
      _isAccelerating = false;
      _isHighRiskMode = false;
      _shakeIntensity = 0.0;
      _baseGrowthPerSec = 1.0;
      
      // Cancel any active timers
      _gameTimer?.cancel();
      _shakeTimer?.cancel();
      
      // Reset bet amount to default
      _betAmount = _calculateDefaultBet();
      
      // Determine new round type
      _determineRoundType();
    });
  }

  // Improved crash point calculation algorithm for more fun and engagement
  double _calculateCrashPoint() {
    // If this is a preset outcome round, use that value
    if (_presetCrashPoint != null) {
      return _presetCrashPoint!;
    }
    
    // Basic crash algorithm with adjustable house edge
    double r = _random.nextDouble();
    
    // Base formula with dynamic house edge for hot/cold streaks
    double houseEdge = _currentHouseEdge;
    double crashPoint;
    
    // Lucky rounds have very low house edge
    if (_isLuckyRound) {
      houseEdge *= 0.3; // 70% reduction in house edge
    }
    
    // Jackpot rounds have special high multiplier potential
    if (_isJackpotRound) {
      // 10-100x potential with exponential distribution
      double jackpotValue = -10.0 * log(1.0 - (_random.nextDouble() * 0.98));
      return max(jackpotValue, 10.0).clamp(10.0, 100.0);
    }
    
    // Default crash point calculation with adjusted parameters 
    double baseValue = 0.1 / (houseEdge * (1.0 - r));
    crashPoint = max(1.0, baseValue);
    
    // Make sure we get plenty of rounds in the 2x-5x sweet spot
    if (crashPoint < 1.2) { 
      // 50% of subpar rounds get bumped up to 2x-5x
      if (_random.nextDouble() < 0.5) {
        crashPoint = 2.0 + _random.nextDouble() * 3.0;
      }
    }
    
    // Add occasional extreme multipliers for excitement
    if (_random.nextDouble() < 0.08) { // 8% chance
      double bonus = _random.nextDouble() * 15.0;
      crashPoint += bonus;
    }
    
    // Create round number attractions (e.g. 2.00x, 3.00x) for psychological appeal
    if (_random.nextDouble() < 0.15) { // 15% chance
      crashPoint = crashPoint.roundToDouble();
    }
    
    // Make sure we never return below 1.01x
    return max(1.01, crashPoint);
  }

  void _cashOut() {
    if (!_hasStarted || _isCrashed || _hasCashedOut) return;
    
    setState(() {
      _hasCashedOut = true;
      _cashedOutAt = _multiplier;
      
      // Calculate winnings
      int winnings = (_betAmount * _multiplier).floor();
      
      // Add winnings to appropriate collection
      if (_useRedPills) {
        _redPillsAvailable += winnings;
        
        // Report net winnings (subtract original bet amount) to parent component
        int netWinnings = winnings - _betAmount;
        widget.onRedPillsEarned(netWinnings);
      } else {
        _lionsManeAvailable += winnings;
        // Note: We don't have a callback for Lions Mane yet, could add in future
      }
      
      // Update streak tracking
      _winningStreak++;
      _losingStreak = 0;
      
      // Update round statistics
      _roundsPlayed++;
      _roundsWon++;
      
      // Update UI colors
      _crashLineColor = Colors.green;
      
      // Confirmation message
      String collectibleType = _useRedPills ? "Red Pills" : "Lions Mane";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully cashed out $winnings $collectibleType!'))
      );
    });
    
    // Game continues running in the background after cashing out
  }
  
  // Helper methods for UI
  void _increaseBet() {
    setState(() {
      int availableAmount = _useRedPills ? _redPillsAvailable : _lionsManeAvailable;
      if (_betAmount < availableAmount) {
        // Increase by 5 or 20% of available, whichever is smaller
        int increment = min(5, (availableAmount * 0.2).ceil());
        _betAmount += increment;
      }
    });
  }

  void _decreaseBet() {
    setState(() {
      if (_betAmount > 5) {
        _betAmount -= 5;
      } else if (_betAmount > 1) {
        _betAmount = 1;  // Allow reducing to minimum bet of 1
      }
    });
  }

  // Format multiplier with appropriate precision based on value
  String _formatMultiplier(double value) {
    if (value >= 10) {
      return value.toStringAsFixed(1) + 'x';
    } else {
      return value.toStringAsFixed(2) + 'x';
    }
  }
  
  // Get appropriate color for the multiplier display
  Color _getMultiplierColor() {
    if (_isCrashed) return Colors.red;
    if (_hasCashedOut) return Colors.green;
    
    // Dynamic color based on current multiplier
    if (_multiplier >= _dangerThreshold) {
      return Colors.red.shade400;
    } else if (_multiplier >= _excitementThreshold) {
      return Colors.orange;
    } else if (_multiplier >= 2.0) {
      return Colors.green;
    } else {
      return Colors.white;
    }
  }
  
  // Get background color for the multiplier display
  Color _getMultiplierBackgroundColor() {
    if (_isCrashed) return Colors.red.withOpacity(0.3);
    if (_hasCashedOut) return Colors.green.withOpacity(0.3);
    
    if (_isHighRiskMode) {
      // Pulsate between red shades for excitement
      double t = (sin(_pulseAnimation) + 1) / 2; // 0 to 1
      return Color.lerp(
        Colors.red.shade900.withOpacity(0.7),
        Colors.red.shade700.withOpacity(0.5),
        t
      )!;
    } else if (_isAccelerating) {
      return Colors.orange.withOpacity(0.3);
    } else {
      return Colors.black.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get image path and name for current collectible type
    final String collectibleImagePath = _useRedPills 
        ? 'assets/images/red_pill.png' 
        : 'assets/images/lions_mane.png';
    
    final String collectibleName = _useRedPills ? 'Red Pills' : 'Lions Mane';
    final int availableAmount = _useRedPills ? _redPillsAvailable : _lionsManeAvailable;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Crash Game', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onClose,
        ),
        actions: [
          // Add toggle button to switch between Red Pills and Lions Mane
          IconButton(
            icon: Image.asset(
              collectibleImagePath,
              width: 24,
              height: 24,
            ),
            onPressed: _hasStarted ? null : _toggleCollectibleType,
            tooltip: 'Switch to ${_useRedPills ? 'Lions Mane' : 'Red Pills'}',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section with collectible count and bet controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Collectible balance
                  Row(
                    children: [
                      Image.asset(
                        collectibleImagePath,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, color: Colors.amber, size: 24);
                        },
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$availableAmount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Bet amount controls
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.white),
                        onPressed: _hasStarted ? null : _decreaseBet,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BET: $_betAmount',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.white),
                        onPressed: _hasStarted ? null : _increaseBet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Win rate display
            if (_roundsPlayed > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Win Rate: ${(_roundsWon / _roundsPlayed * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            
            // Main display showing crash multiplier
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Crash graph visualization
                    CustomPaint(
                      size: Size(double.infinity, double.infinity),
                      painter: CrashGraphPainter(
                        multiplier: _multiplier,
                        isCrashed: _isCrashed,
                        lineColor: _crashLineColor,
                        isHighRiskMode: _isHighRiskMode,
                        pulseAnimation: _pulseAnimation,
                      ),
                    ),
                    
                    // Center multiplier display with shake animation
                    Center(
                      child: Transform.translate(
                        offset: _isHighRiskMode ? 
                          Offset(_random.nextDouble() * _shakeIntensity - _shakeIntensity/2,
                                _random.nextDouble() * _shakeIntensity - _shakeIntensity/2) : 
                          Offset.zero,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _getMultiplierBackgroundColor(),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getMultiplierColor().withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: _getMultiplierColor().withOpacity(0.7),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isCrashed 
                                  ? 'CRASHED!' 
                                  : (_hasCashedOut ? 'CASHED OUT' : 'MULTIPLIER'),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _hasCashedOut 
                                  ? _formatMultiplier(_cashedOutAt)
                                  : _formatMultiplier(_multiplier),
                                style: TextStyle(
                                  color: _getMultiplierColor(),
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: _getMultiplierColor().withOpacity(0.7),
                                      offset: Offset(0, 0),
                                    ),
                                  ],
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
            
            // Previous rounds history
            Container(
              height: 60,
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'HISTORY:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _crashHistory.length,
                      itemBuilder: (context, index) {
                        final item = _crashHistory[_crashHistory.length - 1 - index];
                        Color bgColor;
                        if (item >= 10) {
                          bgColor = Colors.purple.withOpacity(0.7); // Exceptional
                        } else if (item >= 5) {
                          bgColor = Colors.blue.withOpacity(0.7); // Very good
                        } else if (item >= 2) {
                          bgColor = Colors.green.withOpacity(0.7); // Good
                        } else if (item >= 1.5) {
                          bgColor = Colors.amber.withOpacity(0.7); // Moderate
                        } else {
                          bgColor = Colors.red.withOpacity(0.7); // Bad
                        }
                        
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: bgColor.withOpacity(0.5),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _formatMultiplier(item),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCrashed ? Colors.blue : (_hasStarted ? Colors.grey : Colors.green),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      // Updated onPressed logic:
                      // If crashed, reset the game
                      // If game is running or cashed out, button is disabled
                      // If game hasn't started, start a new game
                      onPressed: _isCrashed ? 
                        _resetGame : 
                        ((!_hasStarted && availableAmount >= _betAmount) ? _startGame : null),
                      child: Text(
                        _isCrashed ? 'PLAY AGAIN' : 'START',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (!_hasStarted || _isCrashed || _hasCashedOut) 
                            ? Colors.grey 
                            : Colors.amber,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: (!_hasStarted || _isCrashed || _hasCashedOut) 
                          ? null 
                          : _cashOut,
                      child: Text(
                        'CASH OUT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CrashGraphPainter extends CustomPainter {
  final double multiplier;
  final bool isCrashed;
  final Color lineColor;
  final bool isHighRiskMode;
  final double pulseAnimation;
  
  CrashGraphPainter({
    required this.multiplier,
    required this.isCrashed,
    required this.lineColor,
    required this.isHighRiskMode,
    required this.pulseAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid
    _drawGrid(canvas, size);
    
    // Draw crash line
    _drawCrashLine(canvas, size);
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;
      
    // Draw horizontal lines
    for (int i = 1; i <= 10; i++) {
      final y = size.height - (size.height * i / 10);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw vertical lines
    for (int i = 1; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  void _drawCrashLine(Canvas canvas, Size size) {
    // Use a more exciting color scheme based on risk level
    Color baseColor = lineColor;
    if (isHighRiskMode && !isCrashed) {
      // Create flaming effect for high risk mode
      double t = (sin(pulseAnimation) + 1) / 2; // 0 to 1
      baseColor = Color.lerp(Colors.red, Colors.orange, t)!;
    }
    
    final paint = Paint()
      ..color = baseColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    // Background glow for high risk mode
    if (isHighRiskMode && !isCrashed) {
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(0.3)
        ..strokeWidth = 7.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      // Draw the glow effect
      _drawCrashCurve(canvas, size, glowPaint);
    }
    
    // Fill area beneath curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0.3),
          baseColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    // Draw fill and line
    _drawCrashArea(canvas, size, fillPaint);
    _drawCrashCurve(canvas, size, paint);
    
    // Draw crash indicator if crashed
    if (isCrashed) {
      _drawCrashIndicator(canvas, size);
    }
  }
  
  void _drawCrashCurve(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    
    // Starting point at bottom left
    path.moveTo(0, size.height);
    
    // Calculate how far along the curve to draw based on current multiplier
    // Cap at 20x for visual purposes, log scale after that
    final maxVisibleMultiplier = 20.0;
    final visibleMultiplier = min(multiplier, maxVisibleMultiplier);
    final progressRatio = (visibleMultiplier - 1.0) / (maxVisibleMultiplier - 1.0);
    
    // Draw exponential curve with more dramatic shape
    for (double i = 0; i <= progressRatio; i += 0.01) {
      // Use a more dramatic curve shape
      final x = i * size.width;
      final normalizedY = 1.0 - pow(i, 0.7); // More dramatic than linear
      final y = normalizedY * size.height;
      
      // Add small random variations to make the line more interesting
      final wobble = isHighRiskMode ? sin(i * 50) * 2 : 0.0;
      
      path.lineTo(x, y + wobble);
    }
    
    // Draw the path
    canvas.drawPath(path, paint);
  }
  
  void _drawCrashArea(Canvas canvas, Size size, Paint fillPaint) {
    final path = Path();
    
    // Starting point at bottom left
    path.moveTo(0, size.height);
    
    // Calculate how far along the curve to draw
    final maxVisibleMultiplier = 20.0;
    final visibleMultiplier = min(multiplier, maxVisibleMultiplier);
    final progressRatio = (visibleMultiplier - 1.0) / (maxVisibleMultiplier - 1.0);
    
    // Draw the top edge following the curve
    for (double i = 0; i <= progressRatio; i += 0.01) {
      final x = i * size.width;
      final normalizedY = 1.0 - pow(i, 0.7);
      final y = normalizedY * size.height;
      path.lineTo(x, y);
    }
    
    // Complete the fill path
    path.lineTo(progressRatio * size.width, size.height);
    path.close();
    
    // Draw fill
    canvas.drawPath(path, fillPaint);
  }
  
  void _drawCrashIndicator(Canvas canvas, Size size) {
    // Calculate end position of curve
    final maxVisibleMultiplier = 20.0;
    final visibleMultiplier = min(multiplier, maxVisibleMultiplier);
    final progressRatio = (visibleMultiplier - 1.0) / (maxVisibleMultiplier - 1.0);
    final x = progressRatio * size.width;
    final normalizedY = 1.0 - pow(progressRatio, 0.7);
    final y = normalizedY * size.height;
    
    // Draw crash explosion effect
    final explosionPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(x, y), 10, explosionPaint);
    
    // Draw "CRASH!" text with dynamic sizing
    final fontSize = min(24.0, size.width / 15);
    final textSpan = TextSpan(
      text: "CRASH!",
      style: TextStyle(
        color: Colors.red,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 3.0,
            color: Colors.black,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height - 15));
  }
  
  @override
  bool shouldRepaint(CrashGraphPainter oldDelegate) {
    return multiplier != oldDelegate.multiplier ||
        isCrashed != oldDelegate.isCrashed ||
        lineColor != oldDelegate.lineColor ||
        isHighRiskMode != oldDelegate.isHighRiskMode ||
        pulseAnimation != oldDelegate.pulseAnimation;
  }
}
