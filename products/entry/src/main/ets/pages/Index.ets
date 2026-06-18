import { PersistenceV2 } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { GlobalContext, PreferenceConstant, PreferenceUtil, RouterMap, UserInfo, NetworkConfig, AuthToken, Constants, HttpUtil } from 'common';
import { FavoriteUtil, HealthFavoritesPageBuilder } from 'health';
import { BmiCalculatorPageBuilder } from 'health/src/main/ets/views/BmiCalculatorPage';
import { AchievementPageBuilder } from 'health/src/main/ets/views/AchievementPage';
import { AnomalyHistoryPageBuilder } from 'health/src/main/ets/views/AnomalyHistoryPage';
import { BackendLoginPageBuilder } from 'health/src/main/ets/views/BackendLoginPage';
import { HealthDataService } from 'health';
import { WaterIntakeService } from 'health';
import { ReminderService } from 'health';
import { CheckinStreakService } from 'health';
import { HealthGoalService } from 'health';
import { HealthScoreService, AchievementService, AnomalyHistoryService, SleepQualityService } from 'health';
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
    phoneRouterControl.registerPageBuilder(RouterMap.BMI_CALCULATOR_PAGE, wrapBuilder(BmiCalculatorPageBuilder))
    phoneRouterControl.registerPageBuilder(RouterMap.ACHIEVEMENT_PAGE, wrapBuilder(AchievementPageBuilder))
    phoneRouterControl.registerPageBuilder(RouterMap.ANOMALY_HISTORY_PAGE, wrapBuilder(AnomalyHistoryPageBuilder))
    this.vm.registerBreakpointListener(this.getUIContext());
    this.vm.displayOrientationListener();
    // 清理之前 bug 版本残留的收藏脏数据
    FavoriteUtil.init();
    // 加载后端服务器地址配置
    NetworkConfig.load();
    // 监听退出登录事件（SetupPage 发出）
    emitter.on(Constants.onLogout, () => {
      // 清除所有 Service 的内存缓存，防止下一个用户读到旧数据
      HealthDataService.instance.clearCache();
      WaterIntakeService.instance.clearCache();
      ReminderService.invalidateCache();
      CheckinStreakService.instance.clearCache();
      HealthGoalService.instance.clearCache();
      HealthScoreService.instance.clearCache();
      AchievementService.instance.clearCache();
      AnomalyHistoryService.instance.clearCache();
      SleepQualityService.instance.clearCache();
      this.userInfo.isLogin = false;
      phoneRouterControl.replacePage({
        pageName: RouterMap.LOGIN_PAGE,
        builder: wrapBuilder(BackendLoginPageBuilder)
      });
    });
    //读取状态值，如果为空设置为true
    let isFirstLaunch = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext())
      .get(PreferenceConstant.FIRST_LAUNCH, true) as boolean
    if (isFirstLaunch) {
      // 标记首次启动完成，下次不再走这段逻辑
      PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext())
        .put(PreferenceConstant.FIRST_LAUNCH, false);
      // 首次启动：显示隐私协议，同意后进入登录页
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
    if (this.userInfo.isLogin || AuthToken.isLoggedIn()) {
      // 后台静默刷新 Token（续期 7 天）
      HttpUtil.post<Record<string, string>>('/api/auth/refresh').then(resp => {
        if (resp.data && resp.data['access_token']) {
          AuthToken.save(resp.data['access_token']);
        }
      }).catch(() => {});

      phoneRouterControl.replacePage({
        pageName: RouterMap.MAIN_PAGE,
        builder: wrapBuilder(HomePageBuilder)
      })
    } else {
      phoneRouterControl.jumpPage({
        pageName: RouterMap.LOGIN_PAGE,
        builder: wrapBuilder(BackendLoginPageBuilder),
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
    this.vm.unregisterDisplayListeners();
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