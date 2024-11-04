import relationalStore from '@ohos.data.relationalStore';
import * as dbConstant from './constant'
import {common} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import * as scheduleClass from '../packages/schedule/schedule'
import { Schedule } from '../packages/schedule/schedule';

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

function tagToValuesBucket(tag: scheduleClass.Tag): relationalStore.ValuesBucket {
  return {
    tag_name: tag.tagName,
  };
}

//-----------------数据库类-------------------------------

export class DataBaseHelper {
  private static dbInstance : DataBase | null = null;
  private static isInitializing:boolean = false;

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

export class DataBase{
  //----------------------数据库的属性-----------------------------
  db :relationalStore.RdbStore|null = null

  //--------------------------关于数据库的创建-------------------------
  constructor(rdb:relationalStore.RdbStore|null) {
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

  //------------------------关于日程的访问----------------------------
  // 增加日程
  async addSchedule(scheduleData: scheduleClass.Schedule): Promise<void> {
    const schedule = scheduleToValuesBucket(scheduleData)
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const rowId = await this.db.insert("schedule", schedule);
      console.info(`日程插入成功，rowId = ${rowId}`);
    } catch (err) {
      console.error(`日程插入失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 更新日程
  async updateSchedule(scheduleID: number, updatedData: scheduleClass.Schedule): Promise<void> {
    const schedule = scheduleToValuesBucket(updatedData)
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule");
      predicates.equalTo("schedule_sn", scheduleID); // 通过 ID 识别日程

      const rowsUpdated = await this.db.update(schedule, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`更新成功，更新的行数：${rowsUpdated}`);
    } catch (err) {
      console.error(`更新失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 删除日程
  async deleteSchedule(scheduleID: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule");
      predicates.equalTo("schedule_sn", scheduleID); // 通过 ID 查找日程

      const rowsDeleted = await this.db.delete(predicates);
      console.info(`删除成功，删除的行数：${rowsDeleted}`);
    } catch (err) {
      console.error(`删除失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 查询所有日程
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
        let testCnt = 0;

        console.info(resultSet.rowCount.toString());

        // 遍历查询结果集并填充到 schedules 数组中
        while (resultSet.goToNextRow()) {
          console.info('第' + testCnt + '项日程');
          testCnt++;

          const content: string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
          const name: string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
          const startTime:Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
          console.info(resultSet.getString(resultSet.getColumnIndex("start_time")))
          const endTime:Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
          console.info(resultSet.getString(resultSet.getColumnIndex("end_time")))
          const circular: number = resultSet.getLong(resultSet.getColumnIndex("circular"));
          const prior: number = resultSet.getLong(resultSet.getColumnIndex("prior"));
          const status: boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
          const parent: number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));

          schedules.push(new Schedule(
            content, name, circular, prior, status, startTime, endTime, parent
          ));
        }

        resultSet.close(); // 释放内存
        resolve(schedules); // 在查询完成后解析 Promise
      });
    });
  }


  // 查询日程
  async queryScheduleBySn(scheduleSn: number): Promise<Schedule[]> {
    let schedules:Schedule[] = []
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
      console.info('第' + 0 + '项日程')

      let testCnt = 0;

      while (resultSet.goToNextRow()){
        console.info('第' + testCnt + '项日程')
        testCnt++;
        const content :string = resultSet.getString(resultSet.getColumnIndex("schedule_content"));
        const name:string = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
        const startTime:Date = new Date(resultSet.getString(resultSet.getColumnIndex("start_time")));
        console.info(resultSet.getString(resultSet.getColumnIndex("start_time")))
        const endTime:Date = new Date(resultSet.getString(resultSet.getColumnIndex("end_time")));
        console.info(resultSet.getString(resultSet.getColumnIndex("end_time")))
        const circular:number = resultSet.getLong(resultSet.getColumnIndex("circular"));
        const prior:number = resultSet.getLong(resultSet.getColumnIndex("prior"))
        const status:boolean = Boolean(resultSet.getLong(resultSet.getColumnIndex("status")));
        const parent:number = resultSet.getLong(resultSet.getColumnIndex("parent_schedule_sn"));
        schedules.push(new Schedule(
          content,name,circular,prior,status,startTime,endTime,parent
        ))
        resultSet.close(); // 释放内存
      }
    });
    console.info('有' + schedules.length.toString())
    return schedules;
  }
  //------------------------关于日程列表的访问----------------------------

  // 增加日程列表
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

  // 更新日程列表
  async updateScheduleList(listID: number, updatedData: scheduleClass.ScheduleList): Promise<void> {
    const valuesBucket = scheduleListToValuesBucket(updatedData);
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule_list");
      predicates.equalTo("list_sn", listID); // 通过 ID 识别日程列表

      const rowsUpdated = await this.db.update(valuesBucket, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`日程列表更新成功，更新的行数：${rowsUpdated}`);
    } catch (err) {
      console.error(`日程列表更新失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 删除日程列表
  async deleteScheduleList(listID: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("schedule_list");
      predicates.equalTo("list_sn", listID); // 通过 ID 查找日程列表

      const rowsDeleted = await this.db.delete(predicates);
      console.info(`日程列表删除成功，删除的行数：${rowsDeleted}`);
    } catch (err) {
      console.error(`日程列表删除失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 查询日程列表
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
  //------------------------关于标签的访问----------------------------

  // 增加标签
  async addTag(tag: scheduleClass.Tag): Promise<void> {
    const valuesBucket = tagToValuesBucket(tag);
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const rowId = await this.db.insert("tag", valuesBucket);
      console.info(`标签插入成功，rowId = ${rowId}`);
    } catch (err) {
      console.error(`标签插入失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 更新标签
  async updateTag(tagID: number, updatedTag: scheduleClass.Tag): Promise<void> {
    const valuesBucket = tagToValuesBucket(updatedTag);
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("tag");
      predicates.equalTo("tag_sn", tagID); // 通过 ID 识别标签

      const rowsUpdated = await this.db.update(valuesBucket, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`标签更新成功，更新的行数：${rowsUpdated}`);
    } catch (err) {
      console.error(`标签更新失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 删除标签
  async deleteTag(tagID: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates("tag");
      predicates.equalTo("tag_sn", tagID); // 通过 ID 查找标签

      const rowsDeleted = await this.db.delete(predicates);
      console.info(`标签删除成功，删除的行数：${rowsDeleted}`);
    } catch (err) {
      console.error(`标签删除失败，错误代码: ${err.code}，信息: ${err.message}`);
    }
  }

  // 查询标签
  async queryTagBySn(tagSn: number): Promise<void> {
    if (this.db === null) {
      console.error("数据库未初始化");
      return;
    }
    const predicates = new relationalStore.RdbPredicates("tag");
    predicates.equalTo("tag_sn", tagSn);

    this.db.query(predicates, (err, resultSet) => {
      if (err) {
        console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
        return;
      }

      console.info(`查询结果列数：${resultSet.columnCount}`);
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex("tag_sn"));
        const name = resultSet.getString(resultSet.getColumnIndex("tag_name"));

        console.info(`ID=${id}, 名称=${name}`);
      }
      resultSet.close(); // 释放内存
    });
  }
}