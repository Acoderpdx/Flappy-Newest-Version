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
      {
        'filename': 'tate_bird.png',
        'collectible': 'RedPill',
        'count': widget.redPillCollected,
        'asset': 'assets/images/tate_bird.png',
      },
      {
        'filename': 'lion_bird.png',
        'collectible': 'LionsMane',
        'count': widget.lionsManeCollected,
        'asset': 'assets/images/lion_bird.png',
      },
      {
        'filename': 'bankman_bird.png',
        'collectible': 'Bitcoin',
        'count': widget.bitcoinCollected,
        'asset': 'assets/images/bankman_bird.png',
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/matrix_shop.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: skins.map((skin) {
                  final filename = skin['filename'] as String;
                  final unlocked = _unlockedSkins.contains(filename);
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        skinImage,
                        SizedBox(width: 24),
                        if (!unlocked && canUnlock)
                          ElevatedButton(
                            onPressed: () => _handleUnlock(filename, skin['collectible'] as String),
                            child: Text('Unlock'),
                          ),
                        if (unlocked)
                          RotatedBox(
                            quarterTurns: 1,
                            child: Switch(
                              value: filename == _selectedSkin,
                              onChanged: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedSkin = filename;
                                  });
                                  widget.onEquip(filename);
                                }
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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