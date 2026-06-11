@ObservedV2
export class HealthCardModel {
  @Trace img: PixelMap | ResourceStr | DrawableDescriptor = ''
  @Trace title: ResourceStr = '';
  @Trace type: number = 1;
  @Trace value: ResourceStr = '';
  @Trace diastolicValue?: ResourceStr = '';
  @Trace desc: ResourceStr = '';
  @Trace icon: PixelMap | ResourceStr | DrawableDescriptor = '';
  @Trace timeStatus: ResourceStr = '';
}

