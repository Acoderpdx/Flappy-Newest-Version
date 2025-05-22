import 'package:flutter/material.dart';

class ShopScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final Set<String> unlockedSkins;
  final String currentBirdSkin;
  final Function(String skin, String collectible) onUnlock;
  final Function(String skin) onEquip;

  ShopScreen({
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.unlockedSkins,
    required this.currentBirdSkin,
    required this.onUnlock,
    required this.onEquip,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late String _selectedSkin;
  late Set<String> _unlockedSkins;

  @override
  void initState() {
    super.initState();
    _selectedSkin = widget.currentBirdSkin;
    _unlockedSkins = Set<String>.from(widget.unlockedSkins);
  }

  void _handleUnlock(String filename, String collectible) {
    widget.onUnlock(filename, collectible);
    setState(() {
      _unlockedSkins.add(filename);
    });
  }

  @override
  Widget build(BuildContext context) {
    final skins = [
      // Add default bird skin at the beginning of the list
      {
        'filename': 'bird.png',
        'name': 'Default Bird',
        'collectible': 'LionsMane', // Using Lions Mane as it's most common
        'cost': 1, // Just 1 Lions Mane to reselect
        'count': widget.lionsManeCollected,
        'asset': 'assets/images/bird.png',
        'color': Colors.blue, // Blue theme for default bird
        'icon': 'assets/images/lions_mane.png',
      },
      // Existing skins
      {
        'filename': 'tate_bird.png',
        'name': 'Tate Bird',
        'collectible': 'RedPill',
        'cost': 200,
        'count': widget.redPillCollected,
        'asset': 'assets/images/tate_bird.png',
        'color': Colors.red,
        'icon': 'assets/images/red_pill.png',
      },
      {
        'filename': 'lion_bird.png',
        'name': 'Lion Bird',
        'collectible': 'LionsMane',
        'cost': 500,
        'count': widget.lionsManeCollected,
        'asset': 'assets/images/lion_bird.png',
        'color': Colors.amber,
        'icon': 'assets/images/lions_mane.png',
      },
      {
        'filename': 'bankman_bird.png',
        'name': 'Bankman Bird',
        'collectible': 'Bitcoin',
        'cost': 10,
        'count': widget.bitcoinCollected,
        'asset': 'assets/images/bankman_bird.png',
        'color': Colors.amber.shade700,
        'icon': 'assets/images/bitcoin.png',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF212121),
        title: Text('Bird Skin Shop', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF212121), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // RedPill counter
                      _buildCollectibleCounter(
                        'assets/images/red_pill.png', 
                        widget.redPillCollected.toString(),
                        Colors.red,
                      ),
                      // Lions Mane counter
                      _buildCollectibleCounter(
                        'assets/images/lions_mane.png', 
                        widget.lionsManeCollected.toString(),
                        Colors.amber,
                      ),
                      // Bitcoin counter
                      _buildCollectibleCounter(
                        'assets/images/bitcoin.png', 
                        widget.bitcoinCollected.toString(),
                        Colors.amber.shade700,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Available Skins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: skins.length,
                    itemBuilder: (context, index) {
                      final skin = skins[index];
                      final filename = skin['filename'] as String;
                      final unlocked = _unlockedSkins.contains(filename);
                      final canUnlock = (skin['count'] as int) >= (skin['cost'] as int);
                      final isEquipped = filename == _selectedSkin;
                      
                      return _buildSkinCard(
                        skin: skin,
                        unlocked: unlocked,
                        canUnlock: canUnlock,
                        isEquipped: isEquipped,
                        onUnlock: () => _handleUnlock(filename, skin['collectible'] as String),
                        onEquip: () {
                          setState(() {
                            _selectedSkin = filename;
                          });
                          widget.onEquip(filename);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectibleCounter(String imagePath, String count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.error, color: Colors.red, size: 20);
            },
          ),
          SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard({
    required Map<String, dynamic> skin,
    required bool unlocked,
    required bool canUnlock,
    required bool isEquipped,
    required VoidCallback onUnlock,
    required VoidCallback onEquip,
  }) {
    final Color primaryColor = skin['color'] as Color;
    final String iconPath = skin['icon'] as String;
    
    return Card(
      color: Color(0xFF303030),
      elevation: isEquipped ? 12 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEquipped ? primaryColor : Colors.transparent,
          width: isEquipped ? 3 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Skin name
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              skin['name'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Skin image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    skin['asset'] as String,
                    fit: BoxFit.contain,
                    color: (!unlocked && !canUnlock) ? Colors.black38 : null,
                    colorBlendMode: (!unlocked && !canUnlock) ? BlendMode.srcATop : null,
                  ),
                ),
              ),
            ),
          ),
          
          // Status and buttons
          Container(
            padding: EdgeInsets.all(8),
            width: double.infinity,
            child: unlocked
                ? ElevatedButton(
                    onPressed: isEquipped ? null : onEquip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped ? Colors.green.shade800 : primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      isEquipped ? 'EQUIPPED' : 'EQUIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(
                        current: skin['count'] as int,
                        required: skin['cost'] as int,
                        color: primaryColor,
                      ),
                      SizedBox(height: 8),
                      // Unlock button
                      ElevatedButton(
                        onPressed: canUnlock ? onUnlock : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUnlock ? primaryColor : Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              iconPath,
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.currency_bitcoin, color: Colors.white, size: 16);
                              },
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${skin['cost']} UNLOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

  Widget _buildProgressIndicator({
    required int current,
    required int required,
    required Color color,
  }) {
    final double progress = (current / required).clamp(0.0, 1.0);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${current}/${required}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}