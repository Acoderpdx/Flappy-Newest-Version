import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PortfolioScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final List<double> lionsManePnlHistory;
  final List<double> redPillPnlHistory;
  final List<double> bitcoinPnlHistory;
  final List<double> totalWealthHistory;
  final VoidCallback? onClose;
  // Add callback to update main game state when trading occurs
  final Function(int lionsManeDelta, int redPillDelta, int bitcoinDelta, double usdDelta)? onTrade;
  // Add initial USD balance
  final double usdBalance;

  const PortfolioScreen({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.lionsManePnlHistory,
    required this.redPillPnlHistory,
    required this.bitcoinPnlHistory,
    required this.totalWealthHistory,
    this.onClose,
    this.onTrade,
    this.usdBalance = 0.0,
  }) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  // Constants for exchange rates
  final double _lionsManeRate = 100.0;
  final double _redPillRate = 500.0;
  
  // Bitcoin price simulation variables
  late double _currentBtcPrice;
  final double _minBtcPrice = 60000.0;
  final double _maxBtcPrice = 100000.0;
  Timer? _priceUpdateTimer;
  List<double> _btcPriceHistory = [];
  
  // Trading state
  late double _usdBalance;
  late TabController _tabController;
  String _selectedTab = 'Portfolio';
  final TextEditingController _buyBtcAmountController = TextEditingController();
  final TextEditingController _sellBtcAmountController = TextEditingController();
  
  // Price chart variables
  final int _maxPriceHistoryPoints = 50;
  final Color _matrixGreen = const Color(0xFF00FF41);
  final Color _matrixBlack = const Color(0xFF0D0208);
  String _selectedTimeframe = '1H';

  @override
  void initState() {
    super.initState();
    _usdBalance = widget.usdBalance;
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize Bitcoin price simulation
    _currentBtcPrice = _minBtcPrice + (_maxBtcPrice - _minBtcPrice) * 0.5;  // Start at midpoint
    _btcPriceHistory = List.generate(20, (_) => _currentBtcPrice);
    
    // Start price updates
    _startPriceSimulation();
  }
  
  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    _tabController.dispose();
    _buyBtcAmountController.dispose();
    _sellBtcAmountController.dispose();
    super.dispose();
  }
  
  // Simulate Bitcoin price movements
  void _startPriceSimulation() {
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        // Random walk algorithm with tendency to mean revert
        final midPrice = (_minBtcPrice + _maxBtcPrice) / 2;
        final volatility = (_maxBtcPrice - _minBtcPrice) * 0.02; // 2% of range
        
        // Mean reversion factor: stronger pull toward mean when far from it
        final distanceFromMid = (_currentBtcPrice - midPrice).abs() / (_maxBtcPrice - _minBtcPrice);
        final meanReversionFactor = 0.2 + distanceFromMid * 0.8; // 0.2-1.0 range
        
        // Calculate price change with mean reversion
        double priceChange;
        if (_currentBtcPrice > midPrice) {
          // Above midpoint, bias toward decreasing
          priceChange = volatility * ((Random().nextDouble() * 2 - 1.2) - meanReversionFactor);
        } else {
          // Below midpoint, bias toward increasing
          priceChange = volatility * ((Random().nextDouble() * 2 - 0.8) + meanReversionFactor);
        }
        
        // Apply change and ensure within bounds
        _currentBtcPrice += priceChange;
        _currentBtcPrice = _currentBtcPrice.clamp(_minBtcPrice, _maxBtcPrice);
        
        // Add to history and trim if needed
        _btcPriceHistory.add(_currentBtcPrice);
        if (_btcPriceHistory.length > _maxPriceHistoryPoints) {
          _btcPriceHistory.removeAt(0);
        }
      });
    });
  }
  
  // Calculate total USD value of portfolio
  double get _totalUsdValue {
    double btcValue = widget.bitcoinCollected * _currentBtcPrice;
    double lionsManeValue = widget.lionsManeCollected * _lionsManeRate;
    double redPillValue = widget.redPillCollected * _redPillRate;
    return _usdBalance + btcValue + lionsManeValue + redPillValue;
  }
  
  // Exchange Lions Mane to USD - Fix unlimited exchange issue
  void _exchangeLionsMane() {
    if (widget.lionsManeCollected > 0) { // Changed from lionsManeCollected to widget.lionsManeCollected
      double usdAmount = _lionsManeRate;
      if (widget.onTrade != null) {
        widget.onTrade!(-1, 0, 0, usdAmount);
      } else {
        setState(() {
          _usdBalance += usdAmount;
        });
      }
    }
  }
  
  // Exchange Red Pill to USD - Fix unlimited exchange issue
  void _exchangeRedPill() {
    if (widget.redPillCollected > 0) { // Changed from redPillCollected to widget.redPillCollected
      double usdAmount = _redPillRate;
      if (widget.onTrade != null) {
        widget.onTrade!(0, -1, 0, usdAmount);
      } else {
        setState(() {
          _usdBalance += usdAmount;
        });
      }
    }
  }
  
  // Buy Bitcoin with USD
  void _buyBitcoin() {
    double amount = double.tryParse(_buyBtcAmountController.text) ?? 0.0;
    if (amount > 0) {
      double usdCost = amount * _currentBtcPrice;
      if (_usdBalance >= usdCost) {
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, amount.toInt(), -usdCost);
        }
        setState(() {
          _usdBalance -= usdCost;
        });
        _buyBtcAmountController.clear();
      }
    }
  }
  
  // Sell Bitcoin for USD
  void _sellBitcoin() {
    double amount = double.tryParse(_sellBtcAmountController.text) ?? 0.0;
    if (amount > 0 && amount <= widget.bitcoinCollected) {
      double usdAmount = amount * _currentBtcPrice;
      if (widget.onTrade != null) {
        widget.onTrade!(0, 0, -amount.toInt(), usdAmount);
      }
      setState(() {
        _usdBalance += usdAmount;
      });
      _sellBtcAmountController.clear();
    }
  }
  
  // Price trend indicator
  Widget _buildPriceTrend() {
    if (_btcPriceHistory.length < 2) return const SizedBox.shrink();
    
    bool isUp = _btcPriceHistory.last > _btcPriceHistory[_btcPriceHistory.length - 2];
    Color trendColor = isUp ? Colors.green : Colors.red;
    IconData trendIcon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Row(
      children: [
        Icon(trendIcon, color: trendColor, size: 16),
        Text(
          isUp ? '+${(_btcPriceHistory.last - _btcPriceHistory[_btcPriceHistory.length - 2]).toStringAsFixed(2)}' 
              : '${(_btcPriceHistory.last - _btcPriceHistory[_btcPriceHistory.length - 2]).toStringAsFixed(2)}',
          style: TextStyle(color: trendColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Build graph segment button for timeframe selection
  Widget _buildGraphSegment(String label) {
    final bool isSelected = _selectedTimeframe == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframe = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? _matrixGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _matrixBlack : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Portfolio', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _matrixGreen,
          tabs: [
            Tab(text: 'Portfolio'),
            Tab(text: 'Trade'),
            Tab(text: 'Bitcoin'),
          ],
          onTap: (index) {
            setState(() {
              _selectedTab = index == 0 ? 'Portfolio' : (index == 1 ? 'Trade' : 'Bitcoin');
            });
          },
        ),
        actions: [
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(),
          _buildTradeTab(),
          _buildBitcoinTab(),
        ],
      ),
    );
  }
  
  // Portfolio Tab - Overview of assets
  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall value card
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Portfolio Value',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${_totalUsdValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'USD Balance: \$${_usdBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _matrixGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          Text(
            'Your Assets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Bitcoin Asset Card
          _buildAssetCard(
            'Bitcoin',
            'assets/images/bitcoin.png',
            widget.bitcoinCollected,
            _currentBtcPrice,
            widget.bitcoinCollected * _currentBtcPrice,
          ),
          
          // Lions Mane Asset Card
          _buildAssetCard(
            'Lions Mane',
            'assets/images/lions_mane.png',
            widget.lionsManeCollected,
            _lionsManeRate,
            widget.lionsManeCollected * _lionsManeRate,
            canExchange: widget.lionsManeCollected > 0,
            onExchange: _exchangeLionsMane,
          ),
          
          // Red Pill Asset Card
          _buildAssetCard(
            'Red Pill',
            'assets/images/red_pill.png',
            widget.redPillCollected,
            _redPillRate,
            widget.redPillCollected * _redPillRate,
            canExchange: widget.redPillCollected > 0,
            onExchange: _exchangeRedPill,
          ),
        ],
      ),
    );
  }
  
  // Asset card widget for portfolio items
  Widget _buildAssetCard(String name, String imageAsset, int quantity, double rate, double totalValue, {bool canExchange = false, VoidCallback? onExchange}) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  imageAsset,
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.image_not_supported, color: Colors.amber),
                ),
                SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (name == 'Bitcoin') _buildPriceTrend(),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '\$${rate.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Value',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: name == 'Bitcoin' ? _matrixGreen : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (canExchange && onExchange != null) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: quantity > 0 ? onExchange : null, // Disable button when quantity is 0
                style: ElevatedButton.styleFrom(
                  backgroundColor: quantity > 0 ? _matrixGreen : Colors.grey,
                  foregroundColor: _matrixBlack,
                ),
                child: Text('Exchange for USD'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Trade Tab - Buy/sell Bitcoin
  Widget _buildTradeTab() {
    double maxBtcCanBuy = _usdBalance / _currentBtcPrice;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Bitcoin Price',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${_currentBtcPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildPriceTrend(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Buy Bitcoin section
          Text(
            'Buy Bitcoin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available USD: \$${_usdBalance.toStringAsFixed(2)}',
                    style: TextStyle(color: _matrixGreen, fontSize: 16),
                  ),
                  Text(
                    'Max BTC you can buy: ${maxBtcCanBuy.toStringAsFixed(8)}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _buyBtcAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'BTC Amount',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _matrixGreen),
                      ),
                      suffix: Text('BTC', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _usdBalance > 0 ? _buyBitcoin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Buy Bitcoin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Sell Bitcoin section
          Text(
            'Sell Bitcoin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available BTC: ${widget.bitcoinCollected}',
                    style: TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _sellBtcAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'BTC Amount',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                      suffix: Text('BTC', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.bitcoinCollected > 0 ? _sellBitcoin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Sell Bitcoin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Bitcoin Tab - Price chart and analysis
  Widget _buildBitcoinTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitcoin Price',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${_currentBtcPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildPriceTrend(),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'BTC/USD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Timeframe selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGraphSegment('1H'),
                _buildGraphSegment('24H'),
                _buildGraphSegment('1W'),
                _buildGraphSegment('1M'),
                _buildGraphSegment('1Y'),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Price chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: _buildPriceChart(),
            ),
          ),
        ),
        
        // Market statistics
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('24h High', '\$${(_currentBtcPrice * 1.05).toStringAsFixed(2)}'),
                      _buildStatItem('24h Low', '\$${(_currentBtcPrice * 0.95).toStringAsFixed(2)}'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('All-Time High', '\$100,000.00'),
                      _buildStatItem('All-Time Low', '\$60,000.00'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper widget for market statistics
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Price chart widget
  Widget _buildPriceChart() {
    if (_btcPriceHistory.isEmpty) {
      return Center(
        child: Text(
          'Loading price data...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return CustomPaint(
      painter: _BitcoinPriceChartPainter(
        priceHistory: _btcPriceHistory,
        minPrice: _minBtcPrice,
        maxPrice: _maxBtcPrice,
        lineColor: _matrixGreen,
      ),
      size: Size.infinite,
    );
  }
}

// Custom painter for the Bitcoin price chart
class _BitcoinPriceChartPainter extends CustomPainter {
  final List<double> priceHistory;
  final double minPrice;
  final double maxPrice;
  final Color lineColor;
  
  _BitcoinPriceChartPainter({
    required this.priceHistory,
    required this.minPrice,
    required this.maxPrice,
    required this.lineColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;
    
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
    
    // Calculate price range with 10% padding
    final range = (maxPrice - minPrice) * 1.1;
    final paddedMin = minPrice - range * 0.05;
    
    for (int i = 0; i < priceHistory.length; i++) {
      final x = size.width * i / (priceHistory.length - 1);
      // Invert Y coordinate because canvas origin is top-left
      final y = size.height - ((priceHistory[i] - paddedMin) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    // Draw fill first, then line on top
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw price markers and grid lines
    _drawPriceMarkers(canvas, size, paddedMin, range);
  }
  
  void _drawPriceMarkers(Canvas canvas, Size size, double paddedMin, double range) {
    final textPaint = Paint()
      ..color = Colors.white70;
      
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    final textStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
    );
    
    // Draw a few price markers
    final priceStep = range / 5;
    for (int i = 0; i <= 5; i++) {
      final price = paddedMin + i * priceStep;
      final y = size.height - (price - paddedMin) / range * size.height;
      
      // Draw horizontal grid line
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
      
      // Draw price text
      final textSpan = TextSpan(
        text: '\$${price.round()}',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height - 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _BitcoinPriceChartPainter oldDelegate) {
    return oldDelegate.priceHistory != priceHistory ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.lineColor != lineColor;
  }
}
