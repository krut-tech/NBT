import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/supplier.dart';

class SupplierNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  SupplierNotifier() : super(const AsyncValue.loading()) {
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    try {
      final response = await SupabaseService.client
          .from('suppliers')
          .select()
          .order('name', ascending: true);

      final suppliers =
          (response as List).map((json) => Supplier.fromJson(json)).toList();

      state = AsyncValue.data(suppliers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSupplier({
    required String name,
    String? mobile,
    String? address,
    String? gstNumber,
    String? productsSupplied,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.from('suppliers').insert({
        'name': name.trim(),
        'mobile': mobile,
        'address': address,
        'gst_number': gstNumber,
        'products_supplied': productsSupplied,
        'notes': notes,
      });

      await fetchSuppliers();
    } catch (e) {
      rethrow;
    }
  }
}

final supplierProvider =
    StateNotifierProvider<SupplierNotifier, AsyncValue<List<Supplier>>>(
        (ref) => SupplierNotifier());
