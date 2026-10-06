import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/master_data_provider.dart';

class MasterDataScreen extends ConsumerStatefulWidget {
  const MasterDataScreen({super.key});

  @override
  ConsumerState<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends ConsumerState<MasterDataScreen> {
  String _selectedCategory = 'tyre_size';

  final Map<String, String> _categories = {
    'tyre_size': 'Tyre Sizes',
    'tyre_brand': 'Tyre Brands',
    'pattern': 'Tread Patterns',
    'tyre_type': 'Tyre Types',
    'machine': 'Building / Buffing Machines',
    'cold_chamber': 'Cold Chambers',
    'operator': 'Factory Operators',
    'qc_defect_type': 'QC Defect Types',
    'stock_category': 'Stock Categories',
    'unit': 'Units of Measurement',
    'payment_method': 'Payment Methods',
    'customer_type': 'Customer Types',
  };

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add New ${_categories[_selectedCategory]}'),
          content: CustomTextField(
            label: 'Name / Value',
            hint: 'e.g. 12.00-24',
            controller: nameController,
            isRequired: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(dialogContext);
                try {
                  await ref.read(masterDataProvider.notifier).addMasterData(
                        category: _selectedCategory,
                        name: name,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "$name" to ${_categories[_selectedCategory]}!'),
                        backgroundColor: AppColors.ready,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: AppColors.rejected,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Value'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Master Data Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(masterDataProvider.notifier).fetchMasterData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: Text('Add ${_categories[_selectedCategory]}'),
      ),
      body: Column(
        children: [
          // Category selector chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.keys.length,
              itemBuilder: (context, index) {
                final catKey = _categories.keys.elementAt(index);
                final catName = _categories[catKey]!;
                final isSelected = catKey == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(catName),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = catKey);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: masterAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading options...'),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allItems) {
                final filtered = allItems
                    .where((i) => i.category == _selectedCategory)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.settings_suggest_outlined, size: 48, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        Text('No items in ${_categories[_selectedCategory]}'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Item'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Category: ${item.category}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
