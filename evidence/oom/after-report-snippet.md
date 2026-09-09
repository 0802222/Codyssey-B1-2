# 실험 스니펫: oom-after

_이 파일은 리포트 작성 시 관측 사실 인용에 사용하세요._
_"3. Root Cause Analysis"와 "4. Workaround & Verification"은 직접 작성이 필요합니다._

## 실험 조건

- 실험 시각: 2026-09-09 14:24:39 KST
- 케이스: `oom-after`
- 생존 시간: 측정 불가

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

2026-09-09 14:24:06,556 [INFO] [MemoryWorker] Current Heap: 25MB
2026-09-09 14:24:09,577 [INFO] [MemoryWorker] Current Heap: 50MB
2026-09-09 14:24:12,609 [INFO] [MemoryWorker] Current Heap: 75MB
2026-09-09 14:24:15,659 [INFO] [MemoryWorker] Current Heap: 100MB
2026-09-09 14:24:18,710 [INFO] [MemoryWorker] Current Heap: 125MB
2026-09-09 14:24:21,764 [INFO] [MemoryWorker] Current Heap: 150MB
2026-09-09 14:24:24,811 [INFO] [MemoryWorker] Current Heap: 175MB
2026-09-09 14:24:27,863 [INFO] [MemoryWorker] Current Heap: 200MB
2026-09-09 14:24:30,916 [INFO] [MemoryWorker] Current Heap: 225MB
2026-09-09 14:24:33,966 [INFO] [MemoryWorker] Current Heap: 250MB
2026-09-09 14:24:37,018 [INFO] [MemoryWorker] Current Heap: 275MB
2026-09-09 14:24:37,019 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
2026-09-09 14:24:37,019 [CRITICAL] [MemoryGuard] Self-terminating process 1621 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:01 THREADS:1 PROC_CPU:5.8% PROC_MEM:0.0% RSS:2184KB SYS_CPU:0.0% SYS_MEM:3.5% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:02 THREADS:1 PROC_CPU:2.6% PROC_MEM:0.0% RSS:2184KB SYS_CPU:1.6% SYS_MEM:3.7% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:03 THREADS:1 PROC_CPU:1.6% PROC_MEM:0.0% RSS:2184KB SYS_CPU:0.0% SYS_MEM:3.7% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:29 THREADS:1 PROC_CPU:0.2% PROC_MEM:0.0% RSS:2184KB SYS_CPU:0.0% SYS_MEM:5.2% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:31 THREADS:1 PROC_CPU:0.1% PROC_MEM:0.0% RSS:2184KB SYS_CPU:1.6% SYS_MEM:5.1% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-09 14:24:04] PID:1610 PPID:1601 STATE:S+ ELAPSED:00:32 THREADS:1 PROC_CPU:0.1% PROC_MEM:0.0% RSS:2184KB SYS_CPU:0.0% SYS_MEM:5.1% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)

CSV를 스프레드시트로 열어 RSS, PROC_CPU 그래프를 리포트에 첨부하세요.

## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   256 Sep  9 14:24 .
drwxrwxr-x 1 agentuser agentuser   128 Sep  9 14:24 ..
-rw-r--r-- 1 agentuser agentuser  2246 Sep  9 14:24 app.log
-rw-r--r-- 1 agentuser agentuser   170 Sep  9 14:24 env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 13285 Sep  9 14:24 monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  5928 Sep  9 14:24 monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Sep  9 14:24 report-snippet.md
-rw-r--r-- 1 agentuser agentuser  1261 Sep  9 14:24 timeseries.csv
```
