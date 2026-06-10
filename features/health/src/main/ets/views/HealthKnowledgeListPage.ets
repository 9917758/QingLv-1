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
  @Local searchText: string = '';
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
    this.filterList();
  }

  /**
   * 根据搜索关键词过滤文章列表
   */
  filterList(): void {
    const keyword = this.searchText.trim().toLowerCase();
    if (keyword === '') {
      this.displayList = this.allArticles;
    } else {
      this.displayList = this.allArticles.filter((item: HealthKnowledgeSingleModel) => {
        return item.title.toLowerCase().indexOf(keyword) >= 0 ||
          item.subTitle.toLowerCase().indexOf(keyword) >= 0 ||
          item.tag.toLowerCase().indexOf(keyword) >= 0;
      });
    }
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

      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索健康知识...', text: this.searchText })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .borderRadius(18)
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value;
            this.filterList();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.displayList.length === 0) {
        // 空搜索结果
        Column({ space: 8 }) {
          Text('🔍')
            .fontSize(48)
          Text('没有找到相关文章')
            .fontColor('#999999')
            .fontSize(16)
          Text('试试其他关键词吧')
            .fontColor('#BBBBBB')
            .fontSize(14)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
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
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor($r('sys.color.comp_background_list_card'))
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
