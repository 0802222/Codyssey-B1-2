# 실험 스니펫: cpu-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-09-25 14:21:32 KST
- 케이스: `cpu-after`
- 생존 시간: 772 seconds (2026-09-25 14:08:37 ~ 2026-09-25 14:21:29)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 앱 로그 (마지막 20줄)

```
2026-09-25 14:21:00,061 [INFO] [MemoryWorker] Current Heap: 150MB
2026-09-25 14:21:02,507 [INFO] [CpuWorker] Current Load: 34.91%
2026-09-25 14:21:03,103 [INFO] [MemoryWorker] Current Heap: 175MB
2026-09-25 14:21:05,628 [INFO] [CpuWorker] Current Load: 43.35%
2026-09-25 14:21:06,145 [INFO] [MemoryWorker] Current Heap: 200MB
2026-09-25 14:21:08,747 [INFO] [CpuWorker] Current Load: 44.51%
2026-09-25 14:21:09,196 [INFO] [MemoryWorker] Current Heap: 225MB
2026-09-25 14:21:11,866 [INFO] [CpuWorker] Current Load: 46.96%
2026-09-25 14:21:12,249 [INFO] [MemoryWorker] Current Heap: 250MB
2026-09-25 14:21:13,980 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-09-25 14:21:14,986 [INFO] [CpuWorker] Current Load: 50.00%
2026-09-25 14:21:15,299 [INFO] [MemoryWorker] Current Heap: 275MB
2026-09-25 14:21:18,107 [INFO] [CpuWorker] Current Load: 46.45%
2026-09-25 14:21:18,353 [INFO] [MemoryWorker] Current Heap: 300MB
2026-09-25 14:21:21,227 [INFO] [CpuWorker] Current Load: 44.95%
2026-09-25 14:21:21,402 [INFO] [MemoryWorker] Current Heap: 325MB
2026-09-25 14:21:24,348 [INFO] [CpuWorker] Current Load: 38.55%
2026-09-25 14:21:24,455 [INFO] [MemoryWorker] Current Heap: 350MB
2026-09-25 14:21:27,504 [INFO] [CpuWorker] Current Load: 29.72%
2026-09-25 14:21:27,504 [INFO] [MemoryWorker] Current Heap: 375MB
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-25 14:08:37] PID:8650 PPID:8636 STATE:SN ELAPSED:00:00 THREADS:1 PROC_CPU:4.3% PROC_MEM:0.1% RSS:18276KB SYS_CPU:1.6% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:08:38] PID:8650 PPID:8636 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:2.2% PROC_MEM:0.1% RSS:18340KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:08:39] PID:8650 PPID:8636 STATE:SNl ELAPSED:00:03 THREADS:3 PROC_CPU:2.9% PROC_MEM:0.2% RSS:44176KB SYS_CPU:0.0% SYS_MEM:4.1% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-25 14:21:27] PID:8650 PPID:8636 STATE:SNl ELAPSED:12:50 THREADS:3 PROC_CPU:1.7% PROC_MEM:2.2% RSS:370544KB SYS_CPU:8.1% SYS_MEM:5.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:21:28] PID:8650 PPID:8636 STATE:SNl ELAPSED:12:52 THREADS:3 PROC_CPU:1.7% PROC_MEM:2.4% RSS:396160KB SYS_CPU:0.0% SYS_MEM:5.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:21:29] PID:8650 PPID:8636 STATE:SNl ELAPSED:12:53 THREADS:3 PROC_CPU:1.7% PROC_MEM:2.4% RSS:396160KB SYS_CPU:16.7% SYS_MEM:3.8% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser    448 Sep 25 12:52 .
drwxr-xr-x 1 agentuser agentuser    128 Sep 25 12:26 ..
-rw-r--r-- 1 agentuser agentuser  40194 Sep 25 14:21 after-app.log
-rw-r--r-- 1 agentuser agentuser    171 Sep 25 14:08 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 305590 Sep 25 14:21 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 135719 Sep 25 14:21 after-monitor.log
-rw-r--r-- 1 agentuser agentuser      0 Sep 25 14:21 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  30277 Sep 25 14:21 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser   2167 Sep 25 14:07 before-app.log
-rw-r--r-- 1 agentuser agentuser    172 Sep 25 14:06 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  11618 Sep 25 14:07 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser   5668 Sep 25 14:07 before-monitor.log
-rw-r--r-- 1 agentuser agentuser   4067 Sep 25 14:07 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   1287 Sep 25 14:07 before-timeseries.csv
```
