import router from '@ohos.router';

interface task {
  name: string;
  begin: string;
  end: string;
  isCompleted:boolean;
}

@Entry
@Component
struct Sche {
  @State message: string = 'Hello World';

  // 任务列表，需要从数据库获取
  @State arr:task[]= [
    {
      name:'跳绳',
      begin:'2024-10-22',
      end:'2024-10-30',
      isCompleted:false
    },
    {
      name:'跳绳',
      begin:'2024-10-22',
      end:'2024-10-30',
      isCompleted:false
    }
  ]

  @Builder itemEnd(index:number){
    Row () {
      Image($r("app.media.ic_public_delete"))
        .width(32)
        .height(32)
        .margin(4)
        .onClick(()=>{this.deleteTask(index)})
    }.padding(4).justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Column(){
      Row(){
        Row(){
          Image($r('app.media.ic_public_back')).width('8%').onClick(()=>{ router.back()}).margin({right:10})
          Text('日程列表').fontSize(27)
          Image($r('app.media.ic_public_down_arrow')).width('8%')
        }.margin({top:10,left:20,bottom:10})
        .justifyContent(FlexAlign.Start)
        .width('70%')
        Row(){
          Image($r('app.media.ic_public_add')).width('8%')
          Image($r('app.media.ic_public_settings')).width('8%')
        }.justifyContent(FlexAlign.End)
      }.width('100%')

      Blank().height('1%')

      // 搜索框
      Row() {
        Image($r('app.media.ic_public_input_search')).width('10%').alignSelf(ItemAlign.End).margin({right:10})
        TextInput({placeholder:'搜索任务'})
          .width("90%")
          .height('5%')
          .padding({ top: 8, bottom: 8, left: 16, right: 16 })
          //.backgroundColor(Color.White)
          .borderRadius(8)
          .borderStyle(BorderStyle.Solid)
      }.margin({ bottom: 10, left: 20, right: 20 })
      .width("80%")
      .justifyContent(FlexAlign.Center);

      Blank().height('2%')

      Row(){
        Text('待完成').fontSize('20').margin({left:15}).fontWeight(600)
        Image($r('app.media.ic_public_down_arrow')).width('8%')
      }
      Blank().height('1.5%')

      List({space:10}){
        ForEach(this.arr,(item:task, index:number)=>{
          ListItem(){
            Row(){
              Image($r('app.media.ic_gallery_material_select_checkbo'))
                .width(24)
                .height(24)
                .onClick(()=>{this.toggleComplete(index)});

              Column() {
                Text(item.name)
                  .fontSize(15)
                  .fontWeight(500)
                  .margin({ bottom: 5 })
                  .alignSelf(ItemAlign.Start)

                Row() {
                  Text(item.begin)
                    .fontSize(13)
                    .opacity(0.6)

                  Text(' 到 ')
                    .fontSize(13)
                    .opacity(0.6);

                  Text(item.end)
                    .fontSize(13)
                    .opacity(0.6);
                }.justifyContent(FlexAlign.Start)
                .width('100%')
              }
              .margin({left:4})
              .padding({left:10})
              .onClick(()=>this.viewTaskDetails(item))
            }.width('100%')
             .justifyContent(FlexAlign.Start)
          }
          .margin({left:10})
          .width('100%')
          .backgroundColor(Color.White)
          .padding(5)
          .swipeAction({
              end:{
                builder:()=>{this.itemEnd(index)}
              }
            })
          })
        }
        .width('100%')
      Blank().height('3%')
      Row(){
        Text('已完成').fontSize('20').margin({left:15}).fontWeight(600)
        Image($r('app.media.ic_public_down_arrow')).width('8%')
      }
      // 右下角悬浮按钮
      Image($r('app.media.ic_public_add_norm'))
        .width('20%')
        .position({x:'800px',y:'1800px'})
        .onClick(() => {
          // 添加任务功能
        });
      }.alignItems(HorizontalAlign.Start)
  }

  // 切换任务完成状态
  toggleComplete(index: number) {
    this.arr[index].isCompleted = !this.arr[index].isCompleted;
  }

  // 删除任务
  deleteTask(index: number) {
    this.arr.splice(index, 1);
  }

  // 查看任务详情
  viewTaskDetails(item: task) {
    // 跳转到详情页面，可以传递参数
    router.pushUrl({
      url: 'pages/TaskDetail',
      params: { task: item }
    });
  }
}