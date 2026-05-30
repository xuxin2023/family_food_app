import { BusinessError } from './BusinessError';

export class NullGuard {
  static safeGet<T>(value: T | null | undefined, defaultValue: T): T {
    return value ?? defaultValue;
  }

  static safeArray<T>(arr: T[] | null | undefined): T[] {
    return arr ?? [];
  }

  static safeNumber(value: number | null | undefined, defaultValue: number = 0): number {
    return value ?? defaultValue;
  }

  static safeString(value: string | null | undefined, defaultValue: string = ''): string {
    return value ?? defaultValue;
  }

  static safeBoolean(value: boolean | null | undefined, defaultValue: boolean = false): boolean {
    return value ?? defaultValue;
  }

  static requireNonNull<T>(value: T | null | undefined, message: string): T {
    if (value === null || value === undefined) {
      throw new BusinessError(message, 4001, 'NullGuard');
    }
    return value;
  }

  static safeAccess<T, R>(obj: T | null | undefined, accessor: (o: T) => R | null | undefined, defaultValue: R): R {
    if (obj === null || obj === undefined) {
      return defaultValue;
    }
    try {
      const result = accessor(obj);
      return result ?? defaultValue;
    } catch (_e) {
      return defaultValue;
    }
  }
}