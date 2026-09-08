# 실험 스니펫: oom-before

_이 파일은 리포트 작성 시 관측 사실 인용에 사용하세요._
_"3. Root Cause Analysis"와 "4. Workaround & Verification"은 직접 작성이 필요합니다._

## 실험 조건

- 실험 시각: 2026-09-08 18:06:03 KST
- 케이스: `oom-before`
- 생존 시간: 측정 불가

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
2026-09-08 18:05:49,611 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-09-08 18:05:49,612 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-09-08 18:05:51,660 [INFO] [MemoryWorker] Current Heap: 25MB
2026-09-08 18:05:54,714 [INFO] [MemoryWorker] Current Heap: 50MB
2026-09-08 18:05:57,768 [INFO] [MemoryWorker] Current Heap: 75MB
2026-09-08 18:06:00,820 [INFO] [MemoryWorker] Current Heap: 100MB
2026-09-08 18:06:00,820 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-09-08 18:06:00,821 [CRITICAL] [MemoryGuard] Self-terminating process 4474 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:01 THREADS:1 PROC_CPU:8.7% PROC_MEM:0.0% RSS:2176KB SYS_CPU:0.0% SYS_MEM:4.0% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:02 THREADS:1 PROC_CPU:3.9% PROC_MEM:0.0% RSS:2176KB SYS_CPU:1.6% SYS_MEM:4.1% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:03 THREADS:1 PROC_CPU:2.5% PROC_MEM:0.0% RSS:2176KB SYS_CPU:0.0% SYS_MEM:4.1% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:08 THREADS:1 PROC_CPU:1.0% PROC_MEM:0.0% RSS:2176KB SYS_CPU:0.0% SYS_MEM:4.5% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:09 THREADS:1 PROC_CPU:0.9% PROC_MEM:0.0% RSS:2176KB SYS_CPU:1.6% SYS_MEM:4.5% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
[2026-09-08 18:05:49] PID:4463 PPID:4454 STATE:S+ ELAPSED:00:11 THREADS:1 PROC_CPU:0.8% PROC_MEM:0.0% RSS:2176KB SYS_CPU:0.0% SYS_MEM:4.5% DISK_USED:1% PORT:15034 FIREWALL:permission denied CMD:/workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`timeseries.csv`](./timeseries.csv)

CSV를 스프레드시트로 열어 RSS, PROC_CPU 그래프를 리포트에 첨부하세요.

## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser  256 Sep  8 18:06 .
drwxrwxr-x 1 agentuser agentuser   96 Sep  8 18:05 ..
-rw-r--r-- 1 agentuser agentuser 1781 Sep  8 18:06 app.log
-rw-r--r-- 1 agentuser agentuser  171 Sep  8 18:05 env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 4859 Sep  8 18:06 monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 2052 Sep  8 18:06 monitor.log
-rw-r--r-- 1 agentuser agentuser    0 Sep  8 18:06 report-snippet.md
-rw-r--r-- 1 agentuser agentuser  479 Sep  8 18:06 timeseries.csv
```
