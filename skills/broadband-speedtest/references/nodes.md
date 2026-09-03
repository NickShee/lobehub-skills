# 测速节点参考

## 中国联通官方测速平台

### 北京（推荐，已验证 2026-09）
```
http://cs1.bbn.com.cn:8800/gzweb/
```
- 现代 SPA 测速平台（标题"北京联通宽带测速平台"）
- **无瑞数 WAF**，curl 可直接访问（对比电信 189 的 412 拦截）
- 需 agent-browser 驱动浏览器测速（测速逻辑是混淆 JS，无法纯命令行调用）
- 会显示：下行/Mbps、时延、抖动、IP、套餐判断、"超越全国"百分比

### 联通网上营业厅测速
```
https://iservice.10010.com/e4/transact/basic/service_broadband.html
```
- 需登录联通账号（服务密码）+ 选择省份
- 无瑞数 WAF，页面可达，但测速需登录态浏览器

### 各省测速服务器（从官网 speedTest.js 省份映射挖出，部分已失效）
| 省份 | URL |
|------|-----|
| 北京 | http://cs1.bbn.com.cn:8800/gzweb/ ✅可用 |
| 天津 | http://adsl.online.tj.cn |
| 浙江 | http://speedtest.zj.chinaunicom.com/ |
| 福建 | http://WWW.SPEED.FJCNC.CN |
| 湖北 | http://hbspeed.hb.cnc.cn/ |
| 河南 | http://cesu.shangdu.com/ |
| 重庆 | http://cesu.cqwin.com/ |
| 吉林 | http://cesu.jl.cn/ |
| 四川 | http://speedtest.169ol.com |
| 北京(旧IP) | http://110.17.170.22 ❌已失效 |

## Ookla Speedtest 可用节点（2026-09）

| ID | 名称 | 位置 | 状态 |
|----|------|------|------|
| 73226 | GSL Networks | 首尔 Seoul | ✅可连（国际，受出口影响） |
| 16204 | JSQY | 苏州 Suzhou | ⚠️下载测速故障（连接正常，下载 1Mbps） |
| 30852 | Duke Kunshan | 昆山 | ❌不可达 |
| 48402 | kdatacenter.com | 首尔 | 可连（国际） |
| 67564 | MOACK Data Center | 龙仁 Yongin-si | 可连（国际） |

**注意**：中国境内 Ookla 节点稀少（仅苏州/昆山），国内测速建议优先联通官方平台或 curl 清华镜像。

## curl 国内镜像（无需账号）

```
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/24.04/ubuntu-24.04.2-desktop-amd64.iso
```
- 清华 TUNA 镜像，国内高速，支持 Range 断点，适合并发测速
- 其他可选：中科大 mirrors.ustc.edu.cn、阿里云 mirrors.aliyun.com
