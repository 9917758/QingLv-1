import { OHDialogModel } from 'common'

@Builder
export function commonDialogBuilder(vm: OHDialogModel) {
  Text(vm.subtitle)
    .fontSize($r('sys.float.Body_M'))
    .fontColor($r('sys.color.font_primary'))
    .lineHeight($r('app.float.vp_22'))
    .maxLines(-1)

  Blank().height($r('app.float.vp_26'))
}