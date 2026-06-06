// ReusableLazyList.test.ets
// V5 ReusableLazyList 通用列表组件单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { ReusableLazyListController } from 'hsp_core';

export default function reusableLazyListTest(): TestSuite {
  const suite: TestSuite = new TestSuite(

  suite.addTest(new TestCase('controller init with empty data', () => {
    const ctrl = new ReusableLazyListController<string>();
    expect(ctrl.totalCount()).assertEqual(0);
    expect(ctrl.cachedCount).assertEqual(3);
  }));

  suite.addTest(new TestCase('controller updateData sets new list', () => {
    const ctrl = new ReusableLazyListController<string>();
    ctrl.updateData(['a', 'b', 'c']);
    expect(ctrl.totalCount()).assertEqual(3);
    expect(ctrl.getData()).assertEqual(['a', 'b', 'c']);
  }));

  suite.addTest(new TestCase('controller appendData adds items', () => {
    const ctrl = new ReusableLazyListController<string>();
    ctrl.updateData(['a']);
    ctrl.appendData(['b', 'c']);
    expect(ctrl.totalCount()).assertEqual(3);
  }));

  suite.addTest(new TestCase('controller reload replaces data', () => {
    const ctrl = new ReusableLazyListController<number>();
    ctrl.updateData([1, 2, 3]);
    ctrl.updateData([4, 5]);
    expect(ctrl.totalCount()).assertEqual(2);
    expect(ctrl.getData()).assertEqual([4, 5]);
  }));

  suite.addTest(new TestCase('cachedCount setter clamps min 1', () => {
    const ctrl = new ReusableLazyListController<number>();
    ctrl.cachedCount = 0;
    expect(ctrl.cachedCount).assertEqual(1);
  }));

  suite.addTest(new TestCase('cachedCount setter clamps max 10', () => {
    const ctrl = new ReusableLazyListController<number>();
    ctrl.cachedCount = 15;
    expect(ctrl.cachedCount).assertEqual(10);
  }));

  suite.addTest(new TestCase('controller works with object type', () => {
    interface Item { id: number; name: string }
    const ctrl = new ReusableLazyListController<Item>();
    ctrl.updateData([{ id: 1, name: 'test' }, { id: 2, name: 'test2' }]);
    expect(ctrl.totalCount()).assertEqual(2);
    expect(ctrl.getData()[0].name).assertEqual('test');
  }));

  suite.addTest(new TestCase('empty appendData is noop', () => {
    const ctrl = new ReusableLazyListController<string>();
    ctrl.updateData(['x']);
    ctrl.appendData([]);
    expect(ctrl.totalCount()).assertEqual(1);
  }));

  return suite;
}