# 测速故障排查与经验

## agent-browser 自动化关键经验（踩坑记录）

### 1. ref 提取必须去掉 `ref=` 前缀
```bash
# snapshot 输出: - generic "开始测速" [ref=e6]
# 错误: 提取出 "ref=e6" 后 click "@ref=e6" -> Element not found
# 正确: 提取 "e6" 后 click "@e6"
REF=$(echo "$SNAP" | grep -oE 'ref=e[0-9]+' | sed 's/ref=//' | head -1)
agent-browser click "@$REF"
```

### 2. "同意"按钮必须精确匹配
```bash
# 协议弹窗含"同意"和"不同意"两个按钮
# 错误: grep '同意' 会先匹配到"不同意"行 -> 点到拒绝
# 正确: grep '"同意"' (带引号精确匹配, 排除"不同意")
AGREE=$(echo "$SNAP" | grep '"同意"' | grep -oE 'ref=e[0-9]+' | sed 's/ref=//' | head -1)
```

### 3. 不要在后台运行 agent-browser 交互
- `run_in_background` 跑 agent-browser 点击命令时，点击可能不生效（测速不开始）
- 前台运行（或后台运行但轮询等待）更可靠

### 4. 每次测速前重新加载页面
- 同页连续点击测速，第二次可能不触发新测速（结果区域不刷新）
- 正确做法：每次 `open` 页面重新加载后再测

### 5. refs 跨命令会失效
- snapshot 拿到的 @eN 在页面变化后会失效
- 单条命令内完成：open -> snapshot -> click -> agree -> wait -> read

### 6. Chrome 缺失依赖
```bash
# 容器内缺 libglib 等库，Chrome 无法启动
# Debian 12 安装:
apt-get update && apt-get install -y libglib2.0-0 libnss3 libnspr4 libdbus-1-3 \
  libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
  libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 \
  libcairo2 libx11-6 libxcb1 libxext6 fonts-liberation
```

### 7. Chrome 下载源（国内）
- `agent-browser install` 走 Google 官方源，国内卡死
- 用 npmmirror 镜像: `https://registry.npmmirror.com/-/binary/chrome-for-testing/<版本>/linux64/chrome-linux64.zip`
- 解压后设 `AGENT_BROWSER_EXECUTABLE_PATH=/opt/chrome-linux64/chrome`

## 网络环境影响

### VLESS / 国际出口故障
- 国际节点（Ookla 首尔、Speedtest 海外）结果会严重失真：
  - 丢包可高达 98%，Ping 300ms+
  - 即使测出高数字（如 879Mbps）也不可信（并发重传补偿）
- 判断方法：看测速结果的**丢包率**和 Ping，丢包 >10% 的结果不可信
- 测国内带宽不受影响（联通本地 CDN、清华镜像直连）

### 电信 189 测速有瑞数 WAF
- 电信测速平台（189.cn 等）有瑞数（River Security）动态防护
- curl / 简单请求返回 412 拦截，需要浏览器真实执行 JS
- 联通平台无此问题

## 带宽不达标排查（签约 1000M 实测 500M 场景）

1. **先区分 WiFi / 有线**：WiFi5 常见 400-600M，有线才能测出真实带宽
2. **检查网卡协商速率**：电脑网卡应显示 1.0 Gbps（百兆口/网线会锁 100M）
3. **光猫/路由器千兆口**：确认插在千兆 LAN 口
4. **多平台交叉验证**：联通官方 + curl 清华镜像 + Speedtest.cn
5. 均不达标 → 10010 报障，要求上门测光衰

## 实测参考值（2026-09-02 北京联通 1000M）

| 来源 | 下行 | 说明 |
|------|------|------|
| 联通官方(6次平均) | ~528 Mbps | 433-765 波动 |
| Ookla 首尔(国际) | 879 Mbps | 丢包98%不可信 |
| Ookla 苏州 | 1 Mbps | 节点故障 |
