import relationalStore from '@ohos.data.relationalStore';
import { securityLabel } from '@kit.CoreFileKit';

//-----------数据库基本配置--------------

export const DB_NAME = 'J_OS.db'
export const DB_CONFIG : relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

//-----------数据库语句----------------
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
    UNIQUE(list_sn, schedule_sn)
  );
`;

// ScheduleList_Schedule 关联表定义
export const GET_TABLE_VIEW = `
  CREATE TABLE IF NOT EXISTS view (
    view_sn INTEGER NOT NULL,
    days INTEGER,
    schedule_list_sn INTEGER NOT NULL,
    FOREIGN KEY(schedule_list_sn) REFERENCES schedule_list(list_sn)
  );
`;

export const DROP_TABLE_TAG = `
  DROP TABLE schedule_tag;
  DROP TABLE schedule_list_schedule_new;
`;

export const DROP_TABLE_SCHEDULE_LIST = `
  DROP TABLE IF EXISTS schedule_list;
`;

export const UPDATE_TABLE_SCHEDULE_LIST_SCHEDULE = `
  CREATE TABLE IF NOT EXISTS schedule_list_schedule_new (
    list_sn INTEGER NOT NULL,
    schedule_sn INTEGER NOT NULL,
    UNIQUE(list_sn, schedule_sn)
  );

  INSERT INTO schedule_list_schedule_new (list_sn, schedule_sn)
  SELECT list_sn, schedule_sn
  FROM schedule_list_schedule;

  DROP TABLE schedule_list_schedule;

  ALTER TABLE schedule_list_schedule_new
  RENAME TO schedule_list_schedule;
`

export const DROP_TABLE_VIEW = `
  DROP TABLE IF EXISTS view;
`

export const CREATE_TABLE_VIEW = `
  CREATE TABLE IF NOT EXISTS view(
    view_sn INTEGER NOT NULL,
    name TEXT NOT NULL,
    days INTEGER,
    list_sn INTEGER
  )
`

export const GET_TABLE:string[] = [
  DROP_TABLE_VIEW,
  CREATE_TABLE_VIEW
]