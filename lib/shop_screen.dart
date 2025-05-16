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
        'filename': 'tate_bird.png',
        'collectible': 'RedPill',
        'count': redPillCollected,
        'asset': 'assets/images/tate_bird.png',
      },
      {
        'filename': 'lion_bird.png',
        'collectible': 'LionsMane',
        'count': lionsManeCollected,
        'asset': 'assets/images/lion_bird.png',
      },
      {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: skins.map((skin) {
                final unlocked = unlockedSkins.contains(skin['filename'] as String);
                final canUnlock = skin['count'] as int >= 10;
                Widget skinImage = Image.asset(
                  skin['asset'] as String,
                  width: 80,
                  height: 80,
                  color: (!unlocked && !canUnlock) ? Colors.black : null,
                  colorBlendMode: (!unlocked && !canUnlock) ? BlendMode.srcATop : null,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Column(
                    children: [
                      skinImage,
                      if (!unlocked && canUnlock)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                            onPressed: () => onUnlock(skin['filename'] as String, skin['collectible'] as String),
                            child: Text('Unlock'),
                          ),
                        ),
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