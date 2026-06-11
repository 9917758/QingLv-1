import { TCLogger } from '../basic/TCLogger';

/**
 * 统一错误处理工具
 * 关键路径（数据读写、网络）必须 log；UI 层可以静默
 */
export class ErrorUtil {
  /**
   * 记录错误并返回默认值
   * @param tag 日志标签
   * @param context 错误上下文描述
   * @param err 错误对象
   * @param fallback 返回的默认值
   */
  static handle<T>(tag: string, context: string, err: Error, fallback: T): T {
    TCLogger.error(tag, `${context}: ${err.message}`);
    return fallback;
  }

  /**
   * 仅记录错误（无返回值场景）
   */
  static log(tag: string, context: string, err: Error): void {
    TCLogger.error(tag, `${context}: ${err.message}`);
  }
}
