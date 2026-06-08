import { PersistenceV2 } from '@kit.ArkUI';
import { LoginPageBuilder } from 'aggregated_login';
import { GlobalContext, PreferenceConstant, PreferenceUtil, RouterMap, UserInfo } from 'common';
import { FavoriteUtil, HealthFavoritesPageBuilder } from 'health';
import { phoneRouterControl } from 'oh_router';
import { PersonInfoInputPageBuilder, PrivacyAgreementPageBuilder } from 'person';
import { IndexVM } from '../viewmodel/IndexVM';
import { HomePageBuilder } from './HomePage';

@Entry
@ComponentV2
struct Index {
  pageStack: NavPathStack = new NavPathStack()
  vm: IndexVM = new IndexVM();
  @Local userInfo: UserInfo = PersistenceV2.connect(UserInfo, () => new UserInfo())!;

  @Builder
  pageStackMap(name: string, _param: string) {
    phoneRouterControl.getPageBuilder(name)?.builder(_param)
  }

  aboutToAppear() {
    phoneRouterControl.createRouter(this.pageStack)
    // 预注册「我的收藏」路由（person 模块无法直接 import health，需在此注册）
    phoneRouterControl.registerPageBuilder(RouterMap.HEALTH_FAVORITES_PAGE, wrapBuilder(HealthFavoritesPageBuilder))
    this.vm.registerBreakpointListener(this.getUIContext());
    this.vm.displayOrientationListener();
    // 清理之前 bug 版本残留的收藏脏数据
    FavoriteUtil.init();
    //读取状态值，如果为空设置为true
    let isFirstLaunch = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext())
      .get(PreferenceConstant.FIRST_LAUNCH, true) as boolean
    if (isFirstLaunch) {
      // 首次启动预填模拟用户数据，确保健康报告等页面有完整数据可展示
      this.userInfo.isLogin = true;
      this.userInfo.isEditOk = true;
      this.userInfo.id = '10001';
      this.userInfo.nickName = '健康用户';
      this.userInfo.gender = '男';
      this.userInfo.birthday = '1998-06-15';
      this.userInfo.height = 172;
      this.userInfo.weight = 68;
      //隐私政策
      phoneRouterControl.jumpPage({
        pageName: RouterMap.PRIVACY_AGREEMENT_PAGE,
        builder: wrapBuilder(PrivacyAgreementPageBuilder),
        onPop: (_popInfo: PopInfo) => {
          this.gotoLoginOrMainPage();
        }
      })
      return;
    }

    this.gotoLoginOrMainPage();
  }

  gotoLoginOrMainPage() {
    if (this.userInfo.isLogin) {
      phoneRouterControl.replacePage({
        pageName: RouterMap.MAIN_PAGE,
        builder: wrapBuilder(HomePageBuilder)
      })
    } else {
      phoneRouterControl.jumpPage({
        pageName: RouterMap.LOGIN_PAGE,
        builder: wrapBuilder(LoginPageBuilder),
        onPop: (_popInfo: PopInfo) => {
          this.gotoMineOrMainPage();
        }
      })
    }
  }

  gotoMineOrMainPage() {
    if (this.userInfo.isEditOk) {
      phoneRouterControl.replacePage({
        pageName: RouterMap.MAIN_PAGE,
        builder: wrapBuilder(HomePageBuilder)
      })
    } else {
      phoneRouterControl.jumpPage({
        pageName: RouterMap.PERSONAL_INFO_INPUT_PAGE,
        builder: wrapBuilder(PersonInfoInputPageBuilder),
        onPop: (_popInfo: PopInfo) => {
          phoneRouterControl.replacePage({
            pageName: RouterMap.MAIN_PAGE,
            builder: wrapBuilder(HomePageBuilder)
          })
        }
      })
    }
  }

  aboutToDisappear(): void {
    this.vm.unregisterBreakpointListener();
  }

  build() {
    Column() {
      Navigation(this.pageStack) {
      }
      .hideNavBar(true)
      .hideToolBar(true)
      .hideTitleBar(true)
      .hideBackButton(true)
      .mode(NavigationMode.Stack)
      .navDestination(this.pageStackMap)
      .id(phoneRouterControl.defaultRouteName)
    }
  }
}