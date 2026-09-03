#!/bin/bash
# ============================================================
# 北京联通官方测速平台自动化测速 (agent-browser)
# 用法: speedtest_unicom.sh [次数]   # 默认 3 次
#
# 前置条件:
#   - agent-browser CLI 已安装 (npm i -g agent-browser)
#   - Chrome/Chromium 引擎: 设置 AGENT_BROWSER_EXECUTABLE_PATH
#     或自动探测 /opt/chrome-linux64/chrome
#   - 建议前台运行, 后台运行时 agent-browser 点击可能失效
#
# 关键经验(勿删):
#   - snapshot 输出 [ref=e6], 提取 e6 需去掉 "ref=" 前缀再 click "@e6"
#   - "同意"按钮必须精确匹配 grep '"同意"', 否则会匹配到"不同意"
#   - 首次测速会弹协议框, 需点击"同意"
# ============================================================

set -u
URL="http://cs1.bbn.com.cn:8800/gzweb/"
TIMES="${1:-3}"

# Chrome 引擎路径
if [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ]; then
  if [ -x /opt/chrome-linux64/chrome ]; then
    export AGENT_BROWSER_EXECUTABLE_PATH=/opt/chrome-linux64/chrome
    echo "[使用 Chrome: /opt/chrome-linux64/chrome]"
  fi
fi
command -v agent-browser >/dev/null 2>&1 || { echo "错误: 需要 agent-browser CLI (npm i -g agent-browser)" >&2; exit 1; }

# 单次测速
run_once() {
  local n=$1
  timeout 60 agent-browser open "$URL" >/dev/null 2>&1
  timeout 20 agent-browser wait --load networkidle >/dev/null 2>&1
  SNAP=$(timeout 30 agent-browser snapshot -i 2>&1)
  # 下行测速开始按钮 = "下行测速" 行之后的 "开始测速" 行
  DL=$(echo "$SNAP" | awk '/下行测速/{getline; print}' | grep -oE 'ref=e[0-9]+' | sed 's/ref=//' | head -1)
  [ -z "$DL" ] && { echo "第 ${n} 次: 未找到下行测速按钮, 跳过" >&2; return 1; }
  timeout 20 agent-browser click "@$DL" >/dev/null 2>&1
  sleep 2
  SNAP2=$(timeout 30 agent-browser snapshot -i 2>&1)
  AGREE=$(echo "$SNAP2" | grep '"同意"' | grep -oE 'ref=e[0-9]+' | sed 's/ref=//' | head -1)
  [ -n "$AGREE" ] && timeout 20 agent-browser click "@$AGREE" >/dev/null 2>&1
  sleep 40   # 测速约 30-60 秒
  echo "--- 第 ${n} 次联通测速结果 ---"
  timeout 30 agent-browser get text body 2>&1 | grep -A1 -E "下行/Mbps|时延|抖动|超越全国"
}

echo "北京联通官方测速平台: $URL"
for i in $(seq 1 "$TIMES"); do
  run_once "$i"
done
timeout 20 agent-browser close >/dev/null 2>&1
echo "=== 测速完成 ==="
