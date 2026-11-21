# 🀄 Antigravity 一键汉化包（修复版）

[![GitHub release](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/43queren/antigravity-zh-oneclick)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

给 [Google Antigravity](https://antigravity.google) 桌面客户端一键汉化的绿色工具包。基于社区汉化引擎，收录 **6005 条**中英词条，并修复了原方案"点击设置卡死"的性能问题。

> ⚠️ 非 Google 官方语言包。本工具修改本地 `app.asar`，安装前自动备份原版，可随时一键还原。

---

## ✨ 特性

- **一键安装 / 一键还原**：双击 `.bat` 即可，自动关闭进程、定位安装目录、备份、注入、重启
- **6005 条词条**：主界面、设置面板、侧边栏、弹窗、原生菜单、托盘、退出确认全覆盖
- **已修复设置卡死**：原引擎对每个文本节点遍历数千词条构造正则，点击设置会卡死；本版本加入翻译缓存、正则预编译和 observer 防抖
- **零依赖**：纯 Python 标准库；电脑没装 Python 时脚本会自动下载官方便携版（约 11 MB）
- **热重载词典**：可编辑 `~/.antigravity-zh/zh-CN.json` 增补词条（部分环境下可能需要重新安装才生效）
- **跨平台**：安装器支持 Windows / macOS / Linux；`.bat` 一键脚本面向 Windows

---

## 🚀 快速开始

### Windows（最简单）

1. 点 **Code → Download ZIP** 下载本仓库，解压到任意文件夹
2. 双击 **`install.bat`**
   - 自动关闭 Antigravity
   - 自动备份原版 `app.asar.bak`
   - 注入汉化并重新启动
3. 完成。若界面未立即变化，完全退出 Antigravity 后重新打开一次

> 若电脑未安装 Python，脚本会自动下载便携版（仅首次，约 11 MB）。

### macOS / Linux

```bash
python3 install.py
# 还原
python3 install.py --restore
# 查看状态
python3 install.py --status
```

---

## 🔧 工作原理

Antigravity 是基于 Electron 的自研 IDE，其界面 bundle 由内嵌的 `language_server.exe` 提供，所有文案硬编码为英文，**没有 i18n 入口**，因此无法像 VS Code 那样装语言包实现整体汉化。

本方案的做法：

1. 解包 `app.asar`
2. 向 `dist/preload.js` 注入一个 DOM 翻译引擎（MutationObserver 监听 + 词典匹配 + 动态正则规则）
3. 向 `dist/menu.js`、`tray.js`、`main.js` 注入原生菜单 / 托盘 / 弹窗翻译
4. 重新打包并替换（自动备份原版）

### 性能修复

原社区引擎存在严重性能缺陷：对每个文本节点都遍历约 6000 条词典逐条构造正则，设置页节点众多时主线程长时间阻塞，表现为"点击设置卡死"。本版本做了四处优化：

| 优化 | 说明 |
| --- | --- |
| 翻译结果缓存 | 相同文本直接返回，避免重复计算 |
| 正则预编译 | 长/短词条正则只构造一次 |
| 按需候选 | 只遍历与当前文本相关的词条 |
| observer 防抖 | 用 `requestAnimationFrame` 合并变动，打断"翻译→重渲染→再翻译"循环 |

实测效果（CDP 测量渲染主线程响应）：

| 指标 | 修复前 | 修复后 |
| --- | --- | --- |
| 点击"设置"响应 | 133 ms | 29 ms |
| 点击后主线程 | **卡死 15 秒超时** | **3 ms 响应** ✅ |

---

## ❓ 常见问题

**Q: 汉化后部分界面仍是英文？**

正常。以下几类按设计保留英文：
- 模型名 / 品牌名：`Gemini 3.8 Flash`、`Claude`、`Antigravity`、`Google Sans`
- 你的数据：对话标题、文件名、账号邮箱、正在输入的内容
- 动态拼接文案：如 `Select model, current: ...` 这类"固定文案 + 运行时值"，词典精确匹配覆盖不到全部模板

这类 DOM 翻译方案**无法做到 100% 全中文**，除非官方原生支持 i18n（Antigravity 目前没有）。

**Q: Antigravity 更新后汉化失效了？**

官方自动更新会覆盖补丁。重新运行一次 `install.bat` 即可。建议关闭自动更新以避免反复失效。

**Q: 点击"设置"卡死？**

本版本已修复。若你用的是旧版汉化，请先运行 `restore.bat` 再运行 `install.bat`。

**Q: 如何彻底恢复原版？**

双击 `restore.bat`（依赖首次安装时生成的 `app.asar.bak`）。

**Q: bat 脚本为什么是英文提示？**

为了兼容所有 Windows 区域语言设置，避免出现中文乱码。中文说明见 `使用说明.txt`。

---

## 📁 文件结构

```
.
├─ install.bat        # 一键安装（Windows，双击运行）
├─ restore.bat        # 一键还原（Windows，双击运行）
├─ install.py         # 汉化安装器核心
├─ asar.py            # 纯 Python asar 解包/打包库
├─ dicts\
│   ├─ engine.js      # DOM 翻译引擎（含性能修复）
│   └─ zh_cn.json     # 中英词典（6005 条）
└─ 使用说明.txt        # 中文使用说明
```

---

## 🙏 致谢

基于社区开源的 `antigravity-zh` 汉化方案，在其基础上修复了设置页卡死问题并补充了新版本词条。

---

## ⚖️ 免责声明

本项目与 Google 及 Antigravity 官方团队无关，不包含 Antigravity 的任何二进制内容。修改本地 `app.asar` 可能违反官方服务条款，请自行评估使用风险。

## 📄 License

[MIT](LICENSE) © 2026
