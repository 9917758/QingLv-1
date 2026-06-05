import { BreakpointModel, CommonHeader, RouterMap, BarVM } from 'common'
import { OHPage, phoneRouterControl } from 'oh_router'
import { healthKnowledge } from '../constants/constants';
import { HealthKnowledgeSingleModel } from '../viewmodel/HealthKnowledgeSingleModel';
import { HealthKnowledgeSingleRow } from '../comp/HealthKnowledgeSingleRow';
import { HealthKnowledgeDetailPageBuilder } from './HealthKnowledgeDetailPage';
import { FavoriteUtil } from '../util/FavoriteUtil';
import { AppStorageV2 } from '@kit.ArkUI';
import { BreakpointNameEnum } from 'common/src/main/ets/constant/GridRowColSetting';

@Builder
export function HealthKnowledgeListPageBuilder() {
  HealthKnowledgeListPage()
}

@ComponentV2
export struct HealthKnowledgeListPage {
  @Local allArticles: HealthKnowledgeSingleModel[] = healthKnowledge;
  @Local displayList: HealthKnowledgeSingleModel[] = [];
  @Local breakPointModel: BreakpointModel = AppStorageV2.connect(BreakpointModel, () => new BreakpointModel())!;
  @Local showFavoritesOnly: boolean = false;
  @Local favoriteCount: number = 0;
  @Local onReturnClick: () => void = () => {
    phoneRouterControl.popPage()
  }

  aboutToAppear(): void {
    this.refreshList();
  }

  refreshList(): void {
    // 同步所有文章的收藏状态
    for (let article of this.allArticles) {
      article.isFavorited = FavoriteUtil.isFavorited(article.id);
    }
    this.favoriteCount = FavoriteUtil.getFavoriteCount();
    this.applyFilter();
  }

  applyFilter(): void {
    if (this.showFavoritesOnly) {
      this.displayList = this.allArticles.filter((item) => item.isFavorited);
    } else {
      this.displayList = this.allArticles;
    }
  }

  toggleFilter(): void {
    this.showFavoritesOnly = !this.showFavoritesOnly;
    this.applyFilter();
  }

  // 页面内容渲染
  @Builder
  render() {
    Column() {
      CommonHeader({
        title: $r('app.string.health_knowledge_list_title'),
        onReturnClick: this.onReturnClick,
        leftImageRes: $r('app.media.ic_backward2')
      })

      // 筛选Tab行
      Row({ space: 0 }) {
        Row() {
          Text('全部')
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(this.showFavoritesOnly ? FontWeight.Regular : FontWeight.Medium)
            .fontColor(this.showFavoritesOnly ? $r('sys.color.font_secondary') : '#117CFF')
          Blank().width($r('app.float.vp_8'))
          Text(`(${this.allArticles.length})`)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.font_tertiary'))
        }
        .padding({ top: 8, bottom: 8, left: 16, right: 16 })
        .borderRadius($r('sys.float.corner_radius_level6'))
        .backgroundColor(this.showFavoritesOnly ? Color.Transparent : '#E8F0FE')
        .onClick(() => {
          if (this.showFavoritesOnly) {
            this.toggleFilter();
          }
        })

        Blank().width($r('app.float.vp_8'))

        Row() {
          Text('我的收藏')
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(this.showFavoritesOnly ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.showFavoritesOnly ? '#117CFF' : $r('sys.color.font_secondary'))
          Blank().width($r('app.float.vp_8'))
          Text(`(${this.favoriteCount})`)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.font_tertiary'))
        }
        .padding({ top: 8, bottom: 8, left: 16, right: 16 })
        .borderRadius($r('sys.float.corner_radius_level6'))
        .backgroundColor(this.showFavoritesOnly ? '#E8F0FE' : Color.Transparent)
        .onClick(() => {
          if (!this.showFavoritesOnly) {
            this.toggleFilter();
          }
        })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .width('100%')

      List({ space: 12 }) {
        ForEach(this.displayList, (item: HealthKnowledgeSingleModel,
          _index: number) => {
          ListItem() {
            HealthKnowledgeSingleRow({
              knowledgeSingleModelVM: item
            })
              .onClick(() => {
                phoneRouterControl.jumpPage({
                  pageName: RouterMap.HEALTH_KNOWLEDGE_DETAIL_PAGE,
                  builder: wrapBuilder(HealthKnowledgeDetailPageBuilder),
                  param: item,
                  onPop: () => {
                    this.refreshList();
                  }
                })
              })
          }
        }, (item: HealthKnowledgeSingleModel, index: number) => `${item.id}_${index}`)

        if (this.displayList.length === 0) {
          ListItem() {
            Column() {
              Image($r('app.media.health_data_icon'))
                .width($r('app.float.vp_48'))
                .height($r('app.float.vp_48'))
                .opacity(0.3)
              Blank().height($r('app.float.vp_8'))
              Text('暂无收藏文章')
                .fontColor($r('sys.color.font_tertiary'))
                .fontSize($r('sys.float.Body_M'))
            }
            .width('100%')
            .padding({ top: 60 })
            .alignItems(HorizontalAlign.Center)
          }
        }

        ListItem().height(px2vp(BarVM.instance.aiBarH))
      }
      .height('100%')
      .width('100%')
      .scrollBar(BarState.Off)
      .lanes(this.getFoldShow ? 2 : 1, $r('app.float.vp_12'))
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#FFF1F3F5')
  }

  build() {
    OHPage({
      childBuilder: () => {
        this.render();
      },
      useSafePadding: true
    })
  }

  @Computed
  get getFoldShow(): boolean {
    if (this.breakPointModel.currentBreakpoint === BreakpointNameEnum.SM) {
      return false;
    } else {
      return true;
    }
  }
}

