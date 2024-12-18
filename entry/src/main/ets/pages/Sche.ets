import { router } from '@kit.ArkUI';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import * as DataBase from '../data/entity';
import * as Schedule from '../packages/schedule/schedule';
import { ScheduleList } from '../packages/schedule/schedule';
import {TaskDetailsBuilder} from './TaskDetails'
import {formatDateTime} from '../packages/core/date'

interface GeneratedTypeLiteralInterface_1 {
  slogan: string;
}

enum ListType {LIST,VIEW};

@Builder
export function TaskListBuilder() {
  taskListPage()
}

//--------------路由根页面---------------------
@Entry
@Component
struct SchedulePage {
  // 页面导航栈，用于管理页面堆栈
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  private scroller:Scroller = new Scroller()


  //-------------子页面-----------------------
  @Builder PageMap(name: string, param?: Object) {
    Scroll(this.scroller){
      if (name === "TaskDetails" && param) {
        TaskDetailsBuilder(param)
      } else {
        taskListPage()
      }
    }.scrollBar(BarState.On)
    .scrollBarColor(Color.Gray)
  }

  //-------------构建-----------------------
  build() {
    Navigation(this.pageInfos) {
      Column(){Blank().margin({bottom:20})}
    }
    .hideBackButton(false)
    .title('日程管理', {
      backgroundColor:'#FBE2B2',
      backgroundBlurStyle:BlurStyle.BACKGROUND_THIN,
      paddingStart: LengthMetrics.vp(16),
      paddingEnd: LengthMetrics.vp(32),
    })
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap) // 使用 PageMap 控制页面内容
    .titleMode(NavigationTitleMode.Mini)
    .width('100%')
    .height('100%');
  }

  aboutToAppear(): void {
    this.pageInfos.pushPath({name:"TaskList"});
  }

}

//-------------主任务列表页面---------------------
@Component
struct taskListPage {


  @Consume('pageInfos') pageInfos: NavPathStack;
  @State arr: Schedule.Schedule[] = []
  @State arrDone:Schedule.Schedule[] = []
  @State arrNotDone:Schedule.Schedule[] = []

  @State private isListManageShow:boolean = false;
  @State private isAddScheduleShow:boolean = false;
  @State private isAddSubScheduleShow:boolean = false;
  @State private searchChangeValue:string = '';
  @State private searchSubmitValue:string = '';
  @State private isListOrView:ListType = ListType.LIST

  private scheduleIsWatching:Schedule.Schedule = new Schedule.Schedule();
  private slogan:string = '';

  //------------添加日程页所用变量--------------
  private circularUnit:string [] = ['年','月','日','无周期'];
  private currentDate:Date = new Date();
  private circularUnitNum:number [] = [365,30,1,0];
  private circularUnitSelected:number = 3;

  @State content:string = '';
  @State name:string = '';
  @State startTime:Date = this.currentDate;
  @State endTime:Date = this.currentDate;
  @State circular:number = 0;
  @State prior:number = 0;
  @State private startTimeSelected:Date = this.currentDate;
  @State private endTimeSelected:Date = this.currentDate;
  //----------------------------------------

  //--------------添加日程列表页所用变量-----------
  @State public listArr: Schedule.ScheduleList[] = []
  @State private list:Schedule.ScheduleList = new ScheduleList(0,'')
  addListDialogController?: CustomDialogController | null = new CustomDialogController({
    builder:AddListDialog({
      confirmFlushScheduleList:()=>{this.flushScheduleLists()},
      closeSelf:  (): void => { this.addListDialogController?.close(); }
    }),
    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      console.log("dialog onWillDismiss")
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss()
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss()
      }
    },
    autoCancel:true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: false,
    cornerRadius: 20,
    width: 300,
    height: 400,
    backgroundColor: Color.White,
  })

  //---------------添加视图所用变量-------------
  @State private view:Schedule.View = new Schedule.View(0,null,'',[]);
  @State viewName:string = '';
  @State viewDays:number|null = null;
  @State viewListSns:number[] = [];
  @State selectedLists:number[] = [];
  @State private isAddViewShow:boolean = false;
  @State viewArr:Schedule.View[] = [];
  private taskListScroller:Scroller = new Scroller;
  addViewDialogController?: CustomDialogController | null = new CustomDialogController({
    builder:AddViewDialog({
      listArr:this.listArr,
      confirmFlushView:()=>{this.flushViews()},
      closeSelf:  (): void => { this.addViewDialogController?.close(); }
    }),
    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      console.log("dialog onWillDismiss")
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss()
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss()
      }
    },
    autoCancel:true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: false,
    cornerRadius: 20,
    width: 300,
    height: 400,
    backgroundColor: Color.White,
    shadow: ({ radius: 20, color: Color.Grey, offsetX: 50, offsetY: 0}),
  })
  //-------------标题栏-----------------------
  @Builder NavigationTitle() {
    Column() {
      Text('日程规划').fontFamily('xlwk')
        .fontColor('#182431')
        .fontSize(25)
        .lineHeight(41)
        .fontWeight(700)
        .margin({left:5})
        .baselineOffset(-5)
    }.alignItems(HorizontalAlign.Start)
  }

  //-------------右上角工具栏-----------------------
  @Builder NavigationMenus() {
    Row() {
      Image($r('app.media.ic_public_add'))
        .width(24)
        .height(24)
        .onClick(()=>{
          this.isAddScheduleShow = true;
        })
        .bindSheet($$this.isAddScheduleShow, this.AddSchedulePage('添加新日程'), {
          height: 600,
          onWillDisappear:()=>{this.isAddScheduleShow = false;}
        })
      Image($r('app.media.ic_public_settings'))
        .width(24)
        .height(24)
        .margin({left:20})
        .bindMenu(this.ListManageMenu)
    }.margin({ right:20,top:15 })
  }

  //----------侧滑项----------------------------
  @Builder itemEnd(index: number,isNeedSubSchedule:boolean) {

    Row(){
      // 构建尾端滑出组件

    Image($r('app.media.ic_public_delete'))
      .width(20)
      .height(20)
      .onClick(() => {
        // 建议使用this.getUIContext().showAlertDialog()
        AlertDialog.show(
          {
            title: '是否删除该日程？',
            message: '该操作无法撤回',
            autoCancel: true,
            alignment: DialogAlignment.Default,
            gridCount: 4,
            offset: { dx: 0, dy: -20 },
            primaryButton: {
              value: '取消',
              action: () => {
              }
            },
            secondaryButton: {
              enabled: true,
              defaultFocus: true,
              style: DialogButtonStyle.HIGHLIGHT,
              value: '删除',
              action: () => {
                let context = this.getUIContext().getHostContext()
                if(context)
                  DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
                    if(isNeedSubSchedule){
                      await db.deleteScheduleListScheduleByScheduleSn(this.arrNotDone[index].scheduleSn);
                      await db.deleteSchedule(this.arrNotDone[index].scheduleSn);
                      this.arrNotDone.splice(index,1); // 视图上删除
                    }
                    else{
                      await db.deleteScheduleListScheduleByScheduleSn(this.arrDone[index].scheduleSn);
                      await db.deleteSchedule(this.arrDone[index].scheduleSn);
                      this.arrDone.splice(index,1);
                    }
                  })
              }
            },
            cancel: () => {
            }
          }
        )
      })
      // 添加子日程 TODO:子日程的bo没设计好
      // if(isNeedSubSchedule){
      //   Button({ type: ButtonType.Circle }) {
      //     Image($r('app.media.ic_public_add'))
      //       .width(20)
      //       .height(20)
      //       .onClick(()=>{
      //         this.isAddSubScheduleShow = true;
      //       })
      //       .bindSheet($$this.isAddSubScheduleShow, this.AddSchedulePage('添加子日程',this.arrNotDone[index].scheduleSn), {
      //         height: 600,
      //         onWillDisappear:()=>{this.isAddSubScheduleShow = false;}
      //       })
      //   }
      // }
    }
  }

  //-------------添加视图页面-----------------------
  @Builder AddViewPage() {
    Column() {
      // 标题
      Text(`创建视图`).fontSize(20).fontWeight(600).margin({ bottom: 20 });
      // 输入视图名
      Column(){
        Text('视图名称').margin({left:5,bottom:10})
        TextInput()
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({left:5,bottom:10})
          .onChange((value)=>{
            this.viewName = value;
          })
      }.alignItems(HorizontalAlign.Start)

      // 时间范围为未来几天
      Column() {
        Text('时间范围').fontSize(16).margin({left:5}).width('89%')
        Row(){
          TextInput()
            .width('30%')
            .height(35)
            .fontSize(16)
            .onChange((value:string)=>{
              if(!Number.isNaN(Number(value)))
                this.viewDays = Number(value) * this.circularUnitNum[this.circularUnitSelected]
            })
          TextPicker({range:this.circularUnit, selected:this.circularUnitSelected})
            .onChange((value:string|string [])=>{
              if(!Number.isNaN(Number(value)))
                this.viewDays = Number(value) * this.circularUnitNum[this.circularUnitSelected]
            })
            .margin({left:15})
            .height('8%')
            .width('20%')
        }
      }.alignItems(HorizontalAlign.Start)

      // 选中的列表
      Column() {
        List(){
          ForEach(this.listArr,(item:Schedule.ScheduleList, index:number)=>{
            ListItem(){
              Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                Checkbox({ name: 'checkbox_'+index.toString(), group: 'listGroup' })
                  .selectedColor(0x39a2db)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .onChange((value: boolean) => {
                    if(value)
                      this.selectedLists.push(item.listSn);
                    else {
                      const itemIndex = this.selectedLists.findIndex(sn => sn === item.listSn);
                      if (itemIndex !== -1) {
                        this.selectedLists.splice(itemIndex, 1);
                      }
                    }
                  })
                  .unselectedColor(Color.Gray)
                  .width(30)
                  .height(30)
                Text(item.listName).fontSize(20)
              }
            }
          })
        }
      }

      // 提交按钮
      Button('提交')
        .margin({top:40})
        .width('80%')
        .height(40)
        .backgroundColor('#4CAF50')
        .onClick(async () => {
          let context = this.getUIContext().getHostContext()
          this.viewListSns = this.selectedLists;
          if(context)
            await DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
              let newView = new Schedule.View(
                0,  // 随便设一个id，数据库插入时会重新设置
                this.viewDays,
                this.viewName,
                this.viewListSns
              );
              await db.addView(newView);
              this.flushSchedules(this.list.listSn);
              this.isAddViewShow = false;
            })
        });
    }
    .padding(20)
    .backgroundColor(Color.White);
  }

  //-------------添加日程页面-----------------------
  @Builder AddSchedulePage(pageTitle:string,parentSn:number =-1) {
    Column() {
      // 标题
      Text(pageTitle).fontWeight(FontWeight.Bold)
        .fontFamily('xlwk')
        .fontSize(20)
        .fontWeight(600)
        .margin({ bottom: 20 });
      // 输入任务名
      Column(){
        Text('任务名称').margin({left:5,bottom:10}).fontFamily('xlwk').fontWeight(FontWeight.Bold)
        TextInput()
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({left:5,bottom:10})
          .onChange((value)=>{
            this.name = value;
          })
      }.alignItems(HorizontalAlign.Start)

      // 是否为周期事件
      Column() {
        Text('周期时长').fontSize(16).fontWeight(FontWeight.Bold)
          .margin({left:5})
          .width('89%')
          .fontFamily('xlwk')
        Row(){
          TextInput()
            .width('30%')
            .height(35)
            .fontSize(16)
            .onChange((value:string)=>{
              if(!Number.isNaN(Number(value)))
                this.circular = Number(value) * this.circularUnitNum[this.circularUnitSelected]
            })
          TextPicker({range:this.circularUnit, selected:this.circularUnitSelected})
            .onChange((value:string|string [])=>{
              if(!Number.isNaN(Number(value)))
                this.circular = Number(value) * this.circularUnitNum[this.circularUnitSelected]
            })
            .margin({left:15})
            .height('8%')
            .width('20%')
        }
      }.alignItems(HorizontalAlign.Start)

      // 开始时间
      Column(){
        Text('开始时间').margin({left:5,bottom:10}).fontFamily('xlwk').fontWeight(FontWeight.Bold)
        Text(formatDateTime(this.startTime))
          .width('90%')
          .height(35)
          .fontSize(16)
          .fontFamily('xlwk')
          .margin({left:5,bottom:10})
          .onClick(() => {
            DatePickerDialog.show({ // 建议使用 this.getUIContext().showDatePickerDialog()接口
              start: this.currentDate,
              end: new Date("2100-12-31"),
              selected: this.startTimeSelected,
              showTime:true,
              useMilitaryTime:false,
              disappearTextStyle: {font: {size: '16fp', weight: FontWeight.Regular}},
              textStyle: {color: '#468CED', font: {size: '18fp', weight: FontWeight.Normal}},
              selectedTextStyle: {color: '#468CED', font: {size: '18fp', weight: FontWeight.Bold}},
              onDateAccept: (value: Date) => {
                // 通过Date的setFullYear方法设置按下确定按钮时的日期，这样当弹窗再次弹出时显示选中的是上一次确定的日期
                this.startTimeSelected = value
                this.startTime = value
              },
              onCancel: () => {
                this.startTimeSelected = this.currentDate;
              }
            })
          })
      }.alignItems(HorizontalAlign.Start)

      // 结束时间
      Column(){
        Text('结束时间').margin({left:5,bottom:10}).fontFamily('xlwk').fontWeight(FontWeight.Bold)
        Text(formatDateTime(this.endTime))
          .fontFamily('xlwk')
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({left:5,bottom:10})
          .onClick(() => {
            DatePickerDialog.show({ // 建议使用 this.getUIContext().showDatePickerDialog()接口
              start: this.currentDate,
              end: new Date("2100-12-31"),
              selected: this.endTimeSelected,
              showTime:true,
              useMilitaryTime:false,
              disappearTextStyle: {font: {size: '16fp', weight: FontWeight.Regular}},
              textStyle: {color: '#468CED', font: {size: '18fp', weight: FontWeight.Normal}},
              selectedTextStyle: {color: '#468CED', font: {size: '18fp', weight: FontWeight.Bold}},
              onDateAccept: (value: Date) => {
                if(value>=this.startTime){
                  this.endTimeSelected = value
                  this.endTime = value
                }else{
                  this.endTimeSelected = this.currentDate;
                  this.endTime = this.currentDate;
                }
              },
              onCancel: () => {
                this.endTimeSelected = this.currentDate;
              }
            })
          })
      }.alignItems(HorizontalAlign.Start)

      // 优先级选择
      Column(){
        Text('优先级').margin({left:5,bottom:10}).width('90%').fontFamily('xlwk').fontWeight(FontWeight.Bold)
        Rating({ rating: this.prior, indicator: false })
          .stars(3)
          .stepSize(1)
          .onChange((value: number) => {
            this.prior = value
          })
      }.alignItems(HorizontalAlign.Start)

      // 输入备注
      Column(){
        Text('备注').margin({top:10,left:5,bottom:10}).fontFamily('xlwk').fontWeight(FontWeight.Bold)
        TextInput()
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({left:5,bottom:5})
          .onChange((value)=>{
            this.content = value;
          })
      }.alignItems(HorizontalAlign.Start)

      // 提交按钮
      Button('提交').fontFamily('xlwk').fontWeight(FontWeight.Bold)
        .margin({top:40})
        .width('80%')
        .height(40)
        .backgroundColor('#4CAF50')
        .onClick(async () => {
          let context = this.getUIContext().getHostContext()
          if(context)
            await DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
              let newSchedule = new Schedule.Schedule(
                0,  // 随便设一个id，数据库插入时会重新设置
                this.content,
                this.name,
                this.circular,
                this.prior,
                false,
                this.startTime,
                this.endTime,
                parentSn
              );
              const newScheduleRowId = await db.addSchedule(newSchedule)
              await db.addScheduleScheduleList(newScheduleRowId,this.list.listSn);
              this.flushSchedules(this.list.listSn);
              this.isAddScheduleShow = false;
              this.isAddSubScheduleShow = false;
            })
        });
    }
    .padding(20)
    .backgroundColor(Color.White);
  }

  //-----------添加日程列表菜单-----------------
  @Builder
  ListMenu(){
    Menu() {
      MenuItem({content: "全部日程" })
        .onClick(()=>{
          this.list = new ScheduleList(0,'')
          this.isListOrView = ListType.LIST;
          this.flushSchedules();
        })
      MenuItemGroup({ header: '日程列表' }) {
        ForEach(this.listArr, (item: Schedule.ScheduleList, index: number) => {
          MenuItem({content:item.listName})
            .onClick(()=>{
              this.list = item;
              this.isListOrView = ListType.LIST;
              this.flushSchedules(this.list.listSn);
            })
        });
      }
      MenuItemGroup({ header: '视图' }) {
        ForEach(this.viewArr, (item: Schedule.View, index: number) => {
          MenuItem({content:item.viewName})
            .onClick(()=>{
              this.view = item;
              this.isListOrView = ListType.VIEW;
              this.flushSchedules(this.list.listSn,this.view);
            })
        });
      }
    }
  }

  //-----------日程列表管理菜单-----------------t
  @Builder
  ListManageMenu(){
    Menu() {
      MenuItem({content: "删除" })
        .onClick(()=>{
          AlertDialog.show(
            {
              title: this.isListOrView==ListType.LIST?'是否删除该日程列表？':'是否删除该视图？',
              message: this.isListOrView==ListType.LIST?'该操作无法撤回，且列表内所有日程均会被删除':'该操作无法撤回',
              autoCancel: true,
              alignment: DialogAlignment.Default,
              gridCount: 4,
              offset: { dx: 0, dy: -20 },
              primaryButton: {
                value: '取消',
                action: () => {
                }
              },
              secondaryButton: {
                enabled: true,
                defaultFocus: true,
                style: DialogButtonStyle.HIGHLIGHT,
                value: '删除',
                action: async () => {
                  let context = this.getUIContext().getHostContext()
                  if(context){
                    if(this.isListOrView == ListType.LIST){
                      await DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
                        let dlsn:number = this.list.listSn;
                        await db.deleteScheduleList(dlsn);
                        this.list = new ScheduleList(0,'')
                        this.flushSchedules(this.list.listSn);
                        this.flushScheduleLists()
                      })
                    }else if(this.isListOrView == ListType.VIEW) {
                      await DataBase.DataBaseHelper.dbExecute(context, async (db) => {
                        let dlsn: number = this.view.viewSn;
                        await db.deleteView(dlsn);
                        this.list = new ScheduleList(0, '');
                        this.isListOrView = ListType.LIST;
                        this.flushSchedules(this.list.listSn);
                        this.flushViews()
                      })
                    }
                  }
                }
              },
              cancel: () => {
              }
            })
        })
      MenuItem({content: "新建日程列表" })
        .onClick(()=>{
        if(this.addListDialogController)
          this.addListDialogController.open()
      })
      MenuItem({content: "新建视图" })
        .onClick(()=>{
          if(this.addViewDialogController)
            this.addViewDialogController.open()
        })
    }
  }

  //-----------新建日程列表弹窗--------------


  build(){
    NavDestination(){
      Stack(){
        Column() {
          // 标题栏
          Row() {
            Text('日程列表').fontSize(20).margin({ left: 20 }).fontFamily('xlwk');
            Image($r('app.media.ic_public_down_arrow'))
              .width('8%')
              .bindMenu(this.ListMenu)
          }.width('100%');

          // 搜索框
          Row() {
            Search({value:this.searchChangeValue,
              placeholder:'搜索日程'
            })
              .width("90%")
              .height(40)
              .borderRadius(8)
              .margin({left:20})
              .borderStyle(BorderStyle.Solid)
              .onChange((value:string)=>{
                this.searchChangeValue = value;
                if(value === '')
                  this.flushSchedules();
              })
              .onSubmit((value:string)=>{
                this.searchSubmitValue = value;
                this.flushSchedules();
              })
          }
          .width("100%")
          .margin({ top: 10, left: 20, right: 20, bottom:15 });

          // 待完成任务列表
          Column() {
            Text('待完成')
              .fontFamily('xlwk')
              .fontSize(20)
              .margin({ left: 15,bottom:10 })
              .fontWeight(600)
              .width('337')
            Line()
              .width(800)
              .height(10)
              .startPoint([10, 0])
              .endPoint([350, 0])
              .strokeOpacity(0.3)
              .stroke(Color.Gray)
              .alignSelf(ItemAlign.Start)
          }.alignItems(HorizontalAlign.Start)

          List({ space: 10 }) {
            ForEach(this.arrNotDone, (item: Schedule.Schedule, index: number) => {
              ListItem() {
                Row() {
                  Image($r('app.media.pend_checkbo'))
                    .width(24)
                    .height(24)
                    .margin({right:10})
                    .onClick(() => { this.toggleComplete(index,false) });

                  Row() {
                    Column(){
                      Text(item.name)
                        .fontFamily('xlwk')
                        .fontColor(item.prior == 0 ? Color.Black : item.prior == 1? Color.Orange : Color.Red)
                        .fontSize(18)
                        .fontWeight(400)
                        .width(200)
                        .baselineOffset(-5)
                        .margin({ bottom: 5 });
                      Text('开始时间：'+ formatDateTime(item.startTime))
                        .fontFamily('xlwk')
                        .fontSize(13)
                        .opacity(0.6);

                      Text('结束时间：'+ formatDateTime(item.endTime))
                        .fontFamily('xlwk')
                        .fontSize(13)
                        .opacity(0.6);
                    }
                  }
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: "TaskDetails",
                      param: item,
                      onPop:(popInfo)=> {if(popInfo) this.flushSchedules()
                      }
                    })

                  }
                  )
                }
                .width('100%');
              }
              .margin({left:12})
              .width('100%')
              .backgroundColor(Color.White)
              .swipeAction({
                end: {
                  // index为该ListItem在List中的索引值。
                  builder: () => { this.itemEnd(index,true) },
                }
              })
              .padding(5);
            });
          }.width('100%');

          Blank().margin({bottom:20})

          // 已完成任务标识
          Column() {
            Text('已完成')
              .fontFamily('xlwk')
              .fontSize(20)
              .margin({ left: 15,bottom:10 })
              .fontWeight(600)
              .width('337')
            Line()
              .width(800)
              .height(10)
              .startPoint([10, 0])
              .endPoint([350, 0])
              .strokeOpacity(0.3)
              .stroke(Color.Gray)
              .alignSelf(ItemAlign.Start)
          }.alignItems(HorizontalAlign.Start)

          List({ space: 10 }) {
            ForEach(this.arrDone, (item: Schedule.Schedule, index: number) => {
              ListItem() {
                Row() {
                  Image($r('app.media.done_checkbo'))
                    .width(24)
                    .height(24)
                    .margin({right:10})
                    .onClick(() => { this.toggleComplete(index,true) });


                  Column(){
                    Text(item.name)
                      .fontFamily('xlwk')
                      .fontColor(item.prior == 0 ? Color.Black : item.prior == 1? Color.Orange : Color.Red)
                      .fontSize(18)
                      .fontWeight(400)
                      .width(200)
                      .baselineOffset(-5)
                      .margin({ bottom: 5 });
                    Text('开始时间：'+ formatDateTime(item.startTime))
                      .fontFamily('xlwk')
                      .fontSize(13)
                      .opacity(0.6);

                    Text('结束时间：'+ formatDateTime(item.endTime))
                      .fontFamily('xlwk')
                      .fontSize(13)
                      .opacity(0.6);
                  }
                  .onClick(() => this.pageInfos.pushPath({
                    name: "TaskDetails",
                    param: item,
                    onPop:(popInfo)=> {if(popInfo)
                      this.flushSchedules()
                    }
                  }))
                }
                .width('100%');
              }
              .margin({left:12})
              .width('100%')
              .backgroundColor(Color.White)
              .swipeAction({
                end: {
                  // index为该ListItem在List中的索引值。
                  builder: () => { this.itemEnd(index,false) },
                }
              })
              .padding(5);
            });
          }.width('100%')
        }
      }
    }.onWillShow(()=>{this.flushSchedules()})
    .onBackPressed(()=>{
      router.replaceUrl({ url:"pages/Index",params:{slogan:this.slogan}});
      return true;
    })
    .title(this.NavigationTitle)
    .menus(this.NavigationMenus)
  }

  //-------------相关方法------------------
  /**
   * 切换任务完成状态
   * @param index
   * @param status
   */
  toggleComplete(index: number,status:boolean) {
    let context = this.getUIContext().getHostContext();
    if(context){
      if(status){
        this.arrDone[index].status = !this.arrDone[index].status
        DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
          await db.updateSchedule(this.arrDone[index].scheduleSn,this.arrDone[index])
          this.flushSchedules()
        })
      }else{
        this.arrNotDone[index].status = !this.arrNotDone[index].status
        DataBase.DataBaseHelper.dbExecute(context,async (db)=> {
          await db.updateSchedule(this.arrNotDone[index].scheduleSn, this.arrNotDone[index])
          this.flushSchedules()
        })
      }
    }
  }

  /**
   * 获取所有日程
   */
  flushSchedules(listSn:number = 0,view:Schedule.View|null = null){
    let context = this.getUIContext().getHostContext();
    if (context) {
      DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        try {
          if(listSn == 0){
            const data = await db.queryScheduleIsParent();
            this.arr = data; // 赋值操作
          }
          else if(view === null){
            const data = await db.queryScheduleByListIsParent(listSn)
            this.arr = data; // 赋值操作
          }else {
            const data = await db.queryScheduleByView(view);
            this.arr = data;
          }
          this.arrDone = this.arr.filter(item => item.status && item.name.includes(this.searchChangeValue));
          this.arrNotDone = this.arr.filter(item => !item.status && item.name.includes(this.searchChangeValue));
          this.reRenderSchedules()
        } catch (err) {
          console.error(err);
        }
      });
    }
  }

  /**
   * 重绘UI中的日程
   */
  reRenderSchedules(){
    // 重绘
    this.arrDone.splice(0,0,new Schedule.Schedule());
    this.arrDone.splice(0,1);
    this.arrNotDone.splice(0,0,new Schedule.Schedule());
    this.arrNotDone.splice(0,1);
  }

  /**
   * 刷新日程列表
   */
  flushScheduleLists(){
    let context = this.getUIContext().getHostContext();
    if (context) {
      DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        try {
          const data = await db.queryScheduleListsAll();
          this.listArr = data; // 赋值操作
          this.reRenderSchedulesLists()
        } catch (err) {
          console.error(err);
        }
      });
    }
  }

  /**
   * 重绘UI中的日程列表
   */
  reRenderSchedulesLists(){
    // 重绘
    this.listArr.splice(0,0,new Schedule.ScheduleList(0,''));
    this.listArr.splice(0,1);

  }

  /**
   * 刷新视图
   */
  flushViews(){
    let context = this.getUIContext().getHostContext();
    if (context) {
      DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        try {
          const data = await db.queryViewsAll();
          this.viewArr = data; // 赋值操作
          this.reRenderViews()
        } catch (err) {
          console.error(err);
        }
      });
    }
  }

  /**
   *
   * 重绘视图
   */
  reRenderViews(){
    // 重绘
    this.viewArr.splice(0,0,new Schedule.View(0,null,'',[]));
    this.viewArr.splice(0,1);
  }

  /**
   * 页面生命周期函数，消失时调用
   */
  aboutToDisappear(): void {
    this.addListDialogController = null // 将addListDialogController置空
    this.addViewDialogController = null
  }

  /**
   * 页面生命周期函数，出现时调用
   */
  aboutToAppear(): void {
    let routerParams = router.getParams() as GeneratedTypeLiteralInterface_1 // 使用类型断言，该接口包含路由中的所有类型;
    if (routerParams) {
      this.slogan = routerParams.slogan;
    }
    this.flushScheduleLists()
    this.flushSchedules()
    this.flushViews()
  }
}

//-----------添加列表弹窗----------------
@CustomDialog
struct AddListDialog {
  controller?: CustomDialogController
  textInputController:TextInputController = new TextInputController()
  confirmFlushScheduleList:() => void = ()=>{}
  closeSelf:()=>void = ()=>{}
  @State inputValue: string = ''
  @State confirmValue:string = ''

  cancel: () => void = () => {
    this.closeSelf()
  }
  confirm: () => void = async () => {
    this.confirmValue = this.inputValue;
    let context = this.getUIContext().getHostContext();

    if (context) {
      await DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        let newScheduleList = new Schedule.ScheduleList(
          0,  // 随便设一个id，数据库插入时会重新设置
          this.confirmValue
        );
        const newScheduleRowId = await db.addScheduleList(newScheduleList);
        this.confirmFlushScheduleList();
      });
    }

    this.closeSelf();
  };
  build() {
    Column() {
      Text('新建日程列表')
        .fontFamily('xlwk')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .height(100)
      Text('日程列表名')
        .fontFamily('xlwk')
        .fontSize(20)
        .margin({bottom:10})
      TextInput({text:this.inputValue,controller:this.textInputController})
        .onChange((value: string) => {
          this.inputValue = value
        })
        .width('80%')
        .margin({bottom:30})
      Row(){
        Button('确认')
          .backgroundColor('#4CAF50')
          .fontFamily('xlwk')
          .onClick(() => this.confirm())
          .margin(20)
        Button('取消')
          .backgroundColor('#4CAF50')
          .fontFamily('xlwk')
          .onClick(() => this.cancel())
          .margin(20)
      }
    }
  }
}

//-----------添加视图弹窗----------------
@CustomDialog
struct AddViewDialog {
  @Prop listArr: Schedule.ScheduleList[]; // 从父组件接收的数据
  controller?: CustomDialogController
  textInputController: TextInputController = new TextInputController();
  circularUnit: string[] = ['天', '周', '月'];
  circularUnitSelected: number = 0;
  circularUnitNum: number[] = [1, 7, 30];
  confirmFlushView:() => void = ()=>{}
  closeSelf:()=>void = ()=>{};
  selectedLists: number[] = [];
  viewName: string = '';
  viewDays: number = 0;
  viewListSns:number[] = [];

  cancel: () => void = () => {
    this.closeSelf();
  };

  confirm: () => void = async () => {
    let context = this.getUIContext().getHostContext();
    if (context) {
      this.viewListSns = this.selectedLists;
      await DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        let newView = new Schedule.View(
          0, // 随便设一个id，数据库插入时会重新设置
          this.viewDays,
          this.viewName,
          this.viewListSns
        );
        await db.addView(newView);
        this.confirmFlushView();
      });
    }
    this.closeSelf();
  };

  build() {
    Column() {
      Text('新建视图')
        .fontFamily('xlwk')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .height(50);

      // 输入视图名
      Column() {
        Text('视图名称').fontFamily('xlwk')
          .margin({ left: 5, bottom: 10 });
        TextInput({ text: this.viewName, controller: this.textInputController })
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({ left: 5, bottom: 10 })
          .onChange((value: string) => {
            this.viewName = value;
          });
      }.alignItems(HorizontalAlign.Start);

      // 时间范围为未来几天
      Column() {
        Text('时间范围').fontFamily('xlwk')
          .fontSize(16)
          .margin({ left: 5 })
          .width('89%');
        Row() {
          TextInput()
            .width('30%')
            .height(35)
            .fontSize(16)
            .onChange((value: string) => {
              if (!Number.isNaN(Number(value)))
                this.viewDays = Number(value) * this.circularUnitNum[this.circularUnitSelected];
            });
          TextPicker({ range: this.circularUnit, selected: this.circularUnitSelected })
            .onChange((value: string | string[]) => {
              if (!Number.isNaN(Number(value)))
                this.viewDays = Number(value) * this.circularUnitNum[this.circularUnitSelected];
            })
            .margin({ left: 15 })
            .height('8%')
            .width('20%');
        };
      }.alignItems(HorizontalAlign.Start);

      // 选中的列表
      Column() {
        List() {
          ForEach(this.listArr, (item: Schedule.ScheduleList, index: number) => {
            ListItem() {
              Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                Checkbox({ name: 'checkbox_' + index.toString(), group: 'listGroup' })
                  .selectedColor(0x39a2db)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .onChange((value: boolean) => {
                    if (value)
                      this.selectedLists.push(item.listSn);
                    else {
                      const itemIndex = this.selectedLists.findIndex(sn => sn === item.listSn);
                      if (itemIndex !== -1) {
                        this.selectedLists.splice(itemIndex, 1);
                      }
                    }
                  })
                  .unselectedColor(Color.Gray)
                  .width(30)
                  .height(30);
                Text(item.listName)
                  .fontSize(20);
              };
            };
          });
        };
      };

      // 确认与取消按钮
      Row() {
        Button('确认')
          .backgroundColor('#4CAE50')
          .onClick(() => this.confirm())
          .margin({ right: 20 });
        Button('取消')
          .backgroundColor('#4CAE50')
          .onClick(() => this.cancel());
      }.justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(20)
    .backgroundColor(Color.White);
  }
}
