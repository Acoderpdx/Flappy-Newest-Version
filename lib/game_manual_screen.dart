import 'package:flutter/material.dart';

class GameManualScreen extends StatelessWidget {
  final VoidCallback onClose;

  const GameManualScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Game Manual', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Gameplay Basics'),
            _buildInfoItem('Tap the screen to make the bird fly upward and avoid obstacles.'),
            _buildInfoItem('Score points by flying through gaps between obstacles.'),
            
            _buildSectionTitle('Game Modes'),
            _buildInfoItem('Regular Mode: Collect various items while avoiding obstacles.'),
            _buildInfoItem('Red Pill Mode: A high-risk mode where you can collect red pills for bigger rewards.'),
            
            _buildSectionTitle('Collectibles'),
            _buildCollectibleItem('assets/images/lions_mane.png', "Lion's Mane", 
                'A prized collectible with moderate value.'),
            _buildCollectibleItem('assets/images/red_pill.png', 'Red Pill', 
                'High-value item available primarily in Red Pill Mode.'),
            _buildCollectibleItem('assets/images/solana.png', 'Solana', 
                'Cryptocurrency with fluctuating value.'),
            _buildCollectibleItem('assets/images/brownecoin.png', 'BrowneCoin', 
                'Special cryptocurrency with higher base value.'),
            
            _buildSectionTitle('Special Features'),
            _buildInfoItem('Portals: Jump into portals to access mini-games.'),
            _buildInfoItem('Cash Out: In Red Pill Mode, cash out to secure your collected pills before crashing.'),
            
            _buildSectionTitle('Buildings & Screens'),
            _buildMenuItemInfo(Icons.shopping_cart, 'Shop', 
                'Buy and equip different bird skins using collected items.'),
            _buildMenuItemInfo(Icons.casino, 'Mini-Games', 
                'Play games to earn additional collectibles.'),
            _buildMenuItemInfo(Icons.directions_car, 'Garage', 
                'Purchase and manage vehicles.'),
            _buildMenuItemInfo(Icons.home, 'Property', 
                'Buy and upgrade properties for passive income.'),
            _buildMenuItemInfo(Icons.account_balance_wallet, 'Portfolio', 
                'Manage your collectibles and cryptocurrencies.'),
            
            SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: onClose,
                child: Text('CLOSE MANUAL', style: TextStyle(color: Colors.amber, fontSize: 16)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.amber,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectibleItem(String imagePath, String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
            errorBuilder: (ctx, err, stack) => Container(
              width: 30,
              height: 30,
              color: Colors.red.withOpacity(0.5),
              child: Icon(Icons.error, size: 20, color: Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(description, 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemInfo(IconData icon, String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(description, 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}