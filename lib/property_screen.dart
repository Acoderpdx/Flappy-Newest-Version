import 'package:flutter/material.dart';
import 'main.dart'; // Import for ScrollingBackground

// House type model to represent different house styles
class HouseType {
  final String id;
  final String name;
  final double basePrice;
  final List<double> upgradeCosts;
  final String assetPrefix;
  
  const HouseType({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.upgradeCosts,
    required this.assetPrefix,
  });
  
  String getAssetPath(int level) => 'assets/images/$assetPrefix$level.png';
}

class PropertyScreen extends StatefulWidget {
  final double usdBalance;
  final Function(double) onUpdateBalance;
  final int currentHouseLevel;
  final String currentHouseType;
  final Function(int, String) onHouseChanged;
  final VoidCallback? onClose;

  const PropertyScreen({
    Key? key, 
    required this.usdBalance, 
    required this.onUpdateBalance,
    this.currentHouseLevel = 0,  // 0 means no house purchased
    this.currentHouseType = '',  // Empty means no house type selected
    required this.onHouseChanged,
    this.onClose,
  }) : super(key: key);

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  late int _currentHouseLevel;
  late String _selectedHouseType;
  late double _currentBalance;
  
  // House catalog showing tab selection (browse vs current house view)
  bool _showCatalog = true;
  
  // Define house types with their properties
  final List<HouseType> _houseTypes = [
    HouseType(
      id: 'wood',
      name: 'Wood House',
      basePrice: 5000.0,
      upgradeCosts: [5000.0, 20000.0, 100000.0, 500000.0],
      assetPrefix: 'house',
    ),
    HouseType(
      id: 'castle',
      name: 'Modern Castle',
      basePrice: 20000.0,
      upgradeCosts: [10000.0, 30000.0, 150000.0, 750000.0],
      assetPrefix: 'moderncastle',
    ),
    HouseType(
      id: 'white',
      name: 'White House',
      basePrice: 10000.0,
      upgradeCosts: [7500.0, 25000.0, 125000.0, 600000.0],
      assetPrefix: 'ythouse',
    ),
  ];
  
  // Current house being viewed in catalog
  int _catalogIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _currentBalance = widget.usdBalance;
    _currentHouseLevel = widget.currentHouseLevel;
    _selectedHouseType = widget.currentHouseType;
    
    // If player doesn't have a house yet, show catalog by default
    _showCatalog = _selectedHouseType.isEmpty || _currentHouseLevel == 0;
  }

  @override
  void didUpdateWidget(PropertyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usdBalance != oldWidget.usdBalance) {
      setState(() {
        _currentBalance = widget.usdBalance;
      });
    }
    
    if (widget.currentHouseLevel != oldWidget.currentHouseLevel ||
        widget.currentHouseType != oldWidget.currentHouseType) {
      setState(() {
        _currentHouseLevel = widget.currentHouseLevel;
        _selectedHouseType = widget.currentHouseType;
      });
    }
  }

  // Get the currently selected/owned house type object
  HouseType? get _currentHouseType {
    if (_selectedHouseType.isEmpty) return null;
    try {
      return _houseTypes.firstWhere((house) => house.id == _selectedHouseType);
    } catch (e) {
      return null;
    }
  }
  
  // Get asset path for current house
  String get _currentHouseAsset {
    if (_currentHouseType == null || _currentHouseLevel == 0) {
      return 'assets/images/house1.png'; // Default placeholder
    }
    return _currentHouseType!.getAssetPath(_currentHouseLevel);
  }
  
  // Get the house that's currently being viewed in the catalog
  HouseType get _catalogHouse => _houseTypes[_catalogIndex];
  
  // Check if player can purchase the current catalog house
  bool get _canPurchaseCatalogHouse => 
      _currentBalance >= _catalogHouse.basePrice && 
      (_selectedHouseType.isEmpty || _currentHouseLevel == 0);
  
  // Check if player can upgrade their current house
  bool get _canUpgradeHouse {
    if (_currentHouseType == null || _currentHouseLevel >= 5) return false;
    return _currentHouseLevel > 0 && 
           _currentHouseLevel < 5 && 
           _currentBalance >= _nextUpgradeCost;
  }

  double get _nextUpgradeCost {
    if (_currentHouseType == null || _currentHouseLevel <= 0 || _currentHouseLevel >= 5) return 0;
    return _currentHouseType!.upgradeCosts[_currentHouseLevel - 1];
  }

  // Purchase a new house
  void _purchaseHouse() {
    if (_canPurchaseCatalogHouse) {
      final double purchaseCost = _catalogHouse.basePrice;
      
      // Update local state
      setState(() {
        _currentBalance -= purchaseCost;
        _selectedHouseType = _catalogHouse.id;
        _currentHouseLevel = 1;  // Start at level 1 after purchase
        _showCatalog = false;    // Switch to house view after purchase
      });
      
      // Notify parent components
      widget.onUpdateBalance(-purchaseCost);
      widget.onHouseChanged(_currentHouseLevel, _selectedHouseType);
    }
  }

  // Upgrade existing house
  void _upgradeHouse() {
    if (_canUpgradeHouse) {
      final double upgradeCost = _nextUpgradeCost;
      
      // Update local state
      setState(() {
        _currentBalance -= upgradeCost;
        _currentHouseLevel++;
      });
      
      // Notify parent components
      widget.onUpdateBalance(-upgradeCost);
      widget.onHouseChanged(_currentHouseLevel, _selectedHouseType);
    }
  }
  
  // Navigate through catalog
  void _nextCatalogHouse() {
    setState(() {
      _catalogIndex = (_catalogIndex + 1) % _houseTypes.length;
    });
  }
  
  void _previousCatalogHouse() {
    setState(() {
      _catalogIndex = (_catalogIndex - 1 + _houseTypes.length) % _houseTypes.length;
    });
  }
  
  // Toggle between catalog and owned house view
  void _toggleView() {
    setState(() {
      _showCatalog = !_showCatalog;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_showCatalog ? 'House Catalog' : 'Your Property', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Toggle button between catalog and owned house
          if (_selectedHouseType.isNotEmpty && _currentHouseLevel > 0)
            IconButton(
              icon: Icon(_showCatalog ? Icons.home : Icons.menu_book, color: Colors.white),
              onPressed: _toggleView,
              tooltip: _showCatalog ? 'View Your Property' : 'Browse Catalog',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Scrolling background
          Positioned.fill(
            child: ScrollingBackground(scrollSpeed: 80.0),
          ),
          
          // Main content
          SafeArea(
            child: _showCatalog ? _buildCatalogView() : _buildHouseView(),
          ),
        ],
      ),
    );
  }
  
  // House catalog view
  Widget _buildCatalogView() {
    return Column(
      children: [
        // USD Balance display
        Card(
          color: Colors.black.withOpacity(0.8),
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Column(
              children: [
                Text(
                  'USD Balance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$${_currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // House browsing section
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // House name and price
              Text(
                _catalogHouse.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Price: \$${_catalogHouse.basePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  color: _canPurchaseCatalogHouse ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 20),
              
              // House image with navigation arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous house button
                  IconButton(
                    onPressed: _previousCatalogHouse,
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    iconSize: 30,
                  ),
                  
                  // House image
                  Container(
                    width: 220,
                    height: 190,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage('assets/images/house_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        _catalogHouse.getAssetPath(1), // Always show level 1 in catalog
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.home, color: Colors.amber, size: 120);
                        },
                      ),
                    ),
                  ),
                  
                  // Next house button
                  IconButton(
                    onPressed: _nextCatalogHouse,
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                    iconSize: 30,
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // House description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _getHouseDescription(_catalogHouse),
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Purchase button
              ElevatedButton(
                onPressed: _canPurchaseCatalogHouse ? _purchaseHouse : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPurchaseCatalogHouse ? Colors.amber : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  _hasHouse ? 'Start Over with This House' : 'Purchase House',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Pagination indicator
        Container(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _houseTypes.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _catalogIndex ? Colors.amber : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Current house view
  Widget _buildHouseView() {
    if (_currentHouseType == null || _currentHouseLevel <= 0) {
      // If no house is owned, redirect to catalog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showCatalog = true);
      });
      return Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // USD Balance display
          Card(
            color: Colors.black.withOpacity(0.8),
            margin: const EdgeInsets.only(bottom: 20.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'USD Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${_currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // House type and level
          Text(
            '${_currentHouseType!.name}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          
          SizedBox(height: 8),
          
          // House display container
          Container(
            width: 280,
            height: 240,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage('assets/images/house_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Image.asset(
                _currentHouseAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.home, color: Colors.amber, size: 120);
                },
              ),
            ),
          ),
          
          // House level info
          Text(
            'Level $_currentHouseLevel Property',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          if (_currentHouseLevel < 5) ...[
            SizedBox(height: 8),
            Text(
              'Next upgrade costs \$${_nextUpgradeCost.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: _canUpgradeHouse ? Colors.green : Colors.red,
              ),
            ),
          ],
          
          SizedBox(height: 24),
          
          // Upgrade button
          ElevatedButton(
            onPressed: _canUpgradeHouse ? _upgradeHouse : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canUpgradeHouse ? Colors.green : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(
              _currentHouseLevel >= 5 
              ? 'Maximum Level Reached' 
              : 'Upgrade to Level ${_currentHouseLevel + 1}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // View catalog button
          TextButton(
            onPressed: () => setState(() => _showCatalog = true),
            child: Text(
              'Browse House Catalog',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool get _hasHouse => _selectedHouseType.isNotEmpty && _currentHouseLevel > 0;
  
  // Helper to get house descriptions
  String _getHouseDescription(HouseType house) {
    switch (house.id) {
      case 'wood':
        return 'A cozy wooden house with rustic charm. Affordable and upgradable with a traditional design.';
      case 'castle':
        return 'A luxurious modern castle with unique architecture. Premium features and impressive design at every level.';
      case 'white':
        return 'An elegant white house with classic design. Well-balanced between affordability and luxury.';
      default:
        return 'A beautiful property for you to own and upgrade.';
    }
  }
}
