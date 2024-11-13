import relationalStore from '@ohos.data.relationalStore';
import * as dbConstant from './constant'
import {common} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import * as scheduleClass from '../packages/schedule/schedule'
import { Schedule, ScheduleList } from '../packages/schedule/schedule';

// --------------将对象转为valueBucket---------------------
function scheduleToValuesBucket(schedule:scheduleClass.Schedule): relationalStore.ValuesBucket {
  return {
    schedule_content: schedule.content,
    schedule_name: schedule.name,
    start_time: schedule.startTime ? schedule.startTime.toISOString() : null, // 将 Date 转为 ISO8601 字符串
    end_time: schedule.endTime ? schedule.endTime.toISOString() : null,
    circular: schedule.circular,
    prior: schedule.prior,
    status: schedule.status ? 1 : 0, // 将布尔值转换为整数
    parent_schedule_sn: schedule.parent
  };
}

function scheduleListToValuesBucket(scheduleList:scheduleClass.ScheduleList): relationalStore.ValuesBucket {
  return {
    list_name: scheduleList.listName,
  };
}

function scheduleScheduleListToValuesBucket(scheduleSn:number,listSn:number): relationalStore.ValuesBucket {
  return {
    list_sn:listSn,
    schedule_sn:scheduleSn
  };
}

//-----------------数据库类-------------------------------

export class DataBaseHelper {
  private static dbInstance : DataBase | null = null;
  private static isInitializing:boolean = false;

  //-------数据库管家处理语句-------------------------------
  static async dbExecute(context: common.BaseContext, callback?: (db: DataBase) => void): Promise<boolean> {
    // 如果已经存在实例，直接调用回调函数
    if (DataBaseHelper.dbInstance) {
      if (callback) callback(DataBaseHelper.dbInstance);
      return true;
    }

    // 如果正在初始化，等待初始化完成
    if (DataBaseHelper.isInitializing) {
      return new Promise((resolve) => {
        const checkInterval = setInterval(() => {
          if (DataBaseHelper.dbInstance) {
            clearInterval(checkInterval);
            if (callback) callback(DataBaseHelper.dbInstance!);
            resolve(true);
          }
        }, 50);
      });
    }

    // 设置初始化标志
    DataBaseHelper.isInitializing = true;

    // 初始化数据库
    try {
      const dbTemp: relationalStore.RdbStore = await new Promise((resolve, reject) => {
        relationalStore.getRdbStore(context, dbConstant.DB_CONFIG, (e, rdb) => {
          if (e) {
            console.error(`Get RdbStore failed, code is ${e.code}, message is ${e.message}`);
            DataBaseHelper.isInitializing = false;
            reject(e);
            return;
          }

          console.info('Get RdbStore successfully.');
          resolve(rdb);
        });
      });

      DataBaseHelper.dbInstance = new DataBase(dbTemp);
      DataBaseHelper.isInitializing = false;
      if (callback) callback(DataBaseHelper.dbInstance);
      return true;
    } catch (error) {
      console.error("Failed to initialize the database:", error);
      DataBaseHelper.isInitializing = false;
      return false;
    }
  }
}

export class DataBase {
  //----------------------数据库的属性-----------------------------
  db: relationalStore.RdbStore | null = null

  //--------------------------关于数据库的创建-------------------------
  constructor(rdb: relationalStore.RdbStore | null) {
    this.db = rdb;
  }

  async createTable(getTable: string) {
    if (this.db === null) {
      console.error(`db is empty, retry`);
    } else {
      try {
        await this.db.executeSql(getTable);
        console.log(`创建${getTable}成功`);
      } catch (error) {
        console.error(`创建${getTable}失败: ${error.message}`);
      }
    }
  }

  // 初始化数据库，异步创建所有表
  async initDB(): Promise<void> {
    // 使用 Promise.all 让所有表的创建并行执行
    await Promise.all(dbConstant.GET_TABLE.map((statement): Promise<void> => this.createTable(statement)));
    console.info("所有表创建成功");
  }

  // 初始化数据库，顺序创建所有表
  async initSeqDB(): Promise<void> {
    // 使用 Promise.all 让所有表的创建并行执行
    for(let table of dbConstant.GET_TABLE){
      await this.createTable(table);
    }
    console.info("所有表创建成功");
  }

  //------------------------关于日程的访问----------------------------
  // 增加日程
  /**
   *
   * @param scheduleData
   * @returns rowId
   */
  async addSchedule(scheduleData: scheduleClass.Schedule): Promise<number> {
    const schedule = scheduleToValuesBucket(scheduleData)
    return new Promise<number>((resolve,reject)=>{
      const rowId = this.db!.insert("schedule", schedule);
      resolve(rowId);
    })
  }

  // 增加日程与列表之间的关系
  /**
   *
   * @param scheduleSn
   * @param listSn
   * @returns rowId
   */
  async addScheduleScheduleList(scheduleSn:number,listSn:number): Promise<number> {
    const data = scheduleScheduleListToValuesBucket(scheduleSn,listSn);
    return new Promise<number>((resolve,reject)=>{
        const rowId = this.db!.insert("schedule_list_schedule", data);
        resolve(rowId);
      });
  }

  // 更新日程
  /**
   *
   * @param scheduleID
   * @param updatedData
   * @returns Promise<void>
   */
  async updateSchedule(scheduleID: number, updatedData: scheduleClass.Schedule): Promise<void> {
    const schedule = scheduleToValuesBucket(updatedData)
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule");
      predicates.equalTo("schedule_sn", scheduleID); // 通过 ID 识别日程

      const rowsUpdated =
        await this.db.update(schedule, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`更新成功，更新的行数：${rowsUpdated}`);
    } catch (err) {
      console.error(`更新失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 删除日程
  /**
   *
   * @param scheduleID
   */
  async deleteSchedule(scheduleID: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule");
      predicates.equalTo("schedule_sn", scheduleID); // 通过 ID 查找日程

      // 调试语句
      let schedule = await this.queryScheduleBySn(scheduleID)
      for (const i of schedule) {
        console.info(i.name)
      }

      const rowsDeleted = await this.db.delete(predicates);
      console.info(`删除成功，删除的行数：${rowsDeleted}`);
    } catch (err) {
      console.error(`删除失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 查询所有日程
  /**
   *
   * @returns Promise<Schedule[]>
   */
  async queryScheduleAll(): Promise<Schedule[]> {
    let schedules: Schedule[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return schedules;
    }

    const predicates = new relationalStore.RdbPredicates("schedule");

    // 将查询操作包装为一个 Promise
    return new Promise<Schedule[]>((resolve, reject) => {
      this.db!.query(predicates, (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            sn, content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }

  // 查询所有父日程
  /**
   *
   * @returns Promise<Schedule[]>
   */
  async queryScheduleIsParent(): Promise<Schedule[]> {
    let schedules: Schedule[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return schedules;
    }

    const predicates = new relationalStore.RdbPredicates("schedule");
    predicates.equalTo('parent_schedule_sn', -1);

    // 将查询操作包装为一个 Promise
    return new Promise<Schedule[]>((resolve, reject) => {
      this.db!.query(predicates, (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            sn, content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }

  // 通过序号查询日程
  /**
   *
   * @param scheduleSn
   * @returns Promise<Schedule[]>
   */
  async queryScheduleBySn(scheduleSn: number): Promise<Schedule[]> {
    let schedules: Schedule[] = []
    if (this.db === null) {
      console.error("数据库未初始化");
      return schedules;
    }
    const predicates = new relationalStore.RdbPredicates("schedule");
    predicates.equalTo("schedule_sn", scheduleSn);

    this.db.query(predicates, (err, resultSet) => {
      if (err) {
        console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
      }

      console.info(`查询结果列数：${resultSet.columnCount}`);

      while (resultSet.goToNextRow()) {
        const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
        const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
        const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
        const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
        const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
        const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
        const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"))
        const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
        const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));
        schedules.push(new Schedule(
          sn, content, name, circular, prior, status, startTime, endTime, parent
        ))
        resultSet.close(); // 释放内存
      }
    });
    console.info('有' + schedules.length.toString())
    return schedules;
  }

  // 通过日程列表查询日程
  // 查询所有父日程
  /**
   *
   * @returns Promise<Schedule[]>
   */
  async queryScheduleByList(listSn:number): Promise<Schedule[]> {
    let schedules: Schedule[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return schedules;
    }

    const queryString:string ="SELECT * FROM schedule WHERE schedule_sn IN (SELECT schedule_sn FROM schedule_list_schedule WHERE list_sn = ?)"

    // 将查询操作包装为一个 Promise
    return new Promise<Schedule[]>((resolve, reject) => {
      this.db!.querySql(queryString,[listSn], (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            sn, content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }

  // 通过日程列表查询父日程
  /**
   *
   * @returns Promise<Schedule[]>
   */
  async queryScheduleByListIsParent(listSn:number): Promise<Schedule[]> {
    let schedules: Schedule[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return schedules;
    }

    const queryString:string ="SELECT * FROM schedule WHERE schedule_sn IN (SELECT schedule_sn FROM schedule_list_schedule WHERE list_sn = ?)"

    // 将查询操作包装为一个 Promise
    return new Promise<Schedule[]>((resolve, reject) => {
      this.db!.querySql(queryString,[listSn], (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(listSn.toString())
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            sn, content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }

  // 通过日程查询子日程
  /**
   *
   * @returns Promise<Schedule[]>
   */
  async queryScheduleByParentSchedule(scheduleSn:number): Promise<Schedule[]> {
    let schedules: Schedule[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return schedules;
    }

    const predicates = new relationalStore.RdbPredicates("schedule");
    predicates.equalTo("parent_schedule_sn", scheduleSn);

    // 将查询操作包装为一个 Promise
    return new Promise<Schedule[]>((resolve, reject) => {
      this.db!.query(predicates, (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          const endTime: Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            sn, content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }

  //------------------------关于日程列表的访问----------------------------

  // 增加日程列表
  /**
   *
   * @param scheduleList
   * @returns
   */
  async addScheduleList(scheduleList: scheduleClass.ScheduleList): Promise<void> {
    const valuesBucket = scheduleListToValuesBucket(scheduleList);
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const rowId = await this.db.insert("schedule_list", valuesBucket);
      console.info(`日程列表插入成功，rowId = ${rowId}`);
    } catch (err) {
      console.error(`日程列表插入失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 按id更新日程列表
  /**
   *
   * @param listID
   * @param updatedData
   * @returns
   */
  async updateScheduleList(listID: number, updatedData: scheduleClass.ScheduleList): Promise<void> {
    const valuesBucket = scheduleListToValuesBucket(updatedData);
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule_list");
      predicates.equalTo("list_sn", listID); // 通过 ID 识别日程列表

      const rowsUpdated =
        await this.db.update(valuesBucket, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`日程列表更新成功，更新的行数：${rowsUpdated}`);
    } catch (err) {
      console.error(`日程列表更新失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 按id删除日程列表
  /**
   *
   * @param listID
   * @returns
   */
  async deleteScheduleList(listID: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }

    const queryString:string ="SELECT * FROM schedule WHERE schedule_sn IN (SELECT schedule_sn FROM schedule_list_schedule WHERE list_sn = ?)"

    const schedules:Schedule[] = await this.queryScheduleByList(listID);

    console.info(`schedule_len = ${schedules.length.toString()}`)
    for(const sche of schedules){
        // 找到相关联的日程，先删除关联
        let predicatesOfScheduleListSchedule = new relationalStore.RdbPredicates("schedule_list_schedule");
        predicatesOfScheduleListSchedule.equalTo("schedule_sn",sche.scheduleSn)
        this.db!.delete(predicatesOfScheduleListSchedule, (err, rows) => {
          if (err) {
            console.error(`Delete failed, code is ${err.code},message is ${err.message}`);
            return;
          }
          console.info(`Delete rows of schedule_list_schedule: ${rows}`);
        });
        // 接下来删除日程
        let predicateOfSchedule = new relationalStore.RdbPredicates("schedule");
        predicateOfSchedule.equalTo("schedule_sn",sche.scheduleSn);
        this.db!.delete(predicateOfSchedule,(err, rows) => {
          if (err) {
            console.error(`Delete failed, code is ${err.code},message is ${err.message}`);
            return;
          }
          console.info(`Delete rows of schedule: ${rows}`);
        });
    }
      // // 遍历查询结果集并填充到 schedules 数组中
      // while (resultSet.goToNextRow()) {
      //   const sn: number = resultSet.getLong((resultSet.getColumnIndex("schedule_sn")));
      //   // 找到相关联的日程，先删除关联
      //   let predicatesOfScheduleListSchedule = new relationalStore.RdbPredicates("schedule_list_schedule");
      //   predicatesOfScheduleListSchedule.equalTo("schedule_sn",sn)
      //   this.db!.delete(predicatesOfScheduleListSchedule, (err, rows) => {
      //     if (err) {
      //       console.error(`Delete failed, code is ${err.code},message is ${err.message}`);
      //       return;
      //     }
      //     console.info(`Delete rows of schedule_list_schedule: ${rows}`);
      //   });
      //   // 接下来删除日程
      //   let predicateOfSchedule = new relationalStore.RdbPredicates("schedule");
      //   predicateOfSchedule.equalTo("schedule_sn",sn);
      //   this.db!.delete(predicateOfSchedule,(err, rows) => {
      //     if (err) {
      //       console.error(`Delete failed, code is ${err.code},message is ${err.message}`);
      //       return;
      //     }
      //     console.info(`Delete rows of schedule: ${rows}`);
      //   });
      // }
      //
      // 最后删除日程列表
      let predicateOfScheduleList = new relationalStore.RdbPredicates("schedule_list");
      predicateOfScheduleList.equalTo("list_sn",listID);
      this.db!.delete(predicateOfScheduleList,(err, rows) => {
        if (err) {
          console.error(`Delete failed, code is ${err.code},message is ${err.message}`);
          return;
        }
        console.info(`Delete rows of schedule_list: ${rows}`);
      });
      //
      // resultSet.close(); // 释放内存

  }

  // 按序号查询日程列表
  /**
   *
   * @param listSn
   * @returns
   */
  async queryScheduleListBySn(listSn: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    const predicates = new relationalStore.RdbPredicates("schedule_list");
    predicates.equalTo("list_sn", listSn);

    this.db.query(predicates, (err, resultSet) => {
      if (err) {
        console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
        return;
      }

      console.info(`查询结果列数：${resultSet.columnCount}`);
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex("list_sn"));
        const name = resultSet.getString(resultSet.getColumnIndex("list_name"));

        console.info(`ID=${id}, 名称=${name}`);
      }
      resultSet.close(); // 释放内存
    });
  }

  // 查询所有日程列表
  /**
   *
   * @returns Promise<ScheduleList[]>
   */
  async queryScheduleListsAll(): Promise<ScheduleList[]> {
    let lists: ScheduleList[] = [];
    if (!this.db) {
      console.error("数据库未初始化");
      return lists;
    }

    const predicates = new relationalStore.RdbPredicates("schedule_list");

    // 将查询操作包装为一个 Promise
    return new Promise<ScheduleList[]>((resolve, reject) => {
      this.db!.query(predicates, (err, resultSet) => {
        if (err) {
          console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
          reject(err); // 在查询失败时拒绝 Promise
          return;
        }

        console.info(`查询结果列数：${resultSet.columnCount}`);
        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          const sn: number = resultSet.getLong((resultSet.getColumnIndex("list_sn")));
          const name: string = resultSet.getString(resultSet.getColumnIndex("list_name"));

          lists.push(new ScheduleList(sn, name));
        }

        resultSet.close(); // 释放内存
        resolve(lists); // 在查询完成后解析 Promise
      });
    });
  }
}