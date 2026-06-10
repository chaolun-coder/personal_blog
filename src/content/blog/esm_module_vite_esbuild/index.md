---
title: CommonJS 与 ESM 模块异同及 vite 的处理
description: '本文将深入探讨 CommonJS 和 ESM 的异同，分析它们各自的特点和适用场景，并揭示 Vite 如何巧妙地处理 CommonJS 模块，让开发者能够无缝使用庞大的 npm 生态系统。'
publishDate: 2024-08-26 16:58:24
tags: ['js']
heroImage:
  src: './thumbnail.png'
  color: '#eedb5e'
---

## 引言

在现代 JavaScript 开发中，模块系统是构建复杂应用的基石。然而，JavaScript 生态系统中存在着两种主流的模块格式：CommonJS (CJS) 和 ECMAScript Modules (ESM)。这两种格式在设计理念、语法和工作方式上有着根本性的差异，导致了它们在浏览器和 Node.js 环境中的兼容性问题。

本文将深入探讨 CommonJS 和 ESM 的异同，分析它们各自的特点和适用场景，并揭示 Vite 如何巧妙地处理 CommonJS 模块，让开发者能够无缝使用庞大的 npm 生态系统。

## 一、CommonJS 与 ESM 的全面对比

### 1.1 语法差异

**CommonJS (CJS) 语法：**
```javascript
// 导出
module.exports = { value: 42 };
exports.value = 42;

// 导入
const module = require('./module');
const { value } = require('./module');
```

**ES Module (ESM) 语法：**
```javascript
// 导出
export default { value: 42 };
export const value = 42;

// 导入
import module from './module';
import { value } from './module';
```

### 1.2 核心差异对比

| 特性 | CommonJS (CJS) | ES Module (ESM) |
|------|----------------|-----------------|
| **加载方式** | 同步加载（运行时） | 异步加载（编译时静态解析） |
| **值传递** | 值的拷贝 | 值的引用（活的绑定） |
| **动态性** | 高度动态（条件导入、动态路径） | 静态结构（路径必须为字面量） |
| **设计初衷** | 服务器端（Node.js） | 浏览器端（语言标准） |
| **严格模式** | 可选 | 默认启用且不可关闭 |
| **循环引用** | 处理困难，容易出错 | 原生支持，是定义特性 |
| **Tree-Shaking** | 困难 | 天然支持 |
| **顶级 `this`** | 指向 `module.exports` | `undefined` |

### 1.3 值的拷贝 vs 值的引用

这是两者最关键的语义差异，通过代码示例可以清晰看出：

**CommonJS (值的拷贝)：**
```javascript
// counter.cjs
let count = 0;
function increment() { count++; }
module.exports = { count, increment };

// main.cjs
const { count, increment } = require('./counter.cjs');
console.log(count); // 输出: 0
increment();
console.log(count); // 输出: 0 (未改变，导入的是原始值的拷贝)
```

**ES Module (值的引用)：**
```javascript
// counter.mjs
export let count = 0;
export function increment() { count++; }

// main.mjs
import { count, increment } from './counter.mjs';
console.log(count); // 输出: 0
increment();
console.log(count); // 输出: 1 (改变，导入的是值的引用)
```

### 1.4 动态导入机制

**CommonJS 的动态 `require`：**
```javascript
// 可以根据条件动态加载模块
let myModule;
if (condition) {
  myModule = require('./moduleA');
} else {
  myModule = require('./moduleB');
}

// 动态路径
const path = './' + moduleName;
const module = require(path);
```

**ES Module 的静态 `import` 和动态 `import()`：**
```javascript
// 静态导入必须在顶层
import moduleA from './moduleA';

// 动态导入返回 Promise
if (condition) {
  import('./moduleA.mjs').then(module => {
    // 使用模块
  });
}

// 使用 async/await
const loadModule = async () => {
  const module = await import(`./${moduleName}.mjs`);
};
```

## 二、Vite 如何处理 CommonJS 模块

### 2.1 问题背景

Vite 是专为 ESM 设计的构建工具，其开发服务器依赖于浏览器原生 ESM 的特性。然而，npm 生态系统中有大量包仍然是 CommonJS 格式，这导致了兼容性问题。

### 2.2 解决方案：预构建

Vite 的解决方案是预构建（Pre-Bundling），这个过程由 esbuild（一个极快的 JavaScript 打包器）完成，主要步骤包括：

1. **依赖扫描**：Vite 分析项目源码，找出所有依赖的 CommonJS 模块
2. **格式转换**：使用 esbuild 将 CommonJS 模块转换为 ESM 格式
3. **模块合并**：将多个内部模块的包打包成单个文件
4. **存储缓存**：转换后的模块存储在 `node_modules/.vite/deps` 目录中

### 2.3 预构建的优势

- **性能提升**：减少浏览器请求数量，将多个文件合并为一个
- **兼容性保证**：确保 CommonJS 模块在 ESM 环境中正常工作
- **缓存机制**：首次构建后结果被缓存，提高后续启动速度

### 2.4 实际工作流程

当你在 Vite 项目中导入一个 CommonJS 包时：

```javascript
import _ from 'lodash'; // 一个 CommonJS 包
```

Vite 会：

1. 在预构建阶段检测到 `lodash` 是 CommonJS 格式
2. 使用 esbuild 将其转换为 ESM 格式
3. 将转换后的模块存储在 `node_modules/.vite/deps/lodash.js`
4. 重写你的导入语句指向转换后的模块

## 三、esbuild 的转换过程

### 3.1 转换策略

esbuild 的转换过程不仅仅是语法替换，而是深度的语义转换：

1. **导出分析**：识别 `module.exports` 和 `exports` 的使用模式
2. **导入转换**：将 `require()` 调用转换为 `import` 语句
3. **作用域保持**：保留顶级作用域的逻辑执行顺序
4. **模拟机制**：模拟 CommonJS 的缓存和循环引用行为

### 3.2 转换示例

**原始 CommonJS 模块：**
```javascript
// math.cjs
const PI = 3.14159;

function add(a, b) {
  return a + b;
}

function multiply(a, b) {
  return a * b;
}

module.exports = {
  add,
  multiply,
  PI
};
```

**esbuild 转换后的 ESM 模块：**
```javascript
// math.mjs (转换后)
var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = function(cb) { /* CommonJS 模拟函数 */ };

var require_math = __commonJS(function(exports, module) {
  const PI = 3.14159;
  
  function add(a, b) {
    return a + b;
  }
  
  function multiply(a, b) {
    return a * b;
  }
  
  module.exports = {
    add,
    multiply,
    PI
  };
});

// ESM 导出
export default require_math();
export const { add, multiply, PI } = require_math();
```

### 3.3 处理复杂情况

esbuild 能够智能处理各种复杂场景：

1. **条件导出**：根据环境变量选择不同的导出内容
2. **动态 require**：将函数内的 `require()` 调用转换为动态 `import()`
3. **循环依赖**：生成额外的代码来正确处理循环引用
4. **混合使用**：处理模块中同时使用 CJS 和 ESM 语法的情况

## 四、实践建议与最佳实践

### 4.1 对于库开发者

1. **提供双模式导出**：在 `package.json` 中同时指定 `main` (CJS) 和 `module` (ESM) 字段
2. **使用导出映射**：利用 `exports` 字段提供更精细的导出控制
3. **避免混合使用**：在同一个库中尽量避免混合使用 CJS 和 ESM 语法

```json
{
  "name": "my-library",
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs"
    },
    "./feature": {
      "import": "./dist/feature.mjs",
      "require": "./dist/feature.cjs"
    }
  }
}
```

### 4.2 对于应用开发者

1. **优先选择 ESM 包**：在选择依赖时优先考虑提供 ESM 版本的包
2. **注意混合使用**：避免在同一个文件中混合使用 `import` 和 `require`
3. **配置优化**：在必要时使用 `optimizeDeps.include` 强制预构建特定依赖

```javascript
// vite.config.js
import { defineConfig } from 'vite';

export default defineConfig({
  optimizeDeps: {
    include: ['some-cjs-package'], // 强制预构建
    exclude: ['some-esm-package'] // 排除无需预构建的包
  }
});
```

### 4.3 调试与故障排除

如果遇到 CommonJS 相关的问题：

1. **检查预构建结果**：查看 `node_modules/.vite/deps` 目录中的转换结果
2. **强制重新构建**：使用 `vite --force` 命令强制重新预构建
3. **手动排除问题**：使用 `optimizeDeps.exclude` 排除有问题的包，然后手动处理

## 五、未来展望

随着 JavaScript 生态的发展，ESM 正在成为主流格式：

1. **Node.js 的 ESM 支持**：新版 Node.js 不断改进对 ESM 的支持
2. **工具链优化**：构建工具正在优化对混合代码库的处理
3. **生态迁移**：越来越多的 npm 包提供纯 ESM 版本

然而，CommonJS 由于其在 npm 生态中的深厚基础，仍将在相当长的时间内继续存在。工具如 Vite 的价值就在于桥接这两个世界，让开发者能够平稳过渡。

## 结论

CommonJS 和 ESM 的差异反映了 JavaScript 生态系统的演进历程。虽然它们在设计理念和实现方式上有显著不同，但通过像 Vite 这样的现代构建工具，开发者可以几乎无感知地使用这两种模块系统。

理解这两种格式的底层差异有助于我们编写更健壮的代码，做出更合理的架构决策，并更好地调试遇到的问题。随着生态系统的不断发展，ESM 终将成为主导，但 CommonJS 的遗产仍将在未来多年内影响着 JavaScript 的开发方式。

Vite 通过其创新的预构建机制，不仅解决了技术兼容性问题，更为我们提供了一窥 JavaScript 模块系统未来发展的窗口。它提醒我们，良好的工具设计可以在尊重历史的同时，优雅地引领我们走向未来。
