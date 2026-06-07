export function getJsonString(obj: Object, key: string, defaultValue: string = ''): string {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        return val.toString();
      }
    }
  }
  return defaultValue;
}

export function getJsonNumber(obj: Object, key: string): number {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        const num = Number(val);
        if (!isNaN(num)) {
          return num;
        }
      }
    }
  }
  return 0;
}

export function getJsonBoolean(obj: Object, key: string): boolean {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        return val === true || val === 1 || val === 'true' || val === '1';
      }
    }
  }
  return false;
}

export function getJsonObject(obj: Object, key: string): Record<string, Object> | null {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null && typeof val === 'object') {
        return val as Record<string, Object>;
      }
    }
  }
  return null;
}

export function getJsonStringArray(obj: Object, key: string): string[] {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null) {
        const result: string[] = [];
        if (Array.isArray(val)) {
          const arr: string[] = val as string[];
          for (const item of arr) {
            result.push(item.toString());
          }
        }
        return result;
      }
    }
  }
  return [];
}

export function getJsonObjectArray(obj: Object, key: string): Record<string, Object>[] {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      if (val !== undefined && val !== null && Array.isArray(val)) {
        const result: Record<string, Object>[] = [];
        const arr: Object[] = val as Object[];
        for (const item of arr) {
          if (item !== null && typeof item === 'object') {
            result.push(item as Record<string, Object>);
          }
        }
        return result;
      }
    }
  }
  return [];
}

export function hasJsonKey(obj: Object, key: string): boolean {
  const entries = Object.keys(obj) as [string, Object][];
  for (const entry of entries) {
    if (entry[0] === key) {
      const val = entry[1];
      return val !== undefined;
    }
  }
  return false;
}

export function isObject(value: Object | null | undefined): boolean {
  if (value === undefined || value === null) {
    return false;
  }
  return typeof value === 'object';
}

export function isNumber(value: Object | null | undefined): boolean {
  if (value === undefined || value === null) {
    return false;
  }
  return typeof value === 'number' && !isNaN(Number(value));
}

export function safeString(value: Object | null | undefined, defaultValue: string = ''): string {
  if (value === undefined || value === null) {
    return defaultValue;
  }
  return value.toString();
}

export function safeNumber(value: Object | null | undefined): number {
  if (value === undefined || value === null) {
    return 0;
  }
  if (typeof value === 'number') {
    return value;
  }
  const parsed = Number(value);
  if (isNaN(parsed)) {
    return 0;
  }
  return parsed;
}

export function safeInt(value: Object | null | undefined): number {
  if (value === undefined || value === null) {
    return 0;
  }
  if (typeof value === 'number') {
    return Math.round(value);
  }
  const parsed = parseInt(value.toString(), 10);
  if (isNaN(parsed)) {
    return 0;
  }
  return parsed;
}
