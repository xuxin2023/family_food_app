// ScanService 权威实现已迁移至 feature-scan 模块
// 此文件仅做类型重导出，保持向后兼容
// 迁移原因：feature-scan 使用 interface ILocalCacheProvider（更规范），
//           且 ScanService 属于扫描功能域，应由 feature-scan 模块持有

export { ScanService, ScanLookupResult, ILocalCacheProvider } from 'feature_scan';