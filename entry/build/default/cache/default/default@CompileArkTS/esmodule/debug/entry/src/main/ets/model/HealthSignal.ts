// 健康信号数据模型
export enum StepLevel {
    LOW = "\u4F4E",
    NORMAL = "\u6B63\u5E38",
    HIGH = "\u9AD8"
}
export enum SleepStatus {
    GOOD = "\u597D",
    FAIR = "\u4E00\u822C",
    POOR = "\u5DEE"
}
export enum WeightTrend {
    UP = "\u4E0A\u5347",
    STABLE = "\u7A33\u5B9A",
    DOWN = "\u4E0B\u964D"
}
export enum BpStatus {
    NORMAL = "\u6B63\u5E38",
    ELEVATED = "\u504F\u9AD8",
    HIGH = "\u9AD8",
    VERY_HIGH = "\u6781\u9AD8"
}
export enum BsStatus {
    NORMAL = "\u6B63\u5E38",
    ELEVATED = "\u504F\u9AD8",
    HIGH = "\u9AD8",
    VERY_HIGH = "\u6781\u9AD8"
}
export enum DataSource {
    MANUAL = "\u624B\u52A8",
    HUAWEI_HEALTH = "\u534E\u4E3A\u5065\u5EB7"
}
// HealthSignal JSON 输出类
export class HealthSignalJson {
    memberId: Object = '';
    date: Object = '';
    stepLevel: Object = StepLevel.NORMAL;
    sleepStatus: Object = SleepStatus.GOOD;
    weightTrend: Object = WeightTrend.STABLE;
    activityCaloriesLevel: Object = StepLevel.NORMAL;
    manualBpStatus: Object = BpStatus.NORMAL;
    manualBsStatus: Object = BsStatus.NORMAL;
    hadHighSodiumToday: Object = false;
    hadHighSugarToday: Object = false;
    source: Object = DataSource.MANUAL;
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
        return signal;
    }
}
