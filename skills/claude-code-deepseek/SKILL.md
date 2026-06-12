---
name: claude-code-deepseek
description: Guide users through connecting Claude Code CLI to DeepSeek's Anthropic-compatible API — setup API key, configure environment variables, verify connectivity, and troubleshoot.
---

# Claude Code 接入 DeepSeek

帮用户把 Claude Code CLI 接入 DeepSeek 后端，走完注册充值 → 配置环境变量 → 验证 → 排错的完整流程。

DeepSeek 价格约 ¥1-4 / 百万 token，比 Anthropic 官方便宜约 50 倍，充 10 块钱能用很久。

---

## Step 1 — 确认用户现状

先问清楚：
- 是否已安装 Claude Code CLI（`claude --version` 确认）
- 是否有 DeepSeek 账号和 API Key
- 用的是什么系统（macOS / Linux / Windows）

如果用户还没账号，引导去 https://platform.deepseek.com 注册。

---

## Step 2 — DeepSeek 账号准备

### 获取 API Key
1. 打开 https://platform.deepseek.com/api_keys
2. 点击「创建 API Key」，复制保存（格式 `sk-xxxx`，只显示一次）

### 充值
1. 打开 https://platform.deepseek.com/top_up
2. 最低充 10 元人民币（支持微信/支付宝）
3. 告诉用户：flash 模型 ¥0.3/百万 token 输入、¥1.2/百万 token 输出，10 块钱日常编码用一个月绰绰有余

### 计价参考
| 模型 | 输入 | 输出 | 上下文 |
|------|------|------|--------|
| deepseek-v4-pro | ¥1/百万 token | ¥4/百万 token | 1M |
| deepseek-v4-flash | ¥0.3/百万 token | ¥1.2/百万 token | 1M |

---

## Step 3 — 配置环境变量

用户需要设置以下 8 个环境变量。**先确认用户用哪种方式，再给出对应命令。**

### macOS / Linux（推荐手动设，写入 shell 配置）

```bash
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="sk-你的DeepSeek-API-Key"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_EFFORT_LEVEL="max"
export API_TIMEOUT_MS="600000"
```

永久生效：追加到 `~/.zshrc` 或 `~/.bashrc`，然后 `source`。

### Windows PowerShell

```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://api.deepseek.com/anthropic", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "sk-你的Key", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_SONNET_MODEL", "deepseek-v4-pro", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_OPUS_MODEL", "deepseek-v4-pro", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_HAIKU_MODEL", "deepseek-v4-flash", "User")
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_SUBAGENT_MODEL", "deepseek-v4-flash", "User")
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_EFFORT_LEVEL", "max", "User")
[Environment]::SetEnvironmentVariable("API_TIMEOUT_MS", "600000", "User")
```

### VSCode 用户

在 `settings.json` 的 `claudeCode.environmentVariables` 中配置同样这组变量。

### 一键工具（可选）

如果用户不想手动配置，推荐 `claudeep`：
```bash
npm install -g claudeep@latest
claudeep
```
运行后自动写入环境变量并加载。

---

## Step 4 — 模型映射关系（关键）

把这张映射表给用户看，解释清楚：

| Claude Code 调用的模型 | 实际映射 DeepSeek | 适用场景 |
|---|---|---|
| claude-opus-* | deepseek-v4-pro | 复杂推理和编码 |
| claude-sonnet-* | deepseek-v4-pro | 日常编码（建议也用 pro） |
| claude-haiku-* | deepseek-v4-flash | 轻量任务、子任务代理 |

> 子任务单独用 flash：`CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash` 大幅降本。

---

## Step 5 — Gateway 配置速查

| 字段 | 值 |
|------|-----|
| Gateway Base URL | `https://api.deepseek.com/anthropic` |
| Gateway Auth Scheme | `bearer` |
| Gateway API Key | DeepSeek API Key（`sk-xxx`） |
| 实际端点 | `https://api.deepseek.com/anthropic/v1/messages` |

---

## Step 6 — 验证

让用户重启终端，然后跑：

```bash
# 检查环境变量
echo $ANTHROPIC_BASE_URL    # 应输出 https://api.deepseek.com/anthropic

# 试跑一个简单任务
claude -p "用 Python 写一个 hello world 函数"
```

或者用 Python 小脚本验证 API 连通性：
```python
import anthropic
client = anthropic.Anthropic(
    api_key="sk-你的Key",
    base_url="https://api.deepseek.com/anthropic",
)
response = client.messages.create(
    model="deepseek-v4-pro",
    max_tokens=100,
    system="You are a helpful assistant.",
    messages=[{"role": "user", "content": "Say hello in Chinese"}],
)
print(response.content[0].text)
```

---

## Step 7 — 常见问题排错

按优先级从高到低：

| 现象 | 原因 | 解决 |
|------|------|------|
| 401 | API Key 无效 | 去 DeepSeek 平台重新生成 |
| 404 | 模型名错误 | 确认是 `deepseek-v4-pro` 或 `deepseek-v4-flash`，不要用旧的 `deepseek-chat` |
| 超时 | 响应太长或网络问题 | `API_TIMEOUT_MS=600000`（10 分钟） |
| 配置不生效 | 没重启终端 | 完全关闭终端后重开 |
| 更新后失效 | Claude Code 新版本兼容问题 | 尝试降级到已知兼容版本 |
| 返回内容截断 | 超时太短 | 增大 `API_TIMEOUT_MS` |

排查口诀：**401 → 查 Key，404 → 查模型名，超时 → 查网络和超时设置，不生效 → 重启终端。**

---

## DeepSeek 兼容性说明

| 功能 | 状态 |
|------|------|
| 文本对话、system prompt、stream | ✅ |
| 工具调用（tools / tool_choice）| ✅ |
| temperature / top_p / stop_sequences | ✅ |
| 图片输入、cache_control、thinking | ❌ 静默忽略 |

---

## 关键链接

| 名称 | URL |
|------|-----|
| Anthropic API 文档 | https://api-docs.deepseek.com/zh-cn/guides/anthropic_api |
| API Key 管理 | https://platform.deepseek.com/api_keys |
| 充值 | https://platform.deepseek.com/top_up |
| 计价表 | https://api-docs.deepseek.com/zh-cn/quick_start/pricing/ |
| claudeep | https://www.npmjs.com/package/claudeep |

---

## 省钱建议

- 子任务用 flash 模型（`CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash`）
- 简单问题直接用 flash，不需要深度推理的任务不要用 pro
- 在 DeepSeek 平台定期检查余额和消耗
- 设置余额告警，避免余额耗尽中断工作
