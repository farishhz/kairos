import Foundation

actor IconCacheActor {
    private var cache: [String: Data] = [:]
    private var accessOrder: [String] = []
    private let maxEntries: Int

    init(maxEntries: Int = 200) {
        self.maxEntries = maxEntries
    }

    func get(_ key: String) -> Data? {
        guard let data = cache[key] else { return nil }
        // Move to most-recently-used
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        return data
    }

    func set(_ key: String, value: Data) {
        if cache[key] == nil, accessOrder.count >= maxEntries {
            // Evict least-recently-used
            if let oldest = accessOrder.first {
                cache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }
        }
        cache[key] = value
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}
