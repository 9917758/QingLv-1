/**
 * JWT Token 管理
 * 存储/读取/清除登录 Token
 */
import { PreferenceUtil } from './PreferenceUtil';
import { GlobalContext } from '../basic/GlobalContext';
import { TCLogger } from '../basic/TCLogger';

const TAG = 'AuthToken';
const TOKEN_KEY = 'auth_token';

export class AuthToken {
  private static _token: string = '';

  /** 获取 Token（优先内存，其次 Preferences） */
  static getToken(): string {
    if (AuthToken._token.length > 0) {
      return AuthToken._token;
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      AuthToken._token = pref.get(TOKEN_KEY, '') as string;
    } catch {
      AuthToken._token = '';
    }
    return AuthToken._token;
  }

  /** 保存 Token（内存 + Preferences） */
  static save(token: string): void {
    AuthToken._token = token;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(TOKEN_KEY, token);
      TCLogger.info(TAG, 'token saved');
    } catch (err) {
      TCLogger.error(TAG, `save error: ${JSON.stringify(err)}`);
    }
  }

  /** 清除 Token（退出登录时调用） */
  static clear(): void {
    AuthToken._token = '';
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.delete(TOKEN_KEY);
      TCLogger.info(TAG, 'token cleared');
    } catch {
      // ignore
    }
  }

  /** 是否已登录（有 Token） */
  static isLoggedIn(): boolean {
    return AuthToken.getToken().length > 0;
  }
}
