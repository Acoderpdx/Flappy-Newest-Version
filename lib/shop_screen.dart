import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final skins = [
      {
        'name': 'Tate Bird',
        'filename': 'tate_bird.png',
        'collectible': 'RedPill',
        'count': redPillCollected,
        'asset': 'assets/images/tate_bird.png',
      },
      {
        'name': 'Lion Bird',
        'filename': 'lion_bird.png',
        'collectible': 'LionsMane',
        'count': lionsManeCollected,
        'asset': 'assets/images/lion_bird.png',
      },
      {
        'name': 'Bankman Bird',
        'filename': 'bankman_bird.png',
        'collectible': 'Bitcoin',
        'count': bitcoinCollected,
        'asset': 'assets/images/bankman_bird.png',
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          Image.asset('assets/images/matrix_shop.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: skins.map((skin) {
                final unlocked = unlockedSkins.contains(skin['filename'] as String);
                final equipped = currentBirdSkin == (skin['filename'] as String);
                final canUnlock = skin['count'] as int >= 10;
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: equipped ? Border.all(color: Colors.green, width: 4) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(skin['asset'] as String, width: 64, height: 64),
                      ),
                      SizedBox(height: 8),
                      Text('${skin['name']}'),
                      SizedBox(height: 4),
                      Text('You: ${skin['count']}'),
                      SizedBox(height: 8),
                      if (!unlocked && canUnlock)
                        ElevatedButton(
                          onPressed: () => onUnlock(skin['filename'] as String, skin['collectible'] as String),
                          child: Text('Unlock'),
                        )
                      else if (unlocked && !equipped)
                        OutlinedButton(
                          onPressed: () => onEquip(skin['filename'] as String),
                          child: Text('Equip'),
                        )
                      else if (equipped)
                        Text('Equipped', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}