import { CommonHeader, RouterMap, BarVM, OHDialog, OHDialogModel, USE_MOCK_DATA, NetworkConfig, AuthToken, ThemeUtil, I18nUtil } from 'common';
import type { ThemeMode, ThemeOption } from 'common';
import { emitter } from '@kit.BasicServicesKit';
import { OHPage, phoneRouterControl } from 'oh_router';
import { UserInfoRow } from '../comp/UserInfoRow';
import { PrivacySettingsPageBuilder } from './PrivacySettingsPage';
import { AboutPageBuilder } from './AboutPage';
import { ClearCacheDialogModel } from '../viewmodel/ClearCacheDialogModel';
import { SettingAboutVM } from '../viewmodel/SetUpVM';
import { EditPersonalCenterBuilder } from './EditPersonalCenterPage';
import { LogoutDialogModel } from '../viewmodel/LogoutDialogModel';
import { SetUpGenericCard } from '../comp/SetUpGenericCard';

/**
 * @usage: 设置页面，提供应用设置和用户管理功能。包含个人信息管理、隐私设置、缓存清理、版本检查、关于我们、退出登录功能。
 主要数据结构包括UserInfo（用户信息）、设置项配置。包含缓存计算、版本检查、退出登录等逻辑。
 * @layout: 页面采用垂直布局（Column），顶部为CommonHeader导航栏，下方为设置项列表。设置项使用UserInfoRow组件展示，
 支持文本显示、开关切换、点击跳转等交互。
 * @constraints: 退出登录按钮和逻辑不可删除
 * @domain: 健康医疗
 * @isGen: true
 * @fileType: page
 * @zhName: 设置页面
 * @subPage: EditPersonalCenter,PrivacySettingsPage,AboutPage
 * @component: CommonHeader,UserInfoRow,ClearCacheDialog，LogoutDialog，SetUpGenericCard，OHPage
 * @image: screenshot/person/Setup.jpg
 */
@ComponentV2
export struct SetUpPage {
  vm: SettingAboutVM = new SettingAboutVM();
  @Local serverUrl: string = NetworkConfig.serverUrl;
  @Local currentTheme: ThemeMode = ThemeUtil.instance.mode;
  @Local currentLang: string = '';

  aboutToAppear(): void {
    this.vm.init()
    this.vm.getClearSize()
    NetworkConfig.load();
    this.serverUrl = NetworkConfig.serverUrl;
    ThemeUtil.instance.loadTheme();
    this.currentTheme = ThemeUtil.instance.mode;
    // 语言指示器跟随系统 locale（I18nUtil 在 EntryAbility 中已初始化）
    this.currentLang = I18nUtil.lang;
  }

  @Builder
  line() {
    Divider()
      .strokeWidth('1px')
      .width('100%')
      .color($r('sys.color.comp_divider'))
      .padding({ left: $r('app.float.vp_12'), right: $r('app.float.vp_12') })
  }

  build() {
    OHPage({
      childBuilder: () => {
        this.render();
      },
      useSafePadding: true
    })
  }

  @Builder
  clearCacheDialogBuilder(vm: OHDialogModel) {
    Text(vm.subtitle + vm.cacheSize)
      .fontSize($r('sys.float.Body_M'))
      .fontColor($r('sys.color.font_primary'))
      .lineHeight($r('app.float.vp_22'))
      .maxLines(-1)

    Blank().height($r('app.float.vp_26'))
  }

  // 页面内容渲染
  @Builder
  render() {
    Column() {
      CommonHeader({
        title: $r('app.string.person_setting_title'),
        onReturnClick: () => {
          phoneRouterControl.popPage();
        },
        leftImageRes: $r('app.media.ic_backward2')
      })

      Scroll() {
        Column() {
          SetUpGenericCard() {
            UserInfoRow({
              leftTitle: '个人信息', rightOnClick: () => {
                phoneRouterControl.jumpPage({
                  pageName: RouterMap.PERSONAL_CENTER_PAGE,
                  builder: wrapBuilder(EditPersonalCenterBuilder)
                })
              }
            })
            this.line()
            UserInfoRow({
              leftTitle: '隐私设置', rightOnClick: () => {
                phoneRouterControl.jumpPage({
                  pageName: RouterMap.PRIVACY_SETTINGS_PAGE,
                  builder: wrapBuilder(PrivacySettingsPageBuilder)
                })
              }
            })
          }

          SetUpGenericCard() {
            UserInfoRow({
              leftTitle: '清除缓存', rightContent: this.vm.cacheSize, rightOnClick: () => {
                let clearCacheDialogModelVM = new ClearCacheDialogModel();
                clearCacheDialogModelVM.cacheSize = this.vm.cacheSize;
                clearCacheDialogModelVM.onValueConfirmClick = () => {
                  this.vm.clean();
                }
                clearCacheDialogModelVM.childBuilder = this.clearCacheDialogBuilder
                OHDialog.ShowPopup(clearCacheDialogModelVM)
              }
            })
          }

          SetUpGenericCard() {
            UserInfoRow({
              leftTitle: '版本检测', rightOnClick: () => {
                this.vm.checkAppUpdate()
              }
            })

            this.line()
            UserInfoRow({
              leftTitle: '关于我们', rightOnClick: () => {
                phoneRouterControl.jumpPage({
                  pageName: RouterMap.ABOUT_PAGE,
                  builder: wrapBuilder(AboutPageBuilder)
                })
              }
            })
          }

          // 主题设置
          SetUpGenericCard() {
            Row() {
              Text('🎨')
                .fontSize(16)
                .margin({ right: 8 })
              Text($r('app.string.person_setting_theme'))
                .fontSize($r('sys.float.Body_L'))
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
              Blank()
              Text(this.currentTheme === 'light' ? $r('app.string.person_setting_theme_light') :
                this.currentTheme === 'dark' ? $r('app.string.person_setting_theme_dark') :
                  $r('app.string.person_setting_theme_system'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_secondary'))
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })

            this.line()

            Row({ space: 12 }) {
              ForEach(ThemeUtil.getThemeOptions(), (option: ThemeOption) => {
                Button(option.label)
                  .fontSize(13)
                  .fontWeight(this.currentTheme === option.value ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.currentTheme === option.value ? Color.White : $r('sys.color.font_primary'))
                  .backgroundColor(this.currentTheme === option.value ? '#4ECDC4' : $r('sys.color.comp_background_tertiary'))
                  .borderRadius(8)
                  .height(36)
                  .layoutWeight(1)
                  .onClick(() => {
                    ThemeUtil.instance.setTheme(option.value);
                    this.currentTheme = option.value;
                  })
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 14 })
          }

          // 语言设置
          SetUpGenericCard() {
            Row() {
              Text('🌍')
                .fontSize(16)
                .margin({ right: 8 })
              Text($r('app.string.person_setting_language'))
                .fontSize($r('sys.float.Body_L'))
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
              Blank()
              Text(this.currentLang === 'zh' ? $r('app.string.person_setting_lang_zh') : $r('app.string.person_setting_lang_en'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_secondary'))
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          }

          if (USE_MOCK_DATA) {
            SetUpGenericCard() {
              Row() {
                Text('🧪')
                  .fontSize(16)
                  .margin({ right: 8 })
                Text($r('app.string.person_setting_dev_options'))
                  .fontSize($r('sys.float.Body_L'))
                  .fontColor($r('sys.color.font_primary'))
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text($r('app.string.person_setting_mock_mode'))
                  .fontSize($r('sys.float.Body_S'))
                  .fontColor('#FF6B00')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(4)
                  .backgroundColor('#FFF3E0')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })

              this.line()

              Text($r('app.string.person_setting_mock_desc'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor($r('sys.color.font_secondary'))
                .lineHeight(20)
                .width('100%')
                .padding({ left: 16, right: 16, top: 8, bottom: 14 })
            }
          }

          SetUpGenericCard() {
            Row() {
              Text('🌐')
                .fontSize(16)
                .margin({ right: 8 })
              Text($r('app.string.person_setting_server_url'))
                .fontSize($r('sys.float.Body_L'))
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 8 })

            Row({ space: 8 }) {
              TextInput({ text: $$this.serverUrl, placeholder: 'http://192.168.x.x:8000' })
                .layoutWeight(1)
                .height(40)
                .borderRadius(8)
                .backgroundColor($r('sys.color.comp_background_list_card'))
                .fontSize(13)
              Button($r('app.string.person_setting_save'))
                .height(40)
                .borderRadius(8)
                .backgroundColor('#4ECDC4')
                .fontColor($r('sys.color.font_on_primary'))
                .fontSize(13)
                .onClick(() => {
                  try {
                    NetworkConfig.save(this.serverUrl);
                    this.getUIContext().getPromptAction().showToast({
                      message: $r('app.string.person_setting_server_saved'),
                      duration: 1500
                    });
                  } catch (e) {
                    this.getUIContext().getPromptAction().showToast({
                      message: $r('app.string.person_setting_server_save_fail'),
                      duration: 1500
                    });
                  }
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 14 })
          }

          Blank().layoutWeight(1)
          Button($r('app.string.person_setting_logout'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .fontColor($r('sys.color.font_primary'))
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .height($r('app.float.vp_40'))
            .onClick(() => {
              if (this.vm.userInfo.isLogin) {
                let logoutDialogModelVM = new LogoutDialogModel();
                logoutDialogModelVM.onValueConfirmClick = () => {
                  AuthToken.clear();
                  this.vm.userInfo.isLogin = false;
                  this.getUIContext()
                    .getPromptAction()
                    .showToast({ message: $r('app.string.person_setting_logout_success'), duration: 2000 });
                  emitter.emit({ eventId: 814 });
                }
                OHDialog.ShowPopup(logoutDialogModelVM)
              } else {
                this.getUIContext()
                  .getPromptAction()
                  .showToast({ message: $r('app.string.person_setting_not_login'), duration: 2000 });
              }
            })
        }
        .width('100%')
      }
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .enableScrollInteraction(true)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({
      bottom: BarVM.instance.aiBarH
    })
    .backgroundColor($r('sys.color.comp_background_gray'))
  }
}
@Builder
export function SetUpPageBuilder() {
  SetUpPage()
}
