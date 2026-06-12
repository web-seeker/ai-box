---
name: claude-code-deepseek
description: 将 DeepSeek 大模型接入 Claude Code CLI 使用 — 注册充值、获取 API Key、配置环境变量与模型映射、验证连通性、排错全流程。
---

# 将 DeepSeek 大模型接入 Claude Code 使用

## 这是什么？为什么这么做？

**一句话：让 Claude Code 这个 AI 编程助手，底层调用 DeepSeek 的大模型来干活，而不是走 Anthropic 官方的 Claude 模型。**

### 背景

Claude Code 是 Anthropic 出品的一款命令行 AI 编程助手（CLI 工具），它原生对接 Anthropic 的 API，默认使用 Claude 系列模型（Opus / Sonnet / Haiku）。Anthropic 官方的 API 定价较高，以 Sonnet 为例，每百万 token 约 $3 / $15（输入 / 输出），折合人民币约 ¥22 / ¥109。

DeepSeek（深度求索）在 2025 年推出了 **Anthropic 兼容 API**（`https://api.deepseek.com/anthropic`），实现了与 Anthropic Messages API 兼容的接口。这意味着你只需要修改几个环境变量，就能让 Claude Code CLI 把请求发到 DeepSeek 的服务器，底层实际跑的是 DeepSeek 的大模型（V4 Pro / V4 Flash），价格仅为 Anthropic 官方的 **约 1/30 ~ 1/50**。

### 核心原理

```
┌──────────────┐      Anthropic API 格式请求       ┌─────────────────────┐
│              │ ──────────────────────────────────▶ │                     │
│  Claude Code │                                     │  DeepSeek 兼容网关   │
│   (你的终端)  │ ◀────────────────────────────────── │  api.deepseek.com   │
│              │      Anthropic API 格式响应           │  /anthropic         │
└──────────────┘                                     └──────────┬──────────┘
                                                                │
                                                                ▼
                                                   ┌─────────────────────┐
                                                   │  DeepSeek 大模型     │
                                                   │  V4 Pro / V4 Flash   │
                                                   └─────────────────────┘
```

Claude Code 并不知道背后是 DeepSeek — 它发出的请求格式和收到的响应格式完全符合 Anthropic Messages API 规范，DeepSeek 的兼容网关上做了协议翻译，让 DeepSeek 模型"伪装"成了 Claude 模型。

### 成本对比（人民币）

| | Anthropic 官方（Sonnet） | DeepSeek V4 Pro | 节省倍数 |
|---|---|---|---|
| 输入 / 百万 token | ~¥22 | ¥1 | **~22 倍** |
| 输出 / 百万 token | ~¥109 | ¥4 | **~27 倍** |
| 日常编码（月耗 ~5M token）| ~¥330 | ~¥15 | **~22 倍** |

> **充 10 块钱，够用 1-2 个月**（取决于使用强度）。同等用量下 Anthropic 官方需要 ¥200+。

### 代价与取舍

| 方面 | Anthropic 官方 | DeepSeek 接入 |
|------|---------------|--------------|
| 模型能力 | Claude 原生模型，综合最强 | DeepSeek V4，编码能力接近但有差距 |
| 价格 | 贵 | 便宜 20-50 倍 |
| 图片输入 | ✅ 支持 | ❌ 不支持（静默忽略） |
| 长上下文缓存 | ✅ 支持 | ❌ 不支持 |
| 扩展思考（thinking） | ✅ 支持 | ❌ 不支持 |
| 工具调用 | ✅ | ✅ |
| 流式输出 | ✅ | ✅ |
| 中文理解 | 强 | 更强（国产模型天然优势） |

> **适合场景**：日常编码、代码审查、脚本编写、学习辅助、中文场景。**不适合**：需要图片理解、超长上下文缓存、最高级别推理能力的复杂任务。

---

## Step 1 — 确认用户现状

在开始前，先确认用户当前的状态：

| 检查项 | 怎么确认 | 没准备好的话 |
|--------|---------|-------------|
| Claude Code CLI 已安装 | 终端运行 `claude --version`，应输出版本号 | 引导去 `claude.ai/code` 安装 |
| DeepSeek 账号 | 打开 https://platform.deepseek.com 看能否登录 | 引导注册（支持手机号 / 邮箱） |
| 操作系统 | macOS / Linux / Windows | 出对应系统的命令 |
| 网络环境 | 能否访问 `api.deepseek.com` | 如果是国内用户一般没问题，海外用户也正常 |

---

## Step 2 — DeepSeek 账号准备（获取 API Key + 充值）

### 2.1 注册账号

1. 打开 https://platform.deepseek.com
2. 点击右上角「注册」，支持手机号或邮箱注册
3. 注册完成后登录进入控制台

### 2.2 获取 API Key（最关键一步）

1. 打开 https://platform.deepseek.com/api_keys
2. 点击「创建 API Key」
3. 给 Key 起个名字（比如 `claude-code`）
4. **立刻复制保存** — Key 格式为 `sk-` 开头的一长串字符，**关闭页面后无法再次查看**
5. 如果丢失，只能删除旧的重新创建

> ⚠️ **安全提醒**：API Key 等同于你的账户凭证，不要分享给任何人，不要提交到 Git 仓库，不要在公开场合截图。建议存在本地密码管理器中。

### 2.3 充值

1. 打开 https://platform.deepseek.com/top_up
2. 最低充值金额：**10 元人民币**（支持微信 / 支付宝）
3. 充值即时到账

### 2.4 计价详解

DeepSeek 按 token 计费，1 token ≈ 0.7 个中文字符或 0.3 个英文单词。

| 模型 | 输入价格 | 输出价格 | 上下文窗口 | 适用场景 |
|------|---------|---------|-----------|---------|
| **deepseek-v4-pro** | ¥1 / 百万 token | ¥4 / 百万 token | 1M | 复杂推理、大型重构、架构设计 |
| **deepseek-v4-flash** | ¥0.3 / 百万 token | ¥1.2 / 百万 token | 1M | 日常编码、代码审查、子任务代理 |

**花费预估**（按日均编码 2 小时）：
- 只用 Pro：约 ¥15-20 / 月
- Pro + Flash 混用：约 ¥8-12 / 月
- 纯 Flash：约 ¥3-5 / 月

---

## Step 3 — 配置环境变量（核心步骤）

需要设置 **8 个环境变量**。核心思路：通过环境变量告诉 Claude Code "你的 API 地址在这里，认证 Token 用这个，各个模型名映射到这些"。

### 变量详解

| 环境变量 | 作用 | 必须？ |
|----------|------|--------|
| `ANTHROPIC_BASE_URL` | 指向 DeepSeek 兼容网关，让 Claude Code 把请求发到这里 | ✅ 核心 |
| `ANTHROPIC_AUTH_TOKEN` | DeepSeek API Key（`sk-...`），用于鉴权 | ✅ 核心 |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | 默认 Sonnet 级模型映射 | ✅ |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | 最强推理模型映射 | ✅ |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | 轻量快速模型映射 | ✅ |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 子任务/代理使用的模型 | 推荐 |
| `CLAUDE_CODE_EFFORT_LEVEL` | 推理努力程度 | 推荐 |
| `API_TIMEOUT_MS` | API 超时时间（毫秒） | 推荐 |

---

### macOS / Linux

**方法一：临时生效（仅当前终端窗口）**

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

**方法二：永久生效（推荐）**

将上面的 8 行追加到你的 shell 配置文件：
- **zsh 用户**（macOS 默认）：追加到 `~/.zshrc`
- **bash 用户**：追加到 `~/.bashrc`

```bash
# 追加到 ~/.zshrc（zsh 用户）
cat >> ~/.zshrc << 'EOF'
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="sk-你的DeepSeek-API-Key"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_EFFORT_LEVEL="max"
export API_TIMEOUT_MS="600000"
EOF

source ~/.zshrc
```

> 💡 确保 `ANTHROPIC_AUTH_TOKEN` 中的 `sk-` 替换为你自己真实的 DeepSeek API Key。

---

### Windows（三选一）

**方法一：PowerShell 用户环境变量（推荐）**

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

> ⚠️ 设置后**需要重启 PowerShell / 终端**才能生效。

**方法二：图形界面设置（不熟悉命令行的用户）**

1. 按 `Win + R`，输入 `sysdm.cpl` 回车
2. 点击「高级」→「环境变量」
3. 在「用户变量」区域，逐个点击「新建」，输入变量名和值
4. 8 个变量全部添加完毕后确定，重启终端

**方法三：通过 VSCode 设置**

在 VSCode 的 `settings.json` 中添加：

```json
{
  "claudeCode.environmentVariables": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-你的Key",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_EFFORT_LEVEL": "max",
    "API_TIMEOUT_MS": "600000"
  }
}
```

---

### 一键工具 `claudeep`（不想手动的用户用这个）

如果不方便手动配置，可以用社区工具 `claudeep` 交互式完成：

```bash
npm install -g claudeep@latest
claudeep
```

运行后按提示输入 DeepSeek API Key，工具自动检测系统并写入环境变量。

---

## Step 4 — 模型映射关系（必读）

这是整个方案中最容易搞混的地方，务必理解：

Claude Code 内部会根据任务类型调用不同级别的模型，你通过环境变量把这 3 个"槽位"映射到 DeepSeek 模型：

```
Claude Code 想调用          环境变量                          实际跑的模型
─────────────────────    ──────────────────────────────    ────────────────
claude-opus-4-8    →     ANTHROPIC_DEFAULT_OPUS_MODEL    → deepseek-v4-pro
claude-sonnet-4-6  →     ANTHROPIC_DEFAULT_SONNET_MODEL  → deepseek-v4-pro
claude-haiku-4-5   →     ANTHROPIC_DEFAULT_HAIKU_MODEL   → deepseek-v4-flash
子任务代理         →     CLAUDE_CODE_SUBAGENT_MODEL       → deepseek-v4-flash
```

### 推荐配置策略

| 策略 | Sonnet 映射 | Opus 映射 | Haiku 映射 | 说明 |
|------|-----------|----------|-----------|------|
| **激进省钱** | flash | pro | flash | 日常走 flash，只有复杂任务才用 pro |
| **平衡（推荐）** | pro | pro | flash | 主力用 pro 保证质量，子任务/轻量走 flash 省钱 |
| **追求质量** | pro | pro | pro | 全部 pro，不在乎成本 |

> 本指南默认采用**平衡策略**（Sonnet/Opus → pro，Haiku/子任务 → flash）。如果你的编码场景比较重（大型项目、复杂重构），建议走质量策略；如果只是写脚本、看代码、学习，省钱策略完全够用。

---

## Step 5 — Gateway 技术细节速查

DeepSeek 的 Anthropic 兼容网关，本质是 DeepSeek 实现了一个符合 Anthropic Messages API 规范的 HTTP 服务，端点路径从 `/v1/messages` 变为 `/anthropic/v1/messages`：

| 项目 | 值 |
|------|-----|
| 网关地址 | `https://api.deepseek.com/anthropic` |
| 完整 Messages 端点 | `https://api.deepseek.com/anthropic/v1/messages` |
| 鉴权方式 | `x-api-key` Header，值为 DeepSeek API Key |
| 认证格式 | `Bearer`（由 Claude Code SDK 自动附加） |
| 请求/响应格式 | 完全兼容 Anthropic Messages API (2023-06-01) |
| 支持的 Anthropic SDK 版本 | Python `anthropic>=0.39.0`，Node.js `@anthropic-ai/sdk` 最新版 |

---

## Step 6 — 验证连通性（三步确认）

### 6.1 确认环境变量已生效

**macOS / Linux:**
```bash
echo $ANTHROPIC_BASE_URL
# 应输出: https://api.deepseek.com/anthropic
echo $ANTHROPIC_AUTH_TOKEN | cut -c1-10
# 应输出: sk- 开头的前 10 个字符
```

**Windows PowerShell:**
```powershell
$env:ANTHROPIC_BASE_URL
$env:ANTHROPIC_AUTH_TOKEN.Substring(0,10)
```

### 6.2 用 Claude Code 跑第一个任务

```bash
claude -p "用 Python 写一个 hello world 函数并调用它"
```

如果正常输出代码，说明配置成功！

### 6.3 Python 脚本验证 API 直连

如果 Claude Code 不工作但不确定是配置问题还是网络问题，先用 Python 脚本验证 DeepSeek API 连通性：

```python
from anthropic import Anthropic

client = Anthropic(
    api_key="sk-你的Key",    # 替换为你的真实 API Key
    base_url="https://api.deepseek.com/anthropic",
)

response = client.messages.create(
    model="deepseek-v4-pro",
    max_tokens=200,
    system="你是一个有帮助的助手。",
    messages=[
        {"role": "user", "content": "用一句话解释什么是大语言模型"}
    ],
)

print(response.model)           # 应输出: deepseek-v4-pro
print(response.content[0].text) # 应输出一句中文解释
```

> 如果 Python 脚本能跑通，说明 API Key 有效、网络正常，问题出在环境变量上。

---

## Step 7 — 常见问题排错指南

按症状分类，从最可能的原因开始排查：

### 401 Unauthorized

```
错误信息: {"error":{"type":"authentication_error","message":"invalid x-api-key"}}
```

| 原因 | 排查 | 解决 |
|------|------|------|
| API Key 无效或已删除 | 登录 platform.deepseek.com → API Keys 页面，确认 Key 存在 | 重新创建 API Key |
| 环境变量未设置或被覆盖 | `echo $ANTHROPIC_AUTH_TOKEN` 确认值正确 | 重新 export |
| Key 开头少了 `sk-` | DeepSeek 的 Key 一定以 `sk-` 开头 | 检查完整复制 |

### 404 Not Found / Model Not Found

```
错误信息: "model 'deepseek-chat' does not exist" 或 HTTP 404
```

| 原因 | 排查 | 解决 |
|------|------|------|
| 使用了旧模型名 | 查看环境变量中的模型名 | 必须用 `deepseek-v4-pro` 或 `deepseek-v4-flash`，不能用旧的 `deepseek-chat` |
| 模型名拼写错误 | 逐字检查 | 注意是 `deepseek-v4-pro`，不是 `deepseek-v4-pro `（多余空格也不行） |

### 请求超时

| 原因 | 排查 | 解决 |
|------|------|------|
| 默认超时太短（30s） | Claude Code 默认超时可能不够 | 设置 `API_TIMEOUT_MS=600000`（10分钟） |
| DeepSeek V4 Pro 推理慢 | Pro 模型在处理复杂任务时需要更多时间 | 增大超时到 `900000`（15分钟） |
| 网络不稳定 | `curl https://api.deepseek.com/anthropic/v1/messages` 检查连通性 | 检查代理/VPN 设置 |

### 返回内容被截断

| 原因 | 排查 | 解决 |
|------|------|------|
| 超时过短 | 长代码生成需要更久 | 增大 `API_TIMEOUT_MS` |
| max_tokens 限制 | Claude Code 默认可能设置了较小的 max_tokens | 在对话中使用 `/model` 检查当前模型配置 |

### 配置后不生效（环境变量没加载）

| 原因 | 排查 | 解决 |
|------|------|------|
| 没重启终端 | 环境变量只在进程启动时读取 | **完全关闭**终端后重新打开（不是新开 Tab） |
| 写错了配置文件 | 检查 `~/.zshrc` 里是否有拼写错误 | `cat ~/.zshrc | grep ANTHROPIC` 检查 |
| macOS 用了 bash 但写到了 `.zshrc` | 确认当前用的是哪个 shell | `echo $SHELL` 确认，写入对应配置文件 |

### Claude Code 更新后失效

| 原因 | 排查 | 解决 |
|------|------|------|
| 新版改变了环境变量名 | 查看 Claude Code Release Notes | 检查是否需要更新变量名 |
| 新版本增加了 API 验证 | 新版可能严格校验响应格式 | 等待 DeepSeek 适配，或临时降级 Claude Code |

### 排查口诀

> **401 → 查 Key，404 → 查模型名（用 v4），超时 → 增大 API_TIMEOUT_MS，不生效 → 重启终端，截断 → 等久一点。**

---

## DeepSeek Anthropic API 功能兼容性矩阵

| Anthropic API 功能 | DeepSeek 支持 | 说明 |
|-------------------|-------------|------|
| 文本对话 | ✅ 完全支持 | |
| System Prompt | ✅ 完全支持 | |
| 流式输出（stream=true） | ✅ 完全支持 | |
| 多轮对话 | ✅ 完全支持 | |
| 工具调用（tools / tool_use） | ✅ 支持 | 部分高级参数可能降级 |
| tool_choice（强制/自动） | ✅ 支持 | |
| temperature | ✅ 支持 | |
| top_p | ✅ 支持 | |
| stop_sequences | ✅ 支持 | |
| max_tokens | ✅ 支持 | |
| 图片输入（vision） | ❌ 不支持 | 静默忽略，不会报错 |
| prompt cache（cache_control） | ❌ 不支持 | 静默忽略 |
| 扩展思考（thinking / extended thinking） | ❌ 不支持 | 静默忽略 |
| Computer Use | ❌ 不支持 | |
| PDF 输入 | ❌ 不支持 | 静默忽略 |

> ⚠️ **注意"静默忽略"的含义**：如果你使用了不支持的功能，DeepSeek 不会报错，而是直接忽略该参数。这意味着你的请求依然能正常返回，但图表/图片理解等能力实际上没有生效。不要依赖这些功能。

---

## 参考链接

| 名称 | URL | 用途 |
|------|-----|------|
| DeepSeek Anthropic API 官方文档 | https://api-docs.deepseek.com/zh-cn/guides/anthropic_api | 权威接口说明 |
| DeepSeek API Key 管理 | https://platform.deepseek.com/api_keys | 创建/删除 Key |
| 充值页面 | https://platform.deepseek.com/top_up | 账户充值 |
| 官方计价表 | https://api-docs.deepseek.com/zh-cn/quick_start/pricing/ | 最新价格（以官网为准） |
| DeepSeek 控制台 | https://platform.deepseek.com | 用量统计、余额查看 |
| claudeep 工具 | https://www.npmjs.com/package/claudeep | 一键配置环境变量 |

---

## 省钱与长期使用建议

### 日常策略

1. **子任务全部走 flash** — 设置 `CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash`，子任务（代码搜索、简单修改）用 flash 绰绰有余，能节省 70% 以上的子任务费用
2. **简单对话手动切换 flash** — 看代码、问简单问题时，不需要 Pro 的深度推理能力
3. **大项目重构走 Pro** — 涉及多文件重构、架构调整、复杂调试时，Pro 的质量提升值得多花几毛钱

### 账户管理

- 在 https://platform.deepseek.com 定期查看用量和余额
- 建议一次充 30-50 元，一两个月不用管
- 当余额低于 2 元时设置提醒，避免用到中途余额耗尽
- API Key 定期轮换（建议每季度重新生成一次）

### 为什么效果可能不如原生 Claude

DeepSeek V4 是非常强的大模型，在编码能力上与 Claude Sonnet 接近，但在以下方面仍有差距：
- 超长上下文中的信息定位精度
- 复杂的多文件联动推理
- 需要深度思考的架构决策
- 对特定框架/库的熟悉程度

如果遇到 DeepSeek 处理不好的任务，临时切回 Anthropic 官方（删除 8 个环境变量即可）用一次，成本也不高。
