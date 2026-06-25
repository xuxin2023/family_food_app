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

export interface CrdtResult<T extends ConflictRecord> {
  resolved: T;
  hadConflict: boolean;
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
  ): CrdtResult<T> {
    if (!base || strategy === ConflictResolutionStrategy.LAST_WRITE_WINS) {
      const result: CrdtResult<T> = {
        resolved: CrdtSyncResolver.lastWriterWins(local, remote),
        hadConflict: local.updatedAt !== remote.updatedAt,
      };
      return result;
    }

    const localChanged: boolean = local.updatedAt !== base.updatedAt;
    const remoteChanged: boolean = remote.updatedAt !== base.updatedAt;

    if (localChanged && !remoteChanged) {
      const result: CrdtResult<T> = { resolved: local, hadConflict: false };
      return result;
    }
    if (!localChanged && remoteChanged) {
      const result: CrdtResult<T> = { resolved: remote, hadConflict: false };
      return result;
    }
    if (!localChanged && !remoteChanged) {
      const result: CrdtResult<T> = { resolved: local, hadConflict: false };
      return result;
    }

    const result: CrdtResult<T> = {
      resolved: CrdtSyncResolver.fieldLevelMerge(local, remote, base),
      hadConflict: true,
    };
    return result;
  }

  private static lastWriterWins<T extends ConflictRecord>(local: T, remote: T): T {
    return local.updatedAt >= remote.updatedAt ? local : remote;
  }

  private static fieldLevelMerge<T extends ConflictRecord>(local: T, remote: T, base: T): T {
    const merged: Record<string, Object> = {};
    const localObj: Record<string, Object> = local as Object as Record<string, Object>;
    const remoteObj: Record<string, Object> = remote as Object as Record<string, Object>;
    const baseObj: Record<string, Object> = base as Object as Record<string, Object>;

    const keys: string[] = Object.keys(localObj);
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      merged[key] = localObj[key];
    }

    const skipSet: string[] = ['_vectorClock', 'updatedAt', 'createdAt'];

    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      let skip: boolean = false;
      for (let j = 0; j < skipSet.length; j++) {
        if (key === skipSet[j]) {
          skip = true;
          break;
        }
      }
      if (skip) continue;
      if (localObj[key] !== remoteObj[key]) {
        if (remoteObj[key] !== baseObj[key]) {
          merged[key] = remoteObj[key];
        }
      }
    }

    merged['_vectorClock'] = CrdtSyncResolver.mergeVectorClocks(
      local._vectorClock, remote._vectorClock
    ) as Object;
    merged['updatedAt'] = Math.max(local.updatedAt, remote.updatedAt);

    return merged as Object as T;
  }

  static mergeVectorClocks(a: VectorClock[], b: VectorClock[]): VectorClock[] {
    const map: Map<string, number> = new Map<string, number>();
    for (let i = 0; i < a.length; i++) {
      const vc: VectorClock = a[i];
      map.set(vc.nodeId, vc.counter);
    }
    for (let i = 0; i < b.length; i++) {
      const vc: VectorClock = b[i];
      const existing: number = map.get(vc.nodeId) ?? 0;
      map.set(vc.nodeId, Math.max(vc.counter, existing));
    }
    const entries: Array<[string, number]> = Array.from(map.entries());
    const result: VectorClock[] = [];
    for (let i = 0; i < entries.length; i++) {
      const entry: [string, number] = entries[i];
      const vc: VectorClock = { nodeId: entry[0], counter: entry[1] };
      result.push(vc);
    }
    return result;
  }

  static incrementClock(clocks: VectorClock[], nodeId: string): VectorClock[] {
    const updated: VectorClock[] = [];
    for (let i = 0; i < clocks.length; i++) {
      const c: VectorClock = clocks[i];
      if (c.nodeId !== nodeId) {
        updated.push(c);
      }
    }
    let existing: VectorClock | null = null;
    for (let i = 0; i < clocks.length; i++) {
      if (clocks[i].nodeId === nodeId) {
        existing = clocks[i];
        break;
      }
    }
    const newCounter: number = (existing?.counter ?? 0) + 1;
    const newClock: VectorClock = { nodeId: nodeId, counter: newCounter };
    updated.push(newClock);
    return updated;
  }
}
