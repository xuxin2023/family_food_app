import { describe, it, expect } from '@ohos/hypium';
import { LruCache } from 'hsp_core';

export default function lruCacheTest() {
  describe('LruCache', () => {
    it('should_set_and_get_value', 0, () => {
      const cache = new LruCache<string, number>(10);
      cache.set('a', 1);
      cache.set('b', 2);
      expect(cache.get('a')).assertEqual(1);
      expect(cache.get('b')).assertEqual(2);
    });

    it('should_return_undefined_for_missing_key', 0, () => {
      const cache = new LruCache<string, number>(10);
      expect(cache.get('missing')).assertEqual(undefined);
    });

    it('should_update_existing_key', 0, () => {
      const cache = new LruCache<string, number>(10);
      cache.set('a', 1);
      cache.set('a', 99);
      expect(cache.get('a')).assertEqual(99);
      expect(cache.size).assertEqual(1);
    });

    it('should_evict_lru_when_over_capacity', 0, () => {
      const cache = new LruCache<string, number>(3);
      cache.set('a', 1);
      cache.set('b', 2);
      cache.set('c', 3);
      cache.set('d', 4);
      expect(cache.get('a')).assertEqual(undefined);
      expect(cache.get('b')).assertEqual(2);
      expect(cache.get('c')).assertEqual(3);
      expect(cache.get('d')).assertEqual(4);
      expect(cache.size).assertEqual(3);
    });

    it('should_move_accessed_key_to_mru', 0, () => {
      const cache = new LruCache<string, number>(3);
      cache.set('a', 1);
      cache.set('b', 2);
      cache.set('c', 3);
      cache.get('a');
      cache.set('d', 4);
      expect(cache.get('a')).assertEqual(1);
      expect(cache.get('b')).assertEqual(undefined);
    });

    it('should_expire_entry_with_ttl', 0, () => {
      const cache = new LruCache<string, number>(10, 1);
      cache.set('a', 1);
      const val = cache.get('a');
      expect(val).assertEqual(1);
    });

    it('should_support_per_key_ttl', 0, () => {
      const cache = new LruCache<string, number>(10);
      cache.set('a', 1, 1);
      cache.set('b', 2, 0);
      const valA = cache.get('a');
      const valB = cache.get('b');
      expect(valB).assertEqual(2);
    });

    it('has_should_return_false_for_expired', 0, () => {
      const cache = new LruCache<string, number>(10, 1);
      cache.set('a', 1);
      expect(cache.has('a')).assertTrue();
    });

    it('has_should_return_false_for_missing', 0, () => {
      const cache = new LruCache<string, number>(10);
      expect(cache.has('missing')).assertFalse();
    });

    it('delete_should_remove_entry', 0, () => {
      const cache = new LruCache<string, number>(10);
      cache.set('a', 1);
      cache.delete('a');
      expect(cache.get('a')).assertEqual(undefined);
      expect(cache.size).assertEqual(0);
    });

    it('clear_should_remove_all', 0, () => {
      const cache = new LruCache<string, number>(10);
      cache.set('a', 1);
      cache.set('b', 2);
      cache.clear();
      expect(cache.size).assertEqual(0);
    });

    it('size_should_reflect_count', 0, () => {
      const cache = new LruCache<string, number>(10);
      expect(cache.size).assertEqual(0);
      cache.set('a', 1);
      expect(cache.size).assertEqual(1);
      cache.set('b', 2);
      expect(cache.size).assertEqual(2);
    });

    it('evictExpired_should_clean_expired', 0, () => {
      const cache = new LruCache<string, number>(10, 1);
      cache.set('a', 1);
      cache.set('b', 2);
      const evicted = cache.evictExpired();
      expect(evicted).assertGreater(0);
    });

    it('maxSize_should_be_at_least_1', 0, () => {
      const cache = new LruCache<string, number>(0);
      cache.set('a', 1);
      expect(cache.size).assertEqual(1);
    });
  });
}