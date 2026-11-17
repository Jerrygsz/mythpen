export class NovelProject {
  id: string = ''
  name: string = ''
  summary: string = ''
  language: string = 'zh'
  mode: string = 'medium-novel'
  createdAt: number = 0
  updatedAt: number = 0
  chapterCount: number = 0
  wordCount: number = 0
}

export class NovelChapter {
  id: number = 0
  volumeId: number = 0
  num: number = 0
  title: string = ''
  outline: string = ''
  content: string = ''
  summary: string = ''
  wordCount: number = 0
  status: string = 'pending'
  cognitiveFrame: string = ''
  emotionalAnchor: string = ''
  worldTexture: string = ''
  concreteMystery: string = ''
  interpersonalTension: string = ''
  genreBeat: string = ''
  updatedAt: string = ''
}
