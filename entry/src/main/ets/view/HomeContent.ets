// 首页页面内容
@Component
export default struct HomeContent {
  @Prop slogan:string = "加油！"

  @Builder
  build() {
    Column() {
      // 顶部封面部分
      Column() {
        Text(this.slogan)
          .fontSize(20)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .width('100%')
          .height(200)
          .backgroundColor(Color.Blue)
          .padding(20)
      }
      .width('100%')
      .backgroundColor(Color.White)

      // 中间内容部分
      Row() {
        Flex({
          justifyContent: FlexAlign.SpaceAround
        }) {
          // 日程
          Column() {
            Button('日程', { type: ButtonType.Normal, stateEffect: true })
              .onClick(() => {
                console.log('Button onClick')
              })
              .height(100)
              .width(100)
              .borderRadius(40)
          }

          // 占位符1
          Column() {
            Text('占位符')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .fontColor(Color.Black)
              .width(100)
              .height(100)
              .backgroundColor(Color.Gray)
              .borderRadius(10)
              .padding(20)
          }

          // 占位符2
          Column() {
            Text('占位符')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .fontColor(Color.Black)
              .width(100)
              .height(100)
              .backgroundColor(Color.Gray)
              .borderRadius(10)
              .padding(20)
          }
        }
      }
      .width('100%')
      .padding(20)
    }
    .height('100%')
  }
}
