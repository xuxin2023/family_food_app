import { DateUtil, HILOG_DOMAIN } from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AppState } from '../AppState';

const TAG = 'DataExportService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

class ExportData {
  exportVersion: string = '';
  exportDate: string = '';
  members: Object[] = [];
  scanHistory: Object[] = [];
  dietRecords: Object[] = [];
  recipes: Object[] = [];
}

export class DataExportService {
  private static instance: DataExportService | null = null;

  static getInstance(): DataExportService {
    if (!DataExportService.instance) {
      DataExportService.instance = new DataExportService();
    }
    return DataExportService.instance;
  }

  async exportAllData(context: common.Context): Promise<string> {
    const appState = AppState.getInstance();
    const exportData = new ExportData();
    exportData.exportVersion = '1.0';
    exportData.exportDate = new Date().toISOString();
    exportData.members = await appState.familyRepo.getAllMembers();
    exportData.scanHistory = await appState.historyRepo.getAllRecords();
    exportData.dietRecords = await appState.historyRepo.getAllDietRecords();
    exportData.recipes = await appState.recipeRepo.getAllRecipes();

    const json = JSON.stringify(exportData, null, 2);
    const fileName = `family_food_export_${DateUtil.getToday()}.json`;
    const filePath = `${context.filesDir}/${fileName}`;

    let file: fs.File | null = null;
    try {
      file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.TRUNCATE | fs.OpenMode.WRITE_ONLY);
      await fs.write(file.fd, json);
      hilog.info(DOMAIN_ZERO, TAG, 'Data exported to: %{private}s', filePath);
      return filePath;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Data export write failed: %{public}s', JSON.stringify(error));
      throw error;
    } finally {
      if (file !== null) {
        await fs.close(file.fd);
      }
    }
  }
}
