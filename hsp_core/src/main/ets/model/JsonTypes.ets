/**
 * JsonTypes.ets
 * ArkTS 兼容的 JSON 值类型定义
 *
 * ArkTS 限制：
 * - 不支持索引签名 [key: string]
 * - 不支持 obj['field'] 索引访问（但 JSON.parse 后的 (as object)?.["field"] 可以）
 * - 不支持 unknown / any
 *
 * 使用方式：
 *   const parsed = JSON.parse(jsonStr) as JsonObject;
 *   const value = (parsed as object)?.["key"];
 *
 * 推荐做法：各模块定义自己的解析函数，使用 JSON.parse + 具体类构造
 */

/**
 * JsonObject 类型 - 表示 JSON 解析后的对象
 * 使用 Record<string, Object> 来替代索引签名
 *
 * 注意：在 ArkTS 中可通过 (obj as object)?.["key"] 方式安全访问字段
 */
export type JsonObject = Record<string, Object>;
