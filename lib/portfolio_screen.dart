import 'package:flutter/material.dart';

class PortfolioScreen extends StatefulWidget {
  final int lionsManeCollected;
  final int redPillCollected;
  final int bitcoinCollected;
  final List<double> lionsManePnlHistory;
  final List<double> redPillPnlHistory;
  final List<double> bitcoinPnlHistory;
  final List<double> totalWealthHistory;
  final VoidCallback? onClose; // <-- Add this

  const PortfolioScreen({
    Key? key,
    required this.lionsManeCollected,
    required this.redPillCollected,
    required this.bitcoinCollected,
    required this.lionsManePnlHistory,
    required this.redPillPnlHistory,
    required this.bitcoinPnlHistory,
    required this.totalWealthHistory,
    this.onClose, // <-- Add this
  }) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String selectedGraph = 'Total';

  @override
  Widget build(BuildContext context) {
    List<double> graphData;
    String graphLabel;
    Color graphColor;

    switch (selectedGraph) {
      case 'LionsMane':
        graphData = widget.lionsManePnlHistory;
        graphLabel = 'Lions Mane PnL';
        graphColor = Colors.amber;
        break;
      case 'RedPill':
        graphData = widget.redPillPnlHistory;
        graphLabel = 'Red Pill PnL';
        graphColor = Colors.redAccent;
        break;
      case 'Bitcoin':
        graphData = widget.bitcoinPnlHistory;
        graphLabel = 'Bitcoin PnL';
        graphColor = Colors.amberAccent;
        break;
      default:
        graphData = widget.totalWealthHistory;
        graphLabel = 'Total Wealth';
        graphColor = Colors.greenAccent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: Colors.black,
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _holding('assets/images/lions_mane.png', widget.lionsManeCollected, Colors.amber),
                const SizedBox(width: 18),
                _holding('assets/images/red_pill.png', widget.redPillCollected, Colors.redAccent),
                const SizedBox(width: 18),
                _holding('assets/images/bitcoin.png', widget.bitcoinCollected, Colors.amberAccent),
              ],
            ),
            const SizedBox(height: 24),
            ToggleButtons(
              borderColor: Colors.white24,
              selectedBorderColor: Colors.green,
              fillColor: Colors.white10,
              selectedColor: Colors.greenAccent,
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              isSelected: [
                selectedGraph == 'Total',
                selectedGraph == 'LionsMane',
                selectedGraph == 'RedPill',
                selectedGraph == 'Bitcoin',
              ],
              onPressed: (idx) {
                setState(() {
                  switch (idx) {
                    case 0: selectedGraph = 'Total'; break;
                    case 1: selectedGraph = 'LionsMane'; break;
                    case 2: selectedGraph = 'RedPill'; break;
                    case 3: selectedGraph = 'Bitcoin'; break;
                  }
                });
              },
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Total')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Lions Mane')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Red Pill')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Bitcoin')),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              graphLabel,
              style: TextStyle(color: graphColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: _PnLGraph(data: graphData, color: graphColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holding(String asset, int amount, Color color) {
    return Row(
      children: [
        Image.asset(asset, width: 32, height: 32, errorBuilder: (c, e, s) => Icon(Icons.help, color: color)),
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

class _PnLGraph extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _PnLGraph({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return Center(child: Text('No data', style: TextStyle(color: Colors.white54)));
    }
    // Optionally, show a message if the graph is flat (all values the same)
    bool isFlat = data.every((v) => v == data[0]);
    if (isFlat) {
      return Center(child: Text('No change yet', style: TextStyle(color: Colors.white54)));
    }
    return CustomPaint(
      painter: _PnLGraphPainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _PnLGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _PnLGraphPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final yRange = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = size.width * (i / (data.length - 1));
      final y = size.height - ((data[i] - minY) / yRange) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw axis lines
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    // Y axis
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    // X axis
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    // Draw min/max labels
    final textStyle = TextStyle(color: Colors.white54, fontSize: 12);
    final minTp = TextPainter(
      text: TextSpan(text: minY.toStringAsFixed(0), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    minTp.paint(canvas, Offset(4, size.height - minTp.height - 2));
    final maxTp = TextPainter(
      text: TextSpan(text: maxY.toStringAsFixed(0), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxTp.paint(canvas, Offset(4, 2));
  }

  @override
  bool shouldRepaint(covariant _PnLGraphPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
