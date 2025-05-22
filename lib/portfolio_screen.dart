import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart'; // Import for ScrollingBackground
import 'crypto_market_manager.dart';

class PortfolioScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final int ethereumCollected;
  final int solanaCollected;
  final int browneCoinCollected; // Add this line
  final List<double> lionsManePnlHistory;
  final List<double> redPillPnlHistory;
  final List<double> bitcoinPnlHistory;
  final List<double> ethereumPnlHistory;
  final List<double> solanaPnlHistory;
  final List<double> browneCoinPnlHistory; // Add this line
  final List<double> totalWealthHistory;
  final double usdBalance;
  final Function(int, int, int, int, int, int, double) onTrade; // Update parameters to include BrowneCoin
  final VoidCallback onClose;

  const PortfolioScreen({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.ethereumCollected,
    required this.solanaCollected,
    required this.browneCoinCollected, // Add this line
    required this.lionsManePnlHistory,
    required this.redPillPnlHistory,
    required this.bitcoinPnlHistory,
    required this.ethereumPnlHistory,
    required this.solanaPnlHistory,
    required this.browneCoinPnlHistory, // Add this line
    required this.totalWealthHistory,
    required this.usdBalance,
    required this.onTrade,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Add this line to declare the market manager variable
  late CryptoMarketManager _marketManager;
  
  // Add this line to declare the timer variable
  late Timer _uiUpdateTimer;
  
  // Constants for exchange rates
  final double _lionsManeRate = 100.0;
  final double _redPillRate = 500.0;
  
  // Local state variables to track asset quantities
  late int _lionsManeCount;
  late int _redPillCount;
  late int _bitcoinCount;
  late int _ethereumCount;
  late int _solanaCount; // Add Solana count
  late int _browneCoinCount; // Add this line
  late double _usdBalance;
  
  // Bitcoin price simulation variables
  late double _currentBtcPrice;
  final double _minBtcPrice = 60000.0;
  final double _maxBtcPrice = 100000.0;
  List<double> _btcPriceHistory = [];
  
  // Ethereum price simulation variables
  late double _currentEthPrice;
  final double _minEthPrice = 3000.0;
  final double _maxEthPrice = 6000.0;
  List<double> _ethPriceHistory = [];
  
  // Solana price simulation variables - more volatile
  late double _currentSolPrice;
  final double _minSolPrice = 50.0;
  final double _maxSolPrice = 300.0;
  List<double> _solPriceHistory = [];
  
  // BrowneCoin price simulation variables - highly volatile
  late double _currentBrowneCoinPrice;
  final double _minBrowneCoinPrice = 1.0;
  final double _maxBrowneCoinPrice = 10.0;
  List<double> _browneCoinPriceHistory = [];
  
  // Trading state
  final TextEditingController _buyBtcAmountController = TextEditingController();
  final TextEditingController _sellBtcAmountController = TextEditingController();
  final TextEditingController _buyEthAmountController = TextEditingController();
  final TextEditingController _sellEthAmountController = TextEditingController();
  final TextEditingController _buySolAmountController = TextEditingController();
  final TextEditingController _sellSolAmountController = TextEditingController();
  final TextEditingController _buyBrowneCoinAmountController = TextEditingController();
  final TextEditingController _sellBrowneCoinAmountController = TextEditingController();
  
  // Price chart variables
  final int _maxPriceHistoryPoints = 50;
  final Color _matrixGreen = const Color(0xFF00FF41);
  final Color _matrixBlack = const Color(0xFF0D0208);
  final Color _ethereumBlue = const Color(0xFF3C3C3D); // Ethereum brand color
  final Color _solanaPurple = const Color(0xFF9945FF); // Solana brand color
  String _selectedTimeframe = '1H';
  String _selectedEthTimeframe = '1H';
  String _selectedSolTimeframe = '1H';
  String _selectedBrowneCoinTimeframe = '1H'; // Add this line

  // Getters for max tradable amounts
  double get maxBtcCanBuy {
    if (_currentBtcPrice <= 0) return 0;
    return _usdBalance / _currentBtcPrice;
  }

  double get maxEthCanBuy {
    if (_currentEthPrice <= 0) return 0;
    return _usdBalance / _currentEthPrice;
  }

  double get maxSolCanBuy {
    if (_currentSolPrice <= 0) return 0;
    return _usdBalance / _currentSolPrice;
  }

  double get maxBrowneCoinCanBuy {
    if (_currentBrowneCoinPrice <= 0) return 0;
    return _usdBalance / _currentBrowneCoinPrice;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Initialize local state with widget values
    _lionsManeCount = widget.lionsManeCollected;
    _redPillCount = widget.redPillCollected;
    _bitcoinCount = widget.bitcoinCollected;
    _ethereumCount = widget.ethereumCollected;
    _solanaCount = widget.solanaCollected;
    _browneCoinCount = widget.browneCoinCollected; // Add this line
    _usdBalance = widget.usdBalance;
    
    // Get the singleton market manager instance
    _marketManager = CryptoMarketManager();
    
    // Initialize price histories from the market manager
    _currentBtcPrice = _marketManager.bitcoin.currentPrice;
    _currentEthPrice = _marketManager.ethereum.currentPrice;
    _currentSolPrice = _marketManager.solana.currentPrice;
    _currentBrowneCoinPrice = _marketManager.browneCoin.currentPrice; // Add this line
    
    // Create initial price histories if needed
    _btcPriceHistory = _marketManager.bitcoin.priceHistory
        .map((point) => point.price)
        .toList();
        
    _ethPriceHistory = _marketManager.ethereum.priceHistory
        .map((point) => point.price)
        .toList();
        
    _solPriceHistory = _marketManager.solana.priceHistory
        .map((point) => point.price)
        .toList();
        
    _browneCoinPriceHistory = _marketManager.browneCoin.priceHistory
        .map((point) => point.price)
        .toList(); // Add this line
    
    // Set up a timer to periodically refresh the UI with latest prices
    _uiUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentBtcPrice = _marketManager.bitcoin.currentPrice;
          _btcPriceHistory = _marketManager.bitcoin.priceHistory
              .map((point) => point.price)
              .toList();
              
          _currentEthPrice = _marketManager.ethereum.currentPrice;
          _ethPriceHistory = _marketManager.ethereum.priceHistory
              .map((point) => point.price)
              .toList();
              
          _currentSolPrice = _marketManager.solana.currentPrice;
          _solPriceHistory = _marketManager.solana.priceHistory
              .map((point) => point.price)
              .toList();
              
          _currentBrowneCoinPrice = _marketManager.browneCoin.currentPrice; // Add this line
          _browneCoinPriceHistory = _marketManager.browneCoin.priceHistory
              .map((point) => point.price)
              .toList(); // Add this line
        });
      } else {
        // If widget is no longer mounted, cancel the timer
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _uiUpdateTimer.cancel();
    _buyBtcAmountController.dispose();
    _sellBtcAmountController.dispose();
    _buyEthAmountController.dispose();
    _sellEthAmountController.dispose();
    _buySolAmountController.dispose();
    _sellSolAmountController.dispose();
    _buyBrowneCoinAmountController.dispose();
    _sellBrowneCoinAmountController.dispose();
    super.dispose();
  }
  
  // Calculate total USD value of portfolio
  double get _totalUsdValue {
    double btcValue = _bitcoinCount * _currentBtcPrice;
    double ethValue = _ethereumCount * _currentEthPrice;
    double solValue = _solanaCount * _currentSolPrice; // Add Solana value
    double browneCoinValue = _browneCoinCount * _currentBrowneCoinPrice; // Add this line
    double lionsManeValue = _lionsManeCount * _lionsManeRate;
    double redPillValue = _redPillCount * _redPillRate;
    return _usdBalance + btcValue + ethValue + solValue + browneCoinValue + lionsManeValue + redPillValue;
  }
  
  // Exchange one Lions Mane to USD
  void _exchangeLionsMane() {
    if (_lionsManeCount > 0) {
      double usdAmount = _lionsManeRate;
      
      // Update local state first
      setState(() {
        _lionsManeCount -= 1;
        _usdBalance += usdAmount;
      });
      
      // Then notify parent component
      if (widget.onTrade != null) {
        // Call the parent's onTrade callback to update the values
        widget.onTrade!(-1, 0, 0, 0, 0, 0, usdAmount);  // Fixed: Added 0 for Solana and BrowneCoin
      }
    }
  }
  
  // Exchange one Red Pill to USD
  void _exchangeRedPill() {
    if (_redPillCount > 0) {
      double usdAmount = _redPillRate;
      
      // Update local state first
      setState(() {
        _redPillCount -= 1;
        _usdBalance += usdAmount;
      });
      
      // Then notify parent component
      if (widget.onTrade != null) {
        // Call the parent's onTrade callback to update the values
        widget.onTrade!(0, -1, 0, 0, 0, 0, usdAmount);  // Fixed: Added 0 for Solana and BrowneCoin
      }
    }
  }
  
  // Buy Bitcoin with USD
  void _buyBitcoin() {
    // Try to parse the input as a number
    double? amount = double.tryParse(_buyBtcAmountController.text);
    if (amount != null && amount > 0) {
      // Calculate USD cost
      double usdCost = amount * _currentBtcPrice;
      
      // Check if user has enough USD
      if (_usdBalance >= usdCost) {
        // Round down to nearest integer for BTC amount since game only handles whole BTC
        int btcAmount = amount.floor();
        if (btcAmount <= 0) return; // Don't process transactions less than 1 BTC
        
        // Recalculate the actual cost using the rounded BTC amount
        usdCost = btcAmount * _currentBtcPrice;
        
        // Update local state
        setState(() {
          _bitcoinCount += btcAmount;
          _usdBalance -= usdCost;
          _buyBtcAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          // Call the parent's onTrade callback
          widget.onTrade!(0, 0, btcAmount, 0, 0, 0, -usdCost);  // Fixed: Added 0 for Solana and BrowneCoin
        }
      } else {
        // Show error message if not enough USD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough USD for this purchase'))
        );
      }
    }
  }
  
  // Sell Bitcoin for USD
  void _sellBitcoin() {
    // Try to parse the input as a number
    double? amount = double.tryParse(_sellBtcAmountController.text);
    if (amount != null && amount > 0) {
      // Round to integer since game only handles whole BTC
      int btcAmount = amount.floor();
      if (btcAmount <= 0) return; // Don't process transactions less than 1 BTC
      
      // Check if user has enough BTC
      if (_bitcoinCount >= btcAmount) {
        // Calculate USD amount to receive
        double usdAmount = btcAmount * _currentBtcPrice;
        
        // Update local state first
        setState(() {
          _bitcoinCount -= btcAmount;
          _usdBalance += usdAmount;
          _sellBtcAmountController.clear();
        });
        
        // Then notify parent component
        if (widget.onTrade != null) {
          // Call the parent's onTrade callback
          widget.onTrade!(0, 0, -btcAmount, 0, 0, 0, usdAmount);  // Fixed: Added 0 for Solana and BrowneCoin
        }

        // Confirm message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sold $btcAmount Bitcoin for \$${usdAmount.toStringAsFixed(2)}'))
        );
      } else {
        // Show error message if not enough BTC
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough Bitcoin to sell'))
        );
      }
    }
  }
  
  // Buy Ethereum with USD
  void _buyEthereum() {
    double? amount = double.tryParse(_buyEthAmountController.text);
    if (amount != null && amount > 0) {
      double usdCost = amount * _currentEthPrice;
      
      if (_usdBalance >= usdCost) {
        int ethAmount = amount.floor();
        if (ethAmount <= 0) return;
        
        usdCost = ethAmount * _currentEthPrice;
        
        setState(() {
          _ethereumCount += ethAmount;
          _usdBalance -= usdCost;
          _buyEthAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, ethAmount, 0, 0, -usdCost);  // Fixed: Added 0 for Solana and BrowneCoin
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough USD for this purchase'))
        );
      }
    }
  }
  
  // Sell Ethereum for USD
  void _sellEthereum() {
    double? amount = double.tryParse(_sellEthAmountController.text);
    if (amount != null && amount > 0) {
      int ethAmount = amount.floor();
      if (ethAmount <= 0) return;
      
      if (_ethereumCount >= ethAmount) {
        double usdAmount = ethAmount * _currentEthPrice;
        
        setState(() {
          _ethereumCount -= ethAmount;
          _usdBalance += usdAmount;
          _sellEthAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, -ethAmount, 0, 0, usdAmount);  // Fixed: Added 0 for Solana and BrowneCoin
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sold $ethAmount Ethereum for \$${usdAmount.toStringAsFixed(2)}'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough Ethereum to sell'))
        );
      }
    }
  }
  
  // Buy Solana with USD
  void _buySolana() {
    double? amount = double.tryParse(_buySolAmountController.text);
    if (amount != null && amount > 0) {
      double usdCost = amount * _currentSolPrice;
      
      if (_usdBalance >= usdCost) {
        int solAmount = amount.floor();
        if (solAmount <= 0) return;
        
        usdCost = solAmount * _currentSolPrice;
        
        setState(() {
          _solanaCount += solAmount;
          _usdBalance -= usdCost;
          _buySolAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, 0, solAmount, 0, -usdCost);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough USD for this purchase'))
        );
      }
    }
  }
  
  // Sell Solana for USD
  void _sellSolana() {
    double? amount = double.tryParse(_sellSolAmountController.text);
    if (amount != null && amount > 0) {
      int solAmount = amount.floor();
      if (solAmount <= 0) return;
      
      if (_solanaCount >= solAmount) {
        double usdAmount = solAmount * _currentSolPrice;
        
        setState(() {
          _solanaCount -= solAmount;
          _usdBalance += usdAmount;
          _sellSolAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, 0, -solAmount, 0, usdAmount);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sold $solAmount Solana for \$${usdAmount.toStringAsFixed(2)}'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough Solana to sell'))
        );
      }
    }
  }
  
  // Buy BrowneCoin with USD
  void _buyBrowneCoin() {
    double? amount = double.tryParse(_buyBrowneCoinAmountController.text);
    if (amount != null && amount > 0) {
      double usdCost = amount * _currentBrowneCoinPrice;
      
      if (_usdBalance >= usdCost) {
        int browneCoinAmount = amount.floor();
        if (browneCoinAmount <= 0) return;
        
        usdCost = browneCoinAmount * _currentBrowneCoinPrice;
        
        setState(() {
          _browneCoinCount += browneCoinAmount;
          _usdBalance -= usdCost;
          _buyBrowneCoinAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, 0, 0, browneCoinAmount, -usdCost);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough USD for this purchase'))
        );
      }
    }
  }
  
  // Sell BrowneCoin for USD
  void _sellBrowneCoin() {
    double? amount = double.tryParse(_sellBrowneCoinAmountController.text);
    if (amount != null && amount > 0) {
      int browneCoinAmount = amount.floor();
      if (browneCoinAmount <= 0) return;
      
      if (_browneCoinCount >= browneCoinAmount) {
        double usdAmount = browneCoinAmount * _currentBrowneCoinPrice;
        
        setState(() {
          _browneCoinCount -= browneCoinAmount;
          _usdBalance += usdAmount;
          _sellBrowneCoinAmountController.clear();
        });
        
        if (widget.onTrade != null) {
          widget.onTrade!(0, 0, 0, 0, 0, -browneCoinAmount, usdAmount);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sold $browneCoinAmount BrowneCoin for \$${usdAmount.toStringAsFixed(2)}'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough BrowneCoin to sell'))
        );
      }
    }
  }
  
  // Price trend indicator widget
  Widget _buildPriceTrend(List<double> history, Color color) {
    if (history.length <= 1) {
      return Container(height: 50, width: 100, color: Colors.black);
    }

    // Scale the data points
    double minValue = history.reduce((curr, next) => curr < next ? curr : next);
    double maxValue = history.reduce((curr, next) => curr > next ? curr : next);
    double range = maxValue - minValue;
    
    if (range == 0) range = 1; // Avoid division by zero
    
    List<Offset> points = [];
    for (int i = 0; i < history.length; i++) {
      double x = i / (history.length - 1);
      double normalizedY = (history[i] - minValue) / range;
      double y = 1.0 - normalizedY; // invert to match UI coordinates
      points.add(Offset(x, y));
    }

    return Container(
      height: 50,
      width: 100,
      child: CustomPaint(
        size: const Size(100, 50),
        painter: _ChartPainter(points, color),
      ),
    );
  }

  // Build graph segment button for timeframe selection
  Widget _buildGraphSegment(List<double> data, Color color, String label) {
    return Container(
      width: 120, // Fixed width to prevent overflow
      child: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildPriceTrend(data, color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // Asset card widget for portfolio items
  Widget _buildAssetCard(String name, String imageAsset, int quantity, double rate, double totalValue, {bool canExchange = false, VoidCallback? onExchange}) {
    Color valueColor = Colors.white;
    if (name == 'Bitcoin') valueColor = _matrixGreen;
    else if (name == 'Ethereum') valueColor = Colors.blueAccent;
    else if (name == 'Solana') valueColor = _solanaPurple;
    else if (name == 'BrowneCoin') valueColor = Colors.orange; // Add this line
    
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
                if (name == 'Bitcoin') _buildPriceTrend(_btcPriceHistory, _matrixGreen),
                if (name == 'Ethereum') _buildPriceTrend(_ethPriceHistory, Colors.blueAccent),
                if (name == 'Solana') _buildPriceTrend(_solPriceHistory, _solanaPurple),
                if (name == 'BrowneCoin') _buildPriceTrend(_browneCoinPriceHistory, Colors.orange), // Add this line
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
                        color: valueColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (canExchange) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: quantity > 0 ? onExchange : null,
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
  Widget _buildPriceChart(List<double> priceHistory, double minPrice, double maxPrice, Color lineColor) {
    if (priceHistory.isEmpty) {
      return Center(
        child: Text(
          'Loading price data...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    // Find actual min/max from the actual data
    double actualMinPrice = priceHistory.reduce((a, b) => a < b ? a : b);
    double actualMaxPrice = priceHistory.reduce((a, b) => a > b ? a : b);
    
    // Use actual price range instead of fixed values
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _BitcoinPriceChartPainter(
            priceHistory: priceHistory,
            minPrice: actualMinPrice,
            maxPrice: actualMaxPrice,
            lineColor: lineColor,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Portfolio', style: TextStyle(color: Colors.white)),
        leading: widget.onClose != null ? 
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onClose,
          ) : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true, // Make tabs scrollable to fit 6 tabs
                tabs: [
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Trade'),
                  Tab(text: 'Bitcoin'),
                  Tab(text: 'Ethereum'),
                  Tab(text: 'Solana'),
                  Tab(text: 'BrowneCoin'), // Add this line
                ],
                onTap: (int index) {
                  setState(() {}); // Force rebuild on tab change to ensure charts display
                },
              ),
              const Divider(height: 1, color: Colors.grey),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ScrollingBackground(scrollSpeed: 80.0),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Portfolio Tab - Overview of assets
                SingleChildScrollView(
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
                        _bitcoinCount,
                        _currentBtcPrice,
                        _bitcoinCount * _currentBtcPrice,
                      ),
                      
                      // Ethereum Asset Card
                      _buildAssetCard(
                        'Ethereum',
                        'assets/images/eth.png',
                        _ethereumCount,
                        _currentEthPrice,
                        _ethereumCount * _currentEthPrice,
                      ),
                      
                      // Solana Asset Card
                      _buildAssetCard(
                        'Solana',
                        'assets/images/solana.png',
                        _solanaCount,
                        _currentSolPrice,
                        _solanaCount * _currentSolPrice,
                      ),
                      
                      // BrowneCoin Asset Card
                      _buildAssetCard(
                        'BrowneCoin',
                        'assets/images/brownecoin.png', // FIXED - removed underscore
                        _browneCoinCount,
                        _currentBrowneCoinPrice,
                        _browneCoinCount * _currentBrowneCoinPrice,
                      ),
                      
                      // Lions Mane Asset Card
                      _buildAssetCard(
                        'Lions Mane',
                        'assets/images/lions_mane.png',
                        _lionsManeCount,
                        _lionsManeRate,
                        _lionsManeCount * _lionsManeRate,
                        canExchange: true,
                        onExchange: _lionsManeCount > 0 ? _exchangeLionsMane : null,
                      ),
                      
                      // Red Pill Asset Card
                      _buildAssetCard(
                        'Red Pill',
                        'assets/images/red_pill.png',
                        _redPillCount,
                        _redPillRate,
                        _redPillCount * _redPillRate,
                        canExchange: true,
                        onExchange: _redPillCount > 0 ? _exchangeRedPill : null,
                      ),
                    ],
                  ),
                ),
                
                // Trade Tab - Buy/sell cryptocurrencies
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bitcoin section
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bitcoin Price',
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
                                  _buildPriceTrend(_btcPriceHistory, _matrixGreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Ethereum section
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ethereum Price',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$${_currentEthPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildPriceTrend(_ethPriceHistory, Colors.blueAccent),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Solana section
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solana Price',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$${_currentSolPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildPriceTrend(_solPriceHistory, _solanaPurple),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // BrowneCoin section
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BrowneCoin Price',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '\$${_currentBrowneCoinPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildPriceTrend(_browneCoinPriceHistory, Colors.orange), // Add this line
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Buy/Sell Bitcoin UI
                      SizedBox(height: 24),
                      Text(
                        'Bitcoin Trading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Buy Bitcoin
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buy Bitcoin',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _buyBtcAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'BTC Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('BTC', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _usdBalance > 0 ? _buyBitcoin : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Sell Bitcoin
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sell Bitcoin',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _sellBtcAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'BTC Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('BTC', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _bitcoinCount > 0 ? _sellBitcoin : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Sell'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Buy/Sell Ethereum UI
                      Text(
                        'Ethereum Trading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Buy Ethereum
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buy Ethereum',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _buyEthAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'ETH Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('ETH', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _usdBalance > 0 ? _buyEthereum : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Sell Ethereum
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sell Ethereum',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _sellEthAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'ETH Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('ETH', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _ethereumCount > 0 ? _sellEthereum : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Sell'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Buy/Sell Solana UI
                      Text(
                        'Solana Trading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Buy Solana
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buy Solana',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _buySolAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'SOL Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('SOL', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _usdBalance > 0 ? _buySolana : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Sell Solana
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sell Solana',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _sellSolAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'SOL Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('SOL', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _solanaCount > 0 ? _sellSolana : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Sell'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Buy/Sell BrowneCoin UI
                      Text(
                        'BrowneCoin Trading',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Buy BrowneCoin
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buy BrowneCoin',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _buyBrowneCoinAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'BrowneCoin Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('BrowneCoin', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _usdBalance > 0 ? _buyBrowneCoin : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Buy'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Sell BrowneCoin
                          Expanded(
                            child: Card(
                              color: Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sell BrowneCoin',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _sellBrowneCoinAmountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'BrowneCoin Amount',
                                        labelStyle: const TextStyle(color: Colors.white70),
                                        suffix: const Text('BrowneCoin', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _browneCoinCount > 0 ? _sellBrowneCoin : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Sell'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bitcoin Tab - Price chart and analysis
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bitcoin Price',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${_currentBtcPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                      
                      SizedBox(height: 20),
                      
                      // Timeframe selector
                      Container(
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTimeframeButton('1H', _selectedTimeframe == '1H'),
                              _buildTimeframeButton('24H', _selectedTimeframe == '24H'),
                              _buildTimeframeButton('1W', _selectedTimeframe == '1W'),
                              _buildTimeframeButton('1M', _selectedTimeframe == '1M'),
                              _buildTimeframeButton('1Y', _selectedTimeframe == '1Y'),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Price chart
                      Container(
                        height: 300, // Fixed height ensures the chart is visible
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: _buildPriceChart(_btcPriceHistory, _minBtcPrice, _maxBtcPrice, _matrixGreen),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Market statistics
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                    ],
                  ),
                ),
                
                // Ethereum Tab - Price chart and analysis
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ethereum Price',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${_currentEthPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'ETH/USD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Timeframe selector
                      Container(
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTimeframeButton('1H', _selectedEthTimeframe == '1H', Colors.blueAccent),
                              _buildTimeframeButton('24H', _selectedEthTimeframe == '24H', Colors.blueAccent),
                              _buildTimeframeButton('1W', _selectedEthTimeframe == '1W', Colors.blueAccent),
                              _buildTimeframeButton('1M', _selectedEthTimeframe == '1M', Colors.blueAccent),
                              _buildTimeframeButton('1Y', _selectedEthTimeframe == '1Y', Colors.blueAccent),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Price chart
                      Container(
                        height: 300, // Fixed height ensures the chart is visible
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: _buildPriceChart(_ethPriceHistory, _minEthPrice, _maxEthPrice, Colors.blueAccent),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Market statistics
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                                  _buildStatItem('24h High', '\$${(_currentEthPrice * 1.05).toStringAsFixed(2)}'),
                                  _buildStatItem('24h Low', '\$${(_currentEthPrice * 0.95).toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('All-Time High', '\$6,000.00'),
                                  _buildStatItem('All-Time Low', '\$3,000.00'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Solana Tab - Price chart and analysis
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solana Price',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${_currentSolPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'SOL/USD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Timeframe selector
                      Container(
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTimeframeButton('1H', _selectedSolTimeframe == '1H', _solanaPurple),
                              _buildTimeframeButton('24H', _selectedSolTimeframe == '24H', _solanaPurple),
                              _buildTimeframeButton('1W', _selectedSolTimeframe == '1W', _solanaPurple),
                              _buildTimeframeButton('1M', _selectedSolTimeframe == '1M', _solanaPurple),
                              _buildTimeframeButton('1Y', _selectedSolTimeframe == '1Y', _solanaPurple),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Price chart
                      Container(
                        height: 300, // Fixed height ensures the chart is visible
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: _buildPriceChart(_solPriceHistory, _minSolPrice, _maxSolPrice, _solanaPurple),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Market statistics
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                                  _buildStatItem('24h High', '\$${(_currentSolPrice * 1.15).toStringAsFixed(2)}'),
                                  _buildStatItem('24h Low', '\$${(_currentSolPrice * 0.85).toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('All-Time High', '\$300.00'),
                                  _buildStatItem('All-Time Low', '\$50.00'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // BrowneCoin Tab - Price chart and analysis
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BrowneCoin Price',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${_currentBrowneCoinPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'BrowneCoin/USD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Timeframe selector
                      Container(
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTimeframeButton('1H', _selectedBrowneCoinTimeframe == '1H', Colors.orange),
                              _buildTimeframeButton('24H', _selectedBrowneCoinTimeframe == '24H', Colors.orange),
                              _buildTimeframeButton('1W', _selectedBrowneCoinTimeframe == '1W', Colors.orange),
                              _buildTimeframeButton('1M', _selectedBrowneCoinTimeframe == '1M', Colors.orange),
                              _buildTimeframeButton('1Y', _selectedBrowneCoinTimeframe == '1Y', Colors.orange),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Price chart
                      Container(
                        height: 300, // Fixed height ensures the chart is visible
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: _buildPriceChart(_browneCoinPriceHistory, _minBrowneCoinPrice, _maxBrowneCoinPrice, Colors.orange),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Market statistics
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                                  _buildStatItem('24h High', '\$${(_currentBrowneCoinPrice * 1.15).toStringAsFixed(2)}'),
                                  _buildStatItem('24h Low', '\$${(_currentBrowneCoinPrice * 0.85).toStringAsFixed(2)}'),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('All-Time High', '\$10.00'),
                                  _buildStatItem('All-Time Low', '\$1.00'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Sketchy dev warning about BrowneCoin
                      SizedBox(height: 20),
                      Card(
                        color: Colors.red[900]?.withOpacity(0.7),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.yellow),
                                  SizedBox(width: 8),
                                  Text(
                                    'Warning: Sketchy Dev and High Volatility',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'BrowneCoin is developed by a questionable team! Expect extreme price volatility and potential rug pulls. Trade at your own risk.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Updated to accept optional color parameter
  Widget _buildTimeframeButton(String timeframe, bool isSelected, [Color color = const Color(0xFF00FF41)]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (color == Colors.blueAccent) {
            _selectedEthTimeframe = timeframe;
          } else if (color == _solanaPurple) {
            _selectedSolTimeframe = timeframe;
          } else if (color == Colors.orange) {
            _selectedBrowneCoinTimeframe = timeframe; // Add this line
          } else {
            _selectedTimeframe = timeframe;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Text(
          timeframe,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
    
    // Calculate the actual min/max prices from the history
    final actualMinPrice = priceHistory.reduce((a, b) => a < b ? a : b);
    final actualMaxPrice = priceHistory.reduce((a, b) => a > b ? a : b);
    
    // Add 10% padding to the price range
    final range = (actualMaxPrice - actualMinPrice) * 1.1;
    final paddedMin = actualMinPrice - range * 0.05;
    final paddedMax = actualMaxPrice + range * 0.05;
    
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < priceHistory.length; i++) {
      final x = size.width * i / (priceHistory.length - 1);
      // Invert Y coordinate because canvas origin is top-left
      final y = size.height - ((priceHistory[i] - paddedMin) / (paddedMax - paddedMin) * size.height);
      
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
    _drawPriceMarkers(canvas, size, paddedMin, paddedMax - paddedMin);
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
        text: '\$${price.toStringAsFixed(2)}',
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

// Chart painter for price trends
class _ChartPainter extends CustomPainter {
  final List<Offset> points;
  final Color lineColor;

  _ChartPainter(this.points, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(0, points.first.dy * size.height);
      
      for (int i = 1; i < points.length; i++) {
        final point = points[i];
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => 
    oldDelegate.points != points || 
    oldDelegate.lineColor != lineColor;
}
