---
name: technical-indicators
description: 技术指标计算（Python）。计算 MA/MACD/RSI/KDJ/布林带等技术指标时使用，输入 OHLCV 行情数据，输出指标数值与买卖信号。触发词：技术指标/计算/MA/MACD/RSI/KDJ/布林带/均线/金叉/死叉/超买/超卖。配套 a-share-analysis 使用。
---

# 技术指标计算

基于行情 OHLCV 数据（开盘价、最高价、最低价、收盘价、成交量）计算常用技术指标。在 Cloud Sandbox（Python）中运行。

## 数据输入格式

行情数据为 CSV，列顺序：`date,open,high,low,close,volume`，示例：

```csv
date,open,high,low,close,volume
2026-08-01,10.0,10.5,9.8,10.2,1000000
2026-08-02,10.2,10.4,9.9,10.1,1200000
```

获取实时数据后，将其整理为该格式写入脚本输入。

## 计算脚本

将以下脚本保存为 `indicators.py` 并运行（Python 3，无第三方依赖，仅用标准库）：

```python
"""技术指标计算：MA / MACD / RSI / KDJ / 布林带（BOLL）
输入：CSV（date,open,high,low,close,volume）
用法：python indicators.py <input.csv> [output.csv]
"""
import sys, csv, math

def ema(values, period):
    """指数移动平均"""
    if not values: return []
    k = 2 / (period + 1)
    out, prev = [], values[0]
    for v in values:
        prev = v if not out else v * k + prev * (1 - k)
        out.append(prev)
    return out

def sma(values, period):
    """简单移动平均"""
    out = []
    for i in range(len(values)):
        if i < period - 1:
            out.append(None)
        else:
            out.append(sum(values[i-period+1:i+1]) / period)
    return out

def rsi(values, period=14):
    """RSI 相对强弱指标"""
    if len(values) < period + 1:
        return [None] * len(values)
    gains, losses = [], []
    for i in range(1, len(values)):
        chg = values[i] - values[i-1]
        gains.append(max(chg, 0))
        losses.append(max(-chg, 0))
    out = [None] * len(values)
    avg_g = sum(gains[:period]) / period
    avg_l = sum(losses[:period]) / period
    for i in range(period, len(values)):
        if i > period:
            avg_g = (avg_g * (period-1) + gains[i-1]) / period
            avg_l = (avg_l * (period-1) + losses[i-1]) / period
        rs = avg_g / avg_l if avg_l != 0 else 100.0
        out[i] = 100 - 100 / (1 + rs)
    return out

def macd(closes, fast=12, slow=26, signal=9):
    """MACD：DIF / DEA / 柱"""
    ema_fast = ema(closes, fast)
    ema_slow = ema(closes, slow)
    dif = [f - s for f, s in zip(ema_fast, ema_slow)]
    dea = ema(dif, signal)
    hist = [(d - e) * 2 for d, e in zip(dif, dea)]
    return dif, dea, hist

def kdj(highs, lows, closes, n=9, k_period=3, d_period=3):
    """KDJ 随机指标"""
    k, d = 50.0, 50.0
    k_list, d_list, j_list = [], [], []
    for i in range(len(closes)):
        if i < n - 1:
            k_list.append(None); d_list.append(None); j_list.append(None)
            continue
        hh = max(highs[i-n+1:i+1])
        ll = min(lows[i-n+1:i+1])
        rsv = (closes[i] - ll) / (hh - ll) * 100 if hh != ll else 50.0
        k = (2/3) * k + (1/3) * rsv
        d = (2/3) * d + (1/3) * k
        j = 3 * k - 2 * d
        k_list.append(k); d_list.append(d); j_list.append(j)
    return k_list, d_list, j_list

def bollinger(closes, period=20, num_std=2):
    """布林带：中轨/上轨/下轨"""
    mid = sma(closes, period)
    upper, lower = [], []
    for i in range(len(closes)):
        if i < period - 1:
            upper.append(None); lower.append(None)
            continue
        window = closes[i-period+1:i+1]
        variance = sum((x - mid[i])**2 for x in window) / period
        std = math.sqrt(variance)
        upper.append(mid[i] + num_std * std)
        lower.append(mid[i] - num_std * std)
    return mid, upper, lower

def main():
    if len(sys.argv) < 2:
        print("用法: python indicators.py <input.csv> [output.csv]"); sys.exit(1)
    dates, o, h, l, c, v = [], [], [], [], [], []
    with open(sys.argv[1], newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            dates.append(row['date']); o.append(float(row['open']))
            h.append(float(row['high'])); l.append(float(row['low']))
            c.append(float(row['close'])); v.append(float(row['volume']))

    ma5, ma10, ma20, ma60 = sma(c,5), sma(c,10), sma(c,20), sma(c,60)
    dif, dea, hist = macd(c)
    r = rsi(c)
    k, d, j = kdj(h, l, c)
    bmid, bupper, blower = bollinger(c)

    out = sys.argv[2] if len(sys.argv) > 2 else "indicators_out.csv"
    with open(out, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['date','close','MA5','MA10','MA20','MA60','MACD_DIF','MACD_DEA','MACD_HIST','RSI14','K','D','J','BOLL_MID','BOLL_UPPER','BOLL_LOWER'])
        for i in range(len(dates)):
            w.writerow([dates[i], c[i], fmt(ma5[i]), fmt(ma10[i]), fmt(ma20[i]), fmt(ma60[i]),
                        fmt(dif[i]), fmt(dea[i]), fmt(hist[i]), fmt(r[i]),
                        fmt(k[i]), fmt(d[i]), fmt(j[i]), fmt(bmid[i]), fmt(bupper[i]), fmt(blower[i])])

    # 最新信号汇总
    i = len(c) - 1
    def sig(v): return "N/A" if v is None else f"{v:.2f}"
    print(f"日期: {dates[i]}  收盘: {c[i]:.2f}")
    print(f"MA5={sig(ma5[i])} MA10={sig(ma10[i])} MA20={sig(ma20[i])} MA60={sig(ma60[i])}")
    print(f"MACD: DIF={sig(dif[i])} DEA={sig(dea[i])} HIST={sig(hist[i])}")
    print(f"RSI14={sig(r[i])}")
    print(f"KDJ: K={sig(k[i])} D={sig(d[i])} J={sig(j[i])}")
    print(f"BOLL: 上={sig(bupper[i])} 中={sig(bmid[i])} 下={sig(blower[i])}")
    print(f"输出已保存: {out}")

def fmt(x):
    return "" if x is None else f"{x:.4f}"

if __name__ == "__main__":
    main()
```

## 信号解读

| 指标 | 信号 | 含义 |
|---|---|---|
| MA5/MA10/MA20 | 多头排列（MA5>MA10>MA20） | 上升趋势 |
| MA 金叉/死叉 | MA5 上穿/下穿 MA20 | 转强/转弱 |
| MACD | DIF 上穿 DEA（金叉） | 买入信号 |
| MACD | DIF 下穿 DEA（死叉） | 卖出信号 |
| MACD 柱 | 由负转正/由正转负 | 动能转强/转弱 |
| RSI14 | >70 超买，<30 超卖 | 反转风险 |
| KDJ | K 上穿 D（金叉）在低位 | 买入信号 |
| KDJ | K 下穿 D（死叉）在高位 | 卖出信号 |
| 布林带 | 触及上轨/下轨 | 超买/超卖 |
| 布林带 | 开口放大/收窄 | 波动加剧/盘整 |

## 生成图表（可选）

如需走势图/资金流向图，可用 matplotlib 读取输出 CSV 绘制 K 线 + 指标子图，保存为 PNG 后导出给用户。
