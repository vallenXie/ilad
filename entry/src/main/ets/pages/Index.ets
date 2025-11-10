@Entry
@Component
struct Index {
  @State message: string = 'Hello HarmonyOS';
  @State count: number = 0;

  build() {
    Column() {
      Text(this.message)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 32 })

      Text(`当前计数：${this.count}`)
        .fontSize(20)
        .margin({ bottom: 24 })

      Row() {
        Button('增加 +1')
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.count++;
          })
          .margin({ right: 12 })

        Button('重置')
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.count = 0;
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .backgroundColor('#F5F5F5')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
