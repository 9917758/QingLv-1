/**
 * 后端登录页
 * 使用 FastAPI 后端的 /api/auth/login 和 /api/auth/register 接口
 */
import { PersistenceV2 } from '@kit.ArkUI';
import { AuthToken, HttpUtil, NetworkConfig, UserInfo, TCLogger, ThemeUtil } from 'common';
import type { ApiResponse, ApiTokenResponse, ThemeColors } from 'common';
import { phoneRouterControl } from 'oh_router';

interface LoginPayload {
  username: string;
  password: string;
}

const TAG = 'BackendLoginPage';

@Builder
export function BackendLoginPageBuilder() {
  BackendLoginPage()
}

@ComponentV2
export struct BackendLoginPage {
  @Local userInfo: UserInfo = PersistenceV2.connect(UserInfo, () => new UserInfo())!;
  @Local username: string = '';
  @Local password: string = '';
  @Local isRegister: boolean = false;
  @Local isLoading: boolean = false;
  @Local errorMsg: string = '';
  @Computed get themeColors(): ThemeColors {
    return ThemeUtil.instance.currentColors;
  }

  aboutToAppear(): void {
    NetworkConfig.load();
  }

  private async doLogin(): Promise<void> {
    if (this.username.length < 2 || this.password.length < 6) {
      this.errorMsg = '用户名至少2位，密码至少6位';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';

    const path = this.isRegister ? '/api/auth/register' : '/api/auth/login';
    const loginBody: LoginPayload = { username: this.username, password: this.password };
    const resp: ApiResponse<ApiTokenResponse> = await HttpUtil.post<ApiTokenResponse>(path, loginBody);

    this.isLoading = false;

    if (resp.error.length > 0) {
      this.errorMsg = resp.error;
      return;
    }

    if (resp.data) {
      // 保存 Token
      AuthToken.save(resp.data.access_token);
      // 更新本地用户信息
      this.userInfo.isLogin = true;
      this.userInfo.isEditOk = true;
      this.userInfo.id = String(resp.data.user.id);
      this.userInfo.nickName = resp.data.user.nick_name;
      this.userInfo.gender = resp.data.user.gender;
      this.userInfo.height = resp.data.user.height;
      this.userInfo.weight = resp.data.user.weight;
      if (resp.data.user.birthday) {
        this.userInfo.birthday = resp.data.user.birthday;
      }
      TCLogger.info(TAG, `login success: ${resp.data.user.username}`);
      phoneRouterControl.popPage({ popData: 'loginSuccess' });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Blank().height(60)

        // Logo
        Text('🏃')
          .fontSize(48)
        Text($r('app.string.app_name_qinglv'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ top: 8 })
        Text($r('app.string.app_private_health_assistant'))
          .fontSize(14)
          .fontColor(this.themeColors.textTertiary)
          .margin({ top: 4 })

        Blank().height(40)

        // 用户名
        TextInput({ placeholder: $r('app.string.login_username_placeholder'), text: $$this.username })
          .width('85%')
          .height(48)
          .borderRadius(8)
          .backgroundColor(this.themeColors.backgroundInput)
          .fontColor(this.themeColors.textPrimary)
          .margin({ bottom: 12 })

        // 密码
        TextInput({ placeholder: $r('app.string.login_password_placeholder'), text: $$this.password })
          .width('85%')
          .height(48)
          .borderRadius(8)
          .backgroundColor(this.themeColors.backgroundInput)
          .fontColor(this.themeColors.textPrimary)
          .type(InputType.Password)
          .margin({ bottom: 8 })

        // 错误提示
        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor(this.themeColors.danger)
            .width('85%')
            .margin({ bottom: 8 })
        }

        // 登录/注册按钮
        Button(this.isLoading ? '请稍候...' : (this.isRegister ? '注册' : '登录'))
          .width('85%')
          .height(48)
          .borderRadius(24)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.accent)
          .fontColor(this.themeColors.textOnAccent)
          .enabled(!this.isLoading)
          .onClick(() => this.doLogin())
          .margin({ top: 12 })

        // 切换登录/注册
        Row() {
          Text(this.isRegister ? $r('app.string.login_has_account') : $r('app.string.login_no_account'))
            .fontSize(13)
            .fontColor(this.themeColors.textTertiary)
          Text(this.isRegister ? $r('app.string.login_go_login') : $r('app.string.login_go_register'))
            .fontSize(13)
            .fontColor(this.themeColors.accent)
            .margin({ left: 4 })
            .onClick(() => {
              this.isRegister = !this.isRegister;
              this.errorMsg = '';
            })
        }
        .margin({ top: 16 })

        Blank().height(20)

        // 服务器地址显示
        Text(`服务器: ${NetworkConfig.serverUrl}`)
          .fontSize(11)
          .fontColor(this.themeColors.textTertiary)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.backgroundPrimary)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      // 登录页不允许返回
      return true;
    })
  }
}
