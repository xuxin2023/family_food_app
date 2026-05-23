import { CJDateItem } from './CJDateItem';
import { CJMonth } from './CJMonth';

const TAG = "CJMonthController"

export class CJMonthController {
  private cjMonth: CJMonth | undefined
  private month?: CJDateItem

  bind(cjMonth: CJMonth) {
    this.cjMonth = cjMonth
  }

  unbind() {
    this.cjMonth = undefined
  }

  getItems(): CJDateItem[] | undefined {
    return this.cjMonth?.days
  }

  getMonth(): CJDateItem | undefined {
    return this.month ?? this.cjMonth?.month
  }

  refresh(date?: Date) {
    if (date) {
      this.month = new CJDateItem(date)
    } else {
      this.month = undefined
    }
    this.cjMonth?.refresh(date)
  }

  getFoldRowIndex(): number {
    return this.cjMonth?.getFoldRowIndex() ?? 0
  }
}