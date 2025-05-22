import 'dart:async';
import 'dart:math';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'main.dart'; // For ScrollingBackground

class CrashMiniGameScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final Function(String, int) onCollectibleChange;
  final VoidCallback? onClose;

  const CrashMiniGameScreen({
    Key? key, 
    this.lionsManeCollected = 0,
    this.redPillCollected = 0,
    this.bitcoinCollected = 0,
    required this.onCollectibleChange,
    this.onClose,
  }) : super(key: key);

  @override
  State<CrashMiniGameScreen> createState() => _CrashMiniGameScreenState();
}

class _CrashMiniGameScreenState extends State<CrashMiniGameScreen> {
  // Game state variables
  double multiplier = 1.0;
  bool gameRunning = false;
  bool gameOver = false;
  bool userCashedOut = false;
  Timer? gameTimer;
  
  // Current round tracking variables
  int _currentRoundRedPills = 0;
  int _currentRoundLionsMane = 0;
  
  // Cash out variables
  int _redPillsCashedOut = 0;
  int _lionsManeCashedOut = 0;
  
  // Local balance tracking
  int _localLionsManeBet = 0;
  int _localRedPillBet = 0;
  
  // Betting option
  String _selectedBet = 'RedPill'; // 'RedPill' or 'LionsMane'
  
  // Enhanced gameplay variables
  List<double> _graphPoints = [];
  List<Map<String, dynamic>> _gameHistory = [];
  final int _maxHistoryItems = 10;
  final int _maxGraphPoints = 100;
  
  // Auto cash-out feature
  double _autoCashOutValue = 2.0;
  bool _autoEnabled = false;
  TextEditingController _autoCashOutController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _localLionsManeBet = 0;
    _localRedPillBet = 0;
    _autoCashOutController.text = _autoCashOutValue.toString();
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    _autoCashOutController.dispose();
    super.dispose();
  }

  // Generate a crash value with a more natural distribution
  double _generateCrashValue() {
    Random _random = Random();
    double randomValue = _random.nextDouble();
    
    if (randomValue < 0.70) {
      // 70% chance of early crash (1.01x to 2.0x)
      return 1.01 + _random.nextDouble() * 0.99;
    } else if (randomValue < 0.95) {
      // 25% chance of medium crash (2.0x to 10.0x)
      return 2.0 + _random.nextDouble() * 8.0;
    } else {
      // 5% chance of late crash (10.0x to 20.0x or higher)
      double baseValue = 10.0;
      double expFactor = -log(_random.nextDouble()) * 5; // Exponential distribution
      return baseValue + expFactor;
    }
  }

  void startGame() {
    if (_selectedBet == 'RedPill' && _localRedPillBet <= 0) {
      _showInsufficientFundsDialog('Red Pills');
      return;
    }
    if (_selectedBet == 'LionsMane' && _localLionsManeBet <= 0) {
      _showInsufficientFundsDialog('Lions Mane');
      return;
    }
    
    setState(() {
      // Reset game state
      multiplier = 1.0;
      gameRunning = true;
      gameOver = false;
      userCashedOut = false;
      
      // Reset current round tracking
      _currentRoundRedPills = _selectedBet == 'RedPill' ? _localRedPillBet : 0;
      _currentRoundLionsMane = _selectedBet == 'LionsMane' ? _localLionsManeBet : 0;
      
      // Reset local bet amounts
      if (_selectedBet == 'RedPill') {
        _localRedPillBet = 0;
      } else {
        _localLionsManeBet = 0;
      }
      
      // Clear graph points for new game
      _graphPoints = [1.0];
    });
    
    // Generate crash point with improved natural distribution
    double crashPoint = _generateCrashValue();
    print('This round will crash at: ${crashPoint.toStringAsFixed(2)}x');
    
    // Start the game loop with improved growth rate
    double growthRate = 0.05; // Base growth rate
    int interval = 50; // Update every 50ms
    
    gameTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Use easing function for more realistic volatility
        double speedFactor = 1 / (1 + multiplier * 0.1);
        multiplier += growthRate * speedFactor;
        
        // Format to 2 decimal places for display
        multiplier = double.parse(multiplier.toStringAsFixed(2));
        
        // Add point to graph (limit number of points to avoid performance issues)
        if (_graphPoints.length < _maxGraphPoints) {
          _graphPoints.add(multiplier);
        } else {
          _graphPoints.removeAt(0);
          _graphPoints.add(multiplier);
        }
        
        // Check for auto cash out
        if (_autoEnabled && multiplier >= _autoCashOutValue && !userCashedOut) {
          cashOut();
        }
        
        // Check for crash
        if (multiplier >= crashPoint) {
          gameRunning = false;
          gameOver = true;
          timer.cancel();
          
          // Handle bet loss if player didn't cash out
          if (!userCashedOut) {
            // Deduct the bet amount from player's balance
            if (_selectedBet == 'RedPill') {
              // Call the callback with a negative value to subtract the bet
              widget.onCollectibleChange('RedPill', -_currentRoundRedPills);
              
              // Show bet loss message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You lost $_currentRoundRedPills Red Pills!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    )
                  );
                }
              });
            } else if (_selectedBet == 'LionsMane') {
              // Call the callback with a negative value to subtract the bet
              widget.onCollectibleChange('LionsMane', -_currentRoundLionsMane);
              
              // Show bet loss message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You lost $_currentRoundLionsMane Lions Mane!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    )
                  );
                }
              });
            }
          }
          
          // Add to game history
          _addToHistory(multiplier, false);
          
          // Show crash message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CRASHED AT ${multiplier.toStringAsFixed(2)}x!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
  }

  void cashOut() {
    if (!gameRunning || userCashedOut) return;
    
    setState(() {
      gameRunning = false;
      userCashedOut = true;
      
      // Add to game history
      _addToHistory(multiplier, true);
      
      // Calculate winnings
      if (_selectedBet == 'RedPill') {
        int winnings = (_currentRoundRedPills * multiplier).floor();
        _redPillsCashedOut = winnings;
        // Update player stats via callback
        widget.onCollectibleChange('RedPill', winnings);
      } else {
        // Add lions mane cash-out logic, similar to red pills
        int winnings = (_currentRoundLionsMane * multiplier).floor();
        _lionsManeCashedOut = winnings;
        // Update player stats via callback
        widget.onCollectibleChange('LionsMane', winnings);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cashed out at ${multiplier.toStringAsFixed(2)}x!'),
          backgroundColor: Colors.green,
        ),
      );
    });
    
    gameTimer?.cancel();
  }

  void _showInsufficientFundsDialog(String currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient $currency'),
        content: Text('You need to bet at least 1 $currency to play.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // New function to add games to history
  void _addToHistory(double crashPoint, bool userCashedOut) {
    _gameHistory.add({
      'multiplier': crashPoint,
      'cashedOut': userCashedOut,
      'betType': _selectedBet,
      'betAmount': _selectedBet == 'RedPill' ? _currentRoundRedPills : _currentRoundLionsMane,
    });
    
    // Limit history size
    if (_gameHistory.length > _maxHistoryItems) {
      _gameHistory.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Crypto Crash", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: ScrollingBackground(scrollSpeed: 80.0),
          ),
          
          // Game content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Game History Row
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _gameHistory.length,
                    itemBuilder: (context, index) {
                      final item = _gameHistory[index];
                      final bool wasCashedOut = item['cashedOut'] ?? false;
                      final double mult = item['multiplier'] ?? 1.0;
                      
                      // Color based on multiplier value
                      Color color;
                      if (mult < 1.5) {
                        color = Colors.red;
                      } else if (mult < 3.0) {
                        color = Colors.orange;
                      } else if (mult < 10.0) {
                        color = wasCashedOut ? Colors.green : Colors.red;
                      } else {
                        color = wasCashedOut ? Colors.blue : Colors.purple;
                      }
                      
                      return Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${mult.toStringAsFixed(2)}x',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Balance indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Lions Mane balance
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset('assets/images/lions_mane.png', width: 24, height: 24),
                          SizedBox(width: 8),
                          Text('${widget.lionsManeCollected}', 
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    // Red Pill balance
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset('assets/images/red_pill.png', width: 24, height: 24),
                          SizedBox(width: 8),
                          Text('${widget.redPillCollected}', 
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Game display area with graph
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: gameRunning 
                        ? (userCashedOut ? Colors.green.withOpacity(0.2) : Colors.grey[800])
                        : (gameOver ? Colors.red.withOpacity(0.2) : Colors.grey[900]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gameRunning 
                          ? (userCashedOut ? Colors.green : Colors.grey.shade700) 
                          : (gameOver ? Colors.red : Colors.grey.shade800),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Multiplier display
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            gameRunning || gameOver ? multiplier.toStringAsFixed(2) + 'x' : 'READY',
                            style: TextStyle(
                              fontSize: 64, 
                              color: gameOver && !userCashedOut 
                                ? Colors.red 
                                : userCashedOut 
                                  ? Colors.green
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: gameOver && !userCashedOut 
                                    ? Colors.red.withOpacity(0.6) 
                                    : userCashedOut 
                                      ? Colors.green.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Game status message
                        if (gameOver && !userCashedOut)
                          _buildAnimatedStatusText('CRASHED!', Colors.red),
                        if (userCashedOut)
                          _buildAnimatedStatusText('CASHED OUT!', Colors.green),
                          
                        // Show winnings when cashed out
                        if (userCashedOut)
                          _buildWinningsDisplay(),
                        
                        // Graph
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _graphPoints.isEmpty
                              ? Center(child: Text('Start game to see graph', style: TextStyle(color: Colors.grey)))
                              : CustomPaint(
                                  size: Size.infinite,
                                  painter: _CrashGraphPainter(
                                    points: _graphPoints,
                                    maxY: max(10.0, _graphPoints.isNotEmpty ? _graphPoints.reduce(max) + 1 : 10.0),
                                    gameOver: gameOver,
                                    cashedOut: userCashedOut,
                                    currentMultiplier: multiplier,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Auto Cash Out Controls (only when not playing)
                if (!gameRunning && !gameOver)
                  Row(
                    children: [
                      Checkbox(
                        value: _autoEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoEnabled = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        'Auto Cash Out at',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _autoCashOutController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Multiplier',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _autoCashOutValue = double.tryParse(value) ?? 2.0;
                            });
                          },
                        ),
                      ),
                      Text(
                        'x',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                
                SizedBox(height: 12),
                
                // Game controls (betting, cash out, etc.)
                _buildGameControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper widget for animated status text
  Widget _buildAnimatedStatusText(String text, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: color, 
          fontSize: 24, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget for winnings display
  Widget _buildWinningsDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            _selectedBet == 'RedPill' 
              ? 'assets/images/red_pill.png' 
              : 'assets/images/lions_mane.png', 
            width: 28, 
            height: 28
          ),
          SizedBox(width: 8),
          Text(
            '+${_selectedBet == 'RedPill' ? _redPillsCashedOut : _lionsManeCashedOut}',
            style: TextStyle(
              color: Colors.green,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.green.withOpacity(0.6),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for game controls
  Widget _buildGameControls() {
    if (!gameRunning && !gameOver && !userCashedOut) {
      return Column(
        children: [
          // Bet selection toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBetSelector('RedPill', 'Red Pill'),
              SizedBox(width: 16),
              _buildBetSelector('LionsMane', 'Lions Mane'),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Bet amount slider with improved styling
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('BET: ', 
                  style: TextStyle(color: _selectedBet == 'RedPill' ? Colors.red : Colors.amber, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8,
                      activeTrackColor: _selectedBet == 'RedPill' ? Colors.red.withOpacity(0.8) : Colors.amber.withOpacity(0.8),
                      inactiveTrackColor: Colors.grey.shade800,
                      thumbColor: _selectedBet == 'RedPill' ? Colors.red : Colors.amber,
                      overlayColor: (_selectedBet == 'RedPill' ? Colors.red : Colors.amber).withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
                    ),
                    child: Slider(
                      value: _selectedBet == 'RedPill' 
                        ? _localRedPillBet.toDouble() 
                        : _localLionsManeBet.toDouble(),
                      min: 0,
                      max: _selectedBet == 'RedPill'
                        ? widget.redPillCollected.toDouble()
                        : widget.lionsManeCollected.toDouble(),
                      divisions: max(1, _selectedBet == 'RedPill'
                        ? widget.redPillCollected
                        : widget.lionsManeCollected),
                      onChanged: (value) {
                        setState(() {
                          if (_selectedBet == 'RedPill') {
                            _localRedPillBet = value.round();
                          } else {
                            _localLionsManeBet = value.round();
                          }
                        });
                      },
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedBet == 'RedPill' ? Colors.red : Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedBet == 'RedPill' ? '$_localRedPillBet' : '$_localLionsManeBet',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedBet == 'RedPill') {
                        _localRedPillBet = widget.redPillCollected;
                      } else {
                        _localLionsManeBet = widget.lionsManeCollected;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text('MAX', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Start button with improved styling
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                shadowColor: Colors.amber.withOpacity(0.5),
              ),
              onPressed: startGame,
              child: Text(
                'PLACE BET & PLAY', 
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (gameRunning) {
      // Cash out button during game with improved styling
      return Container(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            shadowColor: Colors.green.withOpacity(0.5),
          ),
          onPressed: cashOut,
          child: Text(
            'CASH OUT ${_selectedBet == "RedPill" ? (_currentRoundRedPills * multiplier).toStringAsFixed(0) : (_currentRoundLionsMane * multiplier).toStringAsFixed(0)}', 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    } else {
      // Play again button after game with improved styling
      return Container(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            shadowColor: Colors.blue.withOpacity(0.5),
          ),
          onPressed: () {
            setState(() {
              gameOver = false;
              userCashedOut = false;
            });
          },
          child: Text(
            'PLAY AGAIN', 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
  }

  // Improved bet selector with animation
  Widget _buildBetSelector(String betType, String label) {
    bool isSelected = _selectedBet == betType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBet = betType;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? (betType == 'RedPill' ? Colors.red : Colors.amber) 
            : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (betType == 'RedPill' ? Colors.red : Colors.amber).withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Image.asset(
              betType == 'RedPill' ? 'assets/images/red_pill.png' : 'assets/images/lions_mane.png',
              width: 28,
              height: 28,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this to your CrashMiniGame class, if it's defined as a wrapper
class CrashMiniGame extends StatelessWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final Function(int) onRedPillsEarned;
  final Function(int)? onLionsManeEarned;
  final VoidCallback? onClose;
  final int currentRoundRedPills;

  const CrashMiniGame({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.onRedPillsEarned,
    this.onLionsManeEarned,
    this.onClose,
    required this.currentRoundRedPills,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CrashMiniGameScreen(
      lionsManeCollected: lionsManeCollected,
      redPillCollected: redPillCollected,
      onCollectibleChange: (String type, int amount) {
        if (type == 'RedPill') {
          onRedPillsEarned(amount);
        } else if (type == 'LionsMane' && onLionsManeEarned != null) {
          onLionsManeEarned!(amount);
        }
      },
      onClose: onClose,
    );
  }
}

// Add this class outside of the State class
class _CrashGraphPainter extends CustomPainter {
  final List<double> points;
  final double maxY;
  final bool gameOver;
  final bool cashedOut;
  final double currentMultiplier;
  
  _CrashGraphPainter({
    required this.points,
    required this.maxY,
    required this.gameOver,
    required this.cashedOut,
    required this.currentMultiplier,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    // Setup
    final Paint linePaint = Paint()
      ..color = cashedOut ? Colors.green : (gameOver ? Colors.red : Colors.amber)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cashedOut ? Colors.green.withOpacity(0.2) : 
           (gameOver ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    // Draw axes
    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1;
    
    // Y-axis
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      axisPaint,
    );
    
    // X-axis
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    
    // Create path for the line
    final Path path = Path();
    
    // Draw grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 0.5;
    
    // Horizontal grid lines (multiplier values)
    for (double i = 1.0; i <= maxY; i += 1.0) {
      final double y = size.height - (i / maxY) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      // Add multiplier labels
      TextSpan span = TextSpan(
        text: '${i.toStringAsFixed(1)}x',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
      );
      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(5, y - 15));
    }
    
    // Calculate points
    double xStep = size.width / (points.length - 1 > 0 ? points.length - 1 : 1);
    double maxValue = maxY;
    
    // Start the path
    double startX = 0;
    double startY = size.height - (points.first / maxValue) * size.height;
    path.moveTo(startX, startY);
    
    // Add points to path
    for (int i = 1; i < points.length; i++) {
      double x = i * xStep;
      double y = size.height - (points[i] / maxValue) * size.height;
      path.lineTo(x, y);
    }
    
    // Create a filled path for the area under the curve
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    // Draw the filled area
    canvas.drawPath(fillPath, backgroundPaint);
    
    // Draw the line
    canvas.drawPath(path, linePaint);
    
    // Draw current multiplier indicator
    if (!gameOver) {
      final Paint dotPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      final double lastX = (points.length - 1) * xStep;
      final double lastY = size.height - (points.last / maxValue) * size.height;
      
      canvas.drawPoints(PointMode.points, [Offset(lastX, lastY)], dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(_CrashGraphPainter oldDelegate) => 
    oldDelegate.points != points ||
    oldDelegate.gameOver != gameOver ||
    oldDelegate.cashedOut != cashedOut;
}
