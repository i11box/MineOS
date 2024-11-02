import relationalStore from '@ohos.data.relationalStore';
import * as dbConstant from './constant'
import {common} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import * as scheduleClass from '../packages/schedule/schedule'

// --------------将对象转为valueBucket---------------------
function scheduleToValuesBucket(schedule:scheduleClass.Schedule): relationalStore.ValuesBucket {
  return {
    schedule_sn: schedule.scheduleSn,
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
    list_sn: scheduleList.listSn,
    list_name: scheduleList.listName,
  };
}

function tagToValuesBucket(tag: scheduleClass.Tag): relationalStore.ValuesBucket {
  return {
    tag_sn: tag.tagSn,
    tag_name: tag.tagName,
  };
}

//-----------------数据库类-------------------------------

export class DataBase{
  //----------------------数据库的属性-----------------------------
  db :relationalStore.RdbStore|undefined = undefined

  //--------------------------关于数据库的创建-------------------------
  constructor(rdb:relationalStore.RdbStore) {
    this.db = rdb;
  }

  async createTable(getTable: string) {
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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

  // 查询日程
  async queryScheduleBySn(scheduleSn: number): Promise<void> {
    if (this.db === undefined) {
      console.error("数据库未初始化");
      return;
    }
    const predicates = new relationalStore.RdbPredicates("schedule");
    predicates.equalTo("schedule_sn", scheduleSn);

    this.db.query(predicates, (err, resultSet) => {
      if (err) {
        console.error(`查询失败，错误代码: ${err.code}，信息: ${err.message}`);
        return;
      }

      console.info(`查询结果列数：${resultSet.columnCount}`);
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex("schedule_sn"));
        const name = resultSet.getString(resultSet.getColumnIndex("schedule_name"));
        const startTime = resultSet.getString(resultSet.getColumnIndex("start_time"));
        const endTime = resultSet.getString(resultSet.getColumnIndex("end_time"));
        const status = resultSet.getLong(resultSet.getColumnIndex("status"));

        console.info(`ID=${id}, 名称=${name}, 开始时间=${startTime}, 结束时间=${endTime}, 状态=${status}`);
      }
      resultSet.close(); // 释放内存
    });
  }
  //------------------------关于日程列表的访问----------------------------

  // 增加日程列表
  async addScheduleList(scheduleList: scheduleClass.ScheduleList): Promise<void> {
    const valuesBucket = scheduleListToValuesBucket(scheduleList);
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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
    if (this.db === undefined) {
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