import type { HealthSignal } from '../model/HealthSignal';
import { ManualHealthSignalProvider } from "@bundle:com.familyfood.helper/entry/ets/service/health/ManualHealthSignalProvider";
import type { HealthSignalProvider } from './health/HealthSignalProvider';
export class HealthService {
    private provider: HealthSignalProvider;
    constructor(provider: HealthSignalProvider = new ManualHealthSignalProvider()) {
        this.provider = provider;
    }
    setProvider(provider: HealthSignalProvider): void {
        this.provider = provider;
    }
    async checkAuthorization(): Promise<boolean> {
        return await this.provider.checkAuthorization();
    }
    async requestAuthorization(): Promise<boolean> {
        return await this.provider.requestAuthorization();
    }
    async getTodayHealthData(memberId: string): Promise<HealthSignal> {
        return await this.provider.getTodayHealthData(memberId);
    }
}
