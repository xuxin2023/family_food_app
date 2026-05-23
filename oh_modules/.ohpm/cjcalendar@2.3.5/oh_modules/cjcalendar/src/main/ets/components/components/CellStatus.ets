@Observed
export class CellStatus {
  fontColor?: ResourceColor = "#252a34"
  descFontColor?: ResourceColor = "#252a34"
  markFontColor?: ResourceColor = "#03A9F4"
  fontSize?: number | string | Resource = 18
  backgroundColor?: ResourceColor = "#00000000"
  borderColor?: ResourceColor
  borderWidth?: Length = 1
  isStart?: boolean = false
  isEnd?: boolean = false
  // selected: boolean = false
}