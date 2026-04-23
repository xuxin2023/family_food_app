// 日期工具类
export class DateUtil {
    /**
     * 获取今日日期字符串 YYYY-MM-DD
     */
    static getToday(): string {
        const now = new Date();
        return DateUtil.formatDate(now);
    }
    /**
     * 格式化日期为 YYYY-MM-DD
     */
    static formatDate(date: Date): string {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
    /**
     * 格式化时间为 HH:mm
     */
    static formatTime(date: Date): string {
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`;
    }
    /**
     * 计算两个时间字符串(HH:mm)之间的分钟差
     */
    static minutesBetween(time1: string, time2: string): number {
        const parts1 = time1.split(':');
        const parts2 = time2.split(':');
        const h1 = Number(parts1[0]);
        const m1 = Number(parts1[1]);
        const h2 = Number(parts2[0]);
        const m2 = Number(parts2[1]);
        return (h2 * 60 + m2) - (h1 * 60 + m1);
    }
    /**
     * 格式化时间戳为友好显示
     */
    static formatTimestamp(timestamp: number): string {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - timestamp;
        const diffMin = Math.floor(diffMs / 60000);
        const diffHour = Math.floor(diffMs / 3600000);
        const diffDay = Math.floor(diffMs / 86400000);
        if (diffMin < 1)
            return '刚刚';
        if (diffMin < 60)
            return `${diffMin}分钟前`;
        if (diffHour < 24 && date.getDate() === now.getDate())
            return `今天 ${DateUtil.formatTime(date)}`;
        if (diffDay === 1)
            return `昨天 ${DateUtil.formatTime(date)}`;
        return DateUtil.formatDate(date);
    }
}
