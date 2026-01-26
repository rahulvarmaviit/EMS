import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../models/location.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  List<OfficeLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.get('/api/locations');
      if (response['success'] == true) {
        _locations = (response['data']['locations'] as List)
            .map((json) => OfficeLocation.fromJson(json))
            .toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final longController = TextEditingController();
    final radiusController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Office Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Head Office',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 37.7749',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: longController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., -122.4194',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  hintText: 'e.g., 100',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Use Google Maps to find coordinates. Right-click on a location and copy the latitude/longitude.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  latController.text.isEmpty ||
                  longController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await _apiClient.post('/api/locations', {
                  'name': nameController.text,
                  'latitude': double.parse(latController.text),
                  'longitude': double.parse(longController.text),
                  'radius_meters': int.parse(radiusController.text),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadLocations();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(OfficeLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location?'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiClient.delete('/api/locations/${location.id}');
        if (!context.mounted) return;
        _loadLocations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Locations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLocations,
              child: _locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No office locations defined',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a location to enable GPS check-in',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              location.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${location.latitude.toStringAsFixed(6)}, Long: ${location.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Radius: ${location.radiusMeters}m',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLocation(location),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
