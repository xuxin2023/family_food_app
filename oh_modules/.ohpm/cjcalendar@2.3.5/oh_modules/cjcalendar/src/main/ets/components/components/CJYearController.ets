import { CJYear } from "./CJYear";

export class CJYearController {
  private cjYear?: CJYear

  bind(cjMonth: CJYear) {
    this.cjYear = cjMonth
  }

  unbind() {
    this.cjYear = undefined
  }

}