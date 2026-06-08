import { AppStorageV2 } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { BreakpointModel, CommonHeader, Constants, OHDialog, OHDialogModel, RouterMap, TCLogger } from 'common';
import { HealthCardRow } from '../comp/HealthCardRow';
import { HealthRunningRow } from '../comp/HealthRunningRow';
import { HealthModel } from '../viewmodel/HealthModel';
import { HealthCardModel } from '../viewmodel/HealthCardModel';
import { HealthKnowledgeRow } from '../comp/HealthKnowledgeRow';
import { phoneRouterControl } from 'oh_router';
import { MessageCenterPageBuilder } from 'person';
import { HealthRunningFoldRow } from '../comp/HealthRunningFoldRow';
import { ReminderPlanPageBuilder } from './ReminderPlanPage';
import { WaterIntakeService } from '../service/WaterIntakeService';
import { HealthGoalService } from '../service/HealthGoalService';
import { HealthScoreService } from '../service/HealthScoreService';
import { CheckinStreakService } from '../service/CheckinStreakService';
import { HealthSuggestionService } from '../service/HealthSuggestionService';
import { AchievementService } from '../service/AchievementService';
import { AnomalyHistoryService } from '../service/AnomalyHistoryService';
import { BmiCalculatorPageBuilder } from './BmiCalculatorPage';
import { AchievementPageBuilder } from './AchievementPage';
import { AnomalyHistoryPageBuilder } from './AnomalyHistoryPage';

const TAG = 'HealthPage';

@Builder
export function HealthPageBuilder() {
  HealthPage()
}

/**
 * @usage: 用于展示健康应用的首页。导航栏（CommonHeader）包括模块名称和右侧的消息中心入口，下方是运动组件(包含if逻辑，根据设备情况提供
 * 不同的运动组件样式)，健康卡片组件，健康知识展示组件。
 * @layout: 页面采用Stack布局,底层采用垂直布局（Column）实现渐变色背景，上层的顶部为CommonHeader导航栏，
 * 下方使用列表（List）展示健康卡片。包含运动数据区域（item）、和由健康卡片列表、底部健康知识组件的列表item分组。
 * @constraints: 如果用户需求不需要消息中心入口，可以在CommonHeader组件中不提供图标(rightImageRes)和跳转逻辑(rightOnClick)
 * @domain: 健康医疗
 * @zhName: 健康主页面
 * @fileType: page
 * @isGen: true
 * @subPage: MessageCenterPage
 * @component: HealthCardRow,HealthRunningRow,HealthKnowledgeRow,HealthRunningFoldRow
 * @image: screenshot/health.jpg
 */
@ComponentV2
export struct HealthPage {
  healthModelVM: HealthModel = HealthModel.instance;
  waterService: WaterIntakeService = WaterIntakeService.instance;
  goalService: HealthGoalService = HealthGoalService.instance;
  scoreService: HealthScoreService = HealthScoreService.instance;
  streakService: CheckinStreakService = CheckinStreakService.instance;
  suggestionService: HealthSuggestionService = HealthSuggestionService.instance;
  achievementService: AchievementService = AchievementService.instance;
  anomalyService: AnomalyHistoryService = AnomalyHistoryService.instance;
  @Local breakPointModel: BreakpointModel = AppStorageV2.connect(BreakpointModel, () => new BreakpointModel())!;
  @Local onReturnClick: () => void = () => {
  }
  @Local onRightClick: () => void = () => {
    phoneRouterControl.jumpPage({
      pageName: RouterMap.MESSAGE_CENTER_PAGE,
      builder: wrapBuilder(MessageCenterPageBuilder)
    })
  }

  // #9 修复：emitter 回调不使用 @Local，保持引用稳定性
  private onHealthDataChange: () => void = () => {
    this.healthModelVM.initDeviceData();
    this.healthModelVM.initHealthData();
  }

  // 监听打卡事件，刷新喝水数据（弹窗打卡可能在 HomePage 触发）
  private onReminderCheckIn: () => void = () => {
    this.waterService.loadToday();
  }

  aboutToAppear(): void {
    try {
      emitter.on(Constants.onHealthDataChange, this.onHealthDataChange);
      emitter.on(Constants.onReminderCheckIn, this.onReminderCheckIn);
    } catch (err) {
      TCLogger.error(TAG, `aboutToAppear error: ${JSON.stringify(err)}`);
    }
    // 加载喝水和目标数据
    this.waterService.loadToday();
    this.waterService.loadGoal();
    this.goalService.loadGoal();
    // 初始化新服务（Mock 模式下生成模拟数据）
    this.scoreService.generateMockHistory();
    this.streakService.loadStreaks();
    // 健康建议基于实际健康数据生成
    this.suggestionService.generate(
      this.healthModelVM.inputVM,
      this.healthModelVM.stepCount,
      this.waterService.todayCount,
      this.waterService.todayGoal
    );
    this.achievementService.generateMock();
    this.anomalyService.generateMock();
  }

  aboutToDisappear(): void {
    try {
      emitter.off(Constants.onHealthDataChange.eventId, this.onHealthDataChange);
      emitter.off(Constants.onReminderCheckIn.eventId, this.onReminderCheckIn);
    } catch (err) {
      TCLogger.error(TAG, `aboutToDisappear error: ${JSON.stringify(err)}`);
    }
  }

  /**
   * #11 根据卡片类型获取对应的 ViewModel（消除 if-else 链）
   */
  private getCardModel(type: number): HealthCardModel {
    if (type === 1) {
      return this.healthModelVM.dataVM;
    } else if (type === 2) {
      return this.healthModelVM.reportVM;
    } else if (type === 3) {
      return this.healthModelVM.sleepVM;
    } else if (type === 4) {
      return this.healthModelVM.bloodPreVM;
    } else if (type === 5) {
      return this.healthModelVM.heartRateVM;
    } else {
      return this.healthModelVM.bloodSugarVM;
    }
  }

  @Builder
  waterGoalPickerBuilder(model: OHDialogModel) {
    Column() {
      TextPicker({
        range: ['4', '5', '6', '7', '8', '9', '10', '12', '15', '20'],
        selected: ['4', '5', '6', '7', '8', '9', '10', '12', '15', '20'].indexOf(model.changeValue as string),
        value: model.changeValue as string
      })
        .height(200)
        .width('100%')
        .onChange((value: string | string[], index: number | number[]) => {
          model.changeValue = value as string;
        })
      Text('杯/天')
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_emphasize'))
        .margin({ top: 8 })
    }
  }

  /**
   * 三环进度条区域
   */
  @Builder
  tripleProgressRingSection() {
    Row() {
      Blank().layoutWeight(1)

      Stack() {
        Progress({
          value: this.healthModelVM.activityHeat / 2,
          total: this.healthModelVM.standardActivityHeat,
          type: ProgressType.Ring
        })
          .width($r('app.float.vp_216'))
          .height($r('app.float.vp_216'))
          .color($r('app.color.color_ED6F21'))
          .style({ strokeWidth: $r('app.float.vp_26') })
          .rotate({ angle: -90 })

        Progress({
          value: this.healthModelVM.exerciseDuration / 2,
          total: this.healthModelVM.standardExerciseDuration,
          type: ProgressType.Ring
        })
          .width($r('app.float.vp_150'))
          .height($r('app.float.vp_150'))
          .color($r('app.color.color_F9A01E'))
          .style({ strokeWidth: $r('app.float.vp_26') })
          .rotate({ angle: -90 })

        Progress({
          value: this.healthModelVM.travelDistance / 2,
          total: this.healthModelVM.standardTravelDistance,
          type: ProgressType.Ring
        })
          .width($r('app.float.vp_84'))
          .height($r('app.float.vp_84'))
          .color($r('app.color.color_46B1E3'))
          .style({ strokeWidth: $r('app.float.vp_26') })
          .rotate({ angle: -90 })
      }
      .width($r('app.float.vp_216'))
      .height($r('app.float.vp_216'))

      Blank().layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .height($r('app.float.vp_108'))
    .clip(true)
  }

  /**
   * 运动数据行区域
   */
  @Builder
  runningRowSection() {
    if (this.healthModelVM.getFoldShow) {
      HealthRunningFoldRow({ healthModelVM: this.healthModelVM });
    } else {
      HealthRunningRow({ healthModelVM: this.healthModelVM });
    }
  }

  /**
   * 健康卡片列表区域
   */
  @Builder
  cardListSection() {
    ForEach(this.healthModelVM.cardList, (item: HealthCardModel, _index: number) => {
      ListItem() {
        HealthCardRow({ healthCardModelVM: this.getCardModel(item.type) })
      }
    }, (item: HealthCardModel, index: number) => `${item.title}_${index}`)
  }

  /**
   * 健康知识行区域
   */
  @Builder
  knowledgeRowSection() {
    HealthKnowledgeRow({ healthModelVM: this.healthModelVM })
  }

  /**
   * 今日喝水进度卡片
   */
  @Builder
  waterIntakeCardSection() {
    Row() {
      Text('💧')
        .fontSize(20)
        .margin({ right: 10 })
      Column({ space: 4 }) {
        Row() {
          Text('今日饮水')
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
          Blank()
          Text(`${this.waterService.todayCount}/${this.waterService.todayGoal} 杯`)
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.Caption_S'))
            .onClick(() => {
              let goalPicker = new OHDialogModel();
              goalPicker.title = '设置每日饮水目标';
              goalPicker.changeValue = this.waterService.todayGoal.toString();
              goalPicker.onValueConfirmClick = (model: OHDialogModel) => {
                const newGoal = Number(model.changeValue);
                if (newGoal > 0 && newGoal <= 20) {
                  this.waterService.setGoal(newGoal);
                }
              };
              goalPicker.childBuilder = this.waterGoalPickerBuilder;
              OHDialog.ShowPopup(goalPicker);
            })
        }
        .width('100%')

        Progress({
          value: this.waterService.todayCount,
          total: this.waterService.todayGoal,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(8)
          .color(this.waterService.isGoalReached() ? '#4CAF50' : '#2196F3')
          .backgroundColor('#E0E0E0')

        if (this.waterService.isGoalReached()) {
          Text('🎉 已达成今日目标！')
            .fontColor('#4CAF50')
            .fontSize($r('sys.float.Caption_S'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(this.waterService.todayCount >= 20 ? '✓' : '+1')
        .width(56)
        .height(32)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.waterService.todayCount >= 20 ? '#CCCCCC' : '#2196F3')
        .borderRadius(16)
        .enabled(this.waterService.todayCount < 20)
        .onClick(() => {
          this.waterService.drink();
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius($r('sys.float.corner_radius_level7'))
  }

  /**
   * 健康目标卡片（仅在有目标体重时显示）
   */
  @Builder
  healthGoalCardSection() {
    if (this.goalService.goalWeight > 0) {
      Row() {
        Text('🎯')
          .fontSize(20)
          .margin({ right: 10 })
        Column({ space: 2 }) {
          Text('健康目标')
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
          Text(this.goalService.getGoalDescription(this.healthModelVM.inputVM.weight))
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.Caption_S'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`目标 ${this.goalService.goalWeight}斤`)
          .fontColor('#FF9800')
          .fontSize($r('sys.float.Caption_S'))
      }
      .width('100%')
      .padding(14)
      .backgroundColor(Color.White)
      .borderRadius($r('sys.float.corner_radius_level7'))
    }
  }

  /**
   * 今日健康评分卡片
   */
  @Builder
  healthScoreCardSection() {
    Row() {
      // 左侧：大号评分
      Column({ space: 2 }) {
        Row({ space: 4 }) {
          Text(this.scoreService.todayScore.toString())
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.scoreService.getScoreColor())
          Text('分')
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 6 })
        }
        Text(this.scoreService.getScoreLevel())
          .fontSize($r('sys.float.Caption_S'))
          .fontColor(this.scoreService.getScoreColor())
      }
      .alignItems(HorizontalAlign.Start)

      Blank().width(20)

      // 右侧：各项子评分（横向排列）
      Row({ space: 16 }) {
        Column({ space: 2 }) {
          Text(this.scoreService.bmiScore.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('BMI')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(this.scoreService.bpScore.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('血压')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(this.scoreService.hrScore.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9C27B0')
          Text('心率')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(this.scoreService.exerciseScore.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
          Text('运动')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius($r('sys.float.corner_radius_level7'))
  }

  /**
   * 健康建议卡片
   */
  @Builder
  healthSuggestionCardSection() {
    Column({ space: 8 }) {
      Row() {
        Text('💡')
          .fontSize(16)
          .margin({ right: 6 })
        Text('健康建议')
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
      }

      ForEach(this.suggestionService.suggestions, (item: import('../service/HealthSuggestionService').HealthSuggestion, _index: number) => {
        Row({ space: 8 }) {
          Text(item.icon)
            .fontSize(16)
          Column({ space: 2 }) {
            Text(item.title)
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Medium)
              .fontColor(item.color)
            Text(item.content)
              .fontSize($r('sys.float.Caption_S'))
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (item: import('../service/HealthSuggestionService').HealthSuggestion, index: number) => `${item.title}_${index}`)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius($r('sys.float.corner_radius_level7'))
  }

  /**
   * 快捷入口行（BMI计算器、成就、异常历史）
   */
  @Builder
  quickEntryRowSection() {
    Row({ space: 10 }) {
      Column({ space: 6 }) {
        Text('📊')
          .fontSize(28)
        Text('BMI计算')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius($r('sys.float.corner_radius_level7'))
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        phoneRouterControl.jumpPage({
          pageName: RouterMap.BMI_CALCULATOR_PAGE,
          builder: wrapBuilder(BmiCalculatorPageBuilder)
        })
      })

      Column({ space: 6 }) {
        Text('🏆')
          .fontSize(28)
        Text(`成就 ${this.achievementService.getUnlockedCount()}/${this.achievementService.achievements.length}`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius($r('sys.float.corner_radius_level7'))
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        phoneRouterControl.jumpPage({
          pageName: RouterMap.ACHIEVEMENT_PAGE,
          builder: wrapBuilder(AchievementPageBuilder)
        })
      })

      Column({ space: 6 }) {
        Text('⚠️')
          .fontSize(28)
        Text(`事件 ${this.anomalyService.getThisWeekCount()}`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .layoutWeight(1)
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius($r('sys.float.corner_radius_level7'))
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        phoneRouterControl.jumpPage({
          pageName: RouterMap.ANOMALY_HISTORY_PAGE,
          builder: wrapBuilder(AnomalyHistoryPageBuilder)
        })
      })
    }
    .width('100%')
  }

  /**
   * 连续打卡显示（在提醒入口内联）
   */
  @Builder
  checkinStreakSection() {
    if (this.streakService.totalStreakDays > 0) {
      Row({ space: 6 }) {
        Text('🔥')
          .fontSize(14)
        Text(`已累计打卡 ${this.streakService.totalStreakDays} 天`)
          .fontColor('#FF6B00')
          .fontSize($r('sys.float.Caption_S'))
      }
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .alignItems(HorizontalAlign.Start)
        .height($r('app.float.vp_327'))
        .width('100%')
        .linearGradient({
          angle: 180,
          colors: [['#524792F3', 0.0], ['#00F1F3F5', 1.0]]
        })

      Column() {
        CommonHeader({
          title: $r('app.string.health_module_name'),
          onReturnClick: this.onReturnClick,
          backgroundColorParam: Color.Transparent,
          rightImageRes: $r('app.media.health_message'),
          rowFlexAlign: FlexAlign.SpaceBetween,
          rightOnClick: this.onRightClick
        })
          .padding({
            left: this.breakPointModel.pagePadding,
            right: this.breakPointModel.pagePadding
          })

        Column() {
          List() {
            ListItem() {
              Column() {
                this.tripleProgressRingSection()

                this.runningRowSection()

                Blank().height($r('app.float.vp_12'))
              }
              .height(this.healthModelVM.getFoldShow ? $r('app.float.vp_216') : $r('app.float.vp_240'))
              .width('100%')
              .padding({
                left: 0
              })
            }

            ListItemGroup({
              space: 12
            }) {
              // 健康评分
              ListItem() {
                this.healthScoreCardSection()
              }
              .width('100%')

              // 快捷入口
              ListItem() {
                this.quickEntryRowSection()
              }
              .width('100%')

              // 健康卡片 — 嵌套 List 实现 2 列布局
              ListItem() {
                List({ space: 12 }) {
                  this.cardListSection()
                }
                .lanes(this.healthModelVM.getFoldShow ? 4 : 2)
                .width('100%')
              }
              .width('100%')

              // 健康建议
              ListItem() {
                this.healthSuggestionCardSection()
              }
              .width('100%')

              // 健康知识
              ListItem() {
                this.knowledgeRowSection()
              }
              .width('100%')

              // 用药与饮水提醒入口
              ListItem() {
                Column() {
                  Row() {
                    Image($r('app.media.health_medication_reminder_icon'))
                      .width(24)
                      .height(24)
                      .margin({ right: 10 })
                    Column({ space: 2 }) {
                      Text('用药与饮水提醒')
                        .fontColor($r('sys.color.font_primary'))
                        .fontSize($r('sys.float.Body_L'))
                        .fontWeight(FontWeight.Medium)
                      Text('管理提醒计划，到点打卡')
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.Caption_S'))
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Image($r('app.media.iconRight'))
                      .width(16)
                      .height(16)
                      .fillColor($r('sys.color.font_tertiary'))
                  }
                  .width('100%')

                  if (this.streakService.totalStreakDays > 0) {
                    Row({ space: 6 }) {
                      Text('🔥')
                        .fontSize(14)
                      Text(`已累计打卡 ${this.streakService.totalStreakDays} 天`)
                        .fontColor('#FF6B00')
                        .fontSize($r('sys.float.Caption_S'))
                    }
                    .width('100%')
                    .margin({ top: 8 })
                  }
                }
                .width('100%')
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius($r('sys.float.corner_radius_level7'))
                .onClick(() => {
                  phoneRouterControl.jumpPage({
                    pageName: RouterMap.REMINDER_PLAN_PAGE,
                    builder: wrapBuilder(ReminderPlanPageBuilder)
                  })
                })
              }
              .width('100%')

              // 今日喝水进度
              ListItem() {
                this.waterIntakeCardSection()
              }
              .width('100%')

              // 健康目标
              ListItem() {
                this.healthGoalCardSection()
              }
              .width('100%')
            }
          }
          .height('100%')
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({
          left: this.breakPointModel.pagePadding - 12,
          right: this.breakPointModel.pagePadding
        })
      }
      .height('100%')
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
