// 健康信号数据模型

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

  toJson(): Record<string, Object> {
    return {
      memberId: this.memberId,
      date: this.date,
      stepLevel: this.stepLevel,
      sleepStatus: this.sleepStatus,
      weightTrend: this.weightTrend,
      activityCaloriesLevel: this.activityCaloriesLevel,
      manualBpStatus: this.manualBpStatus,
      manualBsStatus: this.manualBsStatus,
      hadHighSodiumToday: this.hadHighSodiumToday,
      hadHighSugarToday: this.hadHighSugarToday,
      source: this.source
    };
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
    return signal;
  }
}
