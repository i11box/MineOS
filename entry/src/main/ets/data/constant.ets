import relationalStore from '@ohos.data.relationalStore';
import { securityLabel } from '@kit.CoreFileKit';

export const DB_NAME = 'J_OS.db'
export const DB_CONFIG : relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

// Schedule 表定义
export const GET_TABLE_SCHEDULE = `
  CREATE TABLE IF NOT EXISTS schedule (
      schedule_sn INTEGER PRIMARY KEY,
      schedule_name TEXT NOT NULL,
      start_time TEXT,                -- 使用 ISO8601 格式的字符串存储日期时间
      end_time TEXT,                  -- 使用 ISO8601 格式的字符串存储日期时间
      schedule_content TEXT,
      prior INTEGER,                  -- 使用 INTEGER 替代 SMALLINT
      circular INTEGER,
      status INTEGER,                 -- 0 或 1 表示布尔值
      schedule_list_sn INTEGER,       -- 新增字段，用于与 schedule_list 表关联
      parent_schedule_sn INTEGER,
      FOREIGN KEY(schedule_list_sn) REFERENCES schedule_list(list_sn),
      FOREIGN KEY(parent_schedule_sn) REFERENCES schedule(schedule_sn)
  );
`;

// ScheduleList 表定义
export const GET_TABLE_SCHEDULE_LIST = `
  CREATE TABLE IF NOT EXISTS schedule_list (
      list_sn INTEGER PRIMARY KEY,
      list_name TEXT NOT NULL
  );
`;

// ScheduleList_Schedule 关联表定义
export const GET_TABLE_SCHEDULE_LIST_SCHEDULE = `
  CREATE TABLE IF NOT EXISTS schedule_list_schedule (
    list_sn INTEGER NOT NULL,
    schedule_sn INTEGER NOT NULL,
    FOREIGN KEY(list_sn) REFERENCES schedule_list(list_sn),
    FOREIGN KEY(schedule_sn) REFERENCES schedule(schedule_sn),
    UNIQUE(list_sn, schedule_sn)
  );
`;

// ScheduleList_Schedule 关联表定义
export const GET_TABLE_VIEW = `
  CREATE TABLE IF NOT EXISTS view (
    view_sn INTEGER NOT NULL,
    days INTEGER,
    schedule_sn INTEGER NOT NULL,
    FOREIGN KEY(schedule_sn) REFERENCES schedule(schedule_sn),
  );
`;

export const GET_TABLE:string[] = [
  GET_TABLE_SCHEDULE,
  GET_TABLE_SCHEDULE_LIST,
  GET_TABLE_SCHEDULE_LIST_SCHEDULE,
  GET_TABLE_VIEW
]