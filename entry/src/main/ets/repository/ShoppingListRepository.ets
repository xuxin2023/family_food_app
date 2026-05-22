// repository/ShoppingListRepository.ets
import { ShoppingItem } from 'hsp_core';

export class ShoppingListRepository {
  private items: ShoppingItem[] = [];

  async init(_rdbStore: ESObject): Promise<void> {}

  async getAll(): Promise<string[]> { return []; }
  async add(_item: string): Promise<void> {}
  async remove(_item: string): Promise<void> {}
  async clear(): Promise<void> {}

  async addItem(item: ShoppingItem): Promise<boolean> {
    this.items.push(item);
    return true;
  }

  async removeItem(id: string): Promise<void> {
    this.items = this.items.filter(i => i.id !== id);
  }

  async togglePurchased(id: string): Promise<void> {
    const item = this.items.find(i => i.id === id);
    if (item) {
      item.isPurchased = !item.isPurchased;
    }
  }

  async clearPurchased(): Promise<number> {
    const count = this.items.filter(i => i.isPurchased).length;
    this.items = this.items.filter(i => !i.isPurchased);
    return count;
  }

  async getAllItems(): Promise<ShoppingItem[]> {
    return [...this.items];
  }

  async importRows(_rows: Record<string, Object>[]): Promise<number> { return 0; }
}
