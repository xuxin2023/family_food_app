// hsp-cloud: CloudStorage 存储客户端

export class CloudStorageClient {
  async upload(localPath: string, cloudPath: string): Promise<string> {
    return '';
  }
  async download(cloudPath: string, localPath: string): Promise<boolean> {
    return false;
  }
}