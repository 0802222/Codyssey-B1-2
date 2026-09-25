# 실험 스니펫: cpu-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-09-25 14:07:22 KST
- 케이스: `cpu-before`
- 생존 시간: 31 seconds (2026-09-25 14:06:48 ~ 2026-09-25 14:07:19)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=90
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 90%  		[ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False 		[ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-09-25 14:06:49,641 [INFO] [CpuWorker] Started. Maximum CPU Limit: 90%
2026-09-25 14:06:49,641 [INFO] [CpuWorker] Current Load: 5.00%
2026-09-25 14:06:52,761 [INFO] [CpuWorker] Current Load: 8.92%
2026-09-25 14:06:55,881 [INFO] [CpuWorker] Current Load: 13.51%
2026-09-25 14:06:59,001 [INFO] [CpuWorker] Current Load: 13.96%
2026-09-25 14:07:02,123 [INFO] [CpuWorker] Current Load: 23.02%
2026-09-25 14:07:05,244 [INFO] [CpuWorker] Current Load: 28.32%
2026-09-25 14:07:08,363 [INFO] [CpuWorker] Current Load: 31.03%
2026-09-25 14:07:11,484 [INFO] [CpuWorker] Current Load: 36.26%
2026-09-25 14:07:14,604 [INFO] [CpuWorker] Current Load: 36.89%
2026-09-25 14:07:17,723 [INFO] [CpuWorker] Current Load: 44.98%
2026-09-25 14:07:20,842 [INFO] [CpuWorker] Current Load: 53.12%
2026-09-25 14:07:20,943 [CRITICAL] [CpuWorker] CPU Threshold Violated! (53.120000000000005%).
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-25 14:06:48] PID:7522 PPID:7508 STATE:SN ELAPSED:00:00 THREADS:1 PROC_CPU:6.5% PROC_MEM:0.1% RSS:18396KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:06:49] PID:7522 PPID:7508 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:2.7% PROC_MEM:0.1% RSS:18460KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:06:50] PID:7522 PPID:7508 STATE:SN ELAPSED:00:03 THREADS:1 PROC_CPU:1.7% PROC_MEM:0.1% RSS:18460KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-25 14:07:17] PID:7522 PPID:7508 STATE:SN ELAPSED:00:29 THREADS:1 PROC_CPU:0.8% PROC_MEM:0.1% RSS:18460KB SYS_CPU:0.0% SYS_MEM:4.0% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:07:18] PID:7522 PPID:7508 STATE:SN ELAPSED:00:31 THREADS:1 PROC_CPU:0.9% PROC_MEM:0.1% RSS:18460KB SYS_CPU:1.7% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-25 14:07:19] PID:7522 PPID:7508 STATE:SN ELAPSED:00:32 THREADS:1 PROC_CPU:0.9% PROC_MEM:0.1% RSS:18460KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   448 Sep 25 12:52 .
drwxr-xr-x 1 agentuser agentuser   128 Sep 25 12:26 ..
-rw-r--r-- 1 agentuser agentuser  2216 Sep 25 12:52 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Sep 25 12:52 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 12943 Sep 25 12:52 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  6351 Sep 25 12:52 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4086 Sep 25 12:52 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  1457 Sep 25 12:52 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2167 Sep 25 14:07 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Sep 25 14:06 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 11590 Sep 25 14:07 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  5668 Sep 25 14:07 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Sep 25 14:07 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  1287 Sep 25 14:07 before-timeseries.csv
```
