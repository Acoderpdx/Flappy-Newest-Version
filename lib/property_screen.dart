import 'package:flutter/material.dart';
import 'main.dart'; // Import for ScrollingBackground

class PropertyScreen extends StatefulWidget {
  final double usdBalance;
  final Function(double) onUpdateBalance;
  final VoidCallback? onClose;

  const PropertyScreen({
    Key? key, 
    required this.usdBalance, 
    required this.onUpdateBalance,
    this.onClose,
  }) : super(key: key);

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  int _currentHouseLevel = 1;
  
  // Define upgrade costs - each index corresponds to upgrading from level X to X+1
  final List<double> _upgradeCosts = [
    5000.0,   // Level 1 -> 2
    20000.0,  // Level 2 -> 3
    100000.0, // Level 3 -> 4
    500000.0, // Level 4 -> 5
  ];

  String get _currentHouseAsset => 'assets/images/house${_currentHouseLevel}.png';
  
  bool get _canUpgrade {
    if (_currentHouseLevel >= 5) return false; // Max level reached
    return widget.usdBalance >= _upgradeCosts[_currentHouseLevel - 1];
  }

  double get _nextUpgradeCost {
    if (_currentHouseLevel >= 5) return 0;
    return _upgradeCosts[_currentHouseLevel - 1];
  }

  void _upgradeHouse() {
    if (_canUpgrade) {
      setState(() {
        // Deduct the cost
        widget.onUpdateBalance(-_upgradeCosts[_currentHouseLevel - 1]);
        
        // Upgrade to next level
        _currentHouseLevel++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Property Manager', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Ensure we call onClose if provided, or just pop otherwise
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Scrolling background
          Positioned.fill(
            child: ScrollingBackground(scrollSpeed: 80.0),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // USD Balance display
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'USD: \$${widget.usdBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  
                  // House display container - ensures image fits properly
                  Container(
                    width: 280,
                    height: 240,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        _currentHouseAsset,
                        fit: BoxFit.contain, // This ensures image fits without being cut off
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.home, color: Colors.amber, size: 120);
                        },
                      ),
                    ),
                  ),
                  
                  // House info
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        Text(
                          'Level $_currentHouseLevel Property',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Upgrade button
                  ElevatedButton(
                    onPressed: _canUpgrade ? _upgradeHouse : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canUpgrade ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(
                      _currentHouseLevel >= 5 
                      ? 'Maximum Level Reached' 
                      : 'Upgrade to Level ${_currentHouseLevel + 1}: \$${_nextUpgradeCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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
