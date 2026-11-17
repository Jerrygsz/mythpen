import { NovelProject, NovelChapter } from '../model/NovelModels'
import { NovelRepository } from '../data/NovelRepository'

@Entry
@Component
struct Index {
  @State projects: Array<NovelProject> = []
  @State selectedProject: NovelProject | null = null
  @State chapters: Array<NovelChapter> = []
  @State selectedChapter: NovelChapter | null = null
  @State chapterTitle: string = ''
  @State chapterContent: string = ''
  @State newProjectName: string = ''
  @State newProjectSummary: string = ''
  @State newChapterTitle: string = ''
  @State showCreateProject: boolean = false
  @State showCreateChapter: boolean = false
  @State statusMessage: string = '本地离线 · 数据保存在本机'

  aboutToAppear(): void {
    this.initialize()
  }

  private async initialize(): Promise<void> {
    try {
      await NovelRepository.initialize(getContext(this))
      await this.reloadProjects()
    } catch (err) {
      this.statusMessage = '数据库初始化失败，请检查 API 9 SDK 配置'
    }
  }

  private async reloadProjects(): Promise<void> {
    this.projects = await NovelRepository.listProjects()
  }

  private async openProject(project: NovelProject): Promise<void> {
    this.selectedProject = project
    this.selectedChapter = null
    this.chapters = await NovelRepository.listChapters(project.id)
  }

  private async openChapter(chapter: NovelChapter): Promise<void> {
    this.selectedChapter = chapter
    this.chapterTitle = chapter.title
    this.chapterContent = chapter.content
  }

  private async createProject(): Promise<void> {
    const name = this.newProjectName.trim()
    if (name.length === 0) {
      this.statusMessage = '先给小说起个名字'
      return
    }
    try {
      await NovelRepository.createProject(name, this.newProjectSummary)
      this.newProjectName = ''
      this.newProjectSummary = ''
      this.showCreateProject = false
      await this.reloadProjects()
      this.statusMessage = '项目已保存到本机'
    } catch (err) {
      this.statusMessage = '创建失败：名称可能重复'
    }
  }

  private async createChapter(): Promise<void> {
    if (this.selectedProject === null) {
      return
    }
    await NovelRepository.createChapter(this.selectedProject.id, this.newChapterTitle)
    this.newChapterTitle = ''
    this.showCreateChapter = false
    this.chapters = await NovelRepository.listChapters(this.selectedProject.id)
    this.statusMessage = '章节已创建'
  }

  private async saveCurrentChapter(): Promise<void> {
    if (this.selectedProject === null || this.selectedChapter === null) {
      return
    }
    await NovelRepository.saveChapter(
      this.selectedProject.id, this.selectedChapter.id, this.chapterTitle, this.chapterContent
    )
    this.chapters = await NovelRepository.listChapters(this.selectedProject.id)
    this.statusMessage = '已保存 · ' + this.chapterContent.replace(/\s/g, '').length + ' 字'
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('MYTHPEN').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#C49A5A')
        Blank()
        Text('原生创作').fontSize(12).fontColor('#8B8B8B')
      }
      .width('100%')

      if (this.selectedProject === null) {
        Row() {
          Column({ space: 4 }) {
            Text('把故事，写下来。').fontSize(27).fontWeight(FontWeight.Bold).fontColor('#F2EBDD')
            Text('一个安静、离线的小说工作台').fontSize(13).fontColor('#9D9A92')
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Button('＋ 新建').onClick(() => { this.showCreateProject = !this.showCreateProject })
        }.width('100%')

        if (this.showCreateProject) {
          Column({ space: 8 }) {
            TextInput({ placeholder: '小说名称', text: this.newProjectName })
              .onChange((value: string) => { this.newProjectName = value })
            TextInput({ placeholder: '一句话简介（可选）', text: this.newProjectSummary })
              .onChange((value: string) => { this.newProjectSummary = value })
            Row() {
              Button('创建项目').onClick(() => { this.createProject() })
              Button('取消').backgroundColor('#393939').onClick(() => { this.showCreateProject = false })
            }.width('100%').justifyContent(FlexAlign.End)
          }
          .padding(14)
          .backgroundColor('#242424')
          .borderRadius(12)
        }

        if (this.projects.length === 0) {
          Column({ space: 8 }) {
            Text('这里还没有故事').fontSize(18).fontColor('#E8E1D5')
            Text('新建一个项目，先写下第一章。').fontSize(13).fontColor('#92908A')
          }
          .width('100%')
          .padding(24)
          .backgroundColor('#242424')
          .borderRadius(14)
        } else {
          List({ space: 10 }) {
            ForEach(this.projects, (project: NovelProject) => {
              ListItem() {
                Row() {
                  Column({ space: 5 }) {
                    Text(project.name).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#F1EBDD')
                    Text(project.summary.length > 0 ? project.summary : '还没有写下简介')
                      .fontSize(12).fontColor('#98958D').maxLines(1)
                    Text(project.chapterCount + ' 章  ·  ' + project.wordCount + ' 字')
                      .fontSize(11).fontColor('#C49A5A')
                  }.alignItems(HorizontalAlign.Start)
                  Blank()
                  Text('›').fontSize(24).fontColor('#C49A5A')
                }
                .padding(15)
                .backgroundColor('#242424')
                .borderRadius(12)
                .onClick(() => { this.openProject(project) })
              }
            }, (project: NovelProject) => project.id)
          }
          .layoutWeight(1)
          .width('100%')
        }
      } else {
        Row() {
          Button('‹ 项目').backgroundColor('#393939').onClick(() => {
            this.selectedProject = null
            this.selectedChapter = null
            this.reloadProjects()
          })
          Text(this.selectedProject.name).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#F1EBDD')
            .layoutWeight(1).maxLines(1)
          Button('＋ 章节').onClick(() => { this.showCreateChapter = !this.showCreateChapter })
        }.width('100%')

        if (this.showCreateChapter) {
          Row() {
            TextInput({ placeholder: '章节标题', text: this.newChapterTitle })
              .layoutWeight(1)
              .onChange((value: string) => { this.newChapterTitle = value })
            Button('添加').onClick(() => { this.createChapter() })
          }.width('100%')
        }

        if (this.selectedChapter === null) {
          if (this.chapters.length === 0) {
            Text('第一章还在等你。').fontSize(15).fontColor('#AAA49A').padding(20)
          } else {
            List({ space: 8 }) {
              ForEach(this.chapters, (chapter: NovelChapter) => {
                ListItem() {
                  Row() {
                    Text('第' + chapter.num + '章').fontSize(12).fontColor('#C49A5A')
                    Column({ space: 4 }) {
                      Text(chapter.title).fontSize(15).fontColor('#EEE7DA')
                      Text(chapter.wordCount + ' 字').fontSize(11).fontColor('#8E8A82')
                    }.alignItems(HorizontalAlign.Start)
                    Blank()
                    Text('›').fontSize(22).fontColor('#C49A5A')
                  }
                  .padding(13)
                  .backgroundColor('#242424')
                  .borderRadius(10)
                  .onClick(() => { this.openChapter(chapter) })
                }
              }, (chapter: NovelChapter) => chapter.id.toString())
            }
            .layoutWeight(1)
            .width('100%')
          }
        } else {
          Row() {
            Button('‹ 章节').backgroundColor('#393939').onClick(() => {
              this.selectedChapter = null
              this.chapters = this.selectedProject === null ? [] : this.reloadChapters()
            })
            Text('第' + this.selectedChapter.num + '章').fontSize(13).fontColor('#C49A5A')
            Blank()
            Button('保存').onClick(() => { this.saveCurrentChapter() })
          }.width('100%')
          TextInput({ placeholder: '章节标题', text: this.chapterTitle })
            .fontSize(18)
            .onChange((value: string) => { this.chapterTitle = value })
          TextArea({ placeholder: '开始写作……', text: this.chapterContent })
            .layoutWeight(1)
            .fontSize(16)
            .backgroundColor('#242424')
            .fontColor('#EDE6DA')
            .onChange((value: string) => { this.chapterContent = value })
        }
      }

      Text(this.statusMessage).fontSize(11).fontColor('#8F8B83').width('100%')
    }
    .padding(18)
    .width('100%')
    .height('100%')
    .backgroundColor('#191919')
  }

  private async reloadChapters(): Promise<void> {
    if (this.selectedProject !== null) {
      this.chapters = await NovelRepository.listChapters(this.selectedProject.id)
    }
  }
}
