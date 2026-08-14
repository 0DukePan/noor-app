import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/adhkar_data_source.dart';

/// Tests the extended adhkar library: structure, references, categories,
/// and loading through the data source.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AdhkarLibrary? library;

  setUp(() async {
    final raw = await rootBundle.loadString('assets/adhkar/library.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    library = AdhkarLibrary.fromJson(json);
  });

  test('library.json parses into a valid structure', () {
    expect(library, isNotNull);
    expect(library!.categories, isNotEmpty);
    expect(library!.items, isNotEmpty);
  });

  test('library has 100+ sourced items across 15+ categories', () {
    expect(library!.items.length, greaterThanOrEqualTo(100));
    expect(library!.categories.length, greaterThanOrEqualTo(15));
  });

  test('every item has a verbatim source reference', () {
    for (final item in library!.items) {
      expect(item.reference, isNotNull,
          reason: 'zekr #${item.index} has no reference',);
      expect(item.reference!.trim(), isNotEmpty);
      expect(item.text.trim(), isNotEmpty,
          reason: 'zekr #${item.index} has empty text',);
    }
  });

  test('every category has at least one item', () {
    for (final category in library!.categories) {
      expect(library!.countFor(category.id), greaterThan(0),
          reason: 'category ${category.id} has no items',);
    }
  });

  test('all item categories map to a declared category', () {
    final ids = library!.categories.map((c) => c.id).toSet();
    for (final item in library!.items) {
      expect(ids.contains(item.category), isTrue,
          reason: 'item #${item.index} has undeclared category '
              '${item.category}',);
    }
  });

  test('data source loads the library', () async {
    final loaded = await AdhkarDataSource.getLibrary();
    expect(loaded, isNotNull);
    expect(loaded!.items.length, library!.items.length);
  });
}
