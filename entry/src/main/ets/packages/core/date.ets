export const formatDateTime = (date: Date): string => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false, // 使用24小时制
  };

  return new Intl.DateTimeFormat("zh-CN", options)
    .format(date)
    .replace(/\//g, ".") // 将斜杠替换为点号
    .replace(",", " ");  // 将逗号替换为空格
};