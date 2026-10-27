# 실험 스니펫: cpu-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:12:48 KST
- 케이스: `cpu-before`
- 생존 시간: 25 seconds (2026-10-27 19:12:50 ~ 2026-10-27 19:13:15)
- 종료 방식: 앱 자체 종료
- 종료 코드: 143 (SIGTERM)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=90
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 1417)
[INFO] Run timeout: 120s
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
 [ CPU    ] Limit: 90%  		[ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False 		[ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-10-27 19:12:51,312 [INFO] [CpuWorker] Started. Maximum CPU Limit: 90%
2026-10-27 19:12:51,314 [INFO] [CpuWorker] Current Load: 5.00%
2026-10-27 19:12:54,438 [INFO] [CpuWorker] Current Load: 6.62%
2026-10-27 19:12:57,554 [INFO] [CpuWorker] Current Load: 15.90%
2026-10-27 19:13:00,683 [INFO] [CpuWorker] Current Load: 22.39%
2026-10-27 19:13:03,839 [INFO] [CpuWorker] Current Load: 32.15%
2026-10-27 19:13:06,967 [INFO] [CpuWorker] Current Load: 35.04%
2026-10-27 19:13:10,094 [INFO] [CpuWorker] Current Load: 42.31%
2026-10-27 19:13:13,218 [INFO] [CpuWorker] Current Load: 47.71%
2026-10-27 19:13:16,348 [INFO] [CpuWorker] Current Load: 55.10%
2026-10-27 19:13:16,453 [CRITICAL] [CpuWorker] CPU Threshold Violated! (55.1%).

>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:12:50] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:15.7% PROC_MEM:0.3% RSS:25612KB SYS_CPU:3.0% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:52] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:6.5% PROC_MEM:0.3% RSS:25716KB SYS_CPU:4.0% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:54] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.3% PROC_MEM:0.3% RSS:25756KB SYS_CPU:3.1% SYS_MEM:13.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:13:11] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:23 THREADS:1 PROC_CPU:1.7% PROC_MEM:0.3% RSS:25776KB SYS_CPU:2.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:13:13] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:24 THREADS:1 PROC_CPU:1.8% PROC_MEM:0.3% RSS:25776KB SYS_CPU:2.0% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:13:15] PID:1432 PPID:1420 STATE:SN+ ELAPSED:00:26 THREADS:1 PROC_CPU:1.6% PROC_MEM:0.3% RSS:25776KB SYS_CPU:3.4% SYS_MEM:13.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 27 19:13 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8234 Oct 27 19:05 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 27 19:03 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 34838 Oct 27 19:05 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15728 Oct 27 19:05 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4920 Oct 27 19:05 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   757 Oct 27 19:05 after-run.log
-rw-r--r-- 1 agentuser agentuser  3166 Oct 27 19:05 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2091 Oct 27 19:13 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 27 19:12 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  7020 Oct 27 19:13 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  3557 Oct 27 19:13 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 27 19:13 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   575 Oct 27 19:13 before-run.log
-rw-r--r-- 1 agentuser agentuser   752 Oct 27 19:13 before-timeseries.csv
```
