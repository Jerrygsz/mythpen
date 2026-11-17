# Mythpen HarmonyOS 原生版（API 9 基线）

本目录是 Mythpen 的 HarmonyOS Stage + ArkTS + ArkUI 原生移植工程，独立于原 React/Tauri 桌面工程。

## 当前状态

这是第一阶段原生代码提交，不代表已通过 DevEco Studio 编译或 Mate 60 Pro 真机验证。当前提交实现/准备实现的是本地项目、章节和正文的基础闭环；角色、世界观、伏笔、关系、记忆、时间线、AI 和导入导出按数据映射逐步迁移。

## 工程

- `entry/src/main/ets/data/NovelRepository.ets`：API 9 RelationalStore 数据访问层
- `entry/src/main/ets/model/NovelModels.ets`：原生数据模型
- `entry/src/main/ets/pages/Index.ets`：手机端原生项目/章节编辑界面
- `docs/ORIGINAL_DATA_MAPPING.md`：对照 Mythpen 当前项目数据库 schema v13 的迁移映射

## 打开与构建

1. 使用 DevEco Studio，并安装 HarmonyOS API 9 Release 对应 SDK。
2. 打开本目录（不是仓库根目录）作为工程。
3. 检查 `build-profile.json5` 中产品的 `compatibleSdkVersion` 与本机 SDK/设备实际 API Version 一致。
4. 选择 entry 模块构建 HAP。
5. 在 Mate 60 Pro 上先验证启动、创建项目、创建章节、编辑正文、退出重启后数据仍在。

注意：HarmonyOS 4.2 的系统版本号不能单独证明设备 API Version。请以「设置 → 关于手机 → 软件版本/API Version」实际显示为准。此工程以用户报告的 API 9 为兼容基线，不依赖 API 10+ 接口。

## 数据安全原则

- 数据保存在应用私有目录中的 RDB，不上传云端。
- 编辑内容通过显式保存先落库；后续加入定时自动保存与退出前 flush。
- 原版 Mythpen 项目数据库 schema v13 与本地 RDB 并非同一文件格式。导入/导出需要经过 JSON 中间格式，不能直接把 SQLite 文件当作鸿蒙 RDB 文件打开。
- 不覆盖、不删除原版项目文件；导入应复制到应用私有目录后再转换。

## 许可

上游 Mythpen 标注 GPL-3.0-only。本移植目录沿用 GPL-3.0-only；分发修改版时应一并履行 GPLv3 对应义务。
