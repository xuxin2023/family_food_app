import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, FamilyProfile } from 'hsp_core';

const TAG = 'HuaweiCloudStorageService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface CloudBackupData {
  version: string
  timestamp: number
  deviceId: string
  userId: string
  foodLabels: FoodLabel[]
  familyProfiles: FamilyProfile[]
  scanHistory: Object[]
  userSettings: Object
}

export interface CloudStorageConfig {
  region: string
  bucketName: string
  accessKey: string
  secretKey: string
  endpoint: string
}

export interface UploadResult {
  success: boolean
  objectKey?: string
  url?: string
  error?: string
}

export interface DownloadResult {
  success: boolean
  data?: CloudBackupData
  error?: string
}

export interface BackupListItem {
  timestamp: number
  size: number
}

interface ObsListResult {
  Contents?: Object[]
  Key?: string
  Size?: number
}

export class HuaweiCloudStorageService {
  private static instance: HuaweiCloudStorageService | null = null
  private config: CloudStorageConfig | null = null
  private baseUrl: string = ''
  private authToken: string = ''
  private tokenExpireTime: number = 0

  static getInstance(): HuaweiCloudStorageService {
    if (!HuaweiCloudStorageService.instance) {
      HuaweiCloudStorageService.instance = new HuaweiCloudStorageService()
    }
    return HuaweiCloudStorageService.instance
  }

  async initialize(config: CloudStorageConfig): Promise<void> {
    this.config = config
    this.baseUrl = `https://obs.${config.region}.myhuaweicloud.com`
    hilog.info(DOMAIN, TAG, 'HuaweiCloudStorageService initialized')
  }

  private async authenticate(): Promise<boolean> {
    if (!this.config) {
      hilog.error(DOMAIN, TAG, 'Config not initialized')
      return false
    }

    if (this.authToken && Date.now() < this.tokenExpireTime) {
      return true
    }

    try {
      let httpRequest: http.HttpRequest;
      try {
        httpRequest = http.createHttp()
      } catch (createErr) {
        hilog.error(DOMAIN, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr))
        return false
      }
      const response = await httpRequest.request(
        `https://iam.${this.config.region}.myhuaweicloud.com/v3/auth/tokens`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            auth: {
              identity: {
                methods: ['aksk'],
                aksk: {
                  access_key: this.config.accessKey,
                  secret_key: this.config.secretKey
                }
              },
              scope: {
                project: {
                  name: this.config.region
                }
              }
            }
          }
        }
      )

      if (response.responseCode === 201) {
        this.authToken = response.header['X-Subject-Token'] as string || ''
        this.tokenExpireTime = Date.now() + 3600000
        hilog.info(DOMAIN, TAG, 'Authentication successful')
        return true
      } else {
        hilog.error(DOMAIN, TAG, 'Authentication failed: %{public}d', response.responseCode)
        return false
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Authentication error: %{public}s', JSON.stringify(err))
      return false
    }
  }

  async uploadBackup(data: CloudBackupData): Promise<UploadResult> {
    if (!this.config) {
      const result: UploadResult = { success: false, error: 'Config not initialized' };
      return result;
    }

    const authenticated = await this.authenticate()
    if (!authenticated) {
      const result: UploadResult = { success: false, error: 'Authentication failed' };
      return result;
    }

    const objectKey = `backups/${data.userId}/${data.timestamp}.json`
    
    try {
      let httpRequest: http.HttpRequest;
      try {
        httpRequest = http.createHttp()
      } catch (createErr) {
        hilog.error(DOMAIN, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr))
        const result: UploadResult = { success: false, error: 'HTTP client creation failed' };
        return result;
      }
      const response = await httpRequest.request(
        `${this.baseUrl}/${this.config.bucketName}/${objectKey}`,
        {
          method: http.RequestMethod.PUT,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.authToken}`,
            'x-obs-storage-class': 'STANDARD'
          },
          extraData: JSON.stringify(data)
        }
      )

      if (response.responseCode === 200 || response.responseCode === 201) {
        const url = `https://${this.config.bucketName}.obs.${this.config.region}.myhuaweicloud.com/${objectKey}`
        hilog.info(DOMAIN, TAG, 'Upload successful: %{public}s', objectKey)
        const result: UploadResult = { success: true, objectKey: objectKey, url: url };
        return result;
      } else {
        hilog.error(DOMAIN, TAG, 'Upload failed: %{public}d', response.responseCode)
        const result: UploadResult = { success: false, error: `Upload failed: ${response.responseCode}` };
        return result;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Upload error: %{public}s', JSON.stringify(err))
      const result: UploadResult = { success: false, error: JSON.stringify(err) };
      return result;
    }
  }

  async downloadBackup(userId: string, timestamp?: number): Promise<DownloadResult> {
    if (!this.config) {
      const result: DownloadResult = { success: false, error: 'Config not initialized' };
      return result;
    }

    const authenticated = await this.authenticate()
    if (!authenticated) {
      const result: DownloadResult = { success: false, error: 'Authentication failed' };
      return result;
    }

    const objectKey = timestamp 
      ? `backups/${userId}/${timestamp}.json`
      : `backups/${userId}/latest.json`

    try {
      let httpRequest: http.HttpRequest;
      try {
        httpRequest = http.createHttp()
      } catch (createErr) {
        hilog.error(DOMAIN, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr))
        const result: DownloadResult = { success: false, error: 'HTTP client creation failed' };
        return result;
      }
      const response = await httpRequest.request(
        `${this.baseUrl}/${this.config.bucketName}/${objectKey}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      )

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as CloudBackupData
        hilog.info(DOMAIN, TAG, 'Download successful: %{public}s', objectKey)
        const result: DownloadResult = { success: true, data: data };
        return result;
      } else {
        hilog.error(DOMAIN, TAG, 'Download failed: %{public}d', response.responseCode)
        const result: DownloadResult = { success: false, error: `Download failed: ${response.responseCode}` };
        return result;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Download error: %{public}s', JSON.stringify(err))
      const result: DownloadResult = { success: false, error: JSON.stringify(err) };
      return result;
    }
  }

  async listBackups(userId: string): Promise<BackupListItem[]> {
    if (!this.config) {
      return []
    }

    const authenticated = await this.authenticate()
    if (!authenticated) {
      return []
    }

    try {
      let httpRequest: http.HttpRequest;
      try {
        httpRequest = http.createHttp()
      } catch (createErr) {
        hilog.error(DOMAIN, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr))
        return []
      }
      const response: http.HttpResponse = await httpRequest.request(
        `${this.baseUrl}/${this.config.bucketName}?prefix=backups/${userId}/`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      )

      if (response.responseCode === 200) {
        const result: ObsListResult = JSON.parse(response.result as string) as ObsListResult
        const contents: Object[] = result.Contents ?? []
        const backups: BackupListItem[] = []
        
        for (const item of contents) {
          const obsItem: ObsListResult = item as ObsListResult
          const key: string = obsItem.Key ?? ''
          const size: number = obsItem.Size ?? 0
          const match: RegExpMatchArray | null = key.match(/backups\/\w+\/(\d+)\.json/)
          if (match) {
            const backupItem: BackupListItem = {
              timestamp: parseInt(match[1]),
              size: size
            }
            backups.push(backupItem)
          }
        }
        
        return backups.sort((a: BackupListItem, b: BackupListItem): number => b.timestamp - a.timestamp)
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'List backups error: %{public}s', JSON.stringify(err))
    }
    
    return []
  }

  async deleteBackup(userId: string, timestamp: number): Promise<boolean> {
    if (!this.config) {
      return false
    }

    const authenticated = await this.authenticate()
    if (!authenticated) {
      return false
    }

    const objectKey = `backups/${userId}/${timestamp}.json`

    try {
      let httpRequest: http.HttpRequest;
      try {
        httpRequest = http.createHttp()
      } catch (createErr) {
        hilog.error(DOMAIN, TAG, 'createHttp failed: %{public}s', JSON.stringify(createErr))
        return false
      }
      const response = await httpRequest.request(
        `${this.baseUrl}/${this.config.bucketName}/${objectKey}`,
        {
          method: http.RequestMethod.DELETE,
          header: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      )

      if (response.responseCode === 204 || response.responseCode === 200) {
        hilog.info(DOMAIN, TAG, 'Delete successful: %{public}s', objectKey)
        return true
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Delete error: %{public}s', JSON.stringify(err))
    }
    
    return false
  }

  async createBackup(
    userId: string,
    deviceId: string,
    foodLabels: FoodLabel[],
    familyProfiles: FamilyProfile[],
    scanHistory: Object[],
    userSettings: Object
  ): Promise<UploadResult> {
    const backupData: CloudBackupData = {
      version: '1.0.0',
      timestamp: Date.now(),
      deviceId: deviceId,
      userId: userId,
      foodLabels: foodLabels,
      familyProfiles: familyProfiles,
      scanHistory: scanHistory,
      userSettings: userSettings
    }

    return await this.uploadBackup(backupData)
  }

  async restoreFromBackup(userId: string, timestamp?: number): Promise<CloudBackupData | null> {
    const result = await this.downloadBackup(userId, timestamp)
    if (result.success && result.data) {
      return result.data
    }
    return null
  }

  destroy(): void {
    this.authToken = ''
    this.tokenExpireTime = 0
    HuaweiCloudStorageService.instance = null
    hilog.info(DOMAIN, TAG, 'HuaweiCloudStorageService destroyed')
  }
}