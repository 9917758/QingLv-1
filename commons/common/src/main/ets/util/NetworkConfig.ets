/**
 * 网络配置：后端服务器地址
 * 支持用户在设置页修改，存入 Preferences 持久化
 */
import { PreferenceUtil } from './PreferenceUtil';
import { GlobalContext } from '../basic/GlobalContext';
import { TCLogger } from '../basic/TCLogger';

const TAG = 'NetworkConfig';
const SERVER_URL_KEY = 'server_url';

export class NetworkConfig {
  /** 默认后端地址（VMware 虚拟网卡 IP，固定不变） */
  private static readonly DEFAULT_URL = 'http://192.168.237.1:8000';

  /** 当前生效的后端地址 */
  static serverUrl: string = NetworkConfig.DEFAULT_URL;

  /** 从 Preferences 加载用户自定义地址 */
  static load(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const saved = pref.get(SERVER_URL_KEY, '') as string;
      if (saved && saved.length > 0) {
        NetworkConfig.serverUrl = saved;
        TCLogger.info(TAG, `loaded serverUrl: ${saved}`);
      } else {
        NetworkConfig.serverUrl = NetworkConfig.DEFAULT_URL;
        TCLogger.info(TAG, `using default serverUrl: ${NetworkConfig.DEFAULT_URL}`);
      }
    } catch {
      NetworkConfig.serverUrl = NetworkConfig.DEFAULT_URL;
    }
  }

  /** 保存新地址 */
  static save(url: string): void {
    // 去掉末尾的 /
    const cleanUrl = url.endsWith('/') ? url.slice(0, -1) : url;
    NetworkConfig.serverUrl = cleanUrl;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(SERVER_URL_KEY, cleanUrl);
      TCLogger.info(TAG, `saved serverUrl: ${cleanUrl}`);
    } catch (err) {
      TCLogger.error(TAG, `save error: ${JSON.stringify(err)}`);
    }
  }

  /** 重置为默认地址 */
  static reset(): void {
    NetworkConfig.serverUrl = NetworkConfig.DEFAULT_URL;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.delete(SERVER_URL_KEY);
    } catch {
      // ignore
    }
  }
}
