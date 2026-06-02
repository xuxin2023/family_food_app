// CrdtSyncResolver.test.ets
// V5 CRDT向量时钟冲突解决单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { CrdtSyncResolver, ConflictResolutionStrategy } from 'hsp_core';

export default function crdtTest(): TestSuite {
  const suite = new TestSuite('CrdtSyncResolver');

  suite.addTest(new TestCase('mergeVectorClocks_combines disjoint', () => {
    const a = [{ nodeId: 'A', counter: 3 }];
    const b = [{ nodeId: 'B', counter: 5 }];
    const merged = CrdtSyncResolver.mergeVectorClocks(a, b);
    expect(merged.length).assertEqual(2);
    const nodeA = merged.find(c => c.nodeId === 'A');
    const nodeB = merged.find(c => c.nodeId === 'B');
    expect(nodeA!.counter).assertEqual(3);
    expect(nodeB!.counter).assertEqual(5);
  }));

  suite.addTest(new TestCase('mergeVectorClocks_takes maximum counter', () => {
    const a = [{ nodeId: 'A', counter: 3 }];
    const b = [{ nodeId: 'A', counter: 7 }];
    const merged = CrdtSyncResolver.mergeVectorClocks(a, b);
    expect(merged.length).assertEqual(1);
    expect(merged[0].counter).assertEqual(7);
  }));

  suite.addTest(new TestCase('incrementClock_adds node', () => {
    const clocks = [{ nodeId: 'A', counter: 2 }];
    const inc = CrdtSyncResolver.incrementClock(clocks, 'B');
    expect(inc.length).assertEqual(2);
    expect(inc.find(c => c.nodeId === 'B')!.counter).assertEqual(1);
  }));

  suite.addTest(new TestCase('incrementClock_increments existing', () => {
    const clocks = [{ nodeId: 'A', counter: 3 }];
    const inc = CrdtSyncResolver.incrementClock(clocks, 'A');
    expect(inc.length).assertEqual(1);
    expect(inc[0].counter).assertEqual(4);
  }));

  suite.addTest(new TestCase('resolve_lww_same timestamps', () => {
    const local = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 100 };
    const remote = { _vectorClock: [{ nodeId: 'B', counter: 1 }], updatedAt: 200 };
    const result = CrdtSyncResolver.resolve(local, remote, null, ConflictResolutionStrategy.LAST_WRITE_WINS);
    expect(result.resolved.updatedAt).assertEqual(200);
    expect(result.hadConflict).assertTrue();
  }));

  suite.addTest(new TestCase('resolve_threeWay_base_local win', () => {
    const base = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 50, value: 10 };
    const local = { _vectorClock: [{ nodeId: 'A', counter: 2 }], updatedAt: 100, value: 20 };
    const remote = { _vectorClock: [{ nodeId: 'B', counter: 1 }], updatedAt: 50, value: 10 };
    const result = CrdtSyncResolver.resolve(local, remote, base, ConflictResolutionStrategy.FIELD_LEVEL_MERGE);
    expect((result.resolved as Record<string, number>)['value']).assertEqual(20);
    expect(result.hadConflict).assertFalse();
  }));

  suite.addTest(new TestCase('resolve_threeWay_base_remote win', () => {
    const base = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 50, value: 10 };
    const local = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 50, value: 10 };
    const remote = { _vectorClock: [{ nodeId: 'B', counter: 2 }], updatedAt: 100, value: 30 };
    const result = CrdtSyncResolver.resolve(local, remote, base, ConflictResolutionStrategy.FIELD_LEVEL_MERGE);
    expect((result.resolved as Record<string, number>)['value']).assertEqual(30);
    expect(result.hadConflict).assertFalse();
  }));

  suite.addTest(new TestCase('resolve_fieldLevel_merge detects real conflict', () => {
    const base = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 50, value: 10 };
    const local = { _vectorClock: [{ nodeId: 'A', counter: 2 }], updatedAt: 100, value: 20 };
    const remote = { _vectorClock: [{ nodeId: 'B', counter: 2 }], updatedAt: 100, value: 30 };
    const result = CrdtSyncResolver.resolve(local, remote, base, ConflictResolutionStrategy.FIELD_LEVEL_MERGE);
    expect(result.hadConflict).assertTrue();
  }));

  suite.addTest(new TestCase('resolve_noBase falls back to LWW', () => {
    const local = { _vectorClock: [{ nodeId: 'A', counter: 1 }], updatedAt: 100 };
    const remote = { _vectorClock: [{ nodeId: 'B', counter: 1 }], updatedAt: 200 };
    const result = CrdtSyncResolver.resolve(local, remote, null, ConflictResolutionStrategy.THREE_WAY_MERGE);
    expect(result.resolved.updatedAt).assertEqual(200);
  }));

  return suite;
}