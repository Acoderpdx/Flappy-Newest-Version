import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CrashGameScreen extends StatefulWidget {
  final double initialBalance;
  final Function(double) onUpdateBalance;
  final VoidCallback onClose;
  
  // Asset parameters for the game
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final int ethereumCollected;
  final int solanaCollected;
  final Function(int, int, int, int, int) onUpdateAssets;
  final Function(double) onWinnings; // Required callback for winnings

  const CrashGameScreen({
    Key? key,
    required this.initialBalance,
    required this.onUpdateBalance,
    required this.onClose,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.ethereumCollected,
    required this.solanaCollected,
    required this.onUpdateAssets,
    required this.onWinnings,
  }) : super(key: key);

  @override
  State<CrashGameScreen> createState() => _CrashGameScreenState();
}

class _CrashGameScreenState extends State<CrashGameScreen> {
  double _balance = 0;
  double _betAmount = 10;
  double _multiplier = 1.0;
  bool _isPlaying = false;
  bool _hasCashedOut = false;
  Timer? _gameTimer;
  
  // New variables for enhanced features
  List<double> _gameHistory = []; // Store past crash values
  double _autoCashOutValue = 2.0; // Default auto cash out value
  bool _autoEnabled = false; // Whether auto cash out is enabled
  Random _random = Random();
  TextEditingController _betController = TextEditingController();
  TextEditingController _autoCashOutController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance;
    _betController.text = _betAmount.toString();
    _autoCashOutController.text = _autoCashOutValue.toString();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _betController.dispose();
    _autoCashOutController.dispose();
    super.dispose();
  }
  
  // Generate a crash value with a more natural distribution
  double _generateCrashValue() {
    // Create a natural-feeling distribution of crash points
    // Higher probability of early crashes (1.01-2.0x)
    // Medium probability of medium crashes (2.0-10.0x)
    // Low probability of late crashes (10.0x+)
    
    double randomValue = _random.nextDouble();
    
    if (randomValue < 0.70) {
      // 70% chance of early crash (1.01x to 2.0x)
      return 1.01 + _random.nextDouble() * 0.99;
    } else if (randomValue < 0.95) {
      // 25% chance of medium crash (2.0x to 10.0x)
      return 2.0 + _random.nextDouble() * 8.0;
    } else {
      // 5% chance of late crash (10.0x to 20.0x or higher)
      // Using exponential distribution for longer tail
      double baseValue = 10.0;
      double expFactor = -log(_random.nextDouble()) * 5; // Exponential distribution
      return baseValue + expFactor;
    }
  }
  
  void _startGame() {
    if (_balance < _betAmount || _betAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid bet amount')),
      );
      return;
    }
    
    setState(() {
      _balance -= _betAmount;
      _isPlaying = true;
      _hasCashedOut = false;
      _multiplier = 1.0;
    });
    
    // Generate a crash value for this round
    final crashValue = _generateCrashValue();
    print('This round will crash at: ${crashValue.toStringAsFixed(2)}x');
    
    // Start the game timer with increasing multiplier
    double growthRate = 0.05; // Base growth rate
    int interval = 50; // Update every 50ms
    
    _gameTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Use easing function to simulate realistic volatility
        // Slower growth as multiplier increases
        double speedFactor = 1 / (1 + _multiplier * 0.1);
        _multiplier += growthRate * speedFactor;
        
        // Format to 2 decimal places for display but keep full precision for calculations
        _multiplier = double.parse(_multiplier.toStringAsFixed(2));
        
        // Check for auto cash out
        if (_autoEnabled && _multiplier >= _autoCashOutValue && !_hasCashedOut) {
          _cashOut();
        }
        
        // Check if we've hit the crash point
        if (_multiplier >= crashValue && !_hasCashedOut) {
          _handleCrash(crashValue);
          timer.cancel();
        }
      });
    });
  }
  
  void _handleCrash(double crashValue) {
    // Add the crash value to history
    setState(() {
      _isPlaying = false;
      _gameHistory.insert(0, crashValue);
      
      // Keep only the last 10 results
      if (_gameHistory.length > 10) {
        _gameHistory.removeLast();
      }
    });
    
    // Show the crash message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CRASHED AT ${crashValue.toStringAsFixed(2)}x!'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _cashOut() {
    if (!_isPlaying || _hasCashedOut) return;
    
    // Calculate winnings
    double winnings = _betAmount * _multiplier;
    
    // Update balance
    setState(() {
      _hasCashedOut = true;
      _balance += winnings;
      widget.onUpdateBalance(_balance);
      widget.onWinnings(winnings - _betAmount); // Report net winnings
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cashed out at ${_multiplier.toStringAsFixed(2)}x! Won ${winnings.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Build a colored indicator for each historical game
  Widget _buildHistoryIndicator(double crashValue) {
    Color color;
    if (crashValue < 1.5) {
      color = Colors.red;
    } else if (crashValue < 3.0) {
      color = Colors.orange;
    } else if (crashValue < 10.0) {
      color = Colors.green;
    } else {
      color = Colors.blue;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${crashValue.toStringAsFixed(2)}x',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Crash Game'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _gameTimer?.cancel();
            widget.onUpdateBalance(_balance);
            widget.onClose();
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '\$${_balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Multiplier Display
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _isPlaying 
                  ? (_hasCashedOut ? Colors.green.withOpacity(0.2) : Colors.grey[800])
                  : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isPlaying 
                    ? (_hasCashedOut ? Colors.green : Colors.grey) 
                    : Colors.red,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _isPlaying ? '${_multiplier.toStringAsFixed(2)}x' : 'READY',
                  style: TextStyle(
                    color: _isPlaying ? Colors.white : Colors.white70,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Bet Controls
            if (!_isPlaying) Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _betController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Bet Amount',
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
                        _betAmount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _betAmount = _balance;
                      _betController.text = _betAmount.toString();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: Text('MAX'),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Auto Cash Out Controls
            if (!_isPlaying) Row(
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
            
            SizedBox(height: 20),
            
            // Action Buttons
            _isPlaying
                ? ElevatedButton(
                    onPressed: _hasCashedOut ? null : _cashOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'CASH OUT ${(_betAmount * _multiplier).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'BET \$${_betAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
            
            SizedBox(height: 24),
            
            // Game History Header
            Text(
              'Game History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Game History Display
            Container(
              height: 40,
              child: _gameHistory.isEmpty 
                ? Center(child: Text('No previous games', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gameHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryIndicator(_gameHistory[index]);
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}
