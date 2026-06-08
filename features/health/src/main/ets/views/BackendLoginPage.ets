/**
 * 后端登录页
 * 使用 FastAPI 后端的 /api/auth/login 和 /api/auth/register 接口
 */
import { PersistenceV2 } from '@kit.ArkUI';
import { AuthToken, HttpUtil, NetworkConfig, UserInfo, TCLogger } from 'common';
import type { ApiResponse, ApiTokenResponse } from 'common';
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
        Text('清律')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8 })
        Text('您的私人健康助手')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })

        Blank().height(40)

        // 用户名
        TextInput({ placeholder: '请输入用户名', text: $$this.username })
          .width('85%')
          .height(48)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .margin({ bottom: 12 })

        // 密码
        TextInput({ placeholder: '请输入密码', text: $$this.password })
          .width('85%')
          .height(48)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .type(InputType.Password)
          .margin({ bottom: 8 })

        // 错误提示
        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor('#F44336')
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
          .backgroundColor('#4ECDC4')
          .fontColor(Color.White)
          .enabled(!this.isLoading)
          .onClick(() => this.doLogin())
          .margin({ top: 12 })

        // 切换登录/注册
        Row() {
          Text(this.isRegister ? '已有账号？' : '没有账号？')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.isRegister ? '去登录' : '去注册')
            .fontSize(13)
            .fontColor('#4ECDC4')
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
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      // 登录页不允许返回
      return true;
    })
  }
}
