// lib/presentation/widgets/map_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_page/core/constants/map_constants.dart';
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';
import '../providers/station_provider.dart';
import '../../domain/usecases/search_location.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isSearching = false;
  List<SearchResult> _searchResults = [];

  // Debounce for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      final results = await mapProvider.searchLocation(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start a new timer
    if (value.length >= 3) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch(value);
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _onSearchResultSelected(SearchResult result) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    // Set search text to selected place
    _searchController.text = result.name;

    // Clear search results
    setState(() {
      _searchResults = [];
    });

    // Go to selected location
    mapProvider.goToLocation(result.point);

    // Unfocus the search field
    _focusNode.unfocus();

    // After animation, load stations near the selected location
    Future.delayed(
      Duration(milliseconds: MapConstants.mapAnimationDurationMs + 100),
      () {
        if (mapProvider.currentZoom >= 10.0 &&
            mapProvider.visibleRegion != null) {
          stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search for a place',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),

        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result.name),
                  subtitle:
                      result.address != null
                          ? Text(
                            result.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                          : null,
                  onTap: () => _onSearchResultSelected(result),
                );
              },
            ),
          ),
      ],
    );
  }
}
