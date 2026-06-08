import { RouterMap } from 'common';
import { phoneRouterControl } from 'oh_router';
import { healthKnowledge } from '../constants/constants';
import { HealthModel } from '../viewmodel/HealthModel';
import { HealthKnowledgeDetailPageBuilder } from '../views/HealthKnowledgeDetailPage';
import { HealthKnowledgeListPageBuilder } from '../views/HealthKnowledgeListPage';
import { FavoriteUtil } from '../util/FavoriteUtil';
import { HealthKnowledgeSingleModel } from '../viewmodel/HealthKnowledgeSingleModel';

/**
 * @usage: 每日健康小常识卡片，展示今日推荐的随机健康小贴士。每天根据日期自动切换推荐的科普文章。
 * 点击卡片可直接进入文章详情，点击"查看更多"进入文章列表页。
 * @layout: 垂直布局（Column），顶部为标题行"每日健康小常识"+ "查看更多 >"，
 * 下方为今日推荐卡片（Stack布局），包含背景图片、分类标签和文章标题预览。
 * @zhName: 每日健康知识卡片
 */
@ComponentV2
export struct HealthKnowledgeRow {
  @Param @Require healthModelVM: HealthModel;
  @Local todayArticle: HealthKnowledgeSingleModel | null = null;
  private tagColors: Record<string, string> = {
    '饮食': '#FF6B6B',
    '运动': '#4ECDC4',
    '睡眠': '#7C5CFC',
    '心理': '#FFB347'
  };

  aboutToAppear(): void {
    this.pickArticle();
  }

  /** 选取今日文章（同一天相同，可手动"换一换"） */
  pickArticle(): void {
    const index = FavoriteUtil.getTodayArticleIndex(healthKnowledge.length);
    this.todayArticle = healthKnowledge[index];
    if (this.todayArticle) {
      this.todayArticle.isFavorited = FavoriteUtil.isFavorited(this.todayArticle.id);
    }
  }

  /** 手动随机换一篇（区别于今日推荐的另一篇） */
  refreshArticle(): void {
    let newIndex: number;
    const todayIndex = FavoriteUtil.getTodayArticleIndex(healthKnowledge.length);
    do {
      newIndex = Math.floor(Math.random() * healthKnowledge.length);
    } while (newIndex === todayIndex && healthKnowledge.length > 1);
    this.todayArticle = healthKnowledge[newIndex];
    if (this.todayArticle) {
      this.todayArticle.isFavorited = FavoriteUtil.isFavorited(this.todayArticle.id);
    }
  }

  build() {
    Column() {
      Column() {
        // 标题行
        Row() {
          Row({ space: 6 }) {
            Text($r('app.string.health_knowledge_title'))
              .fontColor(Color.Black)
              .fontSize($r('sys.float.Body_L'))
              .fontWeight(FontWeight.Medium)
            // 换一换按钮
            Image($r('app.media.health_message'))
              .width(16)
              .height(16)
              .opacity(0.5)
              .onClick(() => this.refreshArticle())
          }

          Row() {
            Text($r('app.string.health_all_title'))
              .fontColor($r('app.color.color_999'))
              .fontSize($r('sys.float.Body_M'))
            Blank().width($r('app.float.vp_4'))
            Image($r('app.media.iconRight'))
              .width($r('app.float.vp_20'))
              .height($r('app.float.vp_20'))
          }
          .onClick(() => {
            phoneRouterControl.jumpPage({
              pageName: RouterMap.HEALTH_KNOWLEDGE_LIST_PAGE,
              builder: wrapBuilder(HealthKnowledgeListPageBuilder)
            })
          })
        }
        .width('100%')
        .height($r('app.float.vp_28'))
        .justifyContent(FlexAlign.SpaceBetween)

        Blank().height($r('app.float.vp_8'))

        // 今日推荐卡片
        if (this.todayArticle) {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(this.todayArticle.img)
              .objectFit(ImageFit.Cover)
              .width('100%')
              .height('100%')
              .borderRadius($r('sys.float.corner_radius_level7'))

            // 底部渐变遮罩
            Column()
              .width('100%')
              .height($r('app.float.vp_50'))
              .linearGradient({
                angle: 180,
                colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0.6)', 1.0]]
              })
              .borderRadius({
                bottomLeft: $r('sys.float.corner_radius_level7'),
                bottomRight: $r('sys.float.corner_radius_level7')
              })

            // 文字内容
            Column() {
              if (this.todayArticle.tag) {
                Text(this.todayArticle.tag)
                  .fontSize($r('sys.float.Caption_S'))
                  .fontColor(Color.White)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(this.tagColors[this.todayArticle.tag] ?? '#888888')
                  .borderRadius($r('sys.float.corner_radius_level2'))
              }
              Blank().height($r('app.float.vp_4'))
              Text(this.todayArticle.subTitle)
                .fontColor(Color.White)
                .fontSize($r('sys.float.Body_M'))
                .fontWeight(FontWeight.Medium)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: $r('app.float.vp_12'),
              right: $r('app.float.vp_12'),
              bottom: $r('app.float.vp_12')
            })
          }
          .width('100%')
          .height($r('app.float.vp_90'))
          .onClick(() => {
            phoneRouterControl.jumpPage({
              pageName: RouterMap.HEALTH_KNOWLEDGE_DETAIL_PAGE,
              builder: wrapBuilder(HealthKnowledgeDetailPageBuilder),
              param: this.todayArticle as HealthKnowledgeSingleModel
            })
          })
        }
      }
      .backgroundColor(Color.White)
      .width('100%')
      .borderRadius($r('sys.float.corner_radius_level7'))
      .padding($r('app.float.vp_16'))
      .clip(true)
    }
    .width('100%')
  }
}