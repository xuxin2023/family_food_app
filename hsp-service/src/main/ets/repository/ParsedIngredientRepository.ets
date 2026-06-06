// repository/ParsedIngredientRepository.ets
// 成分解析数据仓库 — 对标Yuka成分有害性解析功能

import { relationalStore } from '@kit.ArkData';
import { HILOG_DOMAIN_DEFAULT, ParsedIngredientList, ParsedIngredient, HazardLevel } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ParsedIngredientRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_PARSE_RESULT = 'parsed_ingredient_results';
const TABLE_ADDITIVE_DB = 'additive_hazard_db';

export class ParsedIngredientRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private resultCache: Map<string, ParsedIngredientList> = new Map();
  private additiveDbCache: Map<string, string> = new Map();

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_PARSE_RESULT} (`
        product_barcode TEXT PRIMARY KEY,
        product_name TEXT DEFAULT '',
        ingredients_json TEXT NOT NULL DEFAULT '[]',
        high_risk_count INTEGER DEFAULT 0,
        moderate_risk_count INTEGER DEFAULT 0,
        summary TEXT DEFAULT '',
        additive_interactions TEXT DEFAULT '[]',
        parsed_at INTEGER NOT NULL
      )`);`
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_ADDITIVE_DB} (`
        e_number TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        hazard_level TEXT DEFAULT 'low_risk',
        category TEXT DEFAULT '',
        description TEXT DEFAULT '',
        long_term_effect TEXT DEFAULT '',
        co_warning TEXT DEFAULT '',
        regulation_status TEXT DEFAULT ''
      )`);`
      await this.loadFromDb();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadFromDb(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_PARSE_RESULT);
      const resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        const result: ParsedIngredientList = new ParsedIngredientList()
        result.productBarcode = resultSet.getString(0);
        result.productName = resultSet.getString(1);
        const raw = resultSet.getString(2);
        if (raw && raw.length > 0) {
          result.ingredients = JSON.parse(raw) as ParsedIngredient[];
        }
        result.highRiskCount = resultSet.getLong(3);
        result.moderateRiskCount = resultSet.getLong(4);
        result.summary = resultSet.getString(5);
        const interactions = resultSet.getString(6);
        if (interactions && interactions.length > 0) {
          result.additiveInteractions = JSON.parse(interactions) as string[];
        }
        result.parsedAt = resultSet.getLong(7);
        this.resultCache.set(result.productBarcode, result);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadResults failed: %{public}s', JSON.stringify(e));
    }
    try {
      const pred2 = new relationalStore.RdbPredicates(TABLE_ADDITIVE_DB);
      const rs2 = await this.rdbStore.query(pred2);
      while (rs2.goToNextRow()) {
        const eNum = rs2.getString(0);
        const info = JSON.stringify({
          name: rs2.getString(1),
          hazardLevel: rs2.getString(2),
          category: rs2.getString(3),
          description: rs2.getString(4),
          longTermEffect: rs2.getString(5),
          coWarning: rs2.getString(6),
          regulationStatus: rs2.getString(7)
        });
        this.additiveDbCache.set(eNum, info);
      }
      rs2.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadAdditiveDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async getByBarcode(barcode: string): Promise<ParsedIngredientList | null> {
    return this.resultCache.get(barcode) ?? null;
  }

  async save(result: ParsedIngredientList): Promise<void> {
    this.resultCache.set(result.productBarcode, result);
    if (this.rdbStore) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          'product_barcode': result.productBarcode,
          'product_name': result.productName,
          'ingredients_json': JSON.stringify(result.ingredients),
          'high_risk_count': result.highRiskCount,
          'moderate_risk_count': result.moderateRiskCount,
          'summary': result.summary,
          'additive_interactions': JSON.stringify(result.additiveInteractions),
          'parsed_at': Date.now()
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_PARSE_RESULT);
        predicates.equalTo('product_barcode', result.productBarcode);
        const existing = await this.rdbStore.query(predicates);
        if (existing.rowCount > 0) {
          await this.rdbStore.update(valueBucket, predicates);
        } else {
          await this.rdbStore.insert(TABLE_PARSE_RESULT, valueBucket);
        }
        existing.close();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'save failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async seedAdditiveDatabase(entries: { eNumber: string; name: string; hazardLevel: HazardLevel;
    category: string; description: string; longTermEffect: string; coWarning: string;
    regulationStatus: string }[]): Promise<void> {
    if (!this.rdbStore) return;
    for (const entry of entries) {
      const valueBucket: relationalStore.ValuesBucket = {
        'e_number': entry.eNumber,
        'name': entry.name,
        'hazard_level': entry.hazardLevel,
        'category': entry.category,
        'description': entry.description,
        'long_term_effect': entry.longTermEffect,
        'co_warning': entry.coWarning,
        'regulation_status': entry.regulationStatus
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_ADDITIVE_DB);
      predicates.equalTo('e_number', entry.eNumber);
      const existing = await this.rdbStore.query(predicates);
      if (existing.rowCount > 0) {
        await this.rdbStore.update(valueBucket, predicates);
      } else {
        await this.rdbStore.insert(TABLE_ADDITIVE_DB, valueBucket);
      }
      existing.close();
      this.additiveDbCache.set(entry.eNumber, JSON.stringify(entry));
    }
  }

  async lookupAdditive(eNumber: string): Promise<string | null> {
    return this.additiveDbCache.get(eNumber) ?? null;
  }
}