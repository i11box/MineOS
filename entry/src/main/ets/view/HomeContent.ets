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
            .fontSize(25)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .height(200)
            .padding(20)
            .fontFamily('xlwk')
        }
      }
      .width('100%')
      .backgroundColor(Color.White)

      // 中间内容部分
      Row() {
        Stack(){
          Image($r('app.media.food'))
            .objectFit(ImageFit.Cover)
            .width('110%')
            .height('105%')
          Grid(){
            // 日程
            GridItem(){
              Column() {
                Image($r('app.media.daily'))
                  .objectFit(ImageFit.ScaleDown)
                  .width('40%')
                  .height('40%')
                  .onClick(() => {
                    router.pushUrl( {url: 'pages/Sche',params:{
                      slogan:this.slogan
                    }})
                  })
                Text('日程')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
                  .fontColor(Color.Black)
                  .padding(10)
                  .fontFamily('xlwk')
              }
            }

            GridItem(){
              // 转盘
              Column() {
                Image($r('app.media.zhuanpan'))
                  .objectFit(ImageFit.ScaleDown)
                  .width("40%").height('40%')
                Text('转盘')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
                  .fontColor(Color.Black)
                  .padding(5)
                  .fontFamily('xlwk')
              }
            }
          }
          .rowsTemplate('1fr 1fr 1fr')
          .columnsTemplate('1fr 1fr 1fr')
          .layoutDirection(GridDirection.Row)
          .maxCount(3)
          .margin({bottom:10})
        }
      }
      .width('100%')
      .padding(20)
    }
    .height('100%')
  }
}