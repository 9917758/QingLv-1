import { CommonHeader, RouterMap, BarVM } from 'common'
import { OHPage, phoneRouterControl } from 'oh_router'
import { healthKnowledge } from '../constants/constants';
import { HealthKnowledgeSingleModel } from '../viewmodel/HealthKnowledgeSingleModel';
import { HealthKnowledgeSingleRow } from '../comp/HealthKnowledgeSingleRow';
import { HealthKnowledgeDetailPageBuilder } from './HealthKnowledgeDetailPage';
import { FavoriteUtil } from '../util/FavoriteUtil';

@Builder
export function HealthFavoritesPageBuilder() {
  HealthFavoritesPage()
}

@ComponentV2
export struct HealthFavoritesPage {
  @Local allArticles: HealthKnowledgeSingleModel[] = healthKnowledge;
  @Local displayList: HealthKnowledgeSingleModel[] = [];
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
    this.displayList = this.allArticles.filter((item) => item.isFavorited);
  }

  navigateToDetail(item: HealthKnowledgeSingleModel): void {
    phoneRouterControl.jumpPage({
      pageName: RouterMap.HEALTH_KNOWLEDGE_DETAIL_PAGE,
      builder: wrapBuilder(HealthKnowledgeDetailPageBuilder),
      param: item,
      onPop: () => {
        this.refreshList();
      }
    })
  }

  @Builder
  render() {
    Column() {
      CommonHeader({
        title: '我的收藏',
        onReturnClick: this.onReturnClick,
        leftImageRes: $r('app.media.ic_backward2')
      })

      if (this.displayList.length === 0) {
        Column() {
          Text('🤍')
            .fontSize(48)
          Blank().height(12)
          Text('暂无收藏文章')
            .fontColor($r('sys.color.font_tertiary'))
            .fontSize($r('sys.float.Body_M'))
          Blank().height(6)
          Text('浏览健康知识时点击 ❤️ 即可收藏')
            .fontColor($r('sys.color.font_tertiary'))
            .fontSize($r('sys.float.Caption_S'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.displayList, (item: HealthKnowledgeSingleModel, _index: number) => {
            ListItem() {
              HealthKnowledgeSingleRow({
                knowledgeSingleModelVM: item
              })
                .onClick(() => this.navigateToDetail(item))
            }
          }, (item: HealthKnowledgeSingleModel, index: number) => `${item.id}_${index}`)

          ListItem().height(px2vp(BarVM.instance.aiBarH))
        }
        .height('100%')
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
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
}
