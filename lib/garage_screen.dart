import 'package:flutter/material.dart';
import 'main.dart'; // Import for ScrollingBackground

// Car model to represent different car types
class Car {
  final String id;
  final String name;
  final double price;
  final String assetPath;
  final String description;
  
  const Car({
    required this.id,
    required this.name,
    required this.price,
    required this.assetPath,
    required this.description,
  });
}

class GarageScreen extends StatefulWidget {
  final double usdBalance;
  final Function(double) onUpdateBalance;
  final String currentCarId;
  final Function(String) onCarChanged;
  final VoidCallback? onClose;

  const GarageScreen({
    Key? key, 
    required this.usdBalance, 
    required this.onUpdateBalance,
    this.currentCarId = '',
    required this.onCarChanged,
    this.onClose,
  }) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late double _currentBalance;
  late String _selectedCarId;
  
  // View mode: catalog or owned car
  bool _showCatalog = true;
  
  // Car catalog index
  int _catalogIndex = 0;
  
  // Car collection
  final List<Car> _cars = [
    Car(
      id: 'bugattus',
      name: 'Bugattus Cobra-X',
      price: 500000.0,
      assetPath: 'assets/images/cars/Bugattus Cobra-X.png',
      description: 'An ultra-luxury hypercar with unmatched speed and elegance.',
    ),
    Car(
      id: 'bvm',
      name: 'BVM Phantom 4',
      price: 200000.0,
      assetPath: 'assets/images/cars/BVM Phantom 4.png',
      description: 'A luxurious sedan with advanced technology and supreme comfort.',
    ),
    Car(
      id: 'cerberus',
      name: 'Cerberus Firecat',
      price: 350000.0,
      assetPath: 'assets/images/cars/Cerberus Firecat.png',
      description: 'A high-performance sports car with aggressive styling and power.',
    ),
    Car(
      id: 'hondo',
      name: 'Hondo Racer-X',
      price: 180000.0,
      assetPath: 'assets/images/cars/Hondo Racer-X.png',
      description: 'A reliable sports coupe with impressive handling and speed.',
    ),
    Car(
      id: 'kyo',
      name: 'Kyo Cubelet',
      price: 85000.0,
      assetPath: 'assets/images/cars/Kyo Cubelet.png',
      description: 'A compact city car with futuristic design and excellent efficiency.',
    ),
    Car(
      id: 'mind',
      name: 'Mind Virus',
      price: 420000.0,
      assetPath: 'assets/images/cars/Mind Virus.png',
      description: 'An experimental concept car with mind-bending design and technology.',
    ),
    Car(
      id: 'mustardo',
      name: 'Mustardo Wildrun',
      price: 120000.0,
      assetPath: 'assets/images/cars/Mustardo Wildrun.png',
      description: 'A classic muscle car with modern performance upgrades.',
    ),
    Car(
      id: 'plumber',
      name: 'Plumber Beast-R',
      price: 150000.0,
      assetPath: 'assets/images/cars/Plumber Beast-R.png',
      description: 'A rugged off-road vehicle with unmatched durability and power.',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _currentBalance = widget.usdBalance;
    _selectedCarId = widget.currentCarId;
    
    // If player doesn't have a car yet, show catalog by default
    _showCatalog = _selectedCarId.isEmpty;
  }

  @override
  void didUpdateWidget(GarageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usdBalance != oldWidget.usdBalance) {
      setState(() {
        _currentBalance = widget.usdBalance;
      });
    }
    
    if (widget.currentCarId != oldWidget.currentCarId) {
      setState(() {
        _selectedCarId = widget.currentCarId;
      });
    }
  }

  // Get the currently selected car
  Car? get _currentCar {
    if (_selectedCarId.isEmpty) return null;
    try {
      return _cars.firstWhere((car) => car.id == _selectedCarId);
    } catch (e) {
      return null;
    }
  }
  
  // Get the car being viewed in catalog
  Car get _catalogCar => _cars[_catalogIndex];
  
  // Check if player can buy the current catalog car
  bool get _canPurchaseCar => _currentBalance >= _catalogCar.price;

  // Buy the current catalog car
  void _purchaseCar() {
    if (_canPurchaseCar) {
      final double purchaseCost = _catalogCar.price;
      
      // Update local state
      setState(() {
        _currentBalance -= purchaseCost;
        _selectedCarId = _catalogCar.id;
        _showCatalog = false;  // Switch to car view
      });
      
      // Notify parent components
      widget.onUpdateBalance(-purchaseCost);
      widget.onCarChanged(_selectedCarId);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You purchased the ${_catalogCar.name}!'))
      );
    }
  }
  
  // Navigate to next car in catalog
  void _nextCatalogCar() {
    setState(() {
      _catalogIndex = (_catalogIndex + 1) % _cars.length;
    });
  }
  
  // Navigate to previous car in catalog
  void _previousCatalogCar() {
    setState(() {
      _catalogIndex = (_catalogIndex - 1 + _cars.length) % _cars.length;
    });
  }
  
  // Toggle between catalog and owned car view
  void _toggleView() {
    setState(() {
      _showCatalog = !_showCatalog;
    });
  }

  // Add a new method for building car images with better error handling
  Widget _buildCarImage(String assetPath) {
    print('Loading car image: $assetPath');
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print("Error loading car image: $assetPath - $error");
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, color: Colors.blue, size: 80),
            SizedBox(height: 10),
            Text(
              "Car Preview",
              style: TextStyle(color: Colors.blue),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_showCatalog ? 'Car Showroom' : 'Your Garage', style: TextStyle(color: Colors.white)),
        leading: widget.onClose != null ? 
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onClose,
          ) : null,
        actions: [
          // Toggle button between catalog and owned car
          if (_selectedCarId.isNotEmpty)
            IconButton(
              icon: Icon(_showCatalog ? Icons.directions_car : Icons.menu_book, color: Colors.white),
              onPressed: _toggleView,
              tooltip: _showCatalog ? 'View Your Car' : 'Browse Showroom',
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
            child: _showCatalog ? _buildCatalogView() : _buildCarView(),
          ),
        ],
      ),
    );
  }
  
  // Car catalog view
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
        
        // Car browsing section
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Car name and price
              Text(
                _catalogCar.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Price: \$${_catalogCar.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  color: _canPurchaseCar ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Car image with navigation arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous car button
                  IconButton(
                    onPressed: _previousCatalogCar,
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    iconSize: 30,
                  ),
                  
                  // Car image display
                  Container(
                    width: 220,
                    height: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _buildCarImage(_catalogCar.assetPath),
                    ),
                  ),
                  
                  // Next car button
                  IconButton(
                    onPressed: _nextCatalogCar,
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                    iconSize: 30,
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Car description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _catalogCar.description,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Purchase button
              ElevatedButton(
                onPressed: _canPurchaseCar ? _purchaseCar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPurchaseCar ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  _selectedCarId.isNotEmpty ? 'Trade-In & Buy This Car' : 'Purchase Car',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
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
              _cars.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _catalogIndex ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Current car view
  Widget _buildCarView() {
    if (_currentCar == null) {
      // If no car is owned, redirect to catalog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showCatalog = true);
      });
      return Center(child: CircularProgressIndicator());
    }

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
        
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Car name and text
              Text(
                'Your ${_currentCar!.name}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Car display
              Container(
                width: 280,
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _buildCarImage(_currentCar!.assetPath),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Car value display
              Text(
                'Value: \$${_currentCar!.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Car description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _currentCar!.description,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Browse catalog button
              ElevatedButton(
                onPressed: () => setState(() => _showCatalog = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Browse Car Showroom',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
