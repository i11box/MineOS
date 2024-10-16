@Entry
@Component
struct WelcomePage {
  build() {
    Column(){

    }
    .height('100%')
    .width('100%')
    .backgroundImage($r('app.media.welcomeBg'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .backgroundImagePosition({x:0,y:0})
  }
}