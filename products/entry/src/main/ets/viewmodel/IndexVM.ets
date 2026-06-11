import { display } from '@kit.ArkUI';
import { BaseViewModel, BreakpointUtils, TCLogger } from 'common';

const TAG = 'IndexVM';

@ObservedV2
export class IndexVM extends BaseViewModel {
  breakpoint: BreakpointUtils | null = null;
  private changeCallback: ((type: number) => void) | null = null;
  private foldCallback: ((data: display.FoldStatus) => void) | null = null;

  // 监听设备屏幕方向改变
  displayOrientationListener() {
    try {
      this.displayModel.isFoldable = display.isFoldable();
      this.changeCallback = (type: number) => {
        let displayClass = display.getDisplayByIdSync(type);
        let landscapeType = [display.Orientation.LANDSCAPE, display.Orientation.LANDSCAPE_INVERTED]
        this.displayModel.isLandscape = landscapeType.includes(displayClass.orientation);
      }
      this.foldCallback = (data: display.FoldStatus) => {
        this.displayModel.foldStatus = data;
      }
      display.on('change', this.changeCallback)
      display.on('foldStatusChange', this.foldCallback)
    } catch (err) {
      TCLogger.error(TAG, `displayOrientationListener error: ${JSON.stringify(err)}`)
    }
  }

  unregisterDisplayListeners() {
    try {
      if (this.changeCallback) {
        display.off('change', this.changeCallback)
        this.changeCallback = null
      }
      if (this.foldCallback) {
        display.off('foldStatusChange', this.foldCallback)
        this.foldCallback = null
      }
    } catch (err) {
      TCLogger.error(TAG, `unregisterDisplayListeners error: ${JSON.stringify(err)}`)
    }
  }

  registerBreakpointListener(context: UIContext) {
    this.breakpoint = new BreakpointUtils(context.getMediaQuery());
    this.breakpoint?.register();
  }

  unregisterBreakpointListener() {
    this.breakpoint?.unRegister();
  }
}
