# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 提供在此代码库中工作的指导。

## 项目概述

这是一个用 Racket 语言编写的教育性编译器项目，采用多阶段编译架构，从简单的算术表达式逐步构建到复杂的函数式编程结构。

## 常用开发命令

### 构建和测试
```bash
# 编译运行时系统
make runtime.o

# 运行所有测试
make test

# 或直接使用 Racket
racket run-tests.rkt

# 清理构建文件
make clean
```

### 运行时编译 (Mac M1)
```bash
# 在 M1 Mac 上编译运行时
make runtime.o CC="gcc -arch x86_64"

# 编译单个程序
racket compiler.rkt input.rkt -o output.s
gcc -g runtime.o output.s
```

## 代码架构

### 语言层次结构
编译器实现了渐进式语言层次：
- **Lint**: 基础整数运算 (`+`, `-`, `read`)
- **Lvar**: 添加变量和 `let` 表达式
- **Cvar**: C 风格命令式语言
- **R1-R8**: 逐步添加布尔值、向量、函数、lambda、Any 类型、循环等

### 解释器架构
- **类继承模式**: 所有解释器遵循一致的类继承结构
- **Mixin 模式**: 使用 mixin 实现代码复用
- **环境传递**: 使用高阶函数进行环境管理

### 类型检查系统
- **模块化设计**: 基于 mixin 的类型检查架构
- **类型表**: 每个 mixin 定义操作符签名
- **类型相等性**: 支持子类型的自定义类型比较

### 编译管道
编译器使用顺序传递架构：
1. **uniquify**: 重命名变量避免阴影
2. **remove-complex-opera***: 扁平化复杂表达式
3. **explicate-control**: 转换为 C 风格控制流
4. **select-instructions**: 生成伪 x86 指令
5. **assign-homes**: 变量分配到栈位置/寄存器
6. **patch-instructions**: 修复 x86 指令约束
7. **prelude-and-conclusion**: 添加函数序言/结语

### 运行时系统
- **Cheney 复制垃圾收集**
- **标记指针系统**用于类型信息
- **向量和闭包表示**
- **根栈管理**用于 GC 根

## 开发工作流

### 实现新功能
1. 在相应的 `interp-*.rkt` 文件中添加解释器支持
2. 在对应的 `type-check-*.rkt` 文件中添加类型检查
3. 如有需要，在 `compiler.rkt` 中更新编译传递
4. 在 `tests/` 目录中添加测试用例

### 测试策略
```racket
;; 解释器测试
(interp-tests "var" #f compiler-passes interp_Lvar "var_test" (tests-for "var"))

;; 编译器测试
(compiler-tests "var" #f compiler-passes "var_test" (tests-for "var"))
```

### 调试工具
- 在 `run-tests.rkt` 中取消注释 `(debug-level 1)` 启用调试
- 使用 `(AST-output-syntax 'concrete-syntax)` 查看具体语法

## 文件组织

- `compiler.rkt`: 主编译管道和学生实现
- `interp-*.rkt`: 语言解释器
- `type-check-*.rkt`: 类型检查系统
- `utilities.rkt`: 通用工具和 AST 定义
- `runtime.c`: 运行时系统（含 GC）
- `run-tests.rkt`: 测试运行器
- `tests/`: 按语言级别组织的测试用例

## 重要注意事项

- **不要编辑** `utilities.rkt` 文件，因为它会被课程仓库覆盖
- 学生实现应集中在 `compiler.rkt` 中的 TODO 部分
- 测试文件命名约定：`{language}_test_{number}.rkt`
- 提交时需要提供 `typechecker` 函数（如果作业要求类型检查）

## 设计模式

- **面向对象设计**: 类继承用于语言特性演进
- **函数式组合**: Mixin 模式用于可复用功能
- **模块化架构**: 解释器、类型检查器、传递的清晰分离

这个架构为理解编译器构造提供了坚实的基础，具有清晰的扩展模式和从简单到复杂语言特性的良好组织进展。