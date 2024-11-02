// 定义任务接口
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';

interface task {
  name: string;
  begin: string;
  end: string;
  isCompleted: boolean;
}

@Entry
@Component
struct SchedulePage {
  // 页面导航栈，用于管理页面堆栈
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State arr: task[] = [
    {
      name: '跳绳',
      begin: '2024-10-22',
      end: '2024-10-30',
      isCompleted: false,
    },
    {
      name: '跑步',
      begin: '2024-10-22',
      end: '2024-10-30',
      isCompleted: true,
    }
  ];

  // 用于根据导航名称显示不同的页面内容
  @Builder PageMap(name: string, param?: Object) {
    if (name === "TaskDetails") {
      this.taskDetailPage();
    } else {
      this.taskListPage();
    }
  }

  @Builder NavigationTitle() {
    Column() {
      Text('日程规划')
        .fontColor('#182431')
        .fontSize(25)
        .lineHeight(41)
        .fontWeight(700)
        .margin({left:5})
        .baselineOffset(-5)
    }.alignItems(HorizontalAlign.Start)
  }

  @Builder NavigationMenus() {
    Row() {
      Image($r('app.media.ic_public_add'))
        .width(24)
        .height(24)
      Image($r('app.media.ic_public_settings'))
        .width(24)
        .height(24)
        .margin({left:20})
    }.margin({ right:20,top:15 })
  }

  // 主任务列表页面
  @Builder
  taskListPage() {
    Column() {
      // 标题栏
      Row() {
        Text('日程列表').fontSize(20).margin({ left: 20 });
        Image($r('app.media.ic_public_down_arrow')).width('8%')
      }.width('100%');

      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索任务' })
          .width("90%")
          .height(40)
          .borderRadius(8)
          .margin({left:20})
          .borderStyle(BorderStyle.Solid);
      }
      .width("100%")
      .margin({ top: 10, left: 20, right: 20, bottom:15 });

      // 待完成任务列表
      Column() {
        Text('待完成')
          .fontSize(20)
          .margin({ left: 15,bottom:10 })
          .fontWeight(600)
          .width('337')
      }.alignItems(HorizontalAlign.Start)

      List({ space: 10 }) {
        ForEach(this.arr, (item: task, index: number) => {
          ListItem() {
            Row() {
              Image($r('app.media.ic_gallery_material_select_checkbo'))
                .width(24)
                .height(24)
                .margin({right:10})
                .onClick(() => { this.toggleComplete(index) });

              Row() {
                Column(){
                  Text(item.name)
                    .fontSize(18)
                    .fontWeight(400)
                    .baselineOffset(-5)
                    .margin({ bottom: 5 });
                }

                Column() {
                  Text('开始时间：'+ item.begin)
                    .fontSize(13)
                    .opacity(0.6);

                  Text('结束时间：'+ item.end)
                    .fontSize(13)
                    .opacity(0.6);
                }
                .width('100%');
              }
              .onClick(() => this.pageInfos.pushPath({ name: "TaskDetails", param: item}));
            }
            .width('100%');
          }
          .margin({left:12})
          .width('100%')
          .backgroundColor(Color.White)
          .padding(5);
        });
      }.width('100%');

      Blank().margin({bottom:20})

      // 已完成任务标识
      Column() {
        Text('已完成')
          .fontSize(20)
          .margin({ left: 15,bottom:10 })
          .fontWeight(600)
          .width('337')
      }.alignItems(HorizontalAlign.Start)
    };
  }

  // 任务详情页面
  @Builder
  taskDetailPage() {
    Column() {
      Row() {
        Text('任务详情').fontSize(27).margin({ left: 20 });
      }.width('100%');

      // 显示任务详细信息
      Row() {
        // 这里可以动态展示任务的详细信息
        Text('任务详情内容将在这里显示...').margin({ top: 20 });
      }.width('100%');
    }
  }

  build() {
    Column() {
      Navigation(this.pageInfos) {
        Column(){Blank().margin({bottom:20})}
        // 主任务列表页面的内容
        this.taskListPage();
      }
      .hideBackButton(false)
      .title('日程管理', {
        paddingStart: LengthMetrics.vp(16),
        paddingEnd: LengthMetrics.vp(32),
      })
      .titleMode(NavigationTitleMode.Mini)
      .mode(NavigationMode.Stack) // 分栏模式，可以改为堆栈模式 (Stack) 以适应页面需求
      .navDestination(this.PageMap) // 使用 PageMap 控制页面内容
      .title(this.NavigationTitle)
      .menus(this.NavigationMenus)
      .titleMode(NavigationTitleMode.Mini)
    }
    .width('100%')
    .height('100%');
  }

  // 切换任务完成状态
  toggleComplete(index: number) {
    this.arr[index].isCompleted = !this.arr[index].isCompleted;
  }

  // 删除任务
  deleteTask(index: number) {
    this.arr.splice(index, 1);
  }
}
