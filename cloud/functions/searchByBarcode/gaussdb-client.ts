import { Pool } from 'pg'
import { DBConfig, ProductRecord } from './types'

export class GaussDBClient {
  private pool: Pool
  private ended: boolean = false

  constructor(config: DBConfig) {
    this.pool = new Pool({
      host: config.endpoint,
      user: config.user,
      password: config.password,
      database: config.database,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000
    })
    this.pool.on('error', (err: Error) => {
      console.error('GaussDB pool idle client error:', err.message)
    })
    this.pool.on('connect', () => {
      if (this.pool.totalCount > 8) {
        console.warn(`GaussDB pool approaching limit: ${this.pool.totalCount}/10`)
      }
    })
  }

  async query(sql: string, params?: unknown[]): Promise<{ rows: Record<string, unknown>[] }> {
    if (this.ended) throw new Error('GaussDBClient has been closed')
    const result = await this.pool.query(sql, params)
    return { rows: result.rows as Record<string, unknown>[] }
  }

  async execute(sql: string, params?: unknown[]): Promise<void> {
    if (this.ended) throw new Error('GaussDBClient has been closed')
    await this.pool.query(sql, params)
  }

  async end(): Promise<void> {
    if (this.ended) return
    this.ended = true
    await this.pool.end()
  }

  get poolStatus(): { total: number; idle: number; waiting: number } {
    return {
      total: this.pool.totalCount,
      idle: this.pool.idleCount,
      waiting: this.pool.waitingCount
    }
  }
}

export class QueryBuilder {
  private table: string = ''
  private conditions: string[] = []
  private params: unknown[] = []
  private limitValue: number = 100
  private offsetValue: number = 0

  from(table: string): QueryBuilder {
    this.table = table
    return this
  }

  where(condition: string, param: unknown): QueryBuilder {
    this.conditions.push(condition)
    this.params.push(param)
    return this
  }

  limit(value: number): QueryBuilder {
    this.limitValue = value
    return this
  }

  offset(value: number): QueryBuilder {
    this.offsetValue = value
    return this
  }

  build(): { sql: string; params: unknown[] } {
    let sql = `SELECT * FROM ${this.table}`
    if (this.conditions.length > 0) {
      sql += ` WHERE ${this.conditions.join(' AND ')}`
    }
    sql += ` LIMIT ${this.limitValue} OFFSET ${this.offsetValue}`
    return { sql, params: this.params }
  }
}
