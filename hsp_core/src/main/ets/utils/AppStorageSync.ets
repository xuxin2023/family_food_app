export class AppStorageKeys {
  static readonly NETWORK_IS_ONLINE: string = 'networkIsOnline';
  static readonly CURRENT_MEMBER_ID: string = 'currentMemberId';
  static readonly FAMILY_MEMBER_COUNT: string = 'familyMemberCount';
  static readonly FAVORITE_COUNT: string = 'favoriteCount';
}

export class AppStorageSync {
  static syncNetworkState(isOnline: boolean): void {
    AppStorage.setOrCreate(AppStorageKeys.NETWORK_IS_ONLINE, isOnline);
  }

  static syncCurrentMemberId(memberId: string): void {
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_MEMBER_ID, memberId);
  }

  static syncFamilyMemberCount(count: number): void {
    AppStorage.setOrCreate(AppStorageKeys.FAMILY_MEMBER_COUNT, count);
  }

  static syncFavoriteCount(count: number): void {
    AppStorage.setOrCreate(AppStorageKeys.FAVORITE_COUNT, count);
  }
}
