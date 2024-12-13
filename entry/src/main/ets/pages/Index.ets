import { router } from '@kit.ArkUI';
import HomeContent from '../view/HomeContent';
import SettingsContent from '../view/SettingsContent';

interface GeneratedTypeLiteralInterface_1 {
  slogan: string;
}

@Entry
@Component
@Preview
struct MainPage {
  @State private selectedTab: number = 0 // 0表示首页，1表示个人设置
  @State private slogan: string = "加油！"

  // 构建选项卡
  // @index: 索引
  // @icon: 未选中时图标
  // @selIcon: 选中时图标
  // @text:选项卡文本
  @Builder
  TabBarBuilder(index: number, icon: ResourceStr, selIcon: ResourceStr, text: string) {
    Column() {
      Image(this.selectedTab === index ? selIcon : icon)
        .size({width:30,height:30})
        .margin(7)
      Text(text)
        .fontSize(12)
        .fontFamily('xlwk')
        .fontColor(this.selectedTab === index ? $r('app.color.GREEN3') : $r('app.color.grey2'))
    }
    .width('100%')
  }

  // 构建
  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.selectedTab
    }) {
      TabContent() {
        HomeContent({ slogan: this.slogan })
      }
      .tabBar(this.TabBarBuilder(
        0,
        $r('app.media.ic_public_home'),
        $r('app.media.ic_public_home_filled'),
        "主页"
      )).backgroundColor(Color.White)

      TabContent() {
        SettingsContent({ slogan: this.slogan })
      }
      .tabBar(this.TabBarBuilder(
        1,
        $r('app.media.ic_public_settings'),
        $r('app.media.ic_public_settings_filled'),
        "设置"
      )).backgroundColor(Color.White)
    }
    .width('100%')
    .height('102%')
    .onChange((index: number) => {
      this.selectedTab = index;
    })
    .backgroundColor(Color.White)
  }

  aboutToAppear(): void {
    let routerParams = router.getParams() as GeneratedTypeLiteralInterface_1; // 使用类型断言，该接口包含路由中的所有类型;
    if (routerParams) {
      this.slogan = routerParams.slogan;
    }
  }
}

