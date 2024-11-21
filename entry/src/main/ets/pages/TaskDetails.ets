import * as DataBase from '../data/entity';
import { Schedule } from "../packages/schedule/schedule"
import { Callback } from '@ohos.base';

@Builder
export function TaskDetailsBuilder(param: Object) {
  TaskDetails(param)
}

@Entry
@Component
struct TaskDetails {

  @Consume('pageInfos') pageInfos: NavPathStack;
  param: Schedule = new Schedule();
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
  @State private isEditScheduleShow:boolean = false;
  @State childSchedules:Schedule[] = []

  //-------------编辑日程子页面--------------
  @Builder EditSchedulePage() {
    Column() {
      // 标题
      Text('编辑日程').fontSize(20).fontWeight(600).margin({ bottom: 20 });
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
              },
              onCancel: () => {
                this.startTimeSelected = this.currentDate;
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
              let newSchedule = new Schedule(
                this.param.scheduleSn,  // 随便设一个id，数据库插入时会重新设置
                this.content,
                this.name,
                this.circular,
                this.prior,
                this.param.status,
                this.startTime,
                this.endTime,
                this.param.parent
              );
              await db.updateSchedule(this.param.scheduleSn,newSchedule);
              this.isEditScheduleShow = false;
            })
        });
    }
    .padding(20)
    .backgroundColor(Color.White)
  }

  //-------------右上角工具栏-----------------------
  @Builder NavigationMenus() {
    Row() {
      Image($r('app.media.ic_public_edit'))
        .width(24)
        .height(24)
        .onClick(()=>{
          this.isEditScheduleShow = true;
        })
        .bindSheet($$this.isEditScheduleShow, this.EditSchedulePage(), {
          height: 600,
          onWillDisappear:()=>{this.isEditScheduleShow = false},
          onWillDismiss:((DismissSheetAction: DismissSheetAction) => {
            DismissSheetAction.dismiss = ()=>{
              this.name = this.param.name;
              this.content = this.param.content;
              this.startTime = this.param.startTime ?? new Date();
              this.endTime = this.param.endTime ?? new Date();
              this.circular = this.param.circular;
              this.prior = this.param.prior;
              this.startTimeSelected = this.startTime;
              this.endTimeSelected = this.endTime;
              this.isEditScheduleShow = false;
            }
            DismissSheetAction.dismiss()
          })
        })
      Image($r('app.media.ic_public_delete'))
        .width(24)
        .height(24)
        .margin({left:20})
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
                      await db.deleteScheduleListScheduleByScheduleSn(this.param.scheduleSn);
                      await db.deleteSchedule(this.param.scheduleSn);
                    })
                  this.pageInfos.pop({number:1})
                }
              },
              cancel: () => {
              }
            }
          )
        })
    }.margin({ right:20,top:15 })
  }

  build() {
    NavDestination(){
      Column() {
        // 页面标题
        Row() {
          Text('任务详情').fontSize(27).margin({ left: 20 });
        }.width('100%');

        // 任务名称
        Column() {
          Text('任务名称').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.name).fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        // 周期时长
        Column() {
          Text('周期时长').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.circular + ' 天').fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        // 开始时间
        Column() {
          Text('开始时间').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.startTime?.toLocaleString()).fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        // 结束时间
        Column() {
          Text('结束时间').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.endTime?.toLocaleString()).fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        // 优先级
        Column() {
          Text('优先级').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.prior.toString()).fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        // 备注
        Column() {
          Text('备注').fontSize(18).fontWeight(600).margin({ top: 20, left: 20 });
          Text(this.content).fontSize(16).margin({ left: 20 });
        }.alignItems(HorizontalAlign.Start);

        ForEach(this.childSchedules, (item: Schedule, index: number) => {
          Column(){
            Text('子日程名'+ item.name);
            Text('子日程起始时间' + item.startTime?.toString());
            Text('子日程结束时间' + item.endTime?.toString());
            Text('子日程优先级' + item.prior.toString());
          }
        });
      }
      .padding(20)
      .backgroundColor(Color.White);
    }.onReady((ctx: NavDestinationContext) => {
      // 在NavDestination中能够拿到传来的NavPathInfo和当前所处的NavPathStack
      try {
        this.param = (ctx?.pathInfo?.param as Schedule)
        this.name = this.param.name;
        this.content = this.param.content;
        this.startTime = this.param.startTime ?? new Date();
        this.endTime = this.param.endTime ?? new Date();
        this.circular = this.param.circular;
        this.prior = this.param.prior;
        this.startTimeSelected = this.startTime;
        this.endTimeSelected = this.endTime;
      } catch (e) {
        console.log(`testTag onReady catch exception: ${JSON.stringify(e)}`)
      }
    })
    .onWillHide(()=>{})
    .menus(this.NavigationMenus)
  }

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext();
    if (context) {
      DataBase.DataBaseHelper.dbExecute(context, async (db) => {
        try {
          const data = await db.queryScheduleByParentSchedule(this.param.scheduleSn);
          // this.childSchedules = data; // 赋值操作 TODO:等处理好子日程逻辑再来看这个
        } catch (err) {
          console.error(err);
        }
      });
    }
  }
}