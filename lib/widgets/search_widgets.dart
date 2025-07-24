import 'package:flutter/material.dart';
import '../utils/ui_constants.dart';

class CustomSearchDelegate<T> extends SearchDelegate<T?> {
  final List<T> items;
  final String Function(T) getDisplayText;
  final String Function(T) getSearchText;
  final Widget Function(T) buildItem;
  final String hintText;

  CustomSearchDelegate({
    required this.items,
    required this.getDisplayText,
    required this.getSearchText,
    required this.buildItem,
    this.hintText = 'Search...',
  });

  @override
  String get searchFieldLabel => hintText;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredItems = query.isEmpty
        ? items
        : items
            .where((item) =>
                getSearchText(item).toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: UiConstants.defaultSpacing),
            Text(
              'No results found',
              style: TextStyle(
                  fontSize: UiConstants.titleFontSize, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return InkWell(
          onTap: () => close(context, item),
          child: buildItem(item),
        );
      },
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.defaultBorderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
