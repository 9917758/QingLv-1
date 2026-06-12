/**
 * 健康日记服务
 * 支持为每天添加一段文字备注，存储在本地 Preferences
 */
import { GlobalContext, PreferenceUtil, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

export interface DiaryEntry {
  date: string;      // YYYY-MM-DD
  content: string;   // 用户写的日记内容
  updatedAt: number; // 更新时间戳
}

const DIARY_KEY_PREFIX = 'health_diary_';

@ObservedV2
export class HealthDiaryService {
  private static _instance: HealthDiaryService;
  @Trace entries: DiaryEntry[] = [];
  private _loadedUserId: string = '';

  public static get instance(): HealthDiaryService {
    if (!HealthDiaryService._instance) {
      HealthDiaryService._instance = new HealthDiaryService();
    }
    return HealthDiaryService._instance;
  }

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getDiaryKey(): string {
    return `${DIARY_KEY_PREFIX}${HealthDiaryService.getUserId()}`;
  }

  /** 加载所有日记 */
  public loadAll(): void {
    const userId = HealthDiaryService.getUserId();
    if (this._loadedUserId.length > 0 && this._loadedUserId !== userId) {
      this.entries = [];
    }
    this._loadedUserId = userId;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(this.getDiaryKey(), '[]') as string;
      this.entries = JSON.parse(raw) as DiaryEntry[];
    } catch {
      this.entries = [];
    }
  }

  /** 获取指定日期的日记 */
  public getEntry(dateStr: string): DiaryEntry | undefined {
    this.loadAll();
    return this.entries.find((e: DiaryEntry) => e.date === dateStr);
  }

  /** 保存日记（新增或更新） */
  public saveEntry(dateStr: string, content: string): void {
    this.loadAll();
    const existing = this.entries.findIndex((e: DiaryEntry) => e.date === dateStr);
    const entry: DiaryEntry = {
      date: dateStr,
      content: content,
      updatedAt: Date.now(),
    };
    if (existing >= 0) {
      this.entries[existing] = entry;
    } else {
      this.entries.unshift(entry);
    }
    // 最多保留 365 条
    if (this.entries.length > 365) {
      this.entries = this.entries.slice(0, 365);
    }
    this.persist();
  }

  /** 删除日记 */
  public deleteEntry(dateStr: string): void {
    this.loadAll();
    this.entries = this.entries.filter((e: DiaryEntry) => e.date !== dateStr);
    this.persist();
  }

  /** 获取最近 N 条日记 */
  public getRecent(count: number = 7): DiaryEntry[] {
    this.loadAll();
    return this.entries.slice(0, count);
  }

  /** 持久化 */
  private persist(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getDiaryKey(), JSON.stringify(this.entries));
    } catch {
      // ignore
    }
  }
}
