@ObservedV2
export class HealthKnowledgeSingleModel {
  @Trace id: string = '';
  @Trace img: PixelMap | ResourceStr | DrawableDescriptor = ''
  @Trace title: string = '';
  @Trace subTitle: string = '';
  @Trace content: string = '';
  @Trace tag: string = ''; // 分类标签：饮食、运动、睡眠、心理
  @Trace isFavorited: boolean = false;
}