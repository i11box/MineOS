import * as DataBase from '../data/entity';
import * as Schedule from '../packages/schedule/schedule';

@Entry
@Component
struct Test {
  private circularUnit:string [] = ['年','月','日'];
  private currentDate:Date = new Date();
  private circularUnitNum:number [] = [365,30,1];
  private circularUnitSelected:number = 2;

  @State content:string = '';
  @State name:string = '';
  @State startTime:Date = this.currentDate;
  @State endTime:Date = this.currentDate;
  @State circular:number = 0;
  @State prior:number = 0;
  @State private startTimeSelected:Date = this.currentDate;
  @State private endTimeSelected:Date = this.currentDate;


  build() {
    Column() {
      // 标题
      Text('添加新任务').fontSize(20).fontWeight(600).margin({ bottom: 20 });

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
                if(value>=this.startTime){
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
        .onClick(() => {
          let context = this.getUIContext().getHostContext()
          if(context)
            DataBase.DataBaseHelper.dbExecute(context,(db)=>{
              let newSchedule = new Schedule.Schedule(this.content,this.name,this.circular,this.prior,false,this.startTime,this.endTime);
              db.addSchedule(newSchedule)
            })
        });
    }
    .padding(20)
    .backgroundColor(Color.White);
  }
}