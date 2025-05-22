import 'dart:math';
import 'package:flutter/material.dart';

class PricePoint {
  final DateTime timestamp;
  final double price;
  
  PricePoint(this.timestamp, this.price);
}

enum MarketPhase {
  bull,    // Prices tend to rise
  bear,    // Prices tend to fall
  sideways // Prices move with higher volatility but no strong trend
}

class CryptoCurrency {
  final String name;
  final String symbol;
  final String imagePath;
  final Color color;
  
  // Current state
  double currentPrice;
  MarketPhase currentPhase;
  double volatility; // 0.0 to 1.0, affects price movement magnitude
  int phaseDuration; // How many more updates until phase might change
  int phaseLength; // Total length of current phase
  
  // Historical data
  List<PricePoint> priceHistory = [];
  
  // Track all-time high/low for display purposes
  double allTimeHigh;
  double allTimeLow;
  
  CryptoCurrency({
    required this.name,
    required this.symbol,
    required this.imagePath,
    required this.color,
    required double initialPrice,
  }) : 
    currentPrice = initialPrice,
    allTimeHigh = initialPrice,
    allTimeLow = initialPrice,
    currentPhase = MarketPhase.values[Random().nextInt(MarketPhase.values.length)],
    volatility = 0.3 + (Random().nextDouble() * 0.3), // Random initial volatility
    phaseDuration = Random().nextInt(100) + 50, // Random initial phase duration
    phaseLength = Random().nextInt(100) + 50 {
      // Generate initial historical price data (24 hours of simulated data)
      _generateInitialPriceHistory();
    }
  
  // Generate a reasonable amount of historical data
  void _generateInitialPriceHistory() {
    // Generate 24 hours of data points, 1 per hour (24 points)
    DateTime now = DateTime.now();
    double price = currentPrice;
    
    // First, generate older history with more variance for realistic look
    for (int i = 24; i > 0; i--) {
      // Apply some random variance to create realistic price history
      // Older price points have more variance
      double variance = (Random().nextDouble() - 0.5) * (currentPrice * 0.15);
      double historicalPrice = currentPrice + variance;
      
      // Ensure price doesn't go below reasonable level
      if (historicalPrice < currentPrice * 0.5) {
        historicalPrice = currentPrice * 0.5;
      }
      
      // Create timestamp for this historical point
      DateTime timestamp = now.subtract(Duration(hours: i));
      
      // Add to price history
      priceHistory.add(PricePoint(timestamp, historicalPrice));
      
      // Track max and min
      if (historicalPrice > allTimeHigh) allTimeHigh = historicalPrice;
      if (historicalPrice < allTimeLow) allTimeLow = historicalPrice;
    }
    
    // Add current price as most recent point
    priceHistory.add(PricePoint(now, currentPrice));
  }
  
  // Update price based on current market conditions
  void updatePrice() {
    // Maybe change market phase
    if (--phaseDuration <= 0) {
      _switchMarketPhase();
    }
    
    // Base movement range as percentage of current price
    double baseMovement = currentPrice * 0.005; // 0.5% base movement
    
    // Apply volatility multiplier
    double volatilityFactor = volatility * 4.0;
    
    // Apply trend direction based on market phase
    double trendDirection;
    switch (currentPhase) {
      case MarketPhase.bull:
        trendDirection = 0.6; // Positive bias
        break;
      case MarketPhase.bear:
        trendDirection = -0.6; // Negative bias
        break;
      case MarketPhase.sideways:
      default:
        trendDirection = 0.0; // No bias
    }
    
    // Random component (-1.0 to 1.0)
    double randomFactor = (Random().nextDouble() * 2.0 - 1.0);
    
    // Combine trend and randomness 
    double combinedDirection = trendDirection + (randomFactor * (1.0 - trendDirection.abs()));
    
    // Calculate final price movement
    double priceChange = baseMovement * combinedDirection * volatilityFactor;
    
    // Apply price change
    double newPrice = currentPrice + priceChange;
    
    // Ensure price doesn't go negative
    if (newPrice <= 0) newPrice = currentPrice * 0.9;
    
    // Update current price
    currentPrice = newPrice;
    
    // Update all-time high and low
    if (currentPrice > allTimeHigh) allTimeHigh = currentPrice;
    if (currentPrice < allTimeLow) allTimeLow = currentPrice;
    
    // Add to price history
    priceHistory.add(PricePoint(DateTime.now(), currentPrice));
    
    // Limit history size (keep last 24 hours of data points)
    DateTime cutoff = DateTime.now().subtract(Duration(hours: 24));
    priceHistory = priceHistory.where((point) => point.timestamp.isAfter(cutoff)).toList();
  }
  
  // Switch to a new market phase
  void _switchMarketPhase() {
    // Decide on next phase with some rules for more realism
    List<MarketPhase> possiblePhases = MarketPhase.values.toList();
    
    if (currentPhase == MarketPhase.bull) {
      // After bull, more likely to go sideways or bear
      possiblePhases = [MarketPhase.bear, MarketPhase.sideways, MarketPhase.sideways, MarketPhase.bull];
    } else if (currentPhase == MarketPhase.bear) {
      // After bear, more likely to go sideways or bull
      possiblePhases = [MarketPhase.bull, MarketPhase.sideways, MarketPhase.sideways, MarketPhase.bear];
    }
    
    currentPhase = possiblePhases[Random().nextInt(possiblePhases.length)];
    
    // Set new phase duration (longer for bull/bear, shorter for sideways)
    phaseLength = currentPhase == MarketPhase.sideways 
        ? Random().nextInt(30) + 20  // 20-50 updates for sideways
        : Random().nextInt(100) + 50; // 50-150 updates for bull/bear
    
    phaseDuration = phaseLength;
    
    // Adjust volatility based on new phase
    switch (currentPhase) {
      case MarketPhase.bull:
        volatility = 0.2 + (Random().nextDouble() * 0.2); // Lower volatility in bull
        break;
      case MarketPhase.bear:
        volatility = 0.3 + (Random().nextDouble() * 0.3); // Medium volatility in bear
        break;
      case MarketPhase.sideways:
        volatility = 0.4 + (Random().nextDouble() * 0.4); // Higher volatility in sideways
        break;
    }
  }
  
  // Get price change percentage over the last 24 hours
  double get dailyChangePercentage {
    if (priceHistory.length < 2) return 0.0;
    
    // Find price from 24 hours ago (or oldest available)
    DateTime yesterday = DateTime.now().subtract(Duration(hours: 24));
    PricePoint oldPoint;
    try {
      oldPoint = priceHistory.firstWhere(
        (point) => point.timestamp.isBefore(yesterday),
        orElse: () => priceHistory.first
      );
    } catch (e) {
      oldPoint = priceHistory.first;
    }
    
    double oldPrice = oldPoint.price;
    double change = (currentPrice - oldPrice) / oldPrice * 100;
    return change;
  }
}