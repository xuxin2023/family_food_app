// 历史记录数据仓库 — 从 hsp_service 重导出
// entry 层通过门面调用，本地实现已迁移至 hsp-service 模块
export { HistoryRepository, ScanHistoryRecord, ScanHistoryInput, DietRecordInput, RiskDaysResult } from 'hsp_service';
