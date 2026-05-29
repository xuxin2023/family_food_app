import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { getGlobalState } from 'hsp_core';

const TAG = 'ChatHistoryPrefs';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREFS_NAME = 'ai_chat_history';

export class ChatHistoryPrefsService {
  private static _instance: ChatHistoryPrefsService | null = null;
  static getInstance(): ChatHistoryPrefsService {
    if (!ChatHistoryPrefsService._instance) {
      ChatHistoryPrefsService._instance = new ChatHistoryPrefsService();
    }
    return ChatHistoryPrefsService._instance;
  }

  async getMessages(memberId: string): Promise<string> {
    try {
      const context = getGlobalState().getAppContext();
      if (!context) return '[]';
      const prefs = await preferences.getPreferences(context, { name: PREFS_NAME });
      const key = `messages_${memberId}`;
      return await prefs.get(key, '[]') as string;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'getMessages failed: %{public}s', JSON.stringify(e));
      return '[]';
    }
  }

  async saveMessages(memberId: string, json: string): Promise<void> {
    try {
      const context = getGlobalState().getAppContext();
      if (!context) return;
      const prefs = await preferences.getPreferences(context, { name: PREFS_NAME });
      const key = `messages_${memberId}`;
      await prefs.put(key, json);
      await prefs.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveMessages failed: %{public}s', JSON.stringify(e));
    }
  }
}
