# AI-BOX

AI 工具配置与技能仓库 — 一站式收集各种 AI 工具的接入指南、配置文件和使用技巧。

## 当前内容

### [将 DeepSeek 大模型接入 Claude Code 使用](skills/claude-code-deepseek/SKILL.md)

**核心价值**：通过 DeepSeek 的 Anthropic 兼容 API，让 Claude Code 底层调用 DeepSeek V4 系列大模型，成本降低 20-50 倍，充 10 块钱能用 1-2 个月。

**涵盖内容**：
- 背景原理 — Claude Code 与 DeepSeek 网关的交互架构、成本对比、兼容性权衡
- DeepSeek 账号准备 — 注册、获取 API Key、充值、计价详解与花费预估
- 环境变量配置 — macOS / Linux / Windows / VSCode 四种方式，附变量详解
- 模型映射关系 — 3 个模型槽位到 DeepSeek 的映射策略（省钱 / 平衡 / 质量）
- 连通性验证 — 环境变量检查、Claude Code 试跑、Python 脚本直连三重验证
- 排错指南 — 401 / 404 / 超时 / 截断 / 不生效 / 更新失效，按症状分类排查
- 功能兼容性矩阵 — 逐一说明图片输入、缓存、扩展思考等功能的支持状态
- 省钱策略 — 子任务走 Flash、简单对话走 Flash、大项目重构走 Pro 的最佳实践

## 使用方式

1. 将此仓库克隆到本地
2. 将 `skills/` 目录下的文件夹复制到你的 skills 目录
3. 输入 `/claude-code-deepseek` 即可使用

每个 skill 下的 `SKILL.md` 都是纯 Markdown，也可以直接阅读照着操作。

## 为什么叫 AI-BOX

像一个工具箱，把各种 AI 工具的配置和经验装进去，随时取用。目前从 DeepSeek 接入指南起步，后续会陆续加入更多工具的指南。

## 贡献

欢迎 PR 添加新的 skill 或工具配置。格式参考 `skills/claude-code-deepseek/SKILL.md`。
