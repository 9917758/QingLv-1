import { GlobalContext, PreferenceUtil } from 'common';

const FAVORITE_KEY = 'health_knowledge_favorites';
const VERSION_KEY = 'health_knowledge_favorites_version';
const CURRENT_VERSION = 1; // 递增此版本号可清除旧版本残留的收藏脏数据

/**
 * 健康知识收藏工具类
 * 基于 PreferenceUtil 本地存储收藏的文章ID列表
 */
export class FavoriteUtil {
  private static pref: PreferenceUtil | null = null;

  private static getPref(): PreferenceUtil {
    if (!FavoriteUtil.pref) {
      FavoriteUtil.pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
    }
    return FavoriteUtil.pref;
  }

  /** 初始化：检测旧版本脏数据并自动清理 */
  static init(): void {
    const pref = FavoriteUtil.getPref();
    const storedVersion: number = pref.get(VERSION_KEY, 0) as number;
    if (storedVersion < CURRENT_VERSION) {
      // 旧版本残留数据（之前 bug 导致的状态污染），清空重来
      pref.put(FAVORITE_KEY, '[]');
      pref.put(VERSION_KEY, CURRENT_VERSION);
    }
  }

  /** 获取所有收藏的文章ID */
  static getFavorites(): string[] {
    try {
      const data = FavoriteUtil.getPref().get(FAVORITE_KEY, '[]') as string;
      return JSON.parse(data) as string[];
    } catch {
      return [];
    }
  }

  /** 添加收藏 */
  static addFavorite(id: string): void {
    const favorites = FavoriteUtil.getFavorites();
    if (!favorites.includes(id)) {
      favorites.push(id);
      FavoriteUtil.getPref().put(FAVORITE_KEY, JSON.stringify(favorites));
    }
  }

  /** 取消收藏 */
  static removeFavorite(id: string): void {
    const favorites = FavoriteUtil.getFavorites();
    const index = favorites.indexOf(id);
    if (index !== -1) {
      favorites.splice(index, 1);
      FavoriteUtil.getPref().put(FAVORITE_KEY, JSON.stringify(favorites));
    }
  }

  /** 检查是否已收藏 */
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

  /** 获取今日推荐文章索引（基于日期，同一天不变） */
  static getTodayArticleIndex(totalCount: number): number {
    const now = new Date();
    return (now.getFullYear() * 365 + now.getMonth() * 31 + now.getDate()) % totalCount;
  }

  /** 获取收藏文章数量 */
  static getFavoriteCount(): number {
    return FavoriteUtil.getFavorites().length;
  }
}
