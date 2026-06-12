import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../viewmodels/location_picker_viewmodel.dart';

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = LocationPickerViewModel(
          permissionService: context.read(),
        );
        vm.init();
        return vm;
      },
      child: const _LocationPickerView(),
    );
  }
}

class _LocationPickerView extends StatelessWidget {
  const _LocationPickerView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationPickerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          if (vm.isLoadingLocation || vm.isResolvingAddress)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (!vm.isLoadingLocation && !vm.isResolvingAddress)
            TextButton(
              onPressed: () => Navigator.of(context).pop(vm.selectedLocation),
              child: const Text('Confirmar'),
            ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(vm: vm),
          if (vm.error != null) _ErrorBanner(message: vm.error!),
          Expanded(child: _MapView(vm: vm)),
          _LocationInfo(vm: vm),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: vm.isLoadingLocation ? null : vm.getCurrentLocation,
        tooltip: 'Mi ubicación',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final LocationPickerViewModel vm;
  const _SearchBar({required this.vm});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Buscar dirección o zona',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    widget.vm.searchAddress(query);
  }
}

class _MapView extends StatelessWidget {
  final LocationPickerViewModel vm;
  const _MapView({required this.vm});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: vm.latLng,
        initialZoom: 15.0,
        onTap: (tapPosition, point) => vm.movePin(point.latitude, point.longitude),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cociname.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: vm.latLng,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final LocationPickerViewModel vm;
  const _LocationInfo({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vm.addressLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[100],
      child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
    );
  }
}
