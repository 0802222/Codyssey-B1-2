# 실험 스니펫: oom-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:12:13 KST
- 케이스: `oom-after`
- 생존 시간: 29 seconds (2026-10-27 19:12:14 ~ 2026-10-27 19:12:43)
- 종료 방식: 앱 자체 종료
- 종료 코드: 137 (SIGKILL)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=256
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 682)
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 137 (SIGKILL)
```

## 앱 로그 (마지막 20줄)

```
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-27 19:12:15,500 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-27 19:12:18,532 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-27 19:12:21,563 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-27 19:12:24,591 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-27 19:12:27,625 [INFO] [MemoryWorker] Current Heap: 125MB
2026-10-27 19:12:30,647 [INFO] [MemoryWorker] Current Heap: 150MB
2026-10-27 19:12:33,683 [INFO] [MemoryWorker] Current Heap: 175MB
2026-10-27 19:12:36,706 [INFO] [MemoryWorker] Current Heap: 200MB
2026-10-27 19:12:39,747 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-27 19:12:42,771 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-27 19:12:45,793 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-27 19:12:45,795 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
2026-10-27 19:12:45,795 [CRITICAL] [MemoryGuard] Self-terminating process 695 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:12:14] PID:695 PPID:685 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:16.9% PROC_MEM:0.3% RSS:25596KB SYS_CPU:3.2% SYS_MEM:13.3% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:16] PID:695 PPID:685 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:6.9% PROC_MEM:0.6% RSS:51200KB SYS_CPU:3.2% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:18] PID:695 PPID:685 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.3% PROC_MEM:0.6% RSS:51200KB SYS_CPU:2.1% SYS_MEM:14.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:12:39] PID:695 PPID:685 STATE:SN+ ELAPSED:00:26 THREADS:1 PROC_CPU:1.3% PROC_MEM:3.1% RSS:256032KB SYS_CPU:2.2% SYS_MEM:17.3% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:41] PID:695 PPID:685 STATE:SN+ ELAPSED:00:28 THREADS:1 PROC_CPU:1.2% PROC_MEM:3.1% RSS:256032KB SYS_CPU:3.1% SYS_MEM:17.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:43] PID:695 PPID:685 STATE:SN+ ELAPSED:00:30 THREADS:1 PROC_CPU:1.1% PROC_MEM:3.4% RSS:281636KB SYS_CPU:2.1% SYS_MEM:17.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser  512 Oct 27 19:12 .
drwxr-xr-x 1 agentuser agentuser  192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser 2305 Oct 27 19:12 after-app.log
-rw-r--r-- 1 agentuser agentuser  170 Oct 27 19:12 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 8835 Oct 27 19:12 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 4045 Oct 27 19:12 after-monitor.log
-rw-r--r-- 1 agentuser agentuser    0 Oct 27 19:12 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  543 Oct 27 19:12 after-run.log
-rw-r--r-- 1 agentuser agentuser  862 Oct 27 19:12 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser 1843 Oct 27 19:12 before-app.log
-rw-r--r-- 1 agentuser agentuser  171 Oct 27 19:11 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 3294 Oct 27 19:12 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 1515 Oct 27 19:12 before-monitor.log
-rw-r--r-- 1 agentuser agentuser 4424 Oct 27 19:12 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  663 Oct 27 19:12 before-run.log
-rw-r--r-- 1 agentuser agentuser  362 Oct 27 19:12 before-timeseries.csv
```
