#!/bin/bash
# ============================================================
# Ookla Speedtest CLI 测速
# 用法:
#   speedtest_ookla.sh                # 自动选节点, 1 次
#   speedtest_ookla.sh -s <id>        # 指定节点测速
#   speedtest_ookla.sh -n <次数>      # 连续测 N 次
#   speedtest_ookla.sh -j             # JSON 解析输出
#
# 前置: Ookla CLI 二进制 (speedtest 1.2.x)
#   位置优先: /files/speedtest-ookla/speedtest
#   PATH 或 SPEEDTEST_BIN 环境变量
#
# 已知节点(2026-09):
#   苏州 JSQY 16204      -> 下载测速故障(连接正常但测不出)
#   昆山杜克 30852       -> 不可达
#   首尔 GSL 73226       -> 国际节点, 受国际出口/VLESS影响
# ============================================================

set -u

# 定位 speedtest 二进制
BIN="${SPEEDTEST_BIN:-}"
[ -z "$BIN" ] && [ -x /files/speedtest-ookla/speedtest ] && BIN=/files/speedtest-ookla/speedtest
[ -z "$BIN" ] && BIN=$(command -v speedtest 2>/dev/null || echo "")
[ -z "$BIN" ] && { echo "错误: 未找到 speedtest 二进制" >&2; echo "可设置 SPEEDTEST_BIN 或安装到 /files/speedtest-ookla/" >&2; exit 1; }

LICENSE="--accept-license --accept-gdpr"
SERVER=""
TIMES=1
JSON=0

usage() {
  cat <<'EOF'
用法: speedtest_ookla.sh [-s <server_id>] [-n <次数>] [-j]

选项:
  -s <id>   指定服务器 ID (默认自动选最近节点)
  -n <次数> 连续测速次数 (默认 1)
  -j        JSON 解析输出 (需 python3)
  -h        帮助
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s) SERVER="${2:-}"; shift 2 ;;
    -n) TIMES="${2:-1}"; shift 2 ;;
    -j) JSON=1; shift ;;
    -h) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage; exit 1 ;;
  esac
done

run_once() {
  local n=$1
  CMD=("$BIN" $LICENSE)
  [ -n "$SERVER" ] && CMD+=( -s "$SERVER" )
  if [ "$JSON" -eq 1 ]; then
    RAW="$("${CMD[@]}" -f json 2>/dev/null)" || { echo "测速失败" >&2; return 1; }
    echo "$RAW" | python3 -c '
import json, sys
try: d = json.load(sys.stdin)
except: print("JSON 解析失败"); sys.exit(1)
if "error" in d: print("错误:", d["error"]); sys.exit(1)
svr = d.get("server", {})
p = d.get("ping", {})
dl = d.get("download", {}).get("bandwidth", 0)
ul = d.get("upload", {}).get("bandwidth", 0)
print("=" * 46)
print("服务器 :", svr.get("name","?"), "-", svr.get("location","?"), "(ID %s)" % svr.get("id","?"))
print("ISP    :", d.get("isp","?"))
print("外部IP :", d.get("interface",{}).get("externalIp","?"))
print("Ping   : %.1f ms | Jitter: %.1f ms | 丢包: %s" % (p.get("latency",0), p.get("jitter",0), d.get("packetLoss",0)))
print("下载   : %.1f Mbps (%.2f MB/s)" % (dl*8/1e6, dl/1048576))
print("上传   : %.1f Mbps (%.2f MB/s)" % (ul*8/1e6, ul/1048576))
u = d.get("result",{}).get("url","")
if u: print("结果   :", u)
print("=" * 46)
'
  else
    echo "--- 第 ${n} 次 Ookla 测速 ---"
    "${CMD[@]}"
  fi
}

for i in $(seq 1 "$TIMES"); do
  run_once "$i"
done
