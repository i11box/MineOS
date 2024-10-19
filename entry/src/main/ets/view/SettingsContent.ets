import data_preferences from '@ohos.data.preferences'

const H_STORE = "J_OS"; // 首选项存储名称
const SLOGAN = "USER_SLOGAN"; // 假设标语的 key

// 设置界面
@Component
export default struct SettingsContent {
  @Prop slogan:string = "加油！"

  SaveSettings(){
    data_preferences.getPreferences(globalThis.getContext(), H_STORE)
      .then((preferences) => {
        preferences.put(SLOGAN, this.slogan);  // 将标语保存到 Preferences
        preferences.flush();  // 刷新保存操作
        this.slogan = this.slogan;  // 更新组件的 slogan 状态
        console.log("标语已保存: " + this.slogan);
      })
      .catch((err:Error) => {
        console.error("保存标语失败: ", err);
      });
  }

  build() {
    // 关于全局应用设置
    Column(){
      Text("全局")
        .alignSelf(ItemAlign.Start)
        .margin({left:10,bottom:5})
        .fontSize(20)
      List() {
        // 个人标语
        ListItem() {
          Column(){
            Text('个人标语').fontSize(16).fontColor(Color.Gray).alignSelf(ItemAlign.Start).margin(10)
            TextInput({
              placeholder: this.slogan
            }).width('90%')
              .margin({left:5,top:5})
              .border({width:0})
              .onChange((value)=>{this.slogan = value})
              .enterKeyType(EnterKeyType.Done)
              .onSubmit((enterKey)=>{
                if(enterKey === EnterKeyType.Done)
                  this.SaveSettings()
              })
          }
        }
      }
      .width('100%')
      .height('94%')
    }
  }

}