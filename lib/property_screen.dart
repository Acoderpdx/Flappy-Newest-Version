import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class House {
  final String name;
  final String imagePath;
  final double basePrice;
  final List<double> upgradePrices;
  final double sellMultiplier; // How much you get when selling (e.g., 1.2 = 120% of total investment)
  int currentUpgradeLevel; // 0 = base house, 1-5 = upgrade levels
  bool owned;

  House({
    required this.name,
    required this.imagePath,
    required this.basePrice,
    required this.upgradePrices,
    required this.sellMultiplier,
    this.currentUpgradeLevel = 0,
    this.owned = false,
  });

  String get currentImagePath {
    if (!owned) return imagePath; // Return base image path for display
    
    // Return the appropriate upgrade image based on level
    int imageNumber = currentUpgradeLevel + 1; // house1.png, house2.png, etc.
    return 'assets/images/house$imageNumber.png';
  }

  double get totalInvestment {
    double total = owned ? basePrice : 0;
    for (int i = 0; i < currentUpgradeLevel; i++) {
      total += upgradePrices[i];
    }
    return total;
  }

  double get sellValue {
    return totalInvestment * sellMultiplier;
  }

  double get nextUpgradeCost {
    if (currentUpgradeLevel >= upgradePrices.length) return 0;
    return upgradePrices[currentUpgradeLevel];
  }

  bool get isFullyUpgraded {
    return currentUpgradeLevel >= upgradePrices.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'currentUpgradeLevel': currentUpgradeLevel,
      'owned': owned,
    };
  }

  static House fromJson(Map<String, dynamic> json, House template) {
    return House(
      name: template.name,
      imagePath: template.imagePath,
      basePrice: template.basePrice,
      upgradePrices: template.upgradePrices,
      sellMultiplier: template.sellMultiplier,
      currentUpgradeLevel: json['currentUpgradeLevel'],
      owned: json['owned'],
    );
  }
}

class PropertyScreen extends StatefulWidget {
  final double usdBalance;
  final Function(double usdDelta) onUpdateBalance;

  const PropertyScreen({
    Key? key,
    required this.usdBalance,
    required this.onUpdateBalance,
  }) : super(key: key);

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<House> houses = [];
  double _userBalance = 0;

  @override
  void initState() {
    super.initState();
    _userBalance = widget.usdBalance;
    _pageController = PageController(initialPage: 0, viewportFraction: 0.85);
    _loadHouses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadHouses() {
    // Define the houses with their base properties
    final houseTemplates = [
      House(
        name: 'Starter House',
        imagePath: 'assets/images/house1.png',
        basePrice: 100000,
        upgradePrices: [10000, 25000, 50000, 100000, 200000],
        sellMultiplier: 1.2,
        owned: false,
      ),
      House(
        name: 'Family Home',
        imagePath: 'assets/images/house1.png', // Use placeholder, will show silhouette if not owned
        basePrice: 250000,
        upgradePrices: [25000, 50000, 100000, 200000, 400000],
        sellMultiplier: 1.3,
        owned: false,
      ),
      House(
        name: 'Luxury Villa',
        imagePath: 'assets/images/house1.png', // Use placeholder, will show silhouette if not owned
        basePrice: 500000,
        upgradePrices: [50000, 100000, 200000, 400000, 800000],
        sellMultiplier: 1.4,
        owned: false,
      ),
      House(
        name: 'Mansion',
        imagePath: 'assets/images/house1.png', // Use placeholder, will show silhouette if not owned
        basePrice: 1000000,
        upgradePrices: [100000, 200000, 400000, 800000, 1600000],
        sellMultiplier: 1.5,
        owned: false,
      ),
    ];

    // Load saved house data from preferences
    loadHouseData(houseTemplates).then((loadedHouses) {
      setState(() {
        houses = loadedHouses;
        
        // Make sure first house is owned by default
        if (houses.isNotEmpty && !houses[0].owned) {
          houses[0].owned = true;
        }
      });
    });
  }

  Future<List<House>> loadHouseData(List<House> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<House> result = List.from(templates);
      
      for (int i = 0; i < templates.length; i++) {
        final String? houseJson = prefs.getString('house_$i');
        if (houseJson != null) {
          // Load saved house data
          Map<String, dynamic> houseData = {};
          // Simple parsing for saved data
          houseData['name'] = templates[i].name;
          houseData['currentUpgradeLevel'] = prefs.getInt('house_${i}_level') ?? 0;
          houseData['owned'] = prefs.getBool('house_${i}_owned') ?? (i == 0);
          
          result[i] = House.fromJson(houseData, templates[i]);
        }
      }
      
      return result;
    } catch (e) {
      print("Error loading house data: $e");
      return templates;
    }
  }

  Future<void> saveHouseData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (int i = 0; i < houses.length; i++) {
        prefs.setInt('house_${i}_level', houses[i].currentUpgradeLevel);
        prefs.setBool('house_${i}_owned', houses[i].owned);
      }
    } catch (e) {
      print("Error saving house data: $e");
    }
  }

  void _buyHouse(int index) {
    if (_userBalance < houses[index].basePrice) {
      _showInsufficientFundsDialog();
      return;
    }

    setState(() {
      houses[index].owned = true;
      _userBalance -= houses[index].basePrice;
      widget.onUpdateBalance(-houses[index].basePrice);
      saveHouseData();
    });
  }

  void _upgradeHouse(int index) {
    final house = houses[index];
    
    if (house.isFullyUpgraded) return;
    
    final upgradeCost = house.nextUpgradeCost;
    
    if (_userBalance < upgradeCost) {
      _showInsufficientFundsDialog();
      return;
    }

    setState(() {
      house.currentUpgradeLevel++;
      _userBalance -= upgradeCost;
      widget.onUpdateBalance(-upgradeCost);
      saveHouseData();
    });
  }

  void _sellHouse(int index) {
    final house = houses[index];
    final sellValue = house.sellValue;
    
    // Don't allow selling the last owned house
    bool hasAnotherHouse = false;
    for (int i = 0; i < houses.length; i++) {
      if (i != index && houses[i].owned) {
        hasAnotherHouse = true;
        break;
      }
    }
    
    if (!hasAnotherHouse) {
      _showCannotSellDialog();
      return;
    }

    setState(() {
      house.owned = false;
      house.currentUpgradeLevel = 0;
      _userBalance += sellValue;
      widget.onUpdateBalance(sellValue);
      saveHouseData();

      // Move to the next owned house if possible
      int nextOwnedIndex = -1;
      for (int i = 0; i < houses.length; i++) {
        if (houses[i].owned) {
          nextOwnedIndex = i;
          break;
        }
      }
      
      if (nextOwnedIndex >= 0) {
        _pageController.animateToPage(
          nextOwnedIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Funds'),
        content: Text('You don\'t have enough money for this purchase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCannotSellDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot Sell'),
        content: Text('You need to own at least one house. Buy another house before selling this one.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Real Estate', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '\$${_userBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: houses.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // House pager
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: houses.length,
                    itemBuilder: (context, index) {
                      final house = houses[index];
                      return _buildHouseCard(house, index);
                    },
                  ),
                ),
                
                // Page indicator
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      houses.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // House details and actions
                Expanded(
                  flex: 2,
                  child: _currentPage < houses.length
                      ? _buildHouseDetails(houses[_currentPage], _currentPage)
                      : SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  Widget _buildHouseCard(House house, int index) {
    return AnimatedScale(
      scale: _currentPage == index ? 1.0 : 0.85,
      duration: Duration(milliseconds: 300),
      child: Card(
        margin: EdgeInsets.all(16),
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: house.owned ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: house.owned
            ? Image.asset(
                house.currentImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'House Image Not Found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Silhouette effect for locked house
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7),
                      BlendMode.srcATop,
                    ),
                    child: Image.asset(
                      house.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[800]);
                      },
                    ),
                  ),
                  // Price overlay
                  Center(
                    child: Text(
                      '\$${house.basePrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHouseDetails(House house, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // House name and upgrade level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                house.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (house.owned)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${house.currentUpgradeLevel}/5',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              if (!house.owned)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _userBalance >= house.basePrice
                        ? () => _buyHouse(index)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Buy House (\$${house.basePrice.toStringAsFixed(0)})'),
                  ),
                )
              else ...[
                // Upgrade button
                if (!house.isFullyUpgraded)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _userBalance >= house.nextUpgradeCost
                          ? () => _upgradeHouse(index)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Upgrade (\$${house.nextUpgradeCost.toStringAsFixed(0)})',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white70,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Fully Upgraded'),
                    ),
                  ),
                
                SizedBox(width: 8),
                
                // Sell button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sellHouse(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Sell (\$${house.sellValue.toStringAsFixed(0)})',
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (house.owned && house.isFullyUpgraded) ...[
            SizedBox(height: 8),
            Text(
              'This house is fully upgraded.',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Unlock requirements for next house
          if (index < houses.length - 1 && !houses[index + 1].owned) ...[
            SizedBox(height: 16),
            if (house.isFullyUpgraded)
              Text(
                'Fully upgrade this house to unlock ${houses[index + 1].name}!',
                style: TextStyle(color: Colors.amber),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '${house.isFullyUpgraded ? "You can now buy" : "Fully upgrade this house to unlock"} ${houses[index + 1].name}!',
                style: TextStyle(
                  color: house.isFullyUpgraded ? Colors.green : Colors.amber,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ],
      ),
    );
  }
}
