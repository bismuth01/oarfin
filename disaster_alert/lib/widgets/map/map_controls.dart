import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onMapTypePressed;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onRefreshPressed;

  const MapControls({
    Key? key,
    required this.onMapTypePressed,
    required this.onMyLocationPressed,
    required this.onRefreshPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildMapButton(
            icon: Icons.layers,
            tooltip: 'Change Map Type',
            onPressed: onMapTypePressed,
          ),
          const SizedBox(height: 8),
          _buildMapButton(
            icon: Icons.my_location,
            tooltip: 'My Location',
            onPressed: onMyLocationPressed,
          ),
          const SizedBox(height: 8),
          _buildMapButton(
            icon: Icons.refresh,
            tooltip: 'Refresh Alerts',
            onPressed: onRefreshPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
