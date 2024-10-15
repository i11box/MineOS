import { router } from '@kit.ArkUI';

@Entry
@Component
struct MainPage {
  @State private selectedTab: number = 0 // 0表示首页，1表示个人设置

  build() {
    Column() {
      Row(){
        // 根据selectedTab的状态显示对应的页面
        if (this.selectedTab === 0) {
          HomePage()
        } else {
          SettingsPage()
        }
      }
      Row(){
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {}
          .tabBar("首页")
          TabContent() {}
          .tabBar("设置")
        }
        .vertical(false)
        .width('100%')
        .height(20)
        .scrollable(true)
        .onChange((index:number)=>{ this.selectedTab = index; })
      }
    }
    .height('100%') // 确保Column占满整个页面

  }
}

// 首页页面内容
@Component
struct HomePage {

  @Builder
  build() {
    Column() {
      // 顶部封面部分
      Column() {
        Text('封面，可以加日期，时钟，标语')
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

//
@Component
struct SettingsPage {
  @State private input1Value: string = ''
  @State private input2Value: string = ''

  build() {
    List() {
      // 设置项1
      ListItem() {
        Column(){
          Text('设置项1').fontSize(16).fontColor(Color.Gray)
          TextInput({
            placeholder: '输入框'
          }).width('90%')
        }
      }

      // 个人标语
      ListItem() {
        Column(){
          Text('个人标语').fontSize(16).fontColor(Color.Gray)
          TextInput({
            placeholder: '输入框'
          }).width('90%')
        }
      }
    }
    .width('100%')
  }
}