/**
 * 主题管理工具
 * 支持浅色/深色模式切换，颜色自动适配
 */
import { PreferenceUtil } from './PreferenceUtil';
import { GlobalContext } from '../basic/GlobalContext';
import { ConfigurationConstant } from '@kit.AbilityKit';
import type { common } from '@kit.AbilityKit';

export type ThemeMode = 'light' | 'dark' | 'system';

/** 主题切换选项 */
export interface ThemeOption {
  label: string;
  value: ThemeMode;
}

/** 主题颜色定义 */
export class ThemeColors {
  backgroundPrimary: string = '#FFFFFF';
  backgroundSecondary: string = '#F5F5F5';
  backgroundCard: string = '#FFFFFF';
  backgroundInput: string = '#F5F5F5';
  textPrimary: string = '#333333';
  textSecondary: string = '#666666';
  textTertiary: string = '#999999';
  textOnAccent: string = '#FFFFFF';
  accent: string = '#4ECDC4';
  accentLight: string = '#E8F8F5';
  success: string = '#4CAF50';
  warning: string = '#FF9800';
  danger: string = '#F44336';
  info: string = '#2196F3';
  divider: string = '#F0F0F0';
  chartLine: string = '#4ECDC4';
  chartFill: string = 'rgba(78,205,196,0.2)';
}

function createLightColors(): ThemeColors {
  const c = new ThemeColors();
  c.backgroundPrimary = '#FFFFFF';
  c.backgroundSecondary = '#F5F5F5';
  c.backgroundCard = '#FFFFFF';
  c.backgroundInput = '#F5F5F5';
  c.textPrimary = '#333333';
  c.textSecondary = '#666666';
  c.textTertiary = '#999999';
  c.textOnAccent = '#FFFFFF';
  c.accent = '#4ECDC4';
  c.accentLight = '#E8F8F5';
  c.success = '#4CAF50';
  c.warning = '#FF9800';
  c.danger = '#F44336';
  c.info = '#2196F3';
  c.divider = '#F0F0F0';
  c.chartLine = '#4ECDC4';
  c.chartFill = 'rgba(78,205,196,0.2)';
  return c;
}

function createDarkColors(): ThemeColors {
  const c = new ThemeColors();
  c.backgroundPrimary = '#1A1A1A';
  c.backgroundSecondary = '#121212';
  c.backgroundCard = '#2D2D2D';
  c.backgroundInput = '#3A3A3A';
  c.textPrimary = '#E0E0E0';
  c.textSecondary = '#AAAAAA';
  c.textTertiary = '#777777';
  c.textOnAccent = '#FFFFFF';
  c.accent = '#4ECDC4';
  c.accentLight = '#1A3A38';
  c.success = '#66BB6A';
  c.warning = '#FFA726';
  c.danger = '#EF5350';
  c.info = '#42A5F5';
  c.divider = '#3A3A3A';
  c.chartLine = '#4ECDC4';
  c.chartFill = 'rgba(78,205,196,0.15)';
  return c;
}

const THEME_PREF_KEY = 'app_theme_mode';

@ObservedV2
export class ThemeUtil {
  private static _instance: ThemeUtil;
  @Trace mode: ThemeMode = 'light';
  @Trace isDark: boolean = false;
  @Trace currentColors: ThemeColors = createLightColors();

  private constructor() {
  }

  public static get instance(): ThemeUtil {
    if (!ThemeUtil._instance) {
      ThemeUtil._instance = new ThemeUtil();
    }
    return ThemeUtil._instance;
  }

  /** 加载保存的主题设置 */
  public loadTheme(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const saved = pref.get(THEME_PREF_KEY, 'light') as string;
      this.mode = saved as ThemeMode;
      this.applyMode();
    } catch {
      this.mode = 'light';
      this.isDark = false;
      this.currentColors = createLightColors();
    }
  }

  /** 切换主题 */
  public setTheme(mode: ThemeMode): void {
    this.mode = mode;
    this.applyMode();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(THEME_PREF_KEY, mode);
    } catch {
      // ignore
    }
  }

  /** 应用模式 */
  private applyMode(): void {
    // 每次创建新对象，确保 @Trace 检测到引用变化
    if (this.mode === 'system') {
      // 跟随系统：默认使用浅色，由系统资源解析决定实际效果
      this.isDark = false;
      this.currentColors = createLightColors();
      try {
        const ctx = GlobalContext.getUIAbilityContext() as common.UIAbilityContext;
        ctx.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      } catch (_e) {
        // ignore
      }
    } else {
      this.isDark = this.mode === 'dark';
      this.currentColors = this.isDark ? createDarkColors() : createLightColors();
      try {
        const ctx = GlobalContext.getUIAbilityContext() as common.UIAbilityContext;
        const appCtx = ctx.getApplicationContext();
        if (this.mode === 'dark') {
          appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
        } else {
          appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
        }
      } catch (_e) {
        // ignore
      }
    }
  }

  /** 获取主题切换选项 */
  public static getThemeOptions(): ThemeOption[] {
    const options: ThemeOption[] = [
      { label: '浅色模式', value: 'light' },
      { label: '深色模式', value: 'dark' },
      { label: '跟随系统', value: 'system' },
    ];
    return options;
  }
}
