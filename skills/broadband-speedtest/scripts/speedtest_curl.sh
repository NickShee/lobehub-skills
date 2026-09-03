#!/bin/bash
# ============================================================
# curl 国内镜像多线程下载测速 (无需安装, 最轻量)
# 用途: 验证真实国内下行带宽, 不受国际出口/VLESS 影响
# 用法: speedtest_curl.sh [并发数] [每线程MB]
#   speedtest_curl.sh            # 8 并发 x 100MB
#   speedtest_curl.sh 4 50       # 4 并发 x 50MB
#
# 原理: 每个线程 Range 断点下载镜像不同区间, 并发累加吞吐
#   计算: 总下载字节 / 总耗时 = 下行带宽
# ============================================================

set -u
CONC="${1:-8}"
MB="${2:-100}"
URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/24.04/ubuntu-24.04.4-desktop-amd64.iso"

echo "并发: ${CONC} | 每线程下载: ${MB}MB | 镜像: $(echo $URL | cut -d/ -f3)"
START=$(date +%s.%N)

TMP=$(mktemp -d)
SIZE=$((MB * 1048576))
for i in $(seq 1 "$CONC"); do
  (
    SB=$(( (i-1) * SIZE ))
    EB=$(( i * SIZE - 1 ))
    curl -s -r "$SB-$EB" --max-time 180 -o "$TMP/f$i" "$URL"
  ) &
done
wait
END=$(date +%s.%N)

TOTAL=0
for i in $(seq 1 "$CONC"); do
  [ -f "$TMP/f$i" ] && TOTAL=$((TOTAL + $(stat -c%s "$TMP/f$i" 2>/dev/null || echo 0)))
done
rm -rf "$TMP"

python3 - "$TOTAL" "$START" "$END" <<'EOF'
import sys
total, s, e = int(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
dur = max(e - s, 0.001)
mbps = total * 8 / dur / 1e6
print(f"下载字节: {total} ({total/1048576:.1f} MB)")
print(f"耗时: {dur:.1f}s")
print(f"===== 下行带宽: {mbps:.1f} Mbps =====")
EOF
