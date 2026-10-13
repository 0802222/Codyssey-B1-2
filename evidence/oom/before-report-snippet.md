# 실험 스니펫: oom-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 20:57:08 KST
- 케이스: `oom-before`
- 생존 시간: 8 seconds (2026-10-13 20:57:10 ~ 2026-10-13 20:57:18)
- 종료 방식: 앱 자체 종료

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=100
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 23023)
[INFO] Exit mode: 앱 자체 종료
```

## 앱 로그 (마지막 20줄)

```
Agent READY
2026-10-13 20:57:09,053 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-10-13 20:57:09,055 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-13 20:57:11,083 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-13 20:57:14,091 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-13 20:57:17,116 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-13 20:57:20,165 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-13 20:57:20,167 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-10-13 20:57:20,167 [CRITICAL] [MemoryGuard] Self-terminating process 23029 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 20:57:10] PID:23029 PPID:23023 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:10.4% PROC_MEM:0.3% RSS:25620KB SYS_CPU:1.0% SYS_MEM:13.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:11] PID:23029 PPID:23023 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:5.0% PROC_MEM:0.6% RSS:51224KB SYS_CPU:2.1% SYS_MEM:13.4% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:13] PID:23029 PPID:23023 STATE:SN ELAPSED:00:04 THREADS:1 PROC_CPU:3.2% PROC_MEM:0.6% RSS:51224KB SYS_CPU:3.1% SYS_MEM:13.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 20:57:15] PID:23029 PPID:23023 STATE:SN ELAPSED:00:06 THREADS:1 PROC_CPU:2.5% PROC_MEM:0.9% RSS:76828KB SYS_CPU:2.1% SYS_MEM:14.0% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:16] PID:23029 PPID:23023 STATE:SN ELAPSED:00:08 THREADS:1 PROC_CPU:1.9% PROC_MEM:0.9% RSS:76828KB SYS_CPU:2.2% SYS_MEM:14.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:18] PID:23029 PPID:23023 STATE:SN ELAPSED:00:09 THREADS:1 PROC_CPU:1.6% PROC_MEM:1.2% RSS:102432KB SYS_CPU:2.1% SYS_MEM:14.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 20:57 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  2247 Oct 13 20:57 after-app.log
-rw-r--r-- 1 agentuser agentuser   170 Oct 13 20:57 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 10340 Oct 13 20:57 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  4879 Oct 13 20:57 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4667 Oct 13 21:10 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2133 Oct 13 20:57 after-run.log
-rw-r--r-- 1 agentuser agentuser   992 Oct 13 21:10 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  1785 Oct 13 20:57 before-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 13 20:57 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  3343 Oct 13 20:57 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  1538 Oct 13 20:57 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2074 Oct 13 20:57 before-run.log
-rw-r--r-- 1 agentuser agentuser   355 Oct 13 21:14 before-timeseries.csv
```
