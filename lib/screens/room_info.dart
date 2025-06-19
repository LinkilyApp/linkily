import 'package:flutter/material.dart';
import 'package:linkily/styles/style_common.dart';

class RoomInfoScreen extends StatefulWidget {
  final List<dynamic> roomMembers;
  final dynamic currentDevice;

  const RoomInfoScreen({
    Key? key,
    required this.roomMembers,
    required this.currentDevice,
  }) : super(key: key);

  @override
  _RoomInfoScreenState createState() => _RoomInfoScreenState();
}

class _RoomInfoScreenState extends State<RoomInfoScreen> {
  late List<dynamic> _sortedMembers;

  @override
  void initState() {
    super.initState();
    _sortedMembers = List.from(widget.roomMembers)
      ..sort((a, b) => a['id'] == widget.currentDevice['id'] ? -1 : 1);
  }

  Widget _buildDeviceIcon(String brand) {
    IconData icon;
    switch (brand.toLowerCase()) {
      case 'apple':
        icon = Icons.phone_iphone;
        break;
      case 'samsung':
        icon = Icons.phone_android;
        break;
      case 'google':
        icon = Icons.android;
        break;
      case 'xiaomi':
        icon = Icons.phone_android;
        break;
      case 'oneplus':
        icon = Icons.phone_android;
        break;
      default:
        icon = Icons.devices_other;
    }
    return Icon(icon, size: 32, color: Theme.of(context).primaryColor);
  }

  Widget _buildMemberCard(dynamic member) {
    final isCurrentDevice = member['id'] == widget.currentDevice['id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isCurrentDevice ? Colors.blue[50] : null,
      child: ListTile(
        leading: _buildDeviceIcon(member['brand'] ?? ''),
        title: Text(
          member['user']['username'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrentDevice ? primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${member['brand']} ${member['model']}'),
            if (member['user']['email'] != null)
              Text('Email: ${member['user']['email']}'),
            if (member['user']['phone'] != null)
              Text('Phone: ${member['user']['phone']}'),
          ],
        ),
        trailing: Text(
          '#${member['fingerprint'].toString().substring(0, 6)}',
          style: TextStyle(
            color: isCurrentDevice ? primaryColor : Colors.grey[600],
            fontWeight: isCurrentDevice ? FontWeight.bold : null,
          ),
        ),
        onTap: () {
          // You could add functionality to switch the current device view
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Room Devices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
      ),
      body: _sortedMembers.isEmpty
          ? const Center(child: Text('No room members found'))
          : ListView.builder(
              itemCount: _sortedMembers.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(_sortedMembers[index]);
              },
            ),
    );
  }
}
