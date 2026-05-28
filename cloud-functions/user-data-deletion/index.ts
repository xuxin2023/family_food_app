import cloudDB from '@hw-agcloud/cloud-database';

interface DeletionRequest {
  userId: string;
  scope: 'full' | 'partial';
  retainAnonymousStats?: boolean;
}

interface DeletionResult {
  success: boolean;
  deletedCollections: string[];
  deletedRecordCount: number;
  deletionTime: number;
  errors: string[];
}

const USER_COLLECTIONS = [
  'FamilyProfile',
  'HealthSignal',
  'DietRecord',
  'DailyBudget',
  'ScanHistory',
  'ChatHistory',
  'ShoppingList',
  'NutritionTarget',
  'ReminderRule'
];

export const handler = async (event: { body: string }): Promise<DeletionResult> => {
  const request: DeletionRequest = JSON.parse(event.body);
  const { userId, scope } = request;

  const result: DeletionResult = {
    success: false,
    deletedCollections: [],
    deletedRecordCount: 0,
    deletionTime: Date.now(),
    errors: []
  };

  try {
    const db = cloudDB.db();
    const collections = scope === 'partial'
      ? ['ScanHistory', 'ChatHistory', 'ShoppingList']
      : USER_COLLECTIONS;

    for (const collection of collections) {
      try {
        const deleteResult = await db.collection(collection)
          .where({ memberId: userId })
          .remove();
        result.deletedCollections.push(collection);
        result.deletedRecordCount += (deleteResult as Record<string, number>).deletedCount ?? 0;
      } catch (e) {
        result.errors.push(`Failed to delete ${collection}: ${(e as Error).message}`);
      }
    }

    result.success = result.errors.length === 0;
  } catch (e) {
    result.errors.push(`Database connection failed: ${(e as Error).message}`);
  }

  return result;
};
