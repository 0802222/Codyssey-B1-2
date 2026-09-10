# 실험 스니펫: oom-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-09-10 16:43:40 KST
- 케이스: `oom-before`
- 생존 시간: 10 seconds (2026-09-10 16:43:27 ~ 2026-09-10 16:43:37)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=100
MULTI_THREAD_ENABLE=true
```

## 앱 로그 (마지막 20줄)

```
Agent READY
2026-09-10 16:43:26,294 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-09-10 16:43:26,294 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-09-10 16:43:28,344 [INFO] [MemoryWorker] Current Heap: 25MB
2026-09-10 16:43:31,396 [INFO] [MemoryWorker] Current Heap: 50MB
2026-09-10 16:43:34,450 [INFO] [MemoryWorker] Current Heap: 75MB
2026-09-10 16:43:37,491 [INFO] [MemoryWorker] Current Heap: 100MB
2026-09-10 16:43:37,492 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-09-10 16:43:37,492 [CRITICAL] [MemoryGuard] Self-terminating process 7677 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-10 16:43:27] PID:7677 PPID:7663 STATE:SN ELAPSED:00:00 THREADS:1 PROC_CPU:5.3% PROC_MEM:0.1% RSS:18248KB SYS_CPU:0.0% SYS_MEM:3.7% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:28] PID:7677 PPID:7663 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:3.6% PROC_MEM:0.2% RSS:43852KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:29] PID:7677 PPID:7663 STATE:SN ELAPSED:00:03 THREADS:1 PROC_CPU:2.3% PROC_MEM:0.2% RSS:43852KB SYS_CPU:0.0% SYS_MEM:3.9% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-10 16:43:34] PID:7677 PPID:7663 STATE:SN ELAPSED:00:08 THREADS:1 PROC_CPU:1.8% PROC_MEM:0.5% RSS:95060KB SYS_CPU:0.0% SYS_MEM:4.3% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:35] PID:7677 PPID:7663 STATE:SN ELAPSED:00:09 THREADS:1 PROC_CPU:1.6% PROC_MEM:0.5% RSS:95060KB SYS_CPU:0.0% SYS_MEM:4.0% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:43:37] PID:7677 PPID:7663 STATE:SN ELAPSED:00:10 THREADS:1 PROC_CPU:1.4% PROC_MEM:0.5% RSS:95060KB SYS_CPU:0.0% SYS_MEM:4.0% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)


## 파일 목록

```
drwxrwxr-x 1 agentuser agentuser  256 Sep  9 17:37 .
drwxrwxr-x 1 agentuser agentuser   96 Sep  9 17:37 ..
-rw-rw-r-- 1 agentuser agentuser 1784 Sep 10 16:43 before-app.log
-rw-rw-r-- 1 agentuser agentuser  171 Sep 10 16:43 before-env-snapshot.txt
-rw-rw-r-- 1 agentuser agentuser 4274 Sep 10 16:43 before-monitor-stdout.log
-rw-rw-r-- 1 agentuser agentuser 1962 Sep 10 16:43 before-monitor.log
-rw-rw-r-- 1 agentuser agentuser    0 Sep 10 16:43 before-report-snippet.md
-rw-rw-r-- 1 agentuser agentuser  488 Sep 10 16:43 before-timeseries.csv
```
