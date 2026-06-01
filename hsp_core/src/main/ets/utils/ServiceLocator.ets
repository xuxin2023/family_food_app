export class ServiceLocator {
  private static instances: Map<string, Object> = new Map();

  static register<T>(key: string, instance: T): void {
    ServiceLocator.instances.set(key, instance as Object);
  }

  static get<T>(key: string): T | null {
    return ServiceLocator.instances.get(key) as T ?? null;
  }

  static has(key: string): boolean {
    return ServiceLocator.instances.has(key);
  }

  static clear(): void {
    ServiceLocator.instances.clear();
  }
}