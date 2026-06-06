// 可信度结果数据模型 - V4升级为雷达模型

// 数据等级枚举（A-E五级）
export enum DataGrade {
  A = 'A',  // 官方监管数据、许可、抽检系统
  B = 'B',  // 品牌上传并经平台核验
  C = 'C',  // 有资质第三方检测报告
  D = 'D',  // 用户上传包装照片
  E = 'E'   // 电商评论和舆情
}

// 雷达维度
export class RadarDimension {
  name: string = '';           // 维度名称
  status: string = '';         // 清晰/部分清晰/未识别
  grade: DataGrade = DataGrade.D;       // 数据等级
  detail: string = '';         // 详细说明
}

// 公开查询入口
export class PublicQueryEntry {
  name: string = '';        // 查询系统名称
  keyword: string = '';     // 查询关键词（可复制）
  url: string = '';         // 查询URL（可选）
  description: string = ''; // 使用说明
}

// CredibilityResult JSON 输出类
export class CredibilityResultJson {
  score: number = 0;
  manufacturerClear: boolean = false;
  scNumberClear: boolean = false;
  oemRelationClear: boolean = false;
  hasTraceCode: boolean = false;
  manufacturerMissing: boolean = false;
  oemTrusteeMissing: boolean = false;
  tips: string[] = [];
  radarDimensions: RadarDimension[] = [];
  overallGrade: string = DataGrade.D;
  publicQueryEntries: PublicQueryEntry[] = [];
}

export class CredibilityResult {
  score: number = 0;                     // 可信度评分 0-100
  manufacturerClear: boolean = false;    // 生产商清晰
  scNumberClear: boolean = false;        // SC编号清晰
  oemRelationClear: boolean = false;     // 委托受托关系清楚
  hasTraceCode: boolean = false;         // 有追溯码
  manufacturerMissing: boolean = false;  // 生产主体缺失
  oemTrusteeMissing: boolean = false;    // 委托生产但受托方不清楚
  tips: string[] = [];                   // 提示信息列表

  // V4新增：雷达维度
  radarDimensions: RadarDimension[] = [];

  // V4新增：数据等级
  overallGrade: DataGrade = DataGrade.D;  // 默认用户上传

  // V4新增：公开查询入口
  publicQueryEntries: PublicQueryEntry[] = [];

  // 获取可信度等级描述
  getLevelDesc(): string {
    if (this.score >= 80) return '身份信息较完整';
    if (this.score >= 60) return '身份信息基本完整';
    if (this.score >= 40) return '部分身份信息缺失';
    return '身份信息不完整，建议谨慎';
  }

  // 获取数据等级描述
  getGradeDesc(): string {
    switch (this.overallGrade) {
      case DataGrade.A: return '官方监管数据';
      case DataGrade.B: return '品牌核验数据';
      case DataGrade.C: return '第三方检测数据';
      case DataGrade.D: return '用户上传数据';
      case DataGrade.E: return '公开舆情线索';
      default: return '数据来源待确认';
    }
  }

  toJson(): CredibilityResultJson {
    const json: CredibilityResultJson = new CredibilityResultJson(
    json.score = this.score;
    json.manufacturerClear = this.manufacturerClear;
    json.scNumberClear = this.scNumberClear;
    json.oemRelationClear = this.oemRelationClear;
    json.hasTraceCode = this.hasTraceCode;
    json.manufacturerMissing = this.manufacturerMissing;
    json.oemTrusteeMissing = this.oemTrusteeMissing;
    json.tips = this.tips;
    json.radarDimensions = this.radarDimensions;
    json.overallGrade = this.overallGrade;
    json.publicQueryEntries = this.publicQueryEntries;
    return json;
  }

  static getDefault(): CredibilityResult {
    const cr: CredibilityResult = new CredibilityResult(
    cr.score = 0;
    cr.tips = ['可信度数据不足'];
    cr.overallGrade = DataGrade.D;
    return cr;
  }
}
