import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart'; // For ScrollingBackground

class CrashMiniGame extends StatefulWidget {
  final VoidCallback onClose;
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final int ethereumCollected;
  final int solanaCollected;
  final Function(int, int, int, int, int) onUpdateAssets;

  const CrashMiniGame({
    Key? key, 
    required this.onClose,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.ethereumCollected,
    required this.solanaCollected,
    required this.onUpdateAssets,
  }) : super(key: key);

  @override
  _CrashMiniGameState createState() => _CrashMiniGameState();
}

class _CrashMiniGameState extends State<CrashMiniGame> with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  bool _hasCrashed = false;
  bool _hasCashedOut = false;
  double _multiplier = 1.0;
  final Random _random = Random();
  Timer? _gameTimer;
  
  // Add multiplier history for chart
  List<double> _multiplierHistory = [1.0];
  final int _maxHistoryPoints = 100;
  
  // Track the amount bet for each asset
  int _lionsManeAmountBet = 0;
  int _redPillAmountBet = 0;
  int _bitcoinAmountBet = 0;
  int _ethereumAmountBet = 0;
  int _solanaAmountBet = 0;
  
  // Local copies of asset counts
  late int _lionsManeCount;
  late int _redPillCount;
  late int _bitcoinCount;
  late int _ethereumCount;
  late int _solanaCount;
  
  // Selected asset type for betting
  String _selectedAsset = 'Lions Mane'; // Default selected asset
  
  // Controller for bet amount input
  final TextEditingController _betAmountController = TextEditingController();
  
  // Animation controller for crash effect
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize asset counts from props
    _lionsManeCount = widget.lionsManeCollected;
    _redPillCount = widget.redPillCollected;
    _bitcoinCount = widget.bitcoinCollected;
    _ethereumCount = widget.ethereumCollected;
    _solanaCount = widget.solanaCollected;
    
    // Set up shake animation for crash effect
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _shakeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _betAmountController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Helper to get current count of the selected asset
  int get _currentAssetCount {
    switch (_selectedAsset) {
      case 'Lions Mane': return _lionsManeCount;
      case 'Red Pill': return _redPillCount;
      case 'Bitcoin': return _bitcoinCount;
      case 'Ethereum': return _ethereumCount;
      case 'Solana': return _solanaCount;
      default: return 0;
    }
  }

  // Helper to get current bet amount for the selected asset
  int get _currentAssetBet {
    switch (_selectedAsset) {
      case 'Lions Mane': return _lionsManeAmountBet;
      case 'Red Pill': return _redPillAmountBet;
      case 'Bitcoin': return _bitcoinAmountBet;
      case 'Ethereum': return _ethereumAmountBet;
      case 'Solana': return _solanaAmountBet;
      default: return 0;
    }
  }

  // Helper to get asset image path
  String get _assetImagePath {
    switch (_selectedAsset) {
      case 'Lions Mane': return 'assets/images/lions_mane.png';
      case 'Red Pill': return 'assets/images/red_pill.png';
      case 'Bitcoin': return 'assets/images/bitcoin.png';
      case 'Ethereum': return 'assets/images/eth.png';
      case 'Solana': return 'assets/images/solana.png';
      default: return 'assets/images/lions_mane.png';
    }
  }
  
  // Set bet amount for selected asset
  void _setBetAmount(int amount) {
    if (amount <= 0 || amount > _currentAssetCount) return;
    
    setState(() {
      switch (_selectedAsset) {
        case 'Lions Mane':
          _lionsManeAmountBet = amount;
          break;
        case 'Red Pill':
          _redPillAmountBet = amount;
          break;
        case 'Bitcoin':
          _bitcoinAmountBet = amount;
          break;
        case 'Ethereum':
          _ethereumAmountBet = amount;
          break;
        case 'Solana':
          _solanaAmountBet = amount;
          break;
      }
    });
  }
  
  // Handle bet button press
  void _placeBet() {
    // Try to parse the input value
    int? amount = int.tryParse(_betAmountController.text);
    if (amount == null || amount <= 0 || amount > _currentAssetCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid bet amount'))
      );
      return;
    }
    
    _setBetAmount(amount);
    _betAmountController.clear();
  }
  
  // Handle "Bet Max" button press
  void _betMax() {
    _betAmountController.text = _currentAssetCount.toString();
    _placeBet();
  }

  void _startGame() {
    if (_currentAssetBet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please place a bet first'))
      );
      return;
    }
    
    // Reset multiplier history for new game
    setState(() {
      _multiplierHistory = [1.0];
      _multiplier = 1.0;
      
      // Deduct bet from asset count
      switch (_selectedAsset) {
        case 'Lions Mane':
          _lionsManeCount -= _lionsManeAmountBet;
          break;
        case 'Red Pill':
          _redPillCount -= _redPillAmountBet;
          break;
        case 'Bitcoin':
          _bitcoinCount -= _bitcoinAmountBet;
          break;
        case 'Ethereum':
          _ethereumCount -= _ethereumAmountBet;
          break;
        case 'Solana':
          _solanaCount -= _solanaAmountBet;
          break;
      }
      
      _isRunning = true;
      _hasCrashed = false;
      _hasCashedOut = false;
    });
    
    // Start the game timer - update faster for smoother chart animation
    _gameTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      setState(() {
        // Calculate probability of crash - increases with multiplier
        final double crashProbability = 0.01 * pow(_multiplier, 1.35);
        
        if (_random.nextDouble() < crashProbability) {
          _crash();
        } else {
          // Increase multiplier at a slightly slower rate as it gets higher
          _multiplier += 0.01 * (1.0 / sqrt(_multiplier));
          
          // Add to history for chart
          _multiplierHistory.add(_multiplier);
          if (_multiplierHistory.length > _maxHistoryPoints) {
            _multiplierHistory.removeAt(0);
          }
        }
      });
    });
  }

  void _cashOut() {
    if (!_isRunning || _hasCrashed) return;
    
    _gameTimer?.cancel();
    
    setState(() {
      _isRunning = false;
      _hasCashedOut = true;
      
      // Apply winnings to appropriate asset
      int winnings;
      switch (_selectedAsset) {
        case 'Lions Mane':
          winnings = (_lionsManeAmountBet * _multiplier).floor();
          _lionsManeCount += winnings;
          break;
        case 'Red Pill':
          winnings = (_redPillAmountBet * _multiplier).floor();
          _redPillCount += winnings;
          break;
        case 'Bitcoin':
          winnings = (_bitcoinAmountBet * _multiplier).floor();
          _bitcoinCount += winnings;
          break;
        case 'Ethereum':
          winnings = (_ethereumAmountBet * _multiplier).floor();
          _ethereumCount += winnings;
          break;
        case 'Solana':
          winnings = (_solanaAmountBet * _multiplier).floor();
          _solanaCount += winnings;
          break;
      }
    });
    
    // Notify parent with the updated asset counts
    _notifyAssetChanges();
  }

  void _crash() {
    _gameTimer?.cancel();
    
    setState(() {
      _isRunning = false;
      _hasCrashed = true;
      
      // Add final multiplier to history for visual effect
      _multiplierHistory.add(_multiplier);
      if (_multiplierHistory.length > _maxHistoryPoints) {
        _multiplierHistory.removeAt(0);
      }
      
      // Clear bet amounts - player loses their bet
      _lionsManeAmountBet = 0;
      _redPillAmountBet = 0;
      _bitcoinAmountBet = 0;
      _ethereumAmountBet = 0;
      _solanaAmountBet = 0;
    });
    
    // Play shake animation for crash effect
    _shakeController.reset();
    _shakeController.forward();
    
    // Notify parent with the updated asset counts
    _notifyAssetChanges();
  }
  
  void _notifyAssetChanges() {
    // Calculate net changes from original values
    final int lionsManeDelta = _lionsManeCount - widget.lionsManeCollected;
    final int redPillDelta = _redPillCount - widget.redPillCollected;
    final int bitcoinDelta = _bitcoinCount - widget.bitcoinCollected;
    final int ethereumDelta = _ethereumCount - widget.ethereumCollected;
    final int solanaDelta = _solanaCount - widget.solanaCollected;
    
    // Notify parent with all changes
    widget.onUpdateAssets(
      lionsManeDelta,
      redPillDelta,
      bitcoinDelta,
      ethereumDelta,
      solanaDelta
    );
  }

  void _reset() {
    setState(() {
      _lionsManeAmountBet = 0;
      _redPillAmountBet = 0;
      _bitcoinAmountBet = 0;
      _ethereumAmountBet = 0;
      _solanaAmountBet = 0;
      _multiplier = 1.0;
      _multiplierHistory = [1.0];
      _hasCrashed = false;
      _hasCashedOut = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Crash Mini Game', style: TextStyle(color: Colors.white)),
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
          
          // Game content with shake animation when crashed
          Transform.translate(
            offset: Offset(_hasCrashed ? _shakeAnimation.value : 0, 0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Multiplier display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      decoration: BoxDecoration(
                        color: _hasCrashed ? Colors.red.withOpacity(0.7) :
                               _hasCashedOut ? Colors.green.withOpacity(0.7) :
                               Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _hasCrashed ? 'CRASHED!' : 
                            _hasCashedOut ? 'CASHED OUT!' : 
                            _isRunning ? 'RUNNING...' : 'READY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_multiplier.toStringAsFixed(2)}x',
                            style: TextStyle(
                              color: _hasCrashed ? Colors.red : 
                                    _hasCashedOut ? Colors.green : 
                                    Colors.amber,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Add multiplier chart
                    const SizedBox(height: 20),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomPaint(
                          painter: MultiplierChartPainter(
                            multiplierHistory: _multiplierHistory,
                            isRunning: _isRunning,
                            hasCrashed: _hasCrashed,
                            hasCashedOut: _hasCashedOut,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Asset selection
                    if (!_isRunning) ...[
                      Text(
                        'Select Asset to Bet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Asset selection chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAssetChip('Lions Mane', _lionsManeCount),
                            _buildAssetChip('Red Pill', _redPillCount),
                            _buildAssetChip('Bitcoin', _bitcoinCount),
                            _buildAssetChip('Ethereum', _ethereumCount),
                            _buildAssetChip('Solana', _solanaCount),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Currently selected asset info
                      Row(
                        children: [
                          Image.asset(
                            _assetImagePath,
                            width: 32,
                            height: 32,
                            errorBuilder: (_, __, ___) => Icon(Icons.error, color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAsset,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Available: $_currentAssetCount',
                                  style: TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentAssetBet > 0) ...[
                            Text(
                              'Bet: $_currentAssetBet',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bet amount input
                      if (_currentAssetCount > 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _betAmountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Bet Amount',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.amber),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _placeBet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Bet'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Quick bet buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickBetButton(1),
                            _buildQuickBetButton(5),
                            _buildQuickBetButton(10),
                            _buildQuickBetButton(_currentAssetCount ~/ 2), // Half
                            ElevatedButton(
                              onPressed: _currentAssetCount > 0 ? _betMax : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Max'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Center(
                          child: Text(
                            'No $_selectedAsset available to bet',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                    
                    const Spacer(),
                    
                    // Game controls
                    if (_isRunning) ...[
                      ElevatedButton(
                        onPressed: _cashOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'CASH OUT (${(_currentAssetBet * _multiplier).floor()})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (_hasCrashed || _hasCashedOut) ...[
                      ElevatedButton(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (_currentAssetBet > 0) ...[
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'START',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetChip(String assetName, int count) {
    final isSelected = _selectedAsset == assetName;
    final isAvailable = count > 0;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          '$assetName ($count)',
          style: TextStyle(
            color: isSelected ? Colors.black : (isAvailable ? Colors.white : Colors.grey),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onSelected: isAvailable ? (selected) {
          if (selected) {
            setState(() {
              _selectedAsset = assetName;
            });
          }
        } : null,
        backgroundColor: Colors.black.withOpacity(0.7),
        selectedColor: Colors.amber,
        disabledColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildQuickBetButton(int amount) {
    return ElevatedButton(
      onPressed: amount <= 0 || amount > _currentAssetCount ? null : () {
        _betAmountController.text = amount.toString();
        _placeBet();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      child: Text('$amount'),
    );
  }
}

// Custom painter for multiplier chart
class MultiplierChartPainter extends CustomPainter {
  final List<double> multiplierHistory;
  final bool isRunning;
  final bool hasCrashed;
  final bool hasCashedOut;
  
  MultiplierChartPainter({
    required this.multiplierHistory,
    required this.isRunning,
    required this.hasCrashed,
    required this.hasCashedOut,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (multiplierHistory.isEmpty) return;
    
    // Determine max Y value (multiplier) with minimum of 2x
    final maxMultiplier = multiplierHistory
        .reduce((curr, next) => curr > next ? curr : next)
        .clamp(2.0, double.infinity);
    
    // Line paint
    final paint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Set color based on state
    if (hasCrashed) {
      paint.color = Colors.red;
    } else if (hasCashedOut) {
      paint.color = Colors.green;
    } else {
      paint.color = Colors.amber;
    }
    
    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.0;
    
    // X-axis
    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(40, 0),
      Offset(40, size.height),
      axisPaint,
    );
    
    // Create path for the multiplier line
    final path = Path();
    
    // Calculate horizontal spacing between points
    final xStep = (size.width - 50) / (multiplierHistory.length > 1 ? multiplierHistory.length - 1 : 1);
    
    // First point
    path.moveTo(
      40, // Start at Y-axis
      size.height - 20 - (multiplierHistory[0] - 1) / (maxMultiplier - 1) * (size.height - 40)
    );
    
    // Draw line through points
    for (int i = 1; i < multiplierHistory.length; i++) {
      final x = 40 + i * xStep;
      final normalizedMultiplier = (multiplierHistory[i] - 1) / (maxMultiplier - 1);
      final y = size.height - 20 - normalizedMultiplier * (size.height - 40);
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw multiplier labels on Y axis
    final textStyle = TextStyle(
      color: Colors.grey.shade400,
      fontSize: 12,
    );
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw 1.00x at bottom
    textPainter.text = TextSpan(
      text: '1.00x',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, size.height - 20 - textPainter.height / 2));
    
    // Draw max value at top
    textPainter.text = TextSpan(
      text: '${maxMultiplier.toStringAsFixed(1)}x',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 5));
    
    // Draw current value if running
    if (isRunning || hasCrashed || hasCashedOut) {
      final currentMultiplier = multiplierHistory.last;
      final normalizedMultiplier = (currentMultiplier - 1) / (maxMultiplier - 1);
      final y = size.height - 20 - normalizedMultiplier * (size.height - 40);
      
      // Draw current value marker (circle)
      final markerPaint = Paint()
        ..color = hasCrashed ? Colors.red : hasCashedOut ? Colors.green : Colors.amber
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(40 + (multiplierHistory.length - 1) * xStep, y),
        6.0,
        markerPaint,
      );
      
      // Draw current value text
      textPainter.text = TextSpan(
        text: '${currentMultiplier.toStringAsFixed(2)}x',
        style: TextStyle(
          color: hasCrashed ? Colors.red : hasCashedOut ? Colors.green : Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(
          40 + (multiplierHistory.length - 1) * xStep + 10,
          y - textPainter.height / 2
        )
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant MultiplierChartPainter oldDelegate) {
    return oldDelegate.multiplierHistory != multiplierHistory ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.hasCrashed != hasCrashed ||
        oldDelegate.hasCashedOut != hasCashedOut;
  }
}
