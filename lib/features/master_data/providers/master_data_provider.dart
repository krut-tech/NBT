import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/master_data_item.dart';

class MasterDataNotifier extends StateNotifier<AsyncValue<List<MasterDataItem>>> {
  MasterDataNotifier() : super(const AsyncValue.loading()) {
    fetchMasterData();
  }

  Future<void> fetchMasterData() async {
    try {
      final response = await SupabaseService.client
          .from('master_data')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final items = (response as List)
          .map((json) => MasterDataItem.fromJson(json))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMasterData({
    required String category,
    required String name,
    String? code,
  }) async {
    try {
      await SupabaseService.client.from('master_data').insert({
        'category': category,
        'name': name.trim(),
        'code': code,
        'is_active': true,
      });
      await fetchMasterData();
    } catch (e) {
      rethrow;
    }
  }
}

final masterDataProvider =
    StateNotifierProvider<MasterDataNotifier, AsyncValue<List<MasterDataItem>>>(
        (ref) => MasterDataNotifier());

// Helper selectors for dropdown lists
final tyreSizesProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'tyre_size')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['10.00-20', '9.00-20', '8.25-20', '11.00-20', '295/80R22.5'],
      );
});

final tyreBrandsProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'tyre_brand')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['MRF', 'CEAT', 'Apollo', 'JK Tyre', 'Bridgestone', 'Goodyear'],
      );
});

final tyrePatternsProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'pattern')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Lug', 'Rib', 'Semi-Lug', 'Block', 'Highway'],
      );
});

final tyreTypesProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'tyre_type')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Radial', 'Nylon', 'Tubeless', 'Tube Type'],
      );
});

final machinesProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'machine')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Building Machine #1', 'Buffing Machine #1'],
      );
});

final coldChambersProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'cold_chamber')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Cold Chamber #1', 'Cold Chamber #2'],
      );
});

final operatorsProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'operator')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Ramesh Kumar', 'Suresh Sharma'],
      );
});

final paymentMethodsProvider = Provider<List<String>>((ref) {
  return ref.watch(masterDataProvider).maybeWhen(
        data: (items) => items
            .where((item) => item.category == 'payment_method')
            .map((e) => e.name)
            .toList(),
        orElse: () => ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Credit'],
      );
});
