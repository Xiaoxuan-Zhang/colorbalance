import 'dart:ui';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';

// --- MOCK DATA MODEL ---
class MockColor {
  final String hex;
  final double percentage;
  final Color color;
  final String name;
  final String rgb;
  final String cmyk;
  final String lab;

  const MockColor({
    required this.hex,
    required this.percentage,
    required this.color,
    required this.name,
    required this.rgb,
    required this.cmyk,
    required this.lab,
  });
}

final List<MockColor> kMockPalette = [
  MockColor(hex: "#D4AF37", percentage: 24.0, color: Color(0xFFD4AF37), name: "Antique Gold", rgb: "212, 175, 55", cmyk: "15, 30, 85, 5", lab: "L* 72 a* 5 b* 68"),
  MockColor(hex: "#2C3E50", percentage: 18.0, color: Color(0xFF2C3E50), name: "Midnight Blue", rgb: "44, 62, 80", cmyk: "80, 65, 40, 40", lab: "L* 25 a* -2 b* -12"),
  MockColor(hex: "#E5E7E9", percentage: 15.0, color: Color(0xFFE5E7E9), name: "Gallery White", rgb: "229, 231, 233", cmyk: "5, 3, 3, 5", lab: "L* 92 a* -1 b* -2"),
  MockColor(hex: "#8E44AD", percentage: 12.0, color: Color(0xFF8E44AD), name: "Royal Velvet", rgb: "142, 68, 173", cmyk: "60, 80, 0, 0", lab: "L* 45 a* 45 b* -40"),
  MockColor(hex: "#16A085", percentage: 10.0, color: Color(0xFF16A085), name: "Patina Green", rgb: "22, 160, 133", cmyk: "85, 10, 55, 10", lab: "L* 58 a* -45 b* 5"),
];

class InspectorScreen extends StatefulWidget {
  final Uint8List originalBytes; // ACTUAL IMAGE DATA

  const InspectorScreen({super.key, required this.originalBytes});

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  int _selectedIndex = 0;
  bool _showTechPanel = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    final activeColor = kMockPalette[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND IMAGE (ACTUAL DATA) ---
          Positioned.fill(
            right: isLandscape ? 100 : 0,
            bottom: isLandscape ? 0 : 120,
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image(
                image: MemoryImage(widget.originalBytes), // USE PICKED IMAGE
                fit: BoxFit.contain, // Contain ensures full image is seen
                color: Colors.black.withOpacity(0.2),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          // --- LAYER 2: TOP NAVIGATION ---
          Positioned(
            top: 0, left: 0, right: isLandscape ? 100 : 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _GlassButton(
                        icon: Icons.tune,
                        label: "Data",
                        onTap: () => setState(() => _showTechPanel = true),
                      ),
                      const SizedBox(width: 12),
                      _GlassButton(icon: Icons.ios_share, onTap: () {}),
                    ],
                  )
                ],
              ),
            ),
          ),

          // --- LAYER 3: FLOATING HUD ---
          Positioned(
            top: topPadding + 80,
            left: 20,
            child: _FloatingHud(colorData: activeColor),
          ),

          // --- LAYER 4: PALETTE RAIL ---
          if (isLandscape)
            Positioned(
              right: 0, top: 0, bottom: 0, width: 100,
              child: _SideRail(
                selectedIndex: _selectedIndex,
                onSelect: (index) => setState(() => _selectedIndex = index),
              ),
            )
          else
            Positioned(
              left: 0, right: 0, bottom: 0, height: 120,
              child: _BottomRail(
                selectedIndex: _selectedIndex,
                onSelect: (index) => setState(() => _selectedIndex = index),
              ),
            ),

          // --- LAYER 5: TECH PANEL ---
          if (_showTechPanel)
            _TechPanelOverlay(
              isLandscape: isLandscape,
              colorData: activeColor,
              onClose: () => setState(() => _showTechPanel = false),
            ),
        ],
      ),
    );
  }
}

// --- COMPONENTS (Same as before) ---

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withOpacity(0.1),
            child: Row(children: [Icon(icon, color: Colors.white, size: 18), if (label != null) ...[const SizedBox(width: 8), Text(label!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))]]),
          ),
        ),
      ),
    );
  }
}

class _FloatingHud extends StatelessWidget {
  final MockColor colorData;
  const _FloatingHud({required this.colorData});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: Border(left: BorderSide(color: colorData.color, width: 4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DOMINANT", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(children: [Text(colorData.hex, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16)), const SizedBox(width: 12), Container(width: 1, height: 12, color: Colors.white24), const SizedBox(width: 12), Text("${colorData.percentage.toInt()}%", style: const TextStyle(color: Colors.white70))]),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  const _BottomRail({required this.selectedIndex, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xFF121212).withOpacity(0.85),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PALETTE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 2)),
              const Spacer(),
              SizedBox(height: 50, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: kMockPalette.length, separatorBuilder: (_, __) => const SizedBox(width: 20), itemBuilder: (_, i) => _Swatch(color: kMockPalette[i].color, isSelected: i == selectedIndex, onTap: () => onSelect(i)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  const _SideRail({required this.selectedIndex, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xFF121212).withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
          child: Column(
            children: [
              RotatedBox(quarterTurns: 3, child: Text("PALETTE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 2))),
              const SizedBox(height: 30),
              Expanded(child: ListView.separated(itemCount: kMockPalette.length, separatorBuilder: (_, __) => const SizedBox(height: 20), itemBuilder: (_, i) => _Swatch(color: kMockPalette[i].color, isSelected: i == selectedIndex, onTap: () => onSelect(i)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _Swatch({required this.color, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 0)] : [BoxShadow(color: Colors.transparent, blurRadius: 0, spreadRadius: 0)],
        ),
      ),
    );
  }
}

class _TechPanelOverlay extends StatelessWidget {
  final bool isLandscape;
  final MockColor colorData;
  final VoidCallback onClose;
  const _TechPanelOverlay({required this.isLandscape, required this.colorData, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: isLandscape ? 400 : double.infinity,
              height: isLandscape ? double.infinity : 450,
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: isLandscape ? const BorderRadius.horizontal(left: Radius.circular(32)) : const BorderRadius.vertical(top: Radius.circular(32)), border: Border.all(color: Colors.white10)),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("TECHNICAL SPECTRUM", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)), const SizedBox(height: 8), Text(colorData.name, style: const TextStyle(fontFamily: 'serif', fontSize: 32, color: Colors.white))]), IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: onClose)]),
                  const SizedBox(height: 40),
                  _DataRow(label: "HEX", value: colorData.hex, color: Colors.white),
                  _DataRow(label: "RGB", value: colorData.rgb, color: Colors.grey),
                  _DataRow(label: "CMYK", value: colorData.cmyk, color: Colors.grey),
                  _DataRow(label: "LAB", value: colorData.lab, color: const Color(0xFFD4AF37)),
                  const SizedBox(height: 20), const Divider(color: Colors.white10), const SizedBox(height: 20),
                  const Text("HARMONY", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(children: [CircleAvatar(backgroundColor: colorData.color), const SizedBox(width: 16), const Icon(Icons.arrow_forward, color: Colors.grey, size: 16), const SizedBox(width: 16), CircleAvatar(backgroundColor: colorData.color.withOpacity(0.5)), const SizedBox(width: 12), const Text("Complementary", style: TextStyle(color: Colors.white70, fontSize: 12))]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DataRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 14))]),
    );
  }
}