import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../utils/constants.dart';

class SearchResult {
  final String name;
  final Point point;
  final String? address;

  SearchResult({required this.name, required this.point, this.address});
}

class MapSearchBar extends StatefulWidget {
  final Function(Point) onPlaceSelected;
  final String accessToken;

  const MapSearchBar({
    super.key,
    required this.onPlaceSelected,
    required this.accessToken,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Clear search when focus is lost
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
      // Build the URL for the Mapbox Geocoding API
      final url =
          '${MapConstants.mapboxSearchApiUrl}$query.json?'
          'access_token=${widget.accessToken}'
          '&limit=${MapConstants.searchResultLimit}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        setState(() {
          _searchResults =
              features.map<SearchResult>((feature) {
                final coordinates = feature['center'] as List;
                return SearchResult(
                  name: feature['text'] as String,
                  address: feature['place_name'] as String?,
                  point: Point(
                    coordinates: Position(
                      coordinates[0].toDouble(),
                      coordinates[1].toDouble(),
                    ),
                  ),
                );
              }).toList();
          _isSearching = false;
        });
      } else {
        print('Error searching: ${response.statusCode}');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Exception during search: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
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
            onChanged: (value) {
              if (value.length >= 3) {
                _performSearch(value);
              } else {
                setState(() {
                  _searchResults = [];
                });
              }
            },
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
                  color: Colors.black.withOpacity(0.1),
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
                  onTap: () {
                    widget.onPlaceSelected(result.point);
                    _searchController.text = result.name;
                    setState(() {
                      _searchResults = [];
                    });
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
