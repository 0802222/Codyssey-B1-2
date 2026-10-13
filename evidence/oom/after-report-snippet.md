# 실험 스니펫: oom-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 20:57:22 KST
- 케이스: `oom-after`
- 생존 시간: 32 seconds (2026-10-13 20:57:23 ~ 2026-10-13 20:57:55)
- 종료 방식: 앱 자체 종료

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=256
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 23347)
[INFO] Exit mode: 앱 자체 종료
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 256MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-13 20:57:25,028 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-13 20:57:28,060 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-13 20:57:31,088 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-13 20:57:34,122 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-13 20:57:37,166 [INFO] [MemoryWorker] Current Heap: 125MB
2026-10-13 20:57:40,203 [INFO] [MemoryWorker] Current Heap: 150MB
2026-10-13 20:57:43,235 [INFO] [MemoryWorker] Current Heap: 175MB
2026-10-13 20:57:46,267 [INFO] [MemoryWorker] Current Heap: 200MB
2026-10-13 20:57:49,289 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-13 20:57:52,312 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-13 20:57:55,331 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-13 20:57:55,331 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
2026-10-13 20:57:55,331 [CRITICAL] [MemoryGuard] Self-terminating process 23354 to prevent system instability.
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 20:57:23] PID:23354 PPID:23347 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:10.5% PROC_MEM:0.3% RSS:25600KB SYS_CPU:2.1% SYS_MEM:13.3% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:25] PID:23354 PPID:23347 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:5.4% PROC_MEM:0.6% RSS:51224KB SYS_CPU:2.1% SYS_MEM:13.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:27] PID:23354 PPID:23347 STATE:SN ELAPSED:00:04 THREADS:1 PROC_CPU:3.4% PROC_MEM:0.6% RSS:51224KB SYS_CPU:2.2% SYS_MEM:13.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 20:57:51] PID:23354 PPID:23347 STATE:SN ELAPSED:00:29 THREADS:1 PROC_CPU:0.9% PROC_MEM:3.1% RSS:256056KB SYS_CPU:2.1% SYS_MEM:16.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:53] PID:23354 PPID:23347 STATE:SN ELAPSED:00:30 THREADS:1 PROC_CPU:0.9% PROC_MEM:3.4% RSS:281660KB SYS_CPU:2.1% SYS_MEM:16.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:57:55] PID:23354 PPID:23347 STATE:SN ELAPSED:00:32 THREADS:1 PROC_CPU:0.8% PROC_MEM:3.4% RSS:281660KB SYS_CPU:2.1% SYS_MEM:13.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 20:57 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  2247 Oct 13 20:57 after-app.log
-rw-r--r-- 1 agentuser agentuser   170 Oct 13 20:57 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 10340 Oct 13 20:57 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  4879 Oct 13 20:57 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2133 Oct 13 20:57 after-run.log
-rw-r--r-- 1 agentuser agentuser   992 Oct 13 21:14 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  1785 Oct 13 20:57 before-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 13 20:57 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  3343 Oct 13 20:57 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  1538 Oct 13 20:57 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  4499 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2074 Oct 13 20:57 before-run.log
-rw-r--r-- 1 agentuser agentuser   355 Oct 13 21:14 before-timeseries.csv
```
