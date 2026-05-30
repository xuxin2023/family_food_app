export class LineageRecord {
  foodId: string = '';
  source: string = '';
  confidence: number = 0;
  transformChain: string[] = [];
  capturedAt: number = 0;
}

export class DataLineage {
  private static records: Map<string, LineageRecord> = new Map();

  static record(lineage: LineageRecord): void {
    if (lineage.foodId.length === 0) return;
    DataLineage.records.set(lineage.foodId, lineage);
  }

  static getLineage(foodId: string): LineageRecord | undefined {
    return DataLineage.records.get(foodId);
  }

  static hasLineage(foodId: string): boolean {
    return DataLineage.records.has(foodId);
  }

  static clear(): void {
    DataLineage.records.clear();
  }
}
