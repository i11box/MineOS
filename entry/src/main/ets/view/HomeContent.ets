import { hilog } from "@kit.PerformanceAnalysisKit"
import { router } from "@kit.ArkUI"
import { url } from "@kit.ArkTS"

// 首页页面内容
@Component
export default struct HomeContent {
  @Prop slogan:string = "加油！"

  @Builder
  build() {
    Column() {
      // 顶部封面部分
      Column() {
        Stack(){
          Image($r('app.media.blackboard')).width('100%').height('30%')
          Text(this.slogan)
            .fontSize(20)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .width('100%')
            .height(200)
            .padding(20)
        }
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
                router.pushUrl( {url: 'pages/Sche',params:{
                  slogan:this.slogan
                }})
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