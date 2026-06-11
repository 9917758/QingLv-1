import { GlobalContext, PreferenceUtil, HttpUtil, AuthToken, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

const FAVORITE_KEY_PREFIX = 'fav_';
const VERSION_KEY = 'health_knowledge_favorites_version';
const CURRENT_VERSION = 2; // 递增：v2 按用户ID隔离收藏数据

/**
 * 健康知识收藏工具类
 * 本地 Preferences（按用户ID隔离） + 后端 API 双向同步
 */
export class FavoriteUtil {
  private static pref: PreferenceUtil | null = null;

  private static getPref(): PreferenceUtil {
    if (!FavoriteUtil.pref) {
      FavoriteUtil.pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
    }
    return FavoriteUtil.pref;
  }

  /** 获取当前用户ID，用于隔离收藏数据 */
  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  /** 获取当前用户的收藏 key */
  private static getFavoriteKey(): string {
    return `${FAVORITE_KEY_PREFIX}${FavoriteUtil.getUserId()}`;
  }

  /** 初始化：版本升级时清理旧格式数据 */
  static init(): void {
    const pref = FavoriteUtil.getPref();
    const storedVersion: number = pref.get(VERSION_KEY, 0) as number;
    if (storedVersion < CURRENT_VERSION) {
      // 清除旧版本的全局收藏 key（不再按用户隔离的旧数据）
      pref.delete('health_knowledge_favorites');
      pref.put(VERSION_KEY, CURRENT_VERSION);
    }
  }

  /** 退出登录时清除当前用户的本地收藏缓存 */
  static clearUserData(): void {
    try {
      const key = FavoriteUtil.getFavoriteKey();
      FavoriteUtil.getPref().delete(key);
    } catch {
      // ignore
    }
  }

  /** 获取当前用户所有收藏的文章ID */
  static getFavorites(): string[] {
    try {
      const key = FavoriteUtil.getFavoriteKey();
      const data = FavoriteUtil.getPref().get(key, '[]') as string;
      return JSON.parse(data) as string[];
    } catch {
      return [];
    }
  }

  /** 添加收藏（本地 + API） */
  static addFavorite(id: string): void {
    const favorites = FavoriteUtil.getFavorites();
    if (!favorites.includes(id)) {
      favorites.push(id);
      FavoriteUtil.getPref().put(FavoriteUtil.getFavoriteKey(), JSON.stringify(favorites));
    }
    if (AuthToken.isLoggedIn()) {
      HttpUtil.post<object>(`/api/knowledge/favorites/${id}`);
    }
  }

  /** 取消收藏（本地 + API） */
  static removeFavorite(id: string): void {
    const favorites = FavoriteUtil.getFavorites();
    const index = favorites.indexOf(id);
    if (index !== -1) {
      favorites.splice(index, 1);
      FavoriteUtil.getPref().put(FavoriteUtil.getFavoriteKey(), JSON.stringify(favorites));
    }
    if (AuthToken.isLoggedIn()) {
      HttpUtil.del<object>(`/api/knowledge/favorites/${id}`);
    }
  }

  /** 检查当前用户是否已收藏 */
  static isFavorited(id: string): boolean {
    return FavoriteUtil.getFavorites().includes(id);
  }

  /** 切换收藏状态，返回切换后的状态 */
  static toggleFavorite(id: string): boolean {
    if (FavoriteUtil.isFavorited(id)) {
      FavoriteUtil.removeFavorite(id);
      return false;
    } else {
      FavoriteUtil.addFavorite(id);
      return true;
    }
  }

  /** 获取今日推荐文章索引 */
  static getTodayArticleIndex(totalCount: number): number {
    const now = new Date();
    return (now.getFullYear() * 365 + now.getMonth() * 31 + now.getDate()) % totalCount;
  }

  /** 获取当前用户收藏文章数量 */
  static getFavoriteCount(): number {
    return FavoriteUtil.getFavorites().length;
  }
}
