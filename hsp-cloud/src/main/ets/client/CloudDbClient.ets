// hsp-cloud: CloudDB 数据库客户端

export class CloudDbClient {
  async query(tableName: string, conditions: Record<string, Object>): Promise<Object[]> {
    return [];
  }
  async insert(tableName: string, data: Record<string, Object>): Promise<string> {
    return '';
  }
}