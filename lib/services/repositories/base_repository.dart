// Base repository for the Forge application.
//
// Generic CRUD over a Hive box of [Identifiable] models. Domain
// repositories extend this and add their own query methods.
library;

import 'package:hive/hive.dart';

import '../../models/identifiable.dart';

/// Generic persistence operations shared by every repository.
abstract class BaseRepository<T extends Identifiable> {
  /// Creates a repository backed by [box].
  BaseRepository(this.box);

  /// The Hive box this repository reads from and writes to.
  final Box<T> box;

  /// Inserts or replaces [item], keyed by its id.
  Future<void> save(T item) => box.put(item.id, item);

  /// Inserts or replaces every item in [items] in one batch.
  Future<void> saveAll(Iterable<T> items) =>
      box.putAll({for (final item in items) item.id: item});

  /// Removes the entry with [id]; no-op if absent.
  Future<void> delete(String id) => box.delete(id);

  /// Removes every entry whose id is in [ids] in one batch.
  Future<void> deleteAll(Iterable<String> ids) => box.deleteAll(ids);

  /// Removes all entries and returns the number removed.
  Future<int> clear() => box.clear();

  /// Returns the entry with [id], or null if absent.
  T? byId(String id) => box.get(id);

  /// Whether an entry with [id] exists.
  bool contains(String id) => box.containsKey(id);

  /// All entries in the box, in insertion order.
  List<T> all() => box.values.toList();

  /// Entries for [ids], preserving the given order and dropping missing ones.
  List<T> allByIds(Iterable<String> ids) => [
        for (final id in ids)
          if (box.containsKey(id)) box.get(id) as T,
      ];

  /// Number of entries currently stored.
  int get count => box.length;
}
