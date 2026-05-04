// 健康信号数据模型 — V2.0 扩展穿戴设备数据
//
// V2新增：心率、血氧饱和度、压力等级、精确步数、心率区间、体温

export enum StepLevel {
  LOW = '低',
  NORMAL = '正常',
  HIGH = '高'
}

export enum SleepStatus {
  GOOD = '好',
  FAIR = '一般',
  POOR = '差'
}

export enum WeightTrend {
  UP = '上升',
  STABLE = '稳定',
  DOWN = '下降'
}

export enum BpStatus {
  NORMAL = '正常',
  ELEVATED = '偏高',
  HIGH = '高',
  VERY_HIGH = '极高'
}

export enum BsStatus {
  NORMAL = '正常',
  ELEVATED = '偏高',
  HIGH = '高',
  VERY_HIGH = '极高'
}

export enum DataSource {
  MANUAL = '手动',
  HUAWEI_HEALTH = '华为健康'
}

// ===== V2新增枚举 =====

/** 心率区间 */
export enum HeartRateZone {
  REST = '静息',       // < 60
  FAT_BURN = '燃脂',    // 60-100
  AEROBIC = '有氧',     // 100-140
  ANAEROBIC = '无氧',   // 140-170
  MAXIMUM = '极限'      // > 170
}

/** 压力等级 */
export enum StressLevel {
  RELAXED = '放松',
  NORMAL = '正常',
  MEDIUM = '偏高',
  HIGH = '高'
}

/** 血氧饱和度等级 */
export enum SpO2Level {
  NORMAL = '正常',      // >= 95%
  SLIGHT_LOW = '偏低',  // 90-94%
  LOW = '低'            // < 90%
}

// HealthSignal JSON 输出类
export class HealthSignalJson {
  memberId: string = '';
  date: string = '';
  stepLevel: string = StepLevel.NORMAL;
  sleepStatus: string = SleepStatus.GOOD;
  weightTrend: string = WeightTrend.STABLE;
  activityCaloriesLevel: string = StepLevel.NORMAL;
  manualBpStatus: string = BpStatus.NORMAL;
  manualBsStatus: string = BsStatus.NORMAL;
  hadHighSodiumToday: boolean = false;
  hadHighSugarToday: boolean = false;
  source: string = DataSource.MANUAL;
  // V2扩展字段
  stepCount: number = 0;
  heartRate: number = 0;
  heartRateZone: string = HeartRateZone.REST;
  spo2: number = 0;
  spo2Level: string = SpO2Level.NORMAL;
  stressLevel: string = StressLevel.NORMAL;
  bodyTemperature: number = 0;
  deepSleepMinutes: number = 0;
  lightSleepMinutes: number = 0;
  totalSleepMinutes: number = 0;
  restingHeartRate: number = 0;
}

export class HealthSignal {
  memberId: string = '';
  date: string = '';
  stepLevel: StepLevel = StepLevel.NORMAL;
  sleepStatus: SleepStatus = SleepStatus.GOOD;
  weightTrend: WeightTrend = WeightTrend.STABLE;
  activityCaloriesLevel: StepLevel = StepLevel.NORMAL;
  manualBpStatus: BpStatus = BpStatus.NORMAL;
  manualBsStatus: BsStatus = BsStatus.NORMAL;
  hadHighSodiumToday: boolean = false;
  hadHighSugarToday: boolean = false;
  source: DataSource = DataSource.MANUAL;

  // ===== V2 穿戴设备扩展字段 =====
  /** 精确步数（穿戴设备采集） */
  stepCount: number = 0;
  /** 当前心率（bpm） */
  heartRate: number = 0;
  /** 心率区间 */
  heartRateZone: HeartRateZone = HeartRateZone.REST;
  /** 血氧饱和度（百分比） */
  spo2: number = 0;
  /** 血氧等级 */
  spo2Level: SpO2Level = SpO2Level.NORMAL;
  /** 压力等级 */
  stressLevel: StressLevel = StressLevel.NORMAL;
  /** 体温（摄氏度） */
  bodyTemperature: number = 0;
  /** 深睡时长（分钟） */
  deepSleepMinutes: number = 0;
  /** 浅睡时长（分钟） */
  lightSleepMinutes: number = 0;
  /** 总睡眠时长（分钟） */
  totalSleepMinutes: number = 0;
  /** 静息心率（bpm） */
  restingHeartRate: number = 0;

  isLowActivity(): boolean {
    return this.stepLevel === StepLevel.LOW || this.activityCaloriesLevel === StepLevel.LOW;
  }

  isHighActivity(): boolean {
    return this.stepLevel === StepLevel.HIGH || this.activityCaloriesLevel === StepLevel.HIGH;
  }

  isPoorSleep(): boolean {
    return this.sleepStatus === SleepStatus.POOR;
  }

  isWeightUp(): boolean {
    return this.weightTrend === WeightTrend.UP;
  }

  isHighBp(): boolean {
    return this.manualBpStatus === BpStatus.ELEVATED ||
      this.manualBpStatus === BpStatus.HIGH ||
      this.manualBpStatus === BpStatus.VERY_HIGH;
  }

  isHighBs(): boolean {
    return this.manualBsStatus === BsStatus.ELEVATED ||
      this.manualBsStatus === BsStatus.HIGH ||
      this.manualBsStatus === BsStatus.VERY_HIGH;
  }

  isHighSodiumToday(): boolean {
    return this.hadHighSodiumToday;
  }

  isHighSugarToday(): boolean {
    return this.hadHighSugarToday;
  }

  // ===== V2 新增辅助方法 =====

  /** 步数是否达到推荐日行8000步 */
  isStepGoalMet(): boolean {
    return this.stepCount >= 8000;
  }

  /** 血氧是否正常（>= 95%） */
  isSpO2Normal(): boolean {
    return this.spo2 >= 95 || this.spo2Level === SpO2Level.NORMAL;
  }

  /** 是否处于压力状态 */
  isStressed(): boolean {
    return this.stressLevel === StressLevel.HIGH || this.stressLevel === StressLevel.MEDIUM;
  }

  /** 心率是否偏高（静息>100或当前>140） */
  isHeartRateHigh(): boolean {
    return this.restingHeartRate > 100 || this.heartRate > 140;
  }

  /** 是否在燃脂或有氧区间（运动适度） */
  isInExerciseZone(): boolean {
    return this.heartRateZone === HeartRateZone.FAT_BURN ||
      this.heartRateZone === HeartRateZone.AEROBIC;
  }

  /** 获取心率区间描述 */
  getHeartRateZoneText(): string {
    return this.heartRateZone;
  }

  /** 获取适配用睡眠质量因子（0.7~1.0） */
  getSleepQualityFactor(): number {
    if (this.sleepStatus === SleepStatus.GOOD) {
      return 1.0;
    }
    if (this.sleepStatus === SleepStatus.FAIR) {
      return 0.9;
    }
    // 睡眠差，再根据深睡比例细调
    if (this.totalSleepMinutes > 0 && this.deepSleepMinutes > 0) {
      const deepSleepRatio = this.deepSleepMinutes / this.totalSleepMinutes;
      if (deepSleepRatio >= 0.25) {
        return 0.85; // 虽然总睡眠质量差但深睡还行
      }
      return 0.7; // 深睡严重不足
    }
    return 0.8;
  }

  /** 获取步数对应的活动因子（0.7~1.15） */
  getStepActivityFactor(): number {
    if (this.stepCount >= 10000) {
      return 1.15; // 非常活跃，放宽10%
    }
    if (this.stepCount >= 8000) {
      return 1.05; // 达标
    }
    if (this.stepCount >= 5000) {
      return 1.0; // 正常
    }
    if (this.stepCount >= 3000) {
      return 0.9; // 偏低
    }
    if (this.stepCount >= 1000) {
      return 0.8; // 低
    }
    return 0.7; // 久坐
  }

  toJson(): HealthSignalJson {
    const json = new HealthSignalJson();
    json.memberId = this.memberId;
    json.date = this.date;
    json.stepLevel = this.stepLevel;
    json.sleepStatus = this.sleepStatus;
    json.weightTrend = this.weightTrend;
    json.activityCaloriesLevel = this.activityCaloriesLevel;
    json.manualBpStatus = this.manualBpStatus;
    json.manualBsStatus = this.manualBsStatus;
    json.hadHighSodiumToday = this.hadHighSodiumToday;
    json.hadHighSugarToday = this.hadHighSugarToday;
    json.source = this.source;
    // V2
    json.stepCount = this.stepCount;
    json.heartRate = this.heartRate;
    json.heartRateZone = this.heartRateZone;
    json.spo2 = this.spo2;
    json.spo2Level = this.spo2Level;
    json.stressLevel = this.stressLevel;
    json.bodyTemperature = this.bodyTemperature;
    json.deepSleepMinutes = this.deepSleepMinutes;
    json.lightSleepMinutes = this.lightSleepMinutes;
    json.totalSleepMinutes = this.totalSleepMinutes;
    json.restingHeartRate = this.restingHeartRate;
    return json;
  }

  static fromJson(json: Record<string, Object>): HealthSignal {
    const signal = new HealthSignal();
    signal.memberId = json.memberId as string;
    signal.date = json.date as string;
    signal.stepLevel = json.stepLevel as StepLevel;
    signal.sleepStatus = json.sleepStatus as SleepStatus;
    signal.weightTrend = json.weightTrend as WeightTrend;
    signal.activityCaloriesLevel = json.activityCaloriesLevel as StepLevel;
    signal.manualBpStatus = json.manualBpStatus as BpStatus;
    signal.manualBsStatus = json.manualBsStatus as BsStatus;
    signal.hadHighSodiumToday = Boolean(json.hadHighSodiumToday);
    signal.hadHighSugarToday = Boolean(json.hadHighSugarToday);
    signal.source = json.source as DataSource;
    // V2
    signal.stepCount = Number(json.stepCount || 0);
    signal.heartRate = Number(json.heartRate || 0);
    signal.heartRateZone = (json.heartRateZone as HeartRateZone) || HeartRateZone.REST;
    signal.spo2 = Number(json.spo2 || 0);
    signal.spo2Level = (json.spo2Level as SpO2Level) || SpO2Level.NORMAL;
    signal.stressLevel = (json.stressLevel as StressLevel) || StressLevel.NORMAL;
    signal.bodyTemperature = Number(json.bodyTemperature || 0);
    signal.deepSleepMinutes = Number(json.deepSleepMinutes || 0);
    signal.lightSleepMinutes = Number(json.lightSleepMinutes || 0);
    signal.totalSleepMinutes = Number(json.totalSleepMinutes || 0);
    signal.restingHeartRate = Number(json.restingHeartRate || 0);
    return signal;
  }
}
