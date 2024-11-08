import { router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';

const H_STORE = "J_OS"; // 首选项存储名称
const SLOGAN = "USER_SLOGAN"; // 假设标语的 key


//----------------欢迎页面---------------------
@Entry
@Component
struct WelcomePage {
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State mySlogan: string = '无标语'
  build() {
    Column(){

    }
    .height('100%')
    .width('100%')
    .backgroundImage($r('app.media.welcomeBg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .backgroundImagePosition({x:0,y:0})
  }

  aboutToAppear(): void {
    // 获取首选项
    data_preferences.getPreferences(this.context, H_STORE)
      .then((preferences) => {
        preferences.get(SLOGAN, '欢迎使用应用').then((slogan) => {
          this.mySlogan = slogan.toString();  // 更新标语状态
        }).catch((err:Error) => {
          console.error('读取标语失败:', err);
        });
      })
      .catch((err:Error) => {
        console.error('获取Preferences失败:', err);
      });
    this.JumpMain()
  }

  // 跳转到首页
  JumpMain() {
    setTimeout(()=>{
      router.replaceUrl({
          url:"pages/Index",
          params:{
            slogan:this.mySlogan
          }
        })},1000)
  }
}