import 'dart:math';

// In-memory cache keyed by DialogueRequest.cacheKey.
// Stores up to _variantsPerKey lines per key and rotates through them.
class DialogueCache {
  DialogueCache._();
  static final DialogueCache instance = DialogueCache._();

  static const _variantsPerKey = 3;
  static const _maxKeys = 60;

  final _store = <String, List<String>>{};
  final _rng = Random();

  String? get(String key) {
    final list = _store[key];
    if (list == null || list.isEmpty) return null;
    return list[_rng.nextInt(list.length)];
  }

  void put(String key, String line) {
    final list = _store.putIfAbsent(key, () => []);
    if (!list.contains(line)) {
      list.add(line);
      if (list.length > _variantsPerKey) list.removeAt(0);
    }
    // Evict oldest key if the store is full.
    if (_store.length > _maxKeys) {
      _store.remove(_store.keys.first);
    }
  }

  void clear() => _store.clear();
}
