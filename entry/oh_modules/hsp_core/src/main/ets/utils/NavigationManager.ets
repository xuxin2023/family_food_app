// NavigationManager.ets
// NavPathStack 全局管理 — Navigation 路由体系渐进式迁移基础设施
// 当前项目仍以 router API 为主，此模块为 NavPathStack 导航提供统一入口
// 后续逐页迁移时，页面通过 NavigationManager.getStack() 获取共享栈

export class NavigationManager {
  private static navPathStack: NavPathStack = new NavPathStack();

  static getStack(): NavPathStack {
    return NavigationManager.navPathStack;
  }

  static pushPath(name: string, param?: Object): void {
    NavigationManager.navPathStack.pushPath({ name: name, param: param });
  }

  static replacePath(name: string, param?: Object): void {
    NavigationManager.navPathStack.replacePath({ name: name, param: param });
  }

  static pop(): NavPathInfo | undefined {
    return NavigationManager.navPathStack.pop();
  }

  static popToName(name: string): number {
    return NavigationManager.navPathStack.popToName(name);
  }

  static clear(): void {
    NavigationManager.navPathStack.clear();
  }

  static getAllPathName(): string[] {
    return NavigationManager.navPathStack.getAllPathName();
  }

  static getCurrentPath(): string {
    const paths: string[] = NavigationManager.navPathStack.getAllPathName();
    return paths.length > 0 ? paths[paths.length - 1] : '';
  }

  static getStackSize(): number {
    return NavigationManager.navPathStack.size();
  }

  static getParam(index: number): Object | undefined {
    return NavigationManager.navPathStack.getParamByIndex(index) as Object | undefined;
  }

  static getCurrentParam(): Object | undefined {
    const size = NavigationManager.getStackSize();
    if (size <= 1) return undefined;
    return NavigationManager.getParam(size - 1);
  }
}
