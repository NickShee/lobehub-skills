---
name: broadband-speedtest
description: 家庭宽带测速工具，覆盖三种方式：①中国联通官方测速平台自动化（agent-browser 驱动浏览器）②Ookla Speedtest CLI ③curl 国内镜像下载测速。Use when the user wants to test home broadband speed / 测网速 / 测速 / check internet bandwidth / 宽带测速 / 网速测试 / 带宽达标验证. Handles 联通官方平台浏览器自动化、节点选择、结果解读、带宽不达标排查。
---

# 宽带测速 (Broadband Speedtest)

## Overview

对家庭宽带进行多次测速并解读结果。提供三种互补方式，推荐优先使用联通官方平台（本地 CDN 最准确），Ookla/curl 用于交叉验证。已内置实测踩坑经验（ref 提取、WAF、故障节点、国际出口影响等）。

## 工作流决策树

```
用户要测速
├── 目标是联通/国内真实带宽 → 方式 A：联通官方平台（agent-browser）
│     ├── agent-browser + Chrome 可用 → 直接跑
│     └── 不可用 → 方式 C：curl 清华镜像
├── 需要指定节点/多节点 → 方式 B：Ookla CLI（-s 指定节点）
├── 只要快速看下行 → 方式 C：curl 清华镜像（最轻量）
└── 结果偏低 → 参考 references/troubleshooting.md 排查
```

## 方式 A：联通官方平台自动化（推荐，最准确）

用 agent-browser 驱动浏览器访问北京联通官方测速平台并执行多次测速。

```bash
# 直接运行（默认 3 次）
bash scripts/speedtest_unicom.sh 3

# 单次
bash scripts/speedtest_unicom.sh 1
```

**前置条件**：
- `agent-browser` CLI：`npm i -g --registry https://registry.npmmirror.com agent-browser`
- Chrome 引擎：设置 `AGENT_BROWSER_EXECUTABLE_PATH`，脚本自动探测 `/opt/chrome-linux64/chrome`
- 缺系统库：见 `references/troubleshooting.md` 第 6 节

**脚本内置关键逻辑**（勿改动）：
- 每次测速前重新加载页面，避免二次点击不触发
- snapshot 提取下行按钮 ref 时去掉 `ref=` 前缀（否则 Element not found）
- 协议弹窗"同意"按钮用 `grep '"同意"'` 精确匹配（否则点到"不同意"）
- 前台运行，测速等待约 40 秒

**输出**：每次的下行/Mbps、时延、抖动、"超越全国"百分比。

**手动流程**（若需逐步操作）：
1. `agent-browser open "http://cs1.bbn.com.cn:8800/gzweb/"`
2. `agent-browser snapshot -i` → 找"下行测速"后的"开始测速"按钮 ref
3. click 开始 → 弹协议框 → click "同意"
4. 等待 40s → `agent-browser get text body` 读取结果

## 方式 B：Ookla Speedtest CLI

适用于指定节点或多节点对比。脚本自动定位 `/files/speedtest-ookla/speedtest`。

```bash
# 自动选节点 1 次
bash scripts/speedtest_ookla.sh

# 指定节点 + JSON 解析 + 3 次
bash scripts/speedtest_ookla.sh -s 73226 -n 3 -j

# 查看脚本帮助
bash scripts/speedtest_ookla.sh -h
```

**节点速查**（详见 `references/nodes.md`）：
- 首尔 73226（国际，受出口/VLESS 影响）、苏州 16204（下载故障）、昆山 30852（不可达）
- 国内节点稀少，Ookla 测国内建议改用方式 A/C

**⚠️ 国际节点结果判断**：丢包 >10% 或 Ping >200ms 的结果不可信（即使数字高）。受国际出口/VLESS 故障影响时，海外节点数据无参考价值。

## 方式 C：curl 国内镜像（最轻量）

无需任何安装，验证真实国内下行带宽（不受国际出口影响）。

```bash
# 默认 8 并发 x 100MB
bash scripts/speedtest_curl.sh

# 自定义: 4 并发 x 50MB
bash scripts/speedtest_curl.sh 4 50
```

原理：多线程并发断点下载清华 TUNA 镜像，计算吞吐量。适合快速验证国内带宽是否达标。

## 结果解读

| 签约 | 达标线（Mbps） | 达标判断 |
|------|:---:|------|
| 100M | > 90 | 实测 < 90 不达标 |
| 300M | > 270 | 实测 < 270 不达标 |
| 500M | > 450 | 实测 < 450 不达标 |
| 1000M | > 900 | 实测 < 900 不达标（常见 500M 需排查） |

**带宽不达标排查顺序**（详见 `references/troubleshooting.md`）：
1. WiFi vs 有线（WiFi5 常见 400-600M，有线才准）
2. 网卡协商速率是否 1.0 Gbps
3. 光猫/路由器是否千兆口
4. 多平台交叉验证
5. 仍不达标 → 10010 报障

## 参考资料

- `references/nodes.md` — 联通各省测速平台、Ookla 节点、镜像地址
- `references/troubleshooting.md` — agent-browser 踩坑经验、WAF、国际出口影响、不达标排查
