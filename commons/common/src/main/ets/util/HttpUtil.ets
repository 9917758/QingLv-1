/**
 * HTTP 请求工具
 * 封装 @ohos.net.http，统一 GET/POST/PUT/DELETE，自动携带 JWT Token
 */
import { http } from '@kit.NetworkKit';
import { TCLogger } from '../basic/TCLogger';
import { NetworkConfig } from './NetworkConfig';
import { AuthToken } from './AuthToken';

const TAG = 'HttpUtil';

/** 统一 API 响应结构 */
export interface ApiResponse<T> {
  data: T | null;
  error: string;
  statusCode: number;
}

export class HttpUtil {
  /**
   * GET 请求
   */
  static async get<T>(path: string): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>(http.RequestMethod.GET, path);
  }

  /**
   * POST 请求
   */
  static async post<T>(path: string, body?: object): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>(http.RequestMethod.POST, path, body);
  }

  /**
   * PUT 请求
   */
  static async put<T>(path: string, body?: object): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>(http.RequestMethod.PUT, path, body);
  }

  /**
   * DELETE 请求
   */
  static async del<T>(path: string): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>(http.RequestMethod.DELETE, path);
  }

  /**
   * 统一请求方法
   */
  private static async request<T>(
    method: http.RequestMethod,
    path: string,
    body?: object
  ): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    const url = `${NetworkConfig.serverUrl}${path}`;

    const header: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    // 自动携带 JWT Token
    const token = AuthToken.getToken();
    if (token.length > 0) {
      header['Authorization'] = `Bearer ${token}`;
    }

    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: header,
        connectTimeout: 60000,
        readTimeout: 60000,
      };

      if (body !== undefined) {
        options.extraData = JSON.stringify(body);
      }

      TCLogger.info(TAG, `${http.RequestMethod[method]} ${url}`);
      const response = await httpRequest.request(url, options);
      httpRequest.destroy();
      const statusCode = response.responseCode;
      const resultStr = response.result as string;

      if (statusCode >= 200 && statusCode < 300) {
        try {
          const data = JSON.parse(resultStr) as T;
          return { data: data, error: '', statusCode: statusCode };
        } catch {
          return { data: null, error: '响应解析失败', statusCode: statusCode };
        }
      }

      // 非 2xx 响应：尝试解析 FastAPI 的 {"detail": "..."} 格式
      let errorMsg = `请求失败 (${statusCode})`;
      try {
        const errObj = JSON.parse(resultStr) as Record<string, string>;
        if (errObj['detail']) {
          errorMsg = errObj['detail'];
        }
      } catch {
        // 忽略解析错误
      }

      if (statusCode === 401) {
        // Token 过期或无效，清除登录状态
        AuthToken.clear();
        TCLogger.warn(TAG, 'Token expired, cleared');
        // 如果后端传了具体的错误（如密码错误），优先使用后端的，否则提示登录过期
        if (!errorMsg || errorMsg.startsWith('请求失败')) {
          errorMsg = '登录已过期，请重新登录';
        }
      }

      return { data: null, error: errorMsg, statusCode: statusCode };

    } catch (err) {
      httpRequest.destroy();
      const errMsg = err instanceof Error ? err.message : String(err);
      TCLogger.error(TAG, `request error: ${errMsg}`);
      return { data: null, error: '网络请求失败，请检查网络连接', statusCode: 0 };
    }
  }
}
