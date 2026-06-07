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
  @Local onReturnClick: () => void = () => {
    phoneRouterControl.popPage()
  }

  aboutToAppear(): void {
    this.refreshList();
  }

  refreshList(): void {
    for (let article of this.allArticles) {
      article.isFavorited = FavoriteUtil.isFavorited(article.id);
    }
    this.displayList = this.allArticles;
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
