import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import * as DataBase from '../data/entity';
import * as Schedule from '../packages/schedule/schedule';

@Entry
@Component
struct SchedulePage {
  // 页面导航栈，用于管理页面堆栈
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State arr: Schedule.Schedule[] = []
  @State arrDone:Schedule.Schedule[] = []
  @State arrNotDone:Schedule.Schedule[] = []

  @State private isAddScheduleShow:boolean = false;
  @State private isAddSubScheduleShow:boolean = false;

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

  //-------------子页面-----------------------
  @Builder PageMap(name: string, param?: Object) {
    if (name === "TaskDetails") {
      this.taskDetailPage();
    } else {
      this.taskListPage();
    }
  }

  //-------------标题栏-----------------------
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
    }.margin({ right:20,top:15 })
  }

  //----------侧滑项----------------------------
  @Builder itemEnd(index: number,isNeedSubSchedule:boolean) {

    Row(){
      // 构建尾端滑出组件
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_public_delete'))
          .width(20)
          .height(20)
      }
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
                console.info('Callback when the first button is clicked')
              }
            },
            secondaryButton: {
              enabled: true,
              defaultFocus: true,
              style: DialogButtonStyle.HIGHLIGHT,
              value: '删除',
              action: () => {
                console.info('Callback when the second button is clicked')
                let context = this.getUIContext().getHostContext()
                if(context)
                  DataBase.DataBaseHelper.dbExecute(context,async (db)=>{
                    if(isNeedSubSchedule){
                      await db.deleteSchedule(this.arrNotDone[index].scheduleSn); //TODO:要考虑关联表
                      this.arrNotDone.splice(index,1); // 视图上删除
                    }
                    else{
                      await db.deleteSchedule(this.arrDone[index].scheduleSn); //TODO:要考虑关联表
                      this.arrDone.splice(index,1);
                    }
                  })
              }
            },
            cancel: () => {
              console.info('Closed callbacks')
            }
          }
        )
      })
      // 添加子日程
      if(isNeedSubSchedule){
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_public_add'))
            .width(20)
            .height(20)
            .onClick(()=>{
              this.isAddSubScheduleShow = true;
            })
            .bindSheet($$this.isAddSubScheduleShow, this.AddSchedulePage('添加子日程',this.arrNotDone[index].scheduleSn), {
              height: 600,
              onWillDisappear:()=>{this.isAddSubScheduleShow = false;}
            })
        }
      }
    }
  }

  //-------------添加日程页面-----------------------
  @Builder AddSchedulePage(pageTitle:string,parentSn:number =-1) {
    Column() {
      // 标题
      Text(pageTitle).fontSize(20).fontWeight(600).margin({ bottom: 20 });
      // 输入任务名
      Column(){
        Text('任务名称').margin({left:5,bottom:10})
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
        Text('周期时长').fontSize(16).margin({left:5}).width('89%')
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
        Text('开始时间').margin({left:5,bottom:10})
        Text(this.startTime.toLocaleString())
          .width('90%')
          .height(35)
          .fontSize(16)
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
                console.info("DatePickerDialog:onDateAccept()" + value.toString())
              },
              onCancel: () => {
                this.startTimeSelected = this.currentDate;
                console.info("DatePickerDialog:onCancel()")
              }
            })
          })
      }.alignItems(HorizontalAlign.Start)

      // 结束时间
      Column(){
        Text('结束时间').margin({left:5,bottom:10})
        Text(this.endTime.toLocaleString())
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
                if(value<=this.startTime){
                  this.endTimeSelected = value
                  this.endTime = value
                }else{
                  console.info('[!WARN] EndTime greater than StartTime')
                  this.endTimeSelected = this.currentDate;
                  this.endTime = this.currentDate;
                }
                console.info("EndTime DatePickerDialog:onDateAccept()" + value.toString())
              },
              onCancel: () => {
                this.endTimeSelected = this.currentDate;
                console.info("EndTime DatePickerDialog:onCancel()")
              }
            })
          })
      }.alignItems(HorizontalAlign.Start)

      // 优先级选择
      Column(){
        Text('优先级').margin({left:5,bottom:5}).width('90%')
        Rating({ rating: this.prior, indicator: false })
          .stars(3)
          .stepSize(1)
          .onChange((value: number) => {
            this.prior = value
          })
      }.alignItems(HorizontalAlign.Start)

      // 输入备注
      Column(){
        Text('备注').margin({left:5,bottom:10})
        TextInput()
          .width('90%')
          .height(35)
          .fontSize(16)
          .margin({left:5,bottom:10})
          .onChange((value)=>{
            this.content = value;
          })
      }.alignItems(HorizontalAlign.Start)

      // 提交按钮
      Button('提交')
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
              await db.addSchedule(newSchedule)
              this.flushSchedules();
              this.isAddScheduleShow = false;
              this.isAddSubScheduleShow = false;
            })
        });
    }
    .padding(20)
    .backgroundColor(Color.White);
  }

  //-------------主任务列表页面---------------------
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

      List(){

      }

      // 待完成任务列表
      Column() {
        Text('待完成')
          .fontSize(20)
          .margin({ left: 15,bottom:10 })
          .fontWeight(600)
          .width('337')
      }.alignItems(HorizontalAlign.Start)

      List({ space: 10 }) {
        ForEach(this.arrNotDone, (item: Schedule.Schedule, index: number) => {
          ListItem() {
            Row() {
              Image($r('app.media.ic_gallery_material_select_checkbo'))
                .width(24)
                .height(24)
                .margin({right:10})
                .onClick(() => { this.toggleComplete(index,false) });

              Row() {
                Column(){
                  Text(item.name)
                    .fontSize(18)
                    .fontWeight(400)
                    .baselineOffset(-5)
                    .margin({ bottom: 5 });
                }

                Column() {
                  Text('开始时间：'+ item.startTime)
                    .fontSize(13)
                    .opacity(0.6);

                  Text('结束时间：'+ item.endTime)
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
          .fontSize(20)
          .margin({ left: 15,bottom:10 })
          .fontWeight(600)
          .width('337')
      }.alignItems(HorizontalAlign.Start)

      // TODO:不知道能不能滚动
      List({ space: 10 }) {
        ForEach(this.arrDone, (item: Schedule.Schedule, index: number) => {
          ListItem() {
            Row() {
              Image($r('app.media.ic_gallery_material_select_checkbo'))
                .width(24)
                .height(24)
                .margin({right:10})
                .onClick(() => { this.toggleComplete(index,true) });

              Row() {
                Column(){
                  Text(item.name)
                    .fontSize(18)
                    .fontWeight(400)
                    .baselineOffset(-5)
                    .margin({ bottom: 5 });
                }

                Column() {
                  Text('开始时间：'+ item.startTime)
                    .fontSize(13)
                    .opacity(0.6);

                  Text('结束时间：'+ item.endTime)
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
          .swipeAction({
            end: {
              // index为该ListItem在List中的索引值。
              builder: () => { this.itemEnd(index,false) },
            }
          })
          .padding(5);
        });
      }.width('100%');
    };
  }

  //-------------任务详情页面-----------------------
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

  //-------------构建-----------------------

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
  flushSchedules(){
    let context = this.getUIContext().getHostContext();
    if (context) {
      DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        try {
          const data = await db.queryScheduleIsParent();
          this.arr = data; // 赋值操作
          this.arrDone = this.arr.filter(item => item.status);
          this.arrNotDone = this.arr.filter(item => !item.status);
          this.reRenderSchedules()
        } catch (err) {
          console.error(err);
        }
      });
    }
    console.info('获取一次日程')
  }

  reRenderSchedules(){
    // 重绘
    this.arrDone.splice(0,0,new Schedule.Schedule());
    this.arrDone.splice(0,1);
    this.arrNotDone.splice(0,0,new Schedule.Schedule());
    this.arrNotDone.splice(0,1);
  }

  aboutToAppear(): void {
    this.flushSchedules()
  }
}
