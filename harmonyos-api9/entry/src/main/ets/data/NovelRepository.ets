import relationalStore from '@ohos.data.relationalStore'
import { NovelChapter, NovelProject } from '../model/NovelModels'

/**
 * HarmonyOS API 9 local persistence.
 * Project and chapter identifiers preserve Mythpen's INTEGER/UUID distinction.
 */
export class NovelRepository {
  private static store: relationalStore.RdbStore

  static async initialize(context: Context): Promise<void> {
    if (NovelRepository.store !== undefined) {
      return
    }
    const config: relationalStore.StoreConfig = {
      name: 'mythpen_native.db',
      securityLevel: relationalStore.SecurityLevel.S1
    }
    NovelRepository.store = await relationalStore.getRdbStore(context, config)
    await NovelRepository.store.executeSql('PRAGMA foreign_keys = ON')

    const ddl: string[] = [
      `CREATE TABLE IF NOT EXISTS app_projects (
        id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE, summary TEXT DEFAULT '',
        language TEXT DEFAULT 'zh', mode TEXT DEFAULT 'medium-novel',
        created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS project_meta (
        project_id TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL DEFAULT '',
        PRIMARY KEY(project_id, key),
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS volumes (
        id INTEGER PRIMARY KEY AUTOINCREMENT, project_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL, title TEXT NOT NULL, summary TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT, project_id TEXT NOT NULL,
        volume_id INTEGER NOT NULL, num INTEGER NOT NULL, title TEXT NOT NULL,
        outline TEXT DEFAULT '', content TEXT DEFAULT '', summary TEXT DEFAULT '',
        word_count INTEGER DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending',
        cognitive_frame TEXT DEFAULT '', emotional_anchor TEXT DEFAULT '',
        world_texture TEXT DEFAULT '', concrete_mystery TEXT DEFAULT '',
        interpersonal_tension TEXT DEFAULT '', genre_beat TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE,
        FOREIGN KEY(volume_id) REFERENCES volumes(id) ON DELETE CASCADE,
        UNIQUE(project_id, num)
      )`,
      `CREATE TABLE IF NOT EXISTS characters (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, name TEXT NOT NULL,
        age TEXT DEFAULT '', gender TEXT DEFAULT '', species TEXT DEFAULT '',
        appearance TEXT DEFAULT '', personality TEXT DEFAULT '', background TEXT DEFAULT '',
        motivation TEXT DEFAULT '', arc TEXT DEFAULT '', role TEXT DEFAULT '',
        ext_markers TEXT DEFAULT '', avatar TEXT DEFAULT '', notes TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS chapter_characters (
        chapter_id INTEGER NOT NULL, character_id TEXT NOT NULL, role TEXT DEFAULT 'appears',
        PRIMARY KEY(chapter_id, character_id),
        FOREIGN KEY(chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS world_entries (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, category TEXT NOT NULL,
        name TEXT NOT NULL, description TEXT DEFAULT '', tags TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS project_genres (project_id TEXT NOT NULL, genre TEXT NOT NULL, PRIMARY KEY(project_id, genre), FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE)`,
      `CREATE TABLE IF NOT EXISTS project_styles (project_id TEXT NOT NULL, style TEXT NOT NULL, PRIMARY KEY(project_id, style), FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE)`,
      `CREATE TABLE IF NOT EXISTS foreshadows (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
        description TEXT DEFAULT '', status TEXT DEFAULT 'planted',
        planted_chapter_id INTEGER, expected_resolve_chapter INTEGER,
        resolved_chapter_id INTEGER, priority TEXT DEFAULT 'normal',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS payoff_points (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
        type TEXT DEFAULT 'other', description TEXT DEFAULT '', status TEXT DEFAULT 'planned',
        intensity INTEGER DEFAULT 3, setup_chapter INTEGER, payoff_chapter INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, category TEXT NOT NULL,
        content TEXT NOT NULL, source_chapter_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS character_relations (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, character_a_id TEXT,
        character_b_id TEXT, relation_type TEXT NOT NULL, description TEXT DEFAULT '',
        intensity INTEGER DEFAULT 3, started_at TEXT DEFAULT '', ended_at TEXT DEFAULT '',
        layout_x REAL, layout_y REAL,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS science_entries (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, label TEXT NOT NULL,
        category TEXT DEFAULT '', sort_order INTEGER DEFAULT 0, name TEXT NOT NULL,
        description TEXT DEFAULT '', references_text TEXT DEFAULT '',
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS timeline_events (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, year TEXT NOT NULL,
        title TEXT NOT NULL, description TEXT DEFAULT '', importance INTEGER DEFAULT 3,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS clue_board (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
        description TEXT DEFAULT '', kind TEXT DEFAULT 'clue',
        related_chapter_id INTEGER, resolved INTEGER DEFAULT 0, resolved_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS token_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT, project_id TEXT NOT NULL,
        task_name TEXT NOT NULL, chapter_num INTEGER, input_tokens INTEGER DEFAULT 0,
        output_tokens INTEGER DEFAULT 0, context_tokens INTEGER, model TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS chat_sessions (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT DEFAULT '新对话',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY, project_id TEXT NOT NULL, session_id TEXT NOT NULL,
        role TEXT NOT NULL, content TEXT NOT NULL, tool_calls TEXT DEFAULT '[]',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE,
        FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS assets (
        project_id TEXT NOT NULL, key TEXT NOT NULL, mime TEXT NOT NULL,
        data BLOB NOT NULL, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY(project_id, key),
        FOREIGN KEY(project_id) REFERENCES app_projects(id) ON DELETE CASCADE
      )`,
      'CREATE INDEX IF NOT EXISTS idx_native_chapters_project_num ON chapters(project_id, num)',
      'CREATE INDEX IF NOT EXISTS idx_native_world_project ON world_entries(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_native_foreshadows_project ON foreshadows(project_id)'
    ]
    for (let i = 0; i < ddl.length; i++) {
      await NovelRepository.store.executeSql(ddl[i])
    }
  }

  private static makeId(): string {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 12)
  }

  static async createProject(name: string, summary: string): Promise<void> {
    const now = Date.now()
    const id = NovelRepository.makeId()
    await NovelRepository.store.insert('app_projects', {
      id: id, name: name, summary: summary, language: 'zh',
      mode: 'medium-novel', created_at: now, updated_at: now
    })
    await NovelRepository.store.insert('volumes', {
      project_id: id, sort_order: 1, title: '第一卷', summary: ''
    })
  }

  static async listProjects(): Promise<Array<NovelProject>> {
    const rs = await NovelRepository.store.querySql(
      'SELECT p.id, p.name, p.summary, p.language, p.mode, p.created_at, p.updated_at, COUNT(c.id) AS chapter_count, COALESCE(SUM(c.word_count), 0) AS word_count FROM app_projects p LEFT JOIN chapters c ON c.project_id = p.id GROUP BY p.id ORDER BY p.updated_at DESC'
    )
    const rows: Array<NovelProject> = []
    try {
      for (let i = 0; i < rs.rowCount; i++) {
        rs.goToRow(i)
        const item = new NovelProject()
        item.id = rs.getString(rs.getColumnIndex('id'))
        item.name = rs.getString(rs.getColumnIndex('name'))
        item.summary = rs.getString(rs.getColumnIndex('summary'))
        item.language = rs.getString(rs.getColumnIndex('language'))
        item.mode = rs.getString(rs.getColumnIndex('mode'))
        item.createdAt = rs.getLong(rs.getColumnIndex('created_at'))
        item.updatedAt = rs.getLong(rs.getColumnIndex('updated_at'))
        item.chapterCount = rs.getLong(rs.getColumnIndex('chapter_count'))
        item.wordCount = rs.getLong(rs.getColumnIndex('word_count'))
        rows.push(item)
      }
    } finally {
      rs.close()
    }
    return rows
  }

  static async listChapters(projectId: string): Promise<Array<NovelChapter>> {
    const rs = await NovelRepository.store.querySql(
      'SELECT id, volume_id, num, title, outline, content, summary, word_count, status, cognitive_frame, emotional_anchor, world_texture, concrete_mystery, interpersonal_tension, genre_beat, updated_at FROM chapters WHERE project_id = ? ORDER BY num',
      [projectId]
    )
    const rows: Array<NovelChapter> = []
    try {
      for (let i = 0; i < rs.rowCount; i++) {
        rs.goToRow(i)
        const ch = new NovelChapter()
        ch.id = rs.getLong(rs.getColumnIndex('id'))
        ch.volumeId = rs.getLong(rs.getColumnIndex('volume_id'))
        ch.num = rs.getLong(rs.getColumnIndex('num'))
        ch.title = rs.getString(rs.getColumnIndex('title'))
        ch.outline = rs.getString(rs.getColumnIndex('outline'))
        ch.content = rs.getString(rs.getColumnIndex('content'))
        ch.summary = rs.getString(rs.getColumnIndex('summary'))
        ch.wordCount = rs.getLong(rs.getColumnIndex('word_count'))
        ch.status = rs.getString(rs.getColumnIndex('status'))
        ch.cognitiveFrame = rs.getString(rs.getColumnIndex('cognitive_frame'))
        ch.emotionalAnchor = rs.getString(rs.getColumnIndex('emotional_anchor'))
        ch.worldTexture = rs.getString(rs.getColumnIndex('world_texture'))
        ch.concreteMystery = rs.getString(rs.getColumnIndex('concrete_mystery'))
        ch.interpersonalTension = rs.getString(rs.getColumnIndex('interpersonal_tension'))
        ch.genreBeat = rs.getString(rs.getColumnIndex('genre_beat'))
        ch.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
        rows.push(ch)
      }
    } finally {
      rs.close()
    }
    return rows
  }

  static async createChapter(projectId: string, title: string): Promise<void> {
    const volumeRs = await NovelRepository.store.querySql(
      'SELECT id FROM volumes WHERE project_id = ? ORDER BY sort_order LIMIT 1', [projectId]
    )
    let volumeId: number = 0
    try {
      if (volumeRs.rowCount > 0) {
        volumeRs.goToRow(0)
        volumeId = volumeRs.getLong(volumeRs.getColumnIndex('id'))
      }
    } finally {
      volumeRs.close()
    }
    const numRs = await NovelRepository.store.querySql(
      'SELECT COALESCE(MAX(num), 0) + 1 AS next_num FROM chapters WHERE project_id = ?', [projectId]
    )
    let nextNum: number = 1
    try {
      numRs.goToRow(0)
      nextNum = numRs.getLong(numRs.getColumnIndex('next_num'))
    } finally {
      numRs.close()
    }
    const safeTitle = title.trim().length > 0 ? title.trim() : '未命名章节'
    await NovelRepository.store.insert('chapters', {
      project_id: projectId, volume_id: volumeId, num: nextNum,
      title: safeTitle, outline: '', content: '', summary: '',
      word_count: 0, status: 'pending'
    })
    await NovelRepository.store.executeSql(
      'UPDATE app_projects SET updated_at = ? WHERE id = ?', [Date.now(), projectId]
    )
  }

  static async saveChapter(projectId: string, chapterId: number, title: string, content: string): Promise<void> {
    const count = content.replace(/\s/g, '').length
    await NovelRepository.store.executeSql(
      'UPDATE chapters SET title = ?, content = ?, word_count = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND project_id = ?',
      [title, content, count, chapterId, projectId]
    )
    await NovelRepository.store.executeSql(
      'UPDATE app_projects SET updated_at = ? WHERE id = ?', [Date.now(), projectId]
    )
  }
}
