import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Find the Best Deals on Electronics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search for products, brands, or stores...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[400],
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => onSearchChanged(''),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
