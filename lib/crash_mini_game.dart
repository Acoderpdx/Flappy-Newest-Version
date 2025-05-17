import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

enum CrashGamePhase { waiting, running, crashed, cashedOut }

class CrashMiniGameScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final void Function(String collectible, int amount) onCollectibleChange;

  const CrashMiniGameScreen({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.onCollectibleChange,
  }) : super(key: key);

  @override
  State<CrashMiniGameScreen> createState() => _CrashMiniGameScreenState();
}

class _CrashMiniGameScreenState extends State<CrashMiniGameScreen> {
  CrashGamePhase phase = CrashGamePhase.waiting;
  double multiplier = 1.0;
  double crashMultiplier = 2.0;
  Timer? _timer;
  int elapsedMs = 0;
  String selectedCollectible = 'LionsMane';
  int wager = 1;
  List<double> pastResults = [];
  static final List<String> collectibles = ['LionsMane', 'RedPill', 'Bitcoin'];

  // Provably fair: static example hash chain and signature for demo
  static final List<String> hashChain = [
    // Use random hex strings for now, replace with real chain later
    'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6',
    'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6a1',
    'c3d4e5f6a7b8c9d0e1f2a3b4c5d6a1b2',
    'd4e5f6a7b8c9d0e1f2a3b4c5d6a1b2c3',
    'e5f6a7b8c9d0e1f2a3b4c5d6a1b2c3d4',
  ];
  static final String vxSignature = 'bustabit-demo-signature';

  int hashIndex = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      phase = CrashGamePhase.running;
      multiplier = 1.0;
      elapsedMs = 0;
      crashMultiplier = _computeCrashMultiplier();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        elapsedMs += 30;
        // Bustabit's multiplier curve: m = e^(g*t), g ~ 0.00006
        multiplier = (exp(0.00006 * elapsedMs)).clamp(1.0, crashMultiplier + 2);
        if (multiplier >= crashMultiplier) {
          phase = CrashGamePhase.crashed;
          pastResults.insert(0, crashMultiplier);
          _timer?.cancel();
        }
      });
    });
  }

  void cashOut() {
    if (phase == CrashGamePhase.running) {
      setState(() {
        phase = CrashGamePhase.cashedOut;
        pastResults.insert(0, multiplier);
      });
      _timer?.cancel();
      widget.onCollectibleChange(selectedCollectible, -wager);
    }
  }

  void resetGame() {
    setState(() {
      phase = CrashGamePhase.waiting;
      multiplier = 1.0;
      elapsedMs = 0;
      hashIndex = (hashIndex + 1) % hashChain.length;
    });
  }

  double _computeCrashMultiplier() {
    // Provably fair: mimic bustabit logic
    final gameHash = hexToBytes(hashChain[hashIndex]);
    final key = utf8.encode(vxSignature);
    final hmacSha256 = Hmac(sha256, key);
    final hash = hmacSha256.convert(gameHash).bytes;
    // First 52 bits
    int r = 0;
    for (int i = 0; i < 7; i++) {
      r = (r << 8) | hash[i];
    }
    r = r >> 4; // Only 52 bits
    double X = r / pow(2, 52);
    double result = 99 / (1 - X);
    double crash = max(1.0, (result.floorToDouble() / 100));
    return crash;
  }

  int getMaxWager() {
    switch (selectedCollectible) {
      case 'LionsMane':
        return widget.lionsManeCollected;
      case 'RedPill':
        return widget.redPillCollected;
      case 'Bitcoin':
        return widget.bitcoinCollected;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = getMaxWager() >= wager && wager > 0;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Crash Mini Game', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${multiplier.toStringAsFixed(2)}x',
                  key: ValueKey(multiplier),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: phase == CrashGamePhase.crashed
                        ? Colors.red
                        : (phase == CrashGamePhase.cashedOut ? Colors.green : Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (phase == CrashGamePhase.waiting)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedCollectible,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    items: collectibles.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('$c (${getMaxWager()})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCollectible = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Wager',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (val) {
                        final n = int.tryParse(val) ?? 1;
                        setState(() => wager = n.clamp(1, getMaxWager()));
                      },
                      controller: TextEditingController(text: wager.toString()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: canPlay ? startGame : null,
                    child: const Text('Start'),
                  ),
                ],
              ),
            if (phase == CrashGamePhase.running)
              ElevatedButton(
                onPressed: cashOut,
                child: const Text('Cash Out'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (phase == CrashGamePhase.crashed)
              Text('Crashed!', style: TextStyle(color: Colors.red, fontSize: 24)),
            if (phase == CrashGamePhase.cashedOut)
              Text('Cashed Out!', style: TextStyle(color: Colors.green, fontSize: 24)),
            if (phase == CrashGamePhase.crashed || phase == CrashGamePhase.cashedOut)
              ElevatedButton(
                onPressed: resetGame,
                child: const Text('Play Again'),
              ),
            const SizedBox(height: 32),
            Text('Past Results', style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: pastResults.take(12).map((r) {
                  Color color = r >= 2.0
                      ? Colors.green
                      : (r >= 1.5 ? Colors.orange : Colors.red);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      '${r.toStringAsFixed(2)}x',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper: hex string to bytes
List<int> hexToBytes(String hex) {
  final result = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}
