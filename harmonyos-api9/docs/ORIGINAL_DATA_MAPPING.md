# Mythpen 桌面版 → HarmonyOS 原生版数据迁移映射

基准：当前 Fork 分支的 `server/db.js`，项目数据库 schema version 13；并参考 `src/types/index.ts`、`src/lib/dto.ts`。

## 核心约束

1. 原版项目库以 SQLite 文件保存；鸿蒙端使用 `@ohos.data.relationalStore` 管理应用私有 RDB。两者不能直接互换。
2. 通过版本化 JSON 交换格式导入/导出；保留原始 ID、关系 ID、排序和时间戳。
3. 原版章节/卷/Token 用 INTEGER 主键；角色、世界观、伏笔、记忆等要素使用 UUID 字符串主键。鸿蒙端保留这一类型差异。
4. 导入必须在事务中执行；失败回滚，不覆盖已有项目；schema 高版本数据只读拒绝或要求升级，不能静默降级。

## 数据表映射

| 桌面 SQLite 表 | HarmonyOS RDB 表 | 关键字段/说明 |
|---|---|---|
| project_meta | project_meta | key/value；项目模式、语言、schema、作者笔记等 |
| volumes | volumes | INTEGER id、sort_order、title、summary |
| chapters | chapters | INTEGER id、volume_id、num、title、outline、content、summary、word_count、status、五维叙事字段、genre_beat |
| characters | characters | UUID id、name、age、gender、species、appearance、personality、background、motivation、arc、role、ext_markers、avatar、notes |
| chapter_characters | chapter_characters | chapter_id + character_id + role |
| world_entries | world_entries | UUID id、category、name、description、tags |
| project_genres | project_genres | genre |
| project_styles | project_styles | style |
| foreshadows | foreshadows | UUID、status、章节引用、expected_resolve_chapter、priority |
| payoff_points | payoff_points | 爽点类型、状态、强度、铺垫/兑现章节 |
| memories | memories | UUID、category、content、source_chapter_id |
| character_relations | character_relations | UUID、character_a_id、character_b_id、关系类型/强度/布局坐标 |
| science_entries | science_entries | known/extrapolation/hypothesis、category、sort_order、references |
| timeline_events | timeline_events | year、title、description、importance |
| clue_board | clue_board | clue/red-herring/deduction/question、章节引用、resolved |
| token_usage | token_usage | INTEGER id、task、章节、输入/输出 token、model、时间 |
| chat_sessions | chat_sessions | UUID id、title、时间 |
| chat_messages | chat_messages | UUID id、session_id、role、content、tool_calls JSON |
| assets | assets | key、mime、data BLOB（封面等资源） |

桌面端全局配置库另含 `app_settings`、`recent_projects`、`editor_snapshots`。鸿蒙端配置与项目注册信息由独立应用级 RDB 表管理；API 密钥应使用系统安全存储能力，不能写入导出文件或日志。

## 当前 V1 实现边界

本次第一阶段先建立项目、卷、章节和章节正文的原生存储闭环，并在 schema 中预留其余创作实体。角色/世界观/伏笔/关系/记忆/时间线/线索/爽点等完整 CRUD、原版 SQLite→JSON 导入器、JSON→桌面兼容导出器、AI 流式接口与 EPUB 导出尚未完成。

## 验收顺序

- [ ] 创建项目后重启仍存在
- [ ] 自动创建第一卷
- [ ] 创建章节、编辑正文、保存后重启仍存在
- [ ] 大正文读写不截断，字数统计正确
- [ ] 章节删除/项目删除的外键级联行为正确
- [ ] JSON 导入事务回滚与重复 ID 冲突策略
- [ ] schema v13 桌面项目导入后逐表核对行数与关联完整性
