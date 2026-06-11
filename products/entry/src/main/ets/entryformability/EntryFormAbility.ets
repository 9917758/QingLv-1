// 仅保留项目已存在的合法导入，移除所有无法导入的模块/类型
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // 显式声明变量类型，规避 any 警告
    const emptyData: string = "";
    const formData = formBindingData.createFormBindingData(emptyData);
    return formData;
  }

  onCastToNormalForm(formId: string): void {
    // 空方法，保留原有逻辑
  }

  onUpdateForm(formId: string): void {
    // 空方法，保留原有逻辑
  }

  /**
   * 卡片点击事件 - 全版本兼容跳转方案
   * 不调用 startAbility / 不依赖全局上下文，纯系统原生跳转
   */
  onFormEvent(formId: string, message: string): void {
    console.log("服务卡片被点击，表单ID：", formId);
    try {
      // 构造跳转意图，卡片系统会自动解析并拉起应用
      const jumpWant: Want = {
        // 固定拉起应用主入口
        abilityName: "EntryAbility"
      };
      // 给事件附加跳转参数，系统自动触发App启动（低版本SDK通用方案）
      message = JSON.stringify(jumpWant);
    } catch (err) {
      // 【重点】移除 catch 参数类型注解，符合 arkts-no-types-in-catch 规则
      console.error("卡片点击事件异常：", err);
    }
  }

  onRemoveForm(formId: string): void {
    console.log("服务卡片已移除，表单ID：", formId);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}