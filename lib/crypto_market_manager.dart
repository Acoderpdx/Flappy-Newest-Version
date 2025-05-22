import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'crypto_price_model.dart';

class CryptoMarketManager {
  // Singleton pattern
  static final CryptoMarketManager _instance = CryptoMarketManager._internal();
  factory CryptoMarketManager() => _instance;
  CryptoMarketManager._internal();
  
  // Available cryptocurrencies
  late CryptoCurrency bitcoin;
  late CryptoCurrency ethereum;
  late CryptoCurrency solana;
  late CryptoCurrency browneCoin; // Add this line
  
  // Timer for background updates
  Timer? _updateTimer;
  
  // State
  bool _initialized = false;
  
  // Market events callbacks
  Function(String symbol, double percentage)? onSignificantPriceChange;
  Function(String headline, String symbol, bool isBullish)? onCryptoNewsEvent;
  
  void initialize() {
    if (_initialized) return;
    
    // Create crypto coins with realistic initial prices
    bitcoin = CryptoCurrency(
      name: "Bitcoin",
      symbol: "BTC", 
      imagePath: "assets/images/bitcoin.png",
      color: Colors.amber,
      initialPrice: 40000.0 + (Random().nextDouble() * 10000),  // $40-50k
    );
    
    ethereum = CryptoCurrency(
      name: "Ethereum",
      symbol: "ETH", 
      imagePath: "assets/images/eth.png",
      color: Colors.blueGrey,
      initialPrice: 2000.0 + (Random().nextDouble() * 1000),  // $2-3k
    );
    
    solana = CryptoCurrency(
      name: "Solana",
      symbol: "SOL", 
      imagePath: "assets/images/solana.png",
      color: Colors.purple,
      initialPrice: 80.0 + (Random().nextDouble() * 40),  // $80-120
    );
    
    // Add BrowneCoin initialization
    browneCoin = CryptoCurrency(
      name: "BrowneCoin",
      symbol: "BRWN", 
      imagePath: "assets/images/brownecoin.png",
      color: Colors.orange,
      initialPrice: 1.0 + (Random().nextDouble() * 9.0),  // Start between $1-10
    );
    
    // Start the background update timer (updates every 5 seconds for more visible movement)
    _updateTimer = Timer.periodic(Duration(seconds: 5), (_) => _updatePrices());
    
    _initialized = true;
  }
  
  void dispose() {
    _updateTimer?.cancel();
  }
  
  void _updatePrices() {
    if (!_initialized) return;
    
    bitcoin.updatePrice();
    ethereum.updatePrice();
    solana.updatePrice();
    browneCoin.updatePrice(); // Add this line
    
    // Check for significant price changes (more than 5% since last hour)
    _checkForSignificantChanges(bitcoin);
    _checkForSignificantChanges(ethereum);
    _checkForSignificantChanges(solana);
    _checkForSignificantChanges(browneCoin); // Add this line
    
    // Occasional market events
    if (Random().nextDouble() < 0.01) { // 1% chance per update
      _generateMarketEvent();
    }
  }
  
  void _checkForSignificantChanges(CryptoCurrency crypto) {
    if (crypto.priceHistory.length < 2) return;
    
    // Find data from ~1 hour ago
    DateTime hourAgo = DateTime.now().subtract(Duration(hours: 1));
    PricePoint? oldPoint;
    try {
      oldPoint = crypto.priceHistory.firstWhere(
        (point) => point.timestamp.isBefore(hourAgo),
        orElse: () => crypto.priceHistory.first
      );
    } catch (e) {
      return;
    }
    
    double hourlyChangePercent = (crypto.currentPrice - oldPoint.price) / oldPoint.price * 100;
    
    // Only notify of >5% changes
    if (hourlyChangePercent.abs() >= 5.0 && onSignificantPriceChange != null) {
      onSignificantPriceChange!(crypto.symbol, hourlyChangePercent);
    }
  }
  
  // Get all currencies as a list for easy iteration
  List<CryptoCurrency> getAllCurrencies() {
    return [bitcoin, ethereum, solana, browneCoin]; // Add browneCoin to this list
  }
  
  // News events that impact market
  List<String> _bullishNews = [
    "Major bank announces Bitcoin integration",
    "New ETF approval boosts crypto market",
    "Tech giant adds crypto to balance sheet",
    "Country adopts crypto as legal tender",
    "Institutional investors pour billions into crypto"
  ];

  List<String> _bearishNews = [
    "Regulatory crackdown on crypto exchanges",
    "Major hack affects blockchain security",
    "Central bank warns against crypto risks",
    "Mining operations face new restrictions",
    "Large holder liquidates position"
  ];

  void _generateMarketEvent() {
    if (!_initialized) return;
    
    CryptoCurrency affectedCoin = getAllCurrencies()[Random().nextInt(getAllCurrencies().length)];
    bool isBullish = Random().nextBool();
    
    String newsHeadline = isBullish 
        ? _bullishNews[Random().nextInt(_bullishNews.length)]
        : _bearishNews[Random().nextInt(_bearishNews.length)];
    
    // Apply stronger market movement
    double impactFactor = (0.1 + (Random().nextDouble() * 0.2)) * (isBullish ? 1 : -1);
    affectedCoin.currentPrice *= (1 + impactFactor);
    
    // Force market phase based on news
    affectedCoin.currentPhase = isBullish ? MarketPhase.bull : MarketPhase.bear;
    affectedCoin.phaseDuration = Random().nextInt(30) + 20;
    affectedCoin.phaseLength = affectedCoin.phaseDuration;
    
    // Notify about news
    if (onCryptoNewsEvent != null) {
      onCryptoNewsEvent!(newsHeadline, affectedCoin.symbol, isBullish);
    }
  }
}