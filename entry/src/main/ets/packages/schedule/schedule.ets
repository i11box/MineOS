// 日程列表类
export class ScheduleList {
  listSn:number;
  listName: string;  // 列表名称

  constructor(listSn:number,listName: string) {
    this.listSn = listSn
    this.listName = listName;
  }

}

// 日程类
@ObservedV2
export class Schedule {
  scheduleSn:number;  // 编号
  content: string;    // 内容
  name:string;         //日程名
  startTime: Date | null;  // 可以是 Date 或 null，开始时间
  endTime: Date | null;    // 结束时间
  circular: number;       // 周期
  prior: number;           // 优先级
  @Trace status: boolean;          // 完成状态
  parent: number=-1;  // 父日程可以为 null

  constructor(
    scheduleSn:number = -1,
    content: string = '',
    name:string = '',
    circular: number = 0,
    prior: number = 0,
    status: boolean = false,
    startTime: Date | null = null,   // 开始时间可以为 null
    endTime: Date | null = null,     // 结束时间可以为 null
    parent: number=-1, // 父日程编号
  ) {
    this.scheduleSn = scheduleSn;
    this.content = content;
    this.name = name;
    this.startTime = startTime;
    this.endTime = endTime;
    this.circular = circular;
    this.prior = prior;
    this.status = status;
    this.parent = parent;
  }
}

// 视图类
export class View {
  viewSn:number;
  viewDays:number|null;
  viewName:string;
  listSns:number[];

  constructor(
    viewSn:number,
    viewDays:number|null,
    viewName:string,
    listSns:number[]
  ) {
    this.viewSn = viewSn;
    this.viewDays = viewDays;
    this.viewName = viewName;
    this.listSns = listSns;
  }
}