// hsp-core: 分布式同步增强 — 基于向量时钟的 CRDT 冲突解决
// 替代原有 Last-Write-Wins 策略，实现三路合并

export interface VectorClock {
  nodeId: string;
  counter: number;
}

export interface ConflictRecord {
  _vectorClock: VectorClock[];
  updatedAt: number;
}

export enum ConflictResolutionStrategy {
  LAST_WRITE_WINS = 'lww',
  THREE_WAY_MERGE = 'three_way',
  FIELD_LEVEL_MERGE = 'field_level',
}

export class CrdtSyncResolver {
  static resolve<T extends ConflictRecord>(
    local: T,
    remote: T,
    base: T | null,
    strategy: ConflictResolutionStrategy = ConflictResolutionStrategy.FIELD_LEVEL_MERGE
  ): { resolved: T; hadConflict: boolean } {
    if (!base || strategy === ConflictResolutionStrategy.LAST_WRITE_WINS) {
      return {
        resolved: CrdtSyncResolver.lastWriterWins(local, remote),
        hadConflict: local.updatedAt !== remote.updatedAt,
      };
    }

    const localChanged = local.updatedAt !== base.updatedAt;
    const remoteChanged = remote.updatedAt !== base.updatedAt;

    if (localChanged && !remoteChanged) return { resolved: local, hadConflict: false };
    if (!localChanged && remoteChanged) return { resolved: remote, hadConflict: false };
    if (!localChanged && !remoteChanged) return { resolved: local, hadConflict: false };

    return {
      resolved: CrdtSyncResolver.fieldLevelMerge(local, remote, base),
      hadConflict: true,
    };
  }

  private static lastWriterWins<T extends ConflictRecord>(local: T, remote: T): T {
    return local.updatedAt >= remote.updatedAt ? local : remote;
  }

  private static fieldLevelMerge<T extends ConflictRecord>(local: T, remote: T, base: T): T {
    const merged = Object.assign({},local) as Record<string, Object>;
    const localObj = local as Object as Record<string, Object>;
    const remoteObj = remote as Object as Record<string, Object>;
    const baseObj = base as Object as Record<string, Object>;
    const skipKeys = new Set(['_vectorClock', 'updatedAt', 'createdAt']);

    for (const key of Object.keys(localObj)) {
      if (skipKeys.has(key)) continue;
      if (localObj[key] !== remoteObj[key]) {
        if (remoteObj[key] !== baseObj[key]) {
          merged[key] = remoteObj[key];
        }
      }
    }

    merged._vectorClock = CrdtSyncResolver.mergeVectorClocks(
      local._vectorClock, remote._vectorClock
    );
    merged.updatedAt = Math.max(local.updatedAt, remote.updatedAt);

    return merged as T;
  }

  static mergeVectorClocks(a: VectorClock[], b: VectorClock[]): VectorClock[] {
    const map = new Map<string, number>();
    for (const vc of a) map.set(vc.nodeId, vc.counter);
    for (const vc of b) {
      map.set(vc.nodeId, Math.max(vc.counter, map.get(vc.nodeId) ?? 0));
    }
    return Array.from(map.entries()).map(([nodeId, counter]) => ({ nodeId, counter }));
  }

  static incrementClock(clocks: VectorClock[], nodeId: string): VectorClock[] {
    const updated = clocks.filter(c => c.nodeId !== nodeId);
    const existing = clocks.find(c => c.nodeId === nodeId);
    updated.push({ nodeId, counter: (existing?.counter ?? 0) + 1 });
    return updated;
  }
}