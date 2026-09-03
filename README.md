# lobehub-skills

NickShee 的 LobeHub 自定义技能备份仓库（私有）。

## 用途

- **源仓库**：LobeHub 自定义 skill（source=user）的唯一事实来源与版本控制
- **备份快照**：2026-09-03 首次备份（先备份，运行时未改动）

## 技能清单

| Skill | 说明 | 资源文件 |
|---|---|---|
| technical-indicators | 技术指标计算（MA/MACD/RSI/KDJ/BOLL） | 无（Python 脚本内嵌） |
| a-share-analysis | A股行情分析与走势研判（四步法） | 无 |
| real-estate-profile | 通用房地产档案生成 | 无（附录 A-E 内嵌） |
| broadband-speedtest | 家庭宽带测速（联通/Ookla/curl） | scripts/ + references/ |

## 目录结构

```
skills/
├── technical-indicators/SKILL.md
├── a-share-analysis/SKILL.md
├── real-estate-profile/SKILL.md
└── broadband-speedtest/
    ├── SKILL.md
    ├── scripts/
    │   ├── speedtest_unicom.sh
    │   ├── speedtest_ookla.sh
    │   └── speedtest_curl.sh
    └── references/
        ├── nodes.md
        └── troubleshooting.md
```

## 同步到 LobeHub

```bash
lh skill install https://github.com/NickShee/lobehub-skills
```

## 备注

- broadband-speedtest 依赖设备路径：`/files/speedtest-ookla/speedtest`（Ookla CLI 二进制，未入库）、`/opt/chrome-linux64/chrome`（Chrome 引擎）
- `dist/broadband-speedtest.skill` 为该 skill 的打包产物（ZIP），保留在本地 `/files/skill-backup/skills/broadband-speedtest/dist/`，未推送 GitHub（二进制）
- 市场安装的 skill（anysearch/firecrawl/agent-browser 等）不在此仓库，走 LobeHub 市场通道
