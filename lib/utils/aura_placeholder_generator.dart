import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Generates placeholder images for auras programmatically
class AuraPlaceholderGenerator {
  
  /// Generate a colored circle aura placeholder based on name/type
  static Future<Uint8List> generateAuraPlaceholder({
    required String auraName,
    required String rarity,
    int size = 200,
  }) async {
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Color mapping based on aura name/type
    Color auraColor = _getAuraColor(auraName);
    Color borderColor = _getRarityColor(rarity);
    
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 10;
    
    // Draw outer border (rarity color)
    paint.color = borderColor;
    canvas.drawCircle(center, radius, paint);
    
    // Draw inner aura (aura-specific color)
    paint.color = auraColor.withOpacity(0.8);
    canvas.drawCircle(center, radius - 5, paint);
    
    // Draw inner glow
    paint.color = auraColor.withOpacity(0.4);
    canvas.drawCircle(center, radius - 15, paint);
    
    // Draw center sparkle
    paint.color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(center, 20, paint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  /// Get color based on aura name
  static Color _getAuraColor(String auraName) {
    final name = auraName.toLowerCase();
    
    if (name.contains('ocean') || name.contains('water')) return Colors.blue;
    if (name.contains('forest') || name.contains('nature')) return Colors.green;
    if (name.contains('fire') || name.contains('ember') || name.contains('phoenix')) return Colors.red;
    if (name.contains('lightning') || name.contains('electric')) return Colors.purple;
    if (name.contains('sunset') || name.contains('golden')) return Colors.orange;
    if (name.contains('moonbeam') || name.contains('silver')) return Colors.grey.shade300;
    if (name.contains('starlight') || name.contains('cosmic')) return Colors.indigo;
    if (name.contains('galaxy') || name.contains('nebula')) return Colors.purple.shade300;
    if (name.contains('crystal') || name.contains('prism')) return Colors.cyan;
    if (name.contains('amethyst')) return Colors.purple.shade700;
    if (name.contains('diamond')) return Colors.white;
    if (name.contains('cherry') || name.contains('blossom')) return Colors.pink;
    if (name.contains('autumn') || name.contains('leaves')) return Colors.brown;
    if (name.contains('winter') || name.contains('frost')) return Colors.lightBlue;
    if (name.contains('shadow') || name.contains('dark')) return Colors.grey.shade800;
    if (name.contains('angel') || name.contains('healing')) return Colors.yellow.shade100;
    if (name.contains('dragon')) return Colors.deepPurple;
    if (name.contains('eclipse')) return Colors.black;
    if (name.contains('rainbow') || name.contains('butterfly')) return Colors.pink.shade300;
    if (name.contains('candy') || name.contains('sweet')) return Colors.pink.shade200;
    if (name.contains('disco') || name.contains('neon')) return Colors.cyan.shade400;
    if (name.contains('zen') || name.contains('peaceful')) return Colors.green.shade200;
    
    // Default color
    return Colors.blue.shade300;
  }
  
  /// Get border color based on rarity
  static Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return Colors.grey;
      case 'uncommon': return Colors.green;
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

/// Widget to display generated aura placeholder
class AuraPlaceholderWidget extends StatefulWidget {
  final String auraName;
  final String rarity;
  final double size;
  
  const AuraPlaceholderWidget({
    Key? key,
    required this.auraName,
    required this.rarity,
    this.size = 100,
  }) : super(key: key);
  
  @override
  State<AuraPlaceholderWidget> createState() => _AuraPlaceholderWidgetState();
}

class _AuraPlaceholderWidgetState extends State<AuraPlaceholderWidget> {
  Uint8List? imageBytes;
  
  @override
  void initState() {
    super.initState();
    _generateImage();
  }
  
  void _generateImage() async {
    final bytes = await AuraPlaceholderGenerator.generateAuraPlaceholder(
      auraName: widget.auraName,
      rarity: widget.rarity,
      size: widget.size.toInt(),
    );
    if (mounted) {
      setState(() {
        imageBytes = bytes;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      );
    }
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: MemoryImage(imageBytes!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
