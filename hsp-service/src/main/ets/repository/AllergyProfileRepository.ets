// repository/AllergyProfileRepository.ets
// 过敏原档案数据仓库 — 对标Yuka/Olive过敏原预警功能

import { relationalStore } from '@kit.ArkData';
import { HILOG_DOMAIN_DEFAULT, AllergyProfile, AllergyItem, IntoleranceItem, Severity, createDefaultAllergyProfile } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CryptoEngine } from 'hsp_core';

const TAG = 'AllergyProfileRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TABLE_NAME = 'allergy_profiles';

export class AllergyProfileRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private profiles: Map<string, AllergyProfile> = new Map();
  private crypto: CryptoEngine | null = null;

  async init(rdbStore: relationalStore.RdbStore): Promise<void> {
    this.rdbStore = rdbStore;
    try {
      this.crypto = CryptoEngine.getInstance();
      await this.crypto.init();
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Crypto init failed, storing without encryption');
    }
    try {
      await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
        member_id TEXT PRIMARY KEY,
        allergies_json TEXT NOT NULL DEFAULT '[]',
        intolerances_json TEXT NOT NULL DEFAULT '[]',
        cross_contamination_sensitive INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )`);
      await this.loadFromDb();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'init failed: %{public}s', JSON.stringify(e));
    }
  }

  private async loadFromDb(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      const resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        const profile = new AllergyProfile();
        profile.memberId = resultSet.getString(0);

        const allergiesRaw = resultSet.getString(1);
        if (allergiesRaw && allergiesRaw.length > 0) {
          profile.allergies = JSON.parse(allergiesRaw) as AllergyItem[];
        }

        const intolerancesRaw = resultSet.getString(2);
        if (intolerancesRaw && intolerancesRaw.length > 0) {
          profile.intolerances = JSON.parse(intolerancesRaw) as IntoleranceItem[];
        }

        profile.crossContaminationSensitive = resultSet.getLong(3) === 1;
        profile.updatedAt = resultSet.getLong(4);
        this.profiles.set(profile.memberId, profile);
      }
      resultSet.close();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadFromDb failed: %{public}s', JSON.stringify(e));
    }
  }

  async getByMemberId(memberId: string): Promise<AllergyProfile> {
    let p = this.profiles.get(memberId);
    if (!p) {
      p = createDefaultAllergyProfile(memberId);
      this.profiles.set(memberId, p);
    }
    return p;
  }

  async save(profile: AllergyProfile): Promise<void> {
    this.profiles.set(profile.memberId, profile);
    if (this.rdbStore) {
      try {
        let allergiesJson = JSON.stringify(profile.allergies);
        let intolerancesJson = JSON.stringify(profile.intolerances);
        if (this.crypto) {
          allergiesJson = await this.crypto.encrypt(allergiesJson);
          intolerancesJson = await this.crypto.encrypt(intolerancesJson);
        }
        const valueBucket: relationalStore.ValuesBucket = {
          'member_id': profile.memberId,
          'allergies_json': allergiesJson,
          'intolerances_json': intolerancesJson,
          'cross_contamination_sensitive': profile.crossContaminationSensitive ? 1 : 0,
          'updated_at': Date.now()
        };
        const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo('member_id', profile.memberId);
        const existing = await this.rdbStore.query(predicates);
        if (existing.rowCount > 0) {
          await this.rdbStore.update(valueBucket, predicates);
        } else {
          await this.rdbStore.insert(TABLE_NAME, valueBucket);
        }
        existing.close();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'save db failed: %{public}s', JSON.stringify(e));
      }
    }
  }

  async getAll(): Promise<AllergyProfile[]> {
    return Array.from(this.profiles.values());
  }
}