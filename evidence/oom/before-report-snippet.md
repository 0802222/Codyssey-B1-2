# 실험 스니펫: oom-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:11:58 KST
- 케이스: `oom-before`
- 생존 시간: 10 seconds (2026-10-27 19:11:59 ~ 2026-10-27 19:12:09)
- 종료 방식: 앱 자체 종료
- 종료 코드: 137 (SIGKILL)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=100
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 357)
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 137 (SIGKILL)
```

## 앱 로그 (마지막 20줄)

```
==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-27 19:12:00,883 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-27 19:12:03,907 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-27 19:12:06,940 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-27 19:12:09,971 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-27 19:12:09,972 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-10-27 19:12:09,972 [CRITICAL] [MemoryGuard] Self-terminating process 370 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:11:59] PID:370 PPID:360 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:16.7% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.1% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:01] PID:370 PPID:360 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:7.3% PROC_MEM:0.6% RSS:51204KB SYS_CPU:2.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:03] PID:370 PPID:360 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.6% PROC_MEM:0.6% RSS:51204KB SYS_CPU:3.1% SYS_MEM:14.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:12:05] PID:370 PPID:360 STATE:SN+ ELAPSED:00:07 THREADS:1 PROC_CPU:3.3% PROC_MEM:0.9% RSS:76808KB SYS_CPU:3.0% SYS_MEM:14.3% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:07] PID:370 PPID:360 STATE:SN+ ELAPSED:00:09 THREADS:1 PROC_CPU:2.8% PROC_MEM:1.2% RSS:102412KB SYS_CPU:2.1% SYS_MEM:14.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:12:09] PID:370 PPID:360 STATE:SN+ ELAPSED:00:11 THREADS:1 PROC_CPU:2.3% PROC_MEM:1.2% RSS:102412KB SYS_CPU:3.0% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser  512 Oct 27 19:12 .
drwxr-xr-x 1 agentuser agentuser  192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser 2306 Oct 27 19:02 after-app.log
-rw-r--r-- 1 agentuser agentuser  170 Oct 27 19:02 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 9366 Oct 27 19:02 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 4109 Oct 27 19:02 after-monitor.log
-rw-r--r-- 1 agentuser agentuser 4582 Oct 27 19:02 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  661 Oct 27 19:02 after-run.log
-rw-r--r-- 1 agentuser agentuser  862 Oct 27 19:02 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser 1843 Oct 27 19:12 before-app.log
-rw-r--r-- 1 agentuser agentuser  171 Oct 27 19:11 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 3294 Oct 27 19:12 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 1515 Oct 27 19:12 before-monitor.log
-rw-r--r-- 1 agentuser agentuser    0 Oct 27 19:12 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  546 Oct 27 19:12 before-run.log
-rw-r--r-- 1 agentuser agentuser  362 Oct 27 19:12 before-timeseries.csv
```
