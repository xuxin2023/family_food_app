import {
  ToastHelper, safeBack, KnowledgeArticle, getAllKnowledgeArticles, getArticleCategories, getArticlesByCategory, COLORS, FONT_SIZE, RADIUS, SPACING, LazyDataSource, PageResourceTracker, createPageTracker
} from 'hsp_core';
import { NutritionKnowledgeService, KnowledgeEntry } from 'hsp_service';
import { BackButton } from '../components/BackButton';
import { EmptyState } from '../components/EmptyState';

@Entry
@ComponentV2
struct NutritionKnowledgePage {
  @Local allArticles: KnowledgeArticle[] = []
  @Local categories: string[] = []
  @Local selectedCategory: string = ''
  @Local filteredArticles: KnowledgeArticle[] = []
  @Local expandedArticleId: string = ''
  @Local searchKeyword: string = ''
  @Local searchResults: KnowledgeEntry[] = []
  @Local showSearchResults: boolean = false

  private knowledgeService: NutritionKnowledgeService = NutritionKnowledgeService.getInstance()
  private articleDataSource: LazyDataSource<KnowledgeArticle> = new LazyDataSource()
  private tracker: PageResourceTracker = createPageTracker('NutritionKnowledgePage')

  aboutToAppear(): void {
    this.tracker.onAppear()
    this.allArticles = getAllKnowledgeArticles()
    this.categories = getArticleCategories()
    if (this.categories.length > 0) {
      this.selectedCategory = this.categories[0]
      this.filteredArticles = getArticlesByCategory(this.selectedCategory)
      this.articleDataSource.reloadData(this.filteredArticles)
    }
    this.syncToKnowledgeService()
  }

  aboutToDisappear(): void { this.tracker.onDisappear() }

  private syncToKnowledgeService(): void {
    for (const article of this.allArticles) {
      const entry: KnowledgeEntry = {
        id: article.id,
        title: article.title,
        category: article.category ?? '通用',
        summary: article.summary,
        details: article.content,
        relatedNutrients: article.tags ?? [],
        references: []
      };
      this.knowledgeService.addEntry(entry);
    }
  }

  private performSearch(keyword: string): void {
    if (keyword.length === 0) {
      this.showSearchResults = false;
      this.searchResults = [];
      return;
    }
    this.searchResults = this.knowledgeService.searchByKeyword(keyword);
    this.showSearchResults = true;
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('返回')
            .accessibilityLevel('yes')
          Text($r('app.string.nutrition_knowledge_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        TextInput({ placeholder: '搜索营养知识...', text: this.searchKeyword })
          .width('92%')
          .height(40)
          .fontSize(14)
          .borderRadius(20)
          .backgroundColor(COLORS.WHITE)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.performSearch(value);
          })
          .accessibilityText('搜索营养知识')
          .accessibilityLevel('yes')

        if (this.showSearchResults && this.searchResults.length > 0) {
          Column() {
            Text(`找到 ${this.searchResults.length} 条相关结果`)
              .fontSize(12)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ bottom: 8 })
            ForEach(this.searchResults, (entry: KnowledgeEntry, index: number) => {
              Column() {
                Text(entry.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.TEXT_PRIMARY)
                Text(entry.summary).fontSize(12).fontColor(COLORS.TEXT_SECONDARY).margin({ top: 2 }).maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(RADIUS.MD)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 8 })
              .accessibilityText(entry.title)
              .accessibilityLevel('yes')
            }, (entry: KnowledgeEntry, index: number) => entry.id)
          }
          .width('92%')
          .margin({ bottom: 14 })
        }

        this.CategoryTabs()

        this.ArticleList()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  CategoryTabs() {
    Row() {
      ForEach(this.categories, (cat: string, index: number) => {
        Text(cat)
          .fontSize(13)
          .fontColor(this.selectedCategory === cat ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
          .backgroundColor(this.selectedCategory === cat ? COLORS.PRIMARY : COLORS.BG_LIGHT)
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ right: 8 })
          .onClick(() => {
            this.selectedCategory = cat
            this.filteredArticles = getArticlesByCategory(cat)
            this.articleDataSource.reloadData(this.filteredArticles)
            this.expandedArticleId = ''
          })
          .accessibilityText(cat)
          .accessibilityLevel('yes')
      }, (cat: string, index: number) => cat + index)
    }
    .width('92%')
    .margin({ bottom: 14 })
  }

  @Builder
  ArticleList() {
    if (this.filteredArticles.length === 0) {
      EmptyState({
        icon: '🔍',
        title: $r('app.string.nutrition_knowledge_no_match'),
        subtitle: $r('app.string.nutrition_knowledge_no_match_hint'),
        topPadding: 40
      })
    } else {
      Column() {
        LazyForEach(this.articleDataSource, (article: KnowledgeArticle, index: number) => {
          this.ArticleCard(article)
        }, (article: KnowledgeArticle) => article.id)
      }
      .width('92%')
      .margin({ bottom: 24 })
    }
  }

  @Builder
  ArticleCard(article: KnowledgeArticle) {
    Column() {
      Row() {
        Column() {
          Text(article.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(article.summary)
            .fontSize(13)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.expandedArticleId === article.id ? $r('app.string.nutrition_knowledge_collapse') : $r('app.string.nutrition_knowledge_expand'))
          .fontSize(13)
          .fontColor(COLORS.PRIMARY)
          .margin({ left: 8 })
      }
      .width('100%')
      .onClick(() => {
        this.expandedArticleId = this.expandedArticleId === article.id ? '' : article.id
      })
      .accessibilityText(article.title)
      .accessibilityLevel('yes')

      if (this.expandedArticleId === article.id) {
        Column() {
          Text(article.content)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .lineHeight(22)

          if (article.tags.length > 0) {
            Row() {
              ForEach(article.tags, (tag: string) => {
                Text('#' + tag)
                  .fontSize(11)
                  .fontColor(COLORS.PRIMARY)
                  .backgroundColor(COLORS.BG_WARM_PINK)
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .margin({ right: 6, top: 4 })
              }, (tag: string, idx: number) => tag + idx)
            }
            .margin({ top: 12 })
          }
        }
        .width('100%')
        .padding({ top: 12 })
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 10 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
