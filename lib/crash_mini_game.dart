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
  final VoidCallback? onClose; // <-- Add this

  const CrashMiniGameScreen({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.onCollectibleChange,
    this.onClose, // <-- Add this
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
  late int lionsManeBalance;
  late int redPillBalance;
  late int bitcoinBalance;
  List<Offset> _graphPoints = [];

  @override
  void initState() {
    super.initState();
    lionsManeBalance = widget.lionsManeCollected;
    redPillBalance = widget.redPillCollected;
    bitcoinBalance = widget.bitcoinCollected;
    _graphPoints = [Offset(0, 1.0)];
  }

  @override
  void didUpdateWidget(covariant CrashMiniGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync balances if parent updates them
    lionsManeBalance = widget.lionsManeCollected;
    redPillBalance = widget.redPillCollected;
    bitcoinBalance = widget.bitcoinCollected;
  }

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
      _graphPoints = [Offset(0, 1.0)];
    });
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        elapsedMs += 30;
        // Bustabit's multiplier curve: m = e^(g*t), g ~ 0.00006
        multiplier = (exp(0.00006 * elapsedMs)).clamp(1.0, crashMultiplier + 2);
        _graphPoints.add(Offset(elapsedMs / 1000, multiplier));
        if (multiplier >= crashMultiplier) {
          phase = CrashGamePhase.crashed;
          pastResults.insert(0, crashMultiplier);
          // Lose wager
          _addCollectibles(selectedCollectible, -wager);
          widget.onCollectibleChange(selectedCollectible, -wager);
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
        // Award winnings
        int winnings = (wager * multiplier).floor();
        _addCollectibles(selectedCollectible, winnings);
      });
      _timer?.cancel();
      widget.onCollectibleChange(selectedCollectible, -wager); // Remove wagered amount
      widget.onCollectibleChange(selectedCollectible, (wager * multiplier).floor()); // Add winnings
    }
  }

  void resetGame() {
    setState(() {
      phase = CrashGamePhase.waiting;
      multiplier = 1.0;
      elapsedMs = 0;
      _graphPoints = [Offset(0, 1.0)];
      hashIndex = (hashIndex + 1) % hashChain.length;
    });
  }

  void _addCollectibles(String collectible, int amount) {
    setState(() {
      if (collectible == 'LionsMane') lionsManeBalance += amount;
      if (collectible == 'RedPill') redPillBalance += amount;
      if (collectible == 'Bitcoin') bitcoinBalance += amount;
    });
  }

  double _computeCrashMultiplier() {
    // Make crash multiplier truly random between 1.1x and 10x (or any range you want)
    final rand = Random();
    double crash = 1.1 + rand.nextDouble() * 8.9; // Range: 1.1 to 10.0
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
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // --- Bustabit-style Graph ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: SizedBox(
                height: 200,
                child: CrashGraph(
                  points: _graphPoints,
                  crashMultiplier: phase == CrashGamePhase.crashed ? multiplier : null,
                  cashedOutMultiplier: phase == CrashGamePhase.cashedOut ? multiplier : null,
                ),
              ),
            ),
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
            // --- Balance display ---
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _balanceIcon('assets/images/lions_mane.png', lionsManeBalance, Colors.amber),
                const SizedBox(width: 18),
                _balanceIcon('assets/images/red_pill.png', redPillBalance, Colors.redAccent),
                const SizedBox(width: 18),
                _balanceIcon('assets/images/bitcoin.png', bitcoinBalance, Colors.amber),
              ],
            ),
            // --- End balance display ---
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

  Widget _balanceIcon(String asset, int amount, Color color) {
    return Row(
      children: [
        Image.asset(asset, width: 28, height: 28, errorBuilder: (c, e, s) => Icon(Icons.help, color: color)),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: TextStyle(
            fontSize: 24,
            color: color,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ],
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

class CrashGraph extends StatelessWidget {
  final List<Offset> points;
  final double? crashMultiplier;
  final double? cashedOutMultiplier;

  const CrashGraph({
    Key? key,
    required this.points,
    this.crashMultiplier,
    this.cashedOutMultiplier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: CrashGraphPainter(
            points: points,
            crashMultiplier: crashMultiplier,
            cashedOutMultiplier: cashedOutMultiplier,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class CrashGraphPainter extends CustomPainter {
  final List<Offset> points;
  final double? crashMultiplier;
  final double? cashedOutMultiplier;

  CrashGraphPainter({
    required this.points,
    this.crashMultiplier,
    this.cashedOutMultiplier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFF181A20);
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (points.isEmpty) return;

    // Find max X (time) and Y (multiplier) for scaling
    double maxX = points.last.dx;
    double maxY = points.map((e) => e.dy).fold<double>(1.0, max);

    // Y axis: round up to next integer for label
    double yAxisMax = max(2.0, (maxY + 0.5).ceilToDouble());

    // X axis: show up to 8 seconds, scale if longer
    double xAxisMax = max(3.0, maxX);

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;
    // Y axis
    canvas.drawLine(Offset(40, 10), Offset(40, size.height - 30), axisPaint);
    // X axis
    canvas.drawLine(Offset(40, size.height - 30), Offset(size.width - 10, size.height - 30), axisPaint);

    // Y axis labels (1x, 2x, 3x...)
    final labelStyle = TextStyle(color: Colors.white54, fontSize: 12);
    for (int i = 1; i <= yAxisMax; i++) {
      double y = _mapY(i.toDouble(), yAxisMax, size.height);
      final tp = TextPainter(
        text: TextSpan(text: '${i}x', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5, y - tp.height / 2));
      // Draw grid line
      canvas.drawLine(
        Offset(40, y),
        Offset(size.width - 10, y),
        Paint()
          ..color = Colors.white10
          ..strokeWidth = 1,
      );
    }

    // X axis labels (multiplier values instead of seconds)
    // We'll pick evenly spaced multipliers from the curve
    int xLabels = 5; // Number of labels to show
    List<double> multipliersForLabels = [];
    if (points.length > 1) {
      double minMultiplier = points.first.dy;
      double maxMultiplier = points.last.dy;
      for (int i = 0; i <= xLabels; i++) {
        double m = minMultiplier + (maxMultiplier - minMultiplier) * (i / xLabels);
        multipliersForLabels.add(m);
      }
    } else {
      multipliersForLabels = [1.0, 2.0, 3.0, 4.0, 5.0];
    }
    for (var m in multipliersForLabels) {
      // Find the closest point in time for this multiplier
      Offset? closest = points.reduce((a, b) => (a.dy - m).abs() < (b.dy - m).abs() ? a : b);
      double x = _mapX(closest.dx, maxX, size.width);
      final tp = TextPainter(
        text: TextSpan(text: '${m.toStringAsFixed(1)}x', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 25));
      // Draw grid line
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, size.height - 30),
        Paint()
          ..color = Colors.white10
          ..strokeWidth = 1,
      );
    }

    // Draw curve
    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      double x = _mapX(points[i].dx, xAxisMax, size.width);
      double y = _mapY(points[i].dy, yAxisMax, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw crash/cashout indicator
    if (crashMultiplier != null) {
      double x = _mapX(points.last.dx, xAxisMax, size.width);
      double y = _mapY(crashMultiplier!, yAxisMax, size.height);
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = Colors.redAccent);
    } else if (cashedOutMultiplier != null) {
      double x = _mapX(points.last.dx, xAxisMax, size.width);
      double y = _mapY(cashedOutMultiplier!, yAxisMax, size.height);
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = Colors.amberAccent);
    }
  }

  double _mapX(double t, double maxT, double width) {
    // Map t (seconds) from [0, maxT] to [40, width-10]
    return 40 + (width - 50) * (t / maxT);
  }

  double _mapY(double m, double maxM, double height) {
    // Map m (multiplier) from [1, maxM] to [height-30, 10]
    return (height - 30) - ((m - 1) / (maxM - 1)) * (height - 40);
  }

  @override
  bool shouldRepaint(covariant CrashGraphPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.crashMultiplier != crashMultiplier ||
      oldDelegate.cashedOutMultiplier != cashedOutMultiplier;
}
