import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T item) itemAsString;
  final void Function(T? selected) onChanged;
  final bool isRequired;
  final String? Function(T? value)? validator;
  final Widget Function(BuildContext context, T item)? itemBuilder;

  const SearchableDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
    this.itemBuilder,
  });

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return _SearchableBottomSheetContent<T>(
          label: label,
          items: items,
          itemAsString: itemAsString,
          itemBuilder: itemBuilder,
          onSelected: (selected) {
            Navigator.pop(bottomSheetContext);
            onChanged(selected);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedVal = value;
    final displayText = selectedVal != null
        ? itemAsString(selectedVal)
        : (hint ?? 'Select $label');

    // FormField only reads `initialValue` once. Keying it on the selected value makes
    // it pick up the new selection, so `Form.validate()` sees what the user chose
    // (otherwise required dropdowns could never pass validation).
    return FormField<T>(
      key: ValueKey<T?>(value),
      initialValue: value,
      validator: validator ??
          (val) {
            if (isRequired && val == null) {
              return 'Please select $label';
            }
            return null;
          },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showSearchBottomSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isRequired ? '$label *' : label,
                  hintText: hint,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: state.errorText,
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: value != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchableBottomSheetContent<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final String Function(T item) itemAsString;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final void Function(T selected) onSelected;

  const _SearchableBottomSheetContent({
    required this.label,
    required this.items,
    required this.itemAsString,
    this.itemBuilder,
    required this.onSelected,
  });

  @override
  State<_SearchableBottomSheetContent<T>> createState() =>
      _SearchableBottomSheetContentState<T>();
}

class _SearchableBottomSheetContentState<T>
    extends State<_SearchableBottomSheetContent<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) =>
                widget.itemAsString(item).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select ${widget.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.label}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No options found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          if (widget.itemBuilder != null) {
                            return InkWell(
                              onTap: () => widget.onSelected(item),
                              child: widget.itemBuilder!(context, item),
                            );
                          }
                          return ListTile(
                            title: Text(widget.itemAsString(item)),
                            onTap: () => widget.onSelected(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
