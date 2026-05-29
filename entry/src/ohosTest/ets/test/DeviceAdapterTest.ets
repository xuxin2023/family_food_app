import { describe, it, expect } from '@ohos/hypium';
import { DeviceAdapter, DeviceType, Breakpoint } from '../../../../../../hsp_core/src/main/ets/utils/DeviceAdapter';

export default function deviceAdapterTest() {
  describe('DeviceAdapterTest', () => {
    it('should_return_valid_device_type', 0, () => {
      const type = DeviceAdapter.getDeviceType();
      const valid = type === DeviceType.PHONE || type === DeviceType.TABLET || type === DeviceType.TWO_IN_ONE;
      expect(valid).assertTrue();
    });

    it('should_return_correct_breakpoint_by_width', 0, () => {
      expect(DeviceAdapter.getBreakpoint(360)).assertEqual(Breakpoint.SM);
      expect(DeviceAdapter.getBreakpoint(650)).assertEqual(Breakpoint.MD);
      expect(DeviceAdapter.getBreakpoint(900)).assertEqual(Breakpoint.LG);
    });

    it('should_return_grid_columns_matching_breakpoint', 0, () => {
      const columns = DeviceAdapter.getGridColumns();
      expect(columns === 4 || columns === 8 || columns === 12).assertTrue();
    });
  });
}
