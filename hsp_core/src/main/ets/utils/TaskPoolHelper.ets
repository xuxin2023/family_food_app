// TaskPoolHelper.ets
// TaskPool 并发工具 - 将耗时计算卸载到后台线程
// 使用: const result = await TaskPoolHelper.parseLargeJSON(text)
// 注意: @Concurrent 函数必须是顶层函数, 不能访问组件状态

import { taskpool } from '@kit.ArkTS';

@Concurrent
function concurrentParseJSON(text: string): Object {
  return JSON.parse(text);
}

@Concurrent
function concurrentDeepClone(obj: Object): Object {
  return JSON.parse(JSON.stringify(obj));
}

export class TaskPoolHelper {
  static async parseLargeJSON(text: string): Promise<Object> {
    try {
      const task: taskpool.Task = new taskpool.Task(concurrentParseJSON, text);
      const result: Object = await taskpool.execute(task) as Object;
      return result;
    } catch (_) {
      return JSON.parse(text);
    }
  }

  static async deepClone(obj: Object): Promise<Object> {
    try {
      const task: taskpool.Task = new taskpool.Task(concurrentDeepClone, obj);
      const result: Object = await taskpool.execute(task) as Object;
      return result;
    } catch (_) {
      return JSON.parse(JSON.stringify(obj));
    }
  }
}
