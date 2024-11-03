// 日程列表类
export class ScheduleList {
  listName: string;  // 列表名称

  constructor(listName: string) {
    this.listName = listName;
  }

}

// 标签类
export class Tag {
  tagName: string;  // 标签名称

  constructor(tagName: string) {
    this.tagName = tagName;
  }
}

// 日程类
export class Schedule {
  content: string;    // 内容
  name:string;         //日程名
  startTime: Date | null;  // 可以是 Date 或 null，开始时间
  endTime: Date | null;    // 结束时间
  circular: number;       // 周期
  prior: number;           // 优先级
  status: boolean;          // 完成状态
  parent: number=-1;  // 父日程可以为 null

  constructor(
    content: string,
    name:string,
    circular: number = 0,
    prior: number = 0,
    status: boolean = false,
    startTime: Date | null = null,   // 开始时间可以为 null
    endTime: Date | null = null,     // 结束时间可以为 null
    parent: number=-1, // 父日程编号
  ) {
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
