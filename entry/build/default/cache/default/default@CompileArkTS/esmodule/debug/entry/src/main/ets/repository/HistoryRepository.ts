import relationalStore from "@ohos:data.relationalStore";
import hilog from "@ohos:hilog";
const TAG = 'HistoryRepository';
const DOMAIN_ZERO = 0;
export class ScanHistoryRecord {
    id: number = 0;
    memberId: string = '';
    foodId: string = '';
    foodName: string = '';
    level: string = '';
    maxAmount: number = 0;
    reasons: string[] = [];
    scannedAt: number = 0;
}
export class DietRecord {
    id: number = 0;
    memberId: string = '';
    date: string = '';
    scenario: string = '';
    foodId: string = '';
    amountG: number = 0;
    sodiumIntake: number = 0;
    sugarIntake: number = 0;
    calorieIntake: number = 0;
    fatIntake: number = 0;
    recordedAt: number = 0;
}
// 用于保存扫描历史的输入数据（不含id）
export class ScanHistoryInput {
    memberId: string = '';
    foodId: string = '';
    foodName: string = '';
    level: string = '';
    maxAmount: number = 0;
    reasons: string[] = [];
    scannedAt: number = 0;
}
// 用于保存饮食记录的输入数据（不含id）
export class DietRecordInput {
    memberId: string = '';
    date: string = '';
    scenario: string = '';
    foodId: string = '';
    amountG: number = 0;
    sodiumIntake: number = 0;
    sugarIntake: number = 0;
    calorieIntake: number = 0;
    fatIntake: number = 0;
    recordedAt: number = 0;
}
// 风险统计结果
export class RiskDaysResult {
    highSodiumDays: number = 0;
    highSugarDays: number = 0;
    highFatDays: number = 0;
    totalRecords: number = 0;
}
export class HistoryRepository {
    private rdbStore: relationalStore.RdbStore | null = null;
    async init(rdbStore: relationalStore.RdbStore): Promise<void> {
        this.rdbStore = rdbStore;
        try {
            // 扫描历史表
            await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id TEXT NOT NULL,
        food_id TEXT NOT NULL,
        food_name TEXT NOT NULL,
        level TEXT NOT NULL,
        max_amount REAL NOT NULL,
        reasons TEXT NOT NULL,
        scanned_at INTEGER NOT NULL
      )`);
            // 饮食记录表
            await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS diet_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id TEXT NOT NULL,
        date TEXT NOT NULL,
        scenario TEXT,
        food_id TEXT,
        amount_g REAL,
        sodium_intake REAL,
        sugar_intake REAL,
        calorie_intake REAL,
        fat_intake REAL,
        recorded_at INTEGER NOT NULL
      )`);
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Init tables failed: %{public}s', JSON.stringify(error));
        }
    }
    /**
     * 保存扫描历史
     */
    async saveScanHistory(record: ScanHistoryInput): Promise<void> {
        if (!this.rdbStore)
            return;
        const valueBucket: relationalStore.ValuesBucket = {
            member_id: record.memberId,
            food_id: record.foodId,
            food_name: record.foodName,
            level: record.level,
            max_amount: record.maxAmount,
            reasons: JSON.stringify(record.reasons),
            scanned_at: record.scannedAt
        };
        try {
            await this.rdbStore.insert('scan_history', valueBucket);
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Save scan history failed: %{public}s', JSON.stringify(error));
        }
    }
    /**
     * 保存饮食记录
     */
    async saveDietRecord(record: DietRecordInput): Promise<void> {
        if (!this.rdbStore)
            return;
        const valueBucket: relationalStore.ValuesBucket = {
            member_id: record.memberId,
            date: record.date,
            scenario: record.scenario,
            food_id: record.foodId,
            amount_g: record.amountG,
            sodium_intake: record.sodiumIntake,
            sugar_intake: record.sugarIntake,
            calorie_intake: record.calorieIntake,
            fat_intake: record.fatIntake,
            recorded_at: record.recordedAt
        };
        try {
            await this.rdbStore.insert('diet_record', valueBucket);
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Save diet record failed: %{public}s', JSON.stringify(error));
        }
    }
    /**
     * 查询今日饮食记录（用于计算剩余预算）
     */
    async getTodayDietRecords(memberId: string): Promise<DietRecord[]> {
        if (!this.rdbStore)
            return [];
        const today = this.getTodayDate();
        try {
            const predicates = new relationalStore.RdbPredicates('diet_record');
            predicates.equalTo('member_id', memberId).equalTo('date', today);
            const resultSet = await this.rdbStore.query(predicates);
            const records: DietRecord[] = [];
            while (resultSet.goToNextRow()) {
                records.push(this.dietRecordFromResultSet(resultSet));
            }
            resultSet.close();
            return records;
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Query diet records failed: %{public}s', JSON.stringify(error));
            return [];
        }
    }
    /**
     * 查询最近扫描历史（按时间倒序）
     */
    async getRecentScanHistory(limit: number = 50): Promise<ScanHistoryRecord[]> {
        if (!this.rdbStore)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('scan_history');
            predicates.orderByDesc('scanned_at');
            predicates.limitAs(limit);
            const resultSet = await this.rdbStore.query(predicates);
            const records: ScanHistoryRecord[] = [];
            while (resultSet.goToNextRow()) {
                records.push(this.scanRecordFromResultSet(resultSet));
            }
            resultSet.close();
            return records;
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Query scan history failed: %{public}s', JSON.stringify(error));
            return [];
        }
    }
    /**
     * 查询某成员的扫描历史
     */
    async getScanHistoryByMember(memberId: string, limit: number = 20): Promise<ScanHistoryRecord[]> {
        if (!this.rdbStore)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('scan_history');
            predicates.equalTo('member_id', memberId);
            predicates.orderByDesc('scanned_at');
            predicates.limitAs(limit);
            const resultSet = await this.rdbStore.query(predicates);
            const records: ScanHistoryRecord[] = [];
            while (resultSet.goToNextRow()) {
                records.push(this.scanRecordFromResultSet(resultSet));
            }
            resultSet.close();
            return records;
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Query scan history by member failed: %{public}s', JSON.stringify(error));
            return [];
        }
    }
    /**
     * 查询日期范围内的饮食记录（用于周报）
     */
    async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
        if (!this.rdbStore)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('diet_record');
            predicates.equalTo('member_id', memberId);
            predicates.greaterThanOrEqualTo('date', startDate);
            predicates.lessThanOrEqualTo('date', endDate);
            predicates.orderByAsc('date');
            const resultSet = await this.rdbStore.query(predicates);
            const records: DietRecord[] = [];
            while (resultSet.goToNextRow()) {
                records.push(this.dietRecordFromResultSet(resultSet));
            }
            resultSet.close();
            return records;
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Query diet records by range failed: %{public}s', JSON.stringify(error));
            return [];
        }
    }
    /**
     * 统计某成员某日的高盐/高糖/高脂记录数（用于周报）
     */
    async countRiskDays(memberId: string, startDate: string, endDate: string): Promise<RiskDaysResult> {
        const records = await this.getDietRecordsByDateRange(memberId, startDate, endDate);
        const sodiumDays = new Set<string>();
        const sugarDays = new Set<string>();
        const fatDays = new Set<string>();
        for (const r of records) {
            // 高盐：钠摄入>800mg/餐
            if (r.sodiumIntake > 800)
                sodiumDays.add(r.date);
            // 高糖：糖摄入>15g/餐
            if (r.sugarIntake > 15)
                sugarDays.add(r.date);
            // 高脂：脂肪摄入>20g/餐
            if (r.fatIntake > 20)
                fatDays.add(r.date);
        }
        const result = new RiskDaysResult();
        result.highSodiumDays = sodiumDays.size;
        result.highSugarDays = sugarDays.size;
        result.highFatDays = fatDays.size;
        result.totalRecords = records.length;
        return result;
    }
    /**
     * 删除扫描历史（清理旧数据）
     */
    async deleteScanHistoryBefore(timestamp: number): Promise<number> {
        if (!this.rdbStore)
            return 0;
        try {
            const predicates = new relationalStore.RdbPredicates('scan_history');
            predicates.lessThan('scanned_at', timestamp);
            return await this.rdbStore.delete(predicates);
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Delete old scan history failed: %{public}s', JSON.stringify(error));
            return 0;
        }
    }
    // ========== 内部方法 ==========
    private scanRecordFromResultSet(resultSet: relationalStore.ResultSet): ScanHistoryRecord {
        let reasons: string[] = [];
        try {
            reasons = JSON.parse(resultSet.getString(resultSet.getColumnIndex('reasons')) || '[]') as string[];
        }
        catch (e) {
            reasons = [];
        }
        const record = new ScanHistoryRecord();
        record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        record.memberId = resultSet.getString(resultSet.getColumnIndex('member_id'));
        record.foodId = resultSet.getString(resultSet.getColumnIndex('food_id'));
        record.foodName = resultSet.getString(resultSet.getColumnIndex('food_name'));
        record.level = resultSet.getString(resultSet.getColumnIndex('level'));
        record.maxAmount = resultSet.getDouble(resultSet.getColumnIndex('max_amount'));
        record.reasons = reasons;
        record.scannedAt = resultSet.getLong(resultSet.getColumnIndex('scanned_at'));
        return record;
    }
    private dietRecordFromResultSet(resultSet: relationalStore.ResultSet): DietRecord {
        const record = new DietRecord();
        record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        record.memberId = resultSet.getString(resultSet.getColumnIndex('member_id'));
        record.date = resultSet.getString(resultSet.getColumnIndex('date'));
        record.scenario = resultSet.getString(resultSet.getColumnIndex('scenario'));
        record.foodId = resultSet.getString(resultSet.getColumnIndex('food_id'));
        record.amountG = resultSet.getDouble(resultSet.getColumnIndex('amount_g'));
        record.sodiumIntake = resultSet.getDouble(resultSet.getColumnIndex('sodium_intake'));
        record.sugarIntake = resultSet.getDouble(resultSet.getColumnIndex('sugar_intake'));
        record.calorieIntake = resultSet.getDouble(resultSet.getColumnIndex('calorie_intake'));
        record.fatIntake = resultSet.getDouble(resultSet.getColumnIndex('fat_intake'));
        record.recordedAt = resultSet.getLong(resultSet.getColumnIndex('recorded_at'));
        return record;
    }
    private getTodayDate(): string {
        const now = new Date();
        return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    }
}
