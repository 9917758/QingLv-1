import { AppStorageV2, ComponentContent } from '@kit.ArkUI';
import { BreakpointModel, GlobalContext, HMPromptAction, TCLogger, USE_MOCK_DATA } from 'common';
import { DeviceModel } from '../viewmodel/DeviceModel';

const TAG: string = 'UnbindDeviceDialog';

/**
 * 设备解除绑定弹框
 */
export class UnbindDeviceDialog {
  public static deviceId: string = '';

  private constructor() {
  }

  static ShowUnbindPopup(deviceId: string) {
    UnbindDeviceDialog.deviceId = deviceId;
    if (HMPromptAction.contentNode === undefined) {
      let uiContextUnBind = GlobalContext.getUIContext();
      if (uiContextUnBind) {
        let contentNode = new ComponentContent(uiContextUnBind, wrapBuilder(buildUnbindPopup));
        HMPromptAction.contentNode = contentNode;
        HMPromptAction.uiContext = uiContextUnBind;
        HMPromptAction.options = {
          alignment: DialogAlignment.Center,
          autoCancel: false,
          onWillDismiss: (reasonUnbind: DismissDialogAction) => {
            return reasonUnbind.reason !== DismissReason.PRESS_BACK
          }
        };
        HMPromptAction.openDialog();
      } else {
        TCLogger.info(TAG, `GlobalContext uiContext is empty`);
      }
    }
  }

  static CloseUnbindPopup() {
    HMPromptAction.closeDialog();
  }
}

@ComponentV2
struct popup {
  @Local breakpointModel: BreakpointModel = AppStorageV2.connect(BreakpointModel, () => new BreakpointModel())!;

  build() {
    Column() {
      Blank().height($r('app.float.vp_12'))
      Text($r('app.string.device_info_unbind_btn'))
        .fontSize($r('sys.float.Title_S'))
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .height($r('app.float.vp_52'))

      Row() {
        Blank().width($r('app.float.vp_24'))
        Text($r('app.string.device_info_unbind_tip'))
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_primary'))
          .lineHeight($r('app.float.vp_22'))
          .layoutWeight(1)
          .height('100%')
          .maxLines(2)
        Blank().width($r('app.float.vp_24'))
      }
      .width('100%')
      .height($r('app.float.vp_52'))

      Blank().height($r('app.float.vp_20'))

      Row() {
        Button($r('app.string.device_cancel'))
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_tertiary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            UnbindDeviceDialog.CloseUnbindPopup();
          })

        Blank()
          .height($r('app.float.vp_22'))
          .width('1px')
          .color($r('sys.color.comp_divider'))

        Button($r('app.string.device_unbind'))
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.warning'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            UnbindDeviceDialog.CloseUnbindPopup();
            if (USE_MOCK_DATA) {
              DeviceModel.instance.unbindDeviceMock(UnbindDeviceDialog.deviceId);
            } else {
              DeviceModel.instance.openAppInfo();
            }
          })
      }
      .width('100%')
      .height($r('app.float.vp_40'))

      Blank().height($r('app.float.vp_16'))
    }
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .width(this.breakpointModel.dialogWidth)
    .borderRadius($r('sys.float.corner_radius_level12'))
  }
}

@Builder
function buildUnbindPopup() {
  popup()
}