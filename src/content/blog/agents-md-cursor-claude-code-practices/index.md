---
title: AGENTS.md 用法：Cursor 与 Claude Code 最佳实践
description: 以 lynx-stack 项目为例，介绍 AGENTS.md 的定位、写法、分层策略，以及在 Cursor、Claude Code 等 AI 编程工具中的结合方式。
publishDate: 2026-04-29 02:35:00
tags: ['AI Agent', 'Cursor', 'Claude Code', 'AGENTS.md', '工程实践']
heroImage:
  src: './thumbnail.png'
  alt: 'thumbnail.png'
  color: '#4952BE'
language: 'zh'
draft: false
comment: true
---

# AGENTS.md 用法：Cursor 与 Claude Code 最佳实践

如果说 `README.md` 是写给人类开发者的项目入口，`AGENTS.md` 就更像是写给 AI 编程代理的“项目操作手册”。它不只是告诉 agent 项目是什么，还要告诉 agent：

- 应该用什么包管理器、Node 版本、构建命令和测试命令。
- 哪些目录是核心模块，修改时需要理解哪些数据流。
- 哪些命令有前置条件，例如测试前必须先 build。
- 哪些产物不能手动修改，哪些变更必须同步生成 API 文档或 changeset。
- 当进入某个子系统时，是否存在更局部、更具体的规则。

本文结合 [lynx-family/lynx-stack](https://github.com/lynx-family/lynx-stack) 的实践，聊聊 `AGENTS.md` 应该怎么写，以及如何和 Cursor、Claude Code 等 AI 编程工具配合使用。

## 1. AGENTS.md 解决的核心问题

AI 编程工具真正影响产出质量的，不只是模型能力，还有上下文质量。一个大型仓库里，agent 如果不知道项目约定，很容易犯这些错误：

- 用错包管理器，例如项目要求 `pnpm`，但 agent 直接跑了 `npm install`。
- 跳过必要前置步骤，例如没有先构建 Rust / native bindings 就直接跑测试。
- 只看当前文件，忽略 monorepo 中跨 package 的依赖关系。
- 修改了生成产物，却没有修改源文件。
- 不知道某个子目录的架构，把局部实现当成普通 React 组件来改。

`AGENTS.md` 的价值，就是把这些“资深维护者脑子里的隐性知识”变成可被 agent 自动读取的显性规则。

## 2. 从 lynx-stack 看仓库级 AGENTS.md 应该写什么

`lynx-stack` 是一个典型的大型 monorepo，包含 ReactLynx、Rspeedy、Lynx for Web、testing utilities 等模块，主要语言是 TypeScript / JavaScript，同时还包含 Rust native bindings。

它的根目录 `AGENTS.md` 做得比较好的地方是：没有泛泛地写“请遵守项目规范”，而是把 agent 最容易做错、最需要提前知道的事情写清楚。

### 2.1 先给仓库画像

根目录文档一开始就说明：

- 这是 Lynx 的 core JavaScript stack。
- 仓库规模是大型 monorepo，包含约 49 个 package。
- 主要语言是 TypeScript / JavaScript / Rust。
- 构建系统是 Turbo monorepo + pnpm workspaces。
- 目标运行时包括 Node.js、浏览器和移动端。

这类信息很重要，因为 agent 在选择修改策略时会受到它影响。比如看到 “Rust native bindings”，agent 就会意识到有些测试失败可能不是普通 TypeScript 编译错误，而是 native 构建链路问题。

### 2.2 把命令写成可执行路径，而不是命令清单

lynx-stack 的根目录 `AGENTS.md` 不是简单罗列命令，而是强调顺序：

```bash
npm install -g corepack
corepack enable
pnpm install --frozen-lockfile
pnpm turbo build
pnpm test
```

并且明确写出：

> Always run full build before tests. Watch mode only compiles TypeScript, not Rust components.

这比“测试命令是 `pnpm test`”有用得多。因为 agent 最常见的问题不是不知道测试命令，而是不知道测试命令之前必须做什么。

一个好的 `AGENTS.md` 应该尽量回答：

- 第一次进入仓库怎么安装依赖？
- 修改后最小验证命令是什么？
- 完整验证命令是什么？
- 哪些命令慢，需要设置更长 timeout？
- 哪些命令会改文件，改完后是否需要提交生成结果？

### 2.3 记录常见失败与恢复方式

lynx-stack 还把常见构建问题写进了文档，例如：

- Rust 编译失败时如何安装或更新 Rust toolchain。
- API Report 变化时需要运行 `pnpm turbo api-extractor -- --local` 并提交 `api.md`。
- 测试缺少 build artifacts 时，先运行 `pnpm turbo build`。
- 大型构建内存不足时设置 `NODE_OPTIONS="--max-old-space-size=32768"`。

这类内容对 agent 特别有价值。因为 agent 遇到报错时，如果上下文里已经有“已知故障模式”，就更可能沿着项目推荐路径修复环境，而不是随意改业务代码绕过错误。

### 2.4 写清楚 CI 验证管线

根目录 `AGENTS.md` 还总结了 CI 会跑哪些检查：

1. code style
2. API consistency
3. changeset validation
4. lint
5. TypeScript compilation
6. unit tests
7. E2E tests
8. Rust tests
9. type checking

这能帮助 agent 判断“我的本地验证是否足够接近 CI”。如果一个变更只影响某个小 package，agent 可以选择更聚焦的测试；如果变更影响公共 API，就知道需要额外跑 API extractor。

## 3. 子目录 AGENTS.md：把上下文放到离代码最近的地方

大型仓库只写根目录 `AGENTS.md` 还不够。根目录适合写全局约定，但子系统的架构细节应该放到对应目录下。

lynx-stack 在 A2UI 相关目录新增了两个子目录级说明：

```txt
packages/genui/a2ui/AGENTS.md
packages/genui/a2ui-playground/AGENTS.md
```

这两个文件的价值，是让 agent 进入 A2UI 目录时能快速获得局部架构知识。

### 3.1 a2ui：说明运行时数据流

`packages/genui/a2ui/AGENTS.md` 解释了 `@lynx-js/a2ui-reactlynx` 的核心流程：

```txt
A2UI messages
  -> processor
  -> Surface state
  -> Resource update
  -> A2UIRender
  -> ReactLynx UI
```

它进一步说明：

- `processor` 负责处理 `createSurface`、`updateComponents`、`updateDataModel` 等协议消息。
- 每个 `Surface` 维护 `components`、`resources` 和 `store`。
- `A2UIRender` 根据 `Resource` 渲染 surface root 或单个 component node。
- `componentRegistry` 把协议组件名映射到实际 ReactLynx renderer。
- catalog component 会通过副作用注册到 registry。

如果没有这份文档，agent 很可能只看到一个 `index.tsx` 就开始改组件，却不知道组件渲染依赖协议消息、资源对象、数据绑定和模板展开。

### 3.2 a2ui：说明如何扩展 catalog component

更实用的是，A2UI 的 `AGENTS.md` 还写了新增 catalog component 的步骤：

1. 新建 `src/catalog/Foo/index.tsx`。
2. 组件函数名必须叫 `Foo`，和目录名一致。
3. 新建 `src/catalog/Foo.ts`。
4. 加到 `src/catalog/all.ts`。
5. 加到 `package.json` exports。
6. 运行 build，确认生成 `dist/catalog/Foo/catalog.json`。

这就是典型的 agent 友好信息：不是抽象原则，而是能直接执行的 checklist。

### 3.3 a2ui-playground：说明“看起来像 Web，其实渲染在 Lynx app”

`packages/genui/a2ui-playground/AGENTS.md` 解决的是另一个常见误区：playground 里有两层东西。

- 浏览器里的 React DOM control panel：负责选择 demo、构造 `initData`。
- 真正渲染 A2UI 的 Lynx app：通过 `BaseClient`、`processor.processMessages(...)` 和 `<A2UIRender />` 回放消息并渲染。

它还指出 `/render.html` 是桥接层，会创建 `<lynx-view>`，把 base64 payload 传给 Lynx runtime。

这类说明可以显著减少 agent 的误判：如果要改 A2UI 渲染效果，不应该只盯着 control panel；如果要改 demo 切换逻辑，也不应该直接改 runtime。

## 4. Cursor 如何使用 AGENTS.md

在 Cursor / Cursor Agent / Cursor Cloud 这类环境中，`AGENTS.md` 通常会被作为 agent instructions 或 workspace rules 的一部分读取。

典型流程可以理解为：

1. agent 启动或打开仓库时读取根目录说明。
2. 当任务涉及某个子目录时，再读取更靠近代码的 `AGENTS.md`。
3. 把这些内容加入模型上下文。
4. agent 在搜索、修改、测试、提交时遵守这些规则。

在实际使用中，`AGENTS.md` 对 Cursor 最有帮助的内容包括：

- 项目命令：安装、开发、构建、测试、格式化。
- 修改边界：哪些目录是生成产物，哪些文件不要手改。
- 测试策略：改某类文件应该跑哪些测试。
- 子系统架构：某个目录的入口、数据流、常见扩展步骤。
- 常见问题：构建失败、缓存失效、依赖安装失败的恢复方式。

对于 Cursor Cloud 这种自动执行任务的 agent，`AGENTS.md` 的作用会更明显。因为它不仅回答“项目是什么”，还影响 agent 是否能一次性完成实现、验证、提交和 PR 描述。

## 5. Claude Code 如何使用 AGENTS.md

Claude Code 生态里更常见的项目说明文件是 `CLAUDE.md`。很多项目会把 Claude Code 专属规则写在这里，例如：

```txt
CLAUDE.md
```

不过 `AGENTS.md` 正在变成更中立的跨工具约定。实际行为取决于工具版本和运行环境：

- Claude Code 通常会自动读取 `CLAUDE.md`。
- 一些 wrapper、agent runner 或团队规范会额外读取 `AGENTS.md`。
- 用户也可以在对话中显式要求 Claude Code 查看 `AGENTS.md`。
- 如果同时存在根目录和子目录说明，通常应让更靠近代码的规则补充全局规则。

我的建议是：

- `AGENTS.md` 写跨工具、跨 agent 的通用项目规则。
- `CLAUDE.md` 写 Claude Code 特有的补充说明，或者保留对 `AGENTS.md` 的引用。
- `.cursor/rules` 写 Cursor IDE 特有的交互规则、文件匹配规则或 UI 工作流。
- `.github/copilot-instructions.md` 写 GitHub Copilot 相关说明。

这样可以避免把所有工具规则混在一起，也能保证核心工程知识只维护一份。

## 6. AGENTS.md 的分层最佳实践

一个可维护的 agent 说明体系，可以按三层设计。

### 6.1 根目录：仓库级规则

适合写：

- 项目概览。
- 技术栈。
- 安装、构建、测试、格式化命令。
- CI 验证管线。
- 目录结构。
- 全局编码约定。
- 常见环境问题。

示例：

```md
# Project Overview

This is an Astro 5 personal blog using the astro-pure theme.

## Commands

- bun install
- bun dev
- bun run build
- bun run check

## Content

Blog posts live in src/content/blog.
Each post must include title, description, publishDate, tags, draft and comment.
```

### 6.2 子目录：局部架构和操作步骤

适合写：

- 当前目录负责什么。
- 修改入口在哪里。
- 数据流怎么走。
- 新增一种组件 / 插件 / 页面需要改哪些文件。
- 当前目录相关的测试命令。

比如 `src/content/AGENTS.md` 可以写：

```md
# Content Guidelines

Blog posts are Markdown or MDX files under src/content/blog.
Use Chinese for posts by default.
Keep frontmatter aligned with src/content.config.ts.
Run bun run build after adding or changing public content.
```

### 6.3 工具专属文件：只写工具差异

如果项目同时使用 Cursor、Claude Code、Copilot，可以避免在每个文件里重复项目介绍：

```txt
AGENTS.md                         # 通用规则
CLAUDE.md                         # Claude Code 补充
.cursor/rules/*.mdc               # Cursor 补充
.github/copilot-instructions.md   # Copilot 补充
```

工具专属文件只写差异，例如：

- Cursor 是否需要手动截图或录屏。
- Claude Code 是否需要优先使用某些命令。
- Copilot 在生成测试时需要遵守哪些命名模式。

## 7. AGENTS.md 应该避免什么

`AGENTS.md` 不是越长越好。它应该帮助 agent 更快做对事情，而不是把所有文档复制一遍。

不建议写：

- 密钥、token、内部账号。
- 和真实 CI 不一致的命令。
- 很快会过期的临时说明。
- 大段产品背景，但没有操作价值。
- “写高质量代码”这种没有约束力的空话。
- 与 README、CONTRIBUTING 完全重复的内容。

更好的写法是把规则写成可验证的动作：

| 不推荐 | 推荐 |
| --- | --- |
| 注意测试 | 修改内容后运行 `bun run build` |
| 遵守项目结构 | 新博客放在 `src/content/blog/<slug>/index.md` |
| 不要乱改代码 | 不要手动编辑 `dist/`、`.astro/`、`node_modules/` |
| 保持风格一致 | frontmatter 字段遵循 `src/content.config.ts` |

## 8. 给 johniexu.github.io 的落地建议

当前这个博客项目是 Astro 5 + astro-pure，内容集中在 `src/content/blog` 和 `src/content/docs`。相比 lynx-stack，它不是大型 monorepo，但仍然适合加两类 `AGENTS.md`：

### 8.1 根目录 AGENTS.md

根目录说明应该告诉 agent：

- 这是个人博客项目。
- 使用 Astro 5、astro-pure、UnoCSS、TypeScript。
- 常用命令是 `bun install`、`bun dev`、`bun run build`、`bun run check`、`bun run lint`、`bun run format`。
- 新增公开内容后至少运行 `bun run build`。
- 部署从 `next` 分支触发 GitHub Pages workflow。

### 8.2 src/content/AGENTS.md

内容目录说明应该告诉 agent：

- 博客文章使用 Markdown / MDX。
- 推荐结构是 `src/content/blog/<slug>/index.md`。
- frontmatter 必须满足 `src/content.config.ts`。
- 中文技术文章默认设置 `language: 'zh'`。
- `description` 控制摘要展示，应该简洁。
- `draft: false` 才会公开发布。

这样一来，后续用 Cursor 或 Claude Code 新增文章时，agent 不需要每次都重新摸索 Astro collection schema。

## 9. 一份实用的 AGENTS.md 模板

可以从下面这个模板开始，然后按项目真实情况裁剪：

```md
# Project Name

## Overview

Explain what this repository does, the main stack, and the runtime targets.

## Commands

- Install: `...`
- Dev: `...`
- Build: `...`
- Test: `...`
- Format: `...`

## Architecture

- `src/foo`: ...
- `src/bar`: ...

## Change Guidelines

- Add new feature code in ...
- Do not edit generated files in ...
- Keep public API changes in sync with ...

## Testing

- For content changes, run ...
- For UI changes, run ...
- For API changes, run ...

## Common Issues

- If X fails, try Y.
- If generated files are stale, run Z.
```

模板只是起点。真正有价值的 `AGENTS.md`，一定来自项目真实问题：那些新同事会踩的坑、CI 经常失败的点、agent 容易误判的架构边界，都应该优先写进去。

## 10. 总结

`AGENTS.md` 的本质不是“给 AI 多写一份 README”，而是把项目中会影响 agent 决策的工程知识结构化。

以 lynx-stack 为例，好的实践包括：

- 根目录写清楚 monorepo 画像、命令顺序、CI 管线和常见故障。
- 子目录写清楚局部架构、数据流和扩展 checklist。
- 对 agent 友好的说明应该具体、可执行、可验证。
- Cursor、Claude Code、Copilot 等工具可以共享 `AGENTS.md`，再通过各自专属文件补充差异。

当项目规模变大、构建链路变复杂、agent 参与开发越来越多时，`AGENTS.md` 会逐渐从“可有可无的说明文件”变成工程协作基础设施的一部分。
