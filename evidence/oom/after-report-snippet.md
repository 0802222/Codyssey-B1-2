# 실험 스니펫: oom-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-09-10 16:44:26 KST
- 케이스: `oom-after`
- 생존 시간: 31 seconds (2026-09-10 16:43:52 ~ 2026-09-10 16:44:23)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=256
MULTI_THREAD_ENABLE=true
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 256MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-09-10 16:43:53,300 [INFO] [MemoryWorker] Current Heap: 25MB
2026-09-10 16:43:56,353 [INFO] [MemoryWorker] Current Heap: 50MB
2026-09-10 16:43:59,404 [INFO] [MemoryWorker] Current Heap: 75MB
2026-09-10 16:44:02,450 [INFO] [MemoryWorker] Current Heap: 100MB
2026-09-10 16:44:05,504 [INFO] [MemoryWorker] Current Heap: 125MB
2026-09-10 16:44:08,555 [INFO] [MemoryWorker] Current Heap: 150MB
2026-09-10 16:44:11,605 [INFO] [MemoryWorker] Current Heap: 175MB
2026-09-10 16:44:14,662 [INFO] [MemoryWorker] Current Heap: 200MB
2026-09-10 16:44:17,715 [INFO] [MemoryWorker] Current Heap: 225MB
2026-09-10 16:44:20,769 [INFO] [MemoryWorker] Current Heap: 250MB
2026-09-10 16:44:23,823 [INFO] [MemoryWorker] Current Heap: 275MB
2026-09-10 16:44:23,823 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
2026-09-10 16:44:23,823 [CRITICAL] [MemoryGuard] Self-terminating process 8117 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-10 16:43:52] PID:8117 PPID:8103 STATE:SN ELAPSED:00:00 THREADS:1 PROC_CPU:4.2% PROC_MEM:0.1% RSS:18228KB SYS_CPU:0.0% SYS_MEM:3.7% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:53] PID:8117 PPID:8103 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:3.1% PROC_MEM:0.2% RSS:43832KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:54] PID:8117 PPID:8103 STATE:SN ELAPSED:00:03 THREADS:1 PROC_CPU:2.0% PROC_MEM:0.2% RSS:43832KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-10 16:44:21] PID:8117 PPID:8103 STATE:SN ELAPSED:00:29 THREADS:1 PROC_CPU:1.3% PROC_MEM:1.6% RSS:274268KB SYS_CPU:0.0% SYS_MEM:5.4% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:44:22] PID:8117 PPID:8103 STATE:SN ELAPSED:00:31 THREADS:1 PROC_CPU:1.2% PROC_MEM:1.6% RSS:274268KB SYS_CPU:0.0% SYS_MEM:5.2% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:44:23] PID:8117 PPID:8103 STATE:SN ELAPSED:00:32 THREADS:1 PROC_CPU:1.2% PROC_MEM:1.6% RSS:274268KB SYS_CPU:0.0% SYS_MEM:5.2% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)


## 파일 목록

```
drwxrwxr-x 1 agentuser agentuser   448 Sep 10 16:44 .
drwxrwxr-x 1 agentuser agentuser    96 Sep  9 17:37 ..
-rw-r--r-- 1 agentuser agentuser  2246 Sep 10 16:44 after-app.log
-rw-r--r-- 1 agentuser agentuser   170 Sep 10 16:43 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 12706 Sep 10 16:44 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  5685 Sep 10 16:44 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Sep 10 16:44 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  1304 Sep 10 16:44 after-timeseries.csv
-rw-rw-r-- 1 agentuser agentuser  1784 Sep 10 16:43 before-app.log
-rw-rw-r-- 1 agentuser agentuser   171 Sep 10 16:43 before-env-snapshot.txt
-rw-rw-r-- 1 agentuser agentuser  4274 Sep 10 16:43 before-monitor-stdout.log
-rw-rw-r-- 1 agentuser agentuser  1962 Sep 10 16:43 before-monitor.log
-rw-rw-r-- 1 agentuser agentuser  3532 Sep 10 16:43 before-report-snippet.md
-rw-rw-r-- 1 agentuser agentuser   488 Sep 10 16:43 before-timeseries.csv
```
