# 실험 스니펫: deadlock-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:15:24 KST
- 케이스: `deadlock-before`
- 생존 시간: 117 seconds (2026-10-27 19:15:26 ~ 2026-10-27 19:17:23)
- 종료 방식: RUN_TIMEOUT(120s) 강제 종료
- 종료 코드: 143 (SIGTERM)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 4596)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 4596)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-27 19:15:27,326 [WARNING] [AgentWorker] Initializing concurrent transaction processors...
2026-10-27 19:15:27,327 [WARNING] [System] CAUTION: Strict resource locking is enabled.
2026-10-27 19:15:32,357 [INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-1] Processing critical data in Memory A...
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
2026-10-27 19:15:32,358 [INFO] [AgentWorker] Waiting for worker threads to complete transactions...
2026-10-27 19:15:32,359 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-10-27 19:15:32,359 [INFO] [AgentWorker][Worker-Thread-2] Establishing network connections in Pool B...
2026-10-27 19:15:34,360 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-10-27 19:15:34,360 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
2026-10-27 19:15:34,373 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-10-27 19:15:34,373 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:15:26] PID:4611 PPID:4599 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:16.7% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.1% SYS_MEM:13.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:15:28] PID:4611 PPID:4599 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:6.7% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.1% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:15:30] PID:4611 PPID:4599 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.2% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.2% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:17:19] PID:4611 PPID:4599 STATE:SNl+ ELAPSED:01:54 THREADS:3 PROC_CPU:0.2% PROC_MEM:0.2% RSS:18488KB SYS_CPU:3.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:17:21] PID:4611 PPID:4599 STATE:SNl+ ELAPSED:01:56 THREADS:3 PROC_CPU:0.1% PROC_MEM:0.2% RSS:18488KB SYS_CPU:2.1% SYS_MEM:13.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:17:23] PID:4611 PPID:4599 STATE:SNl+ ELAPSED:01:58 THREADS:3 PROC_CPU:0.1% PROC_MEM:0.2% RSS:18488KB SYS_CPU:4.0% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 27 19:17 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8236 Oct 27 19:09 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 27 19:07 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 34610 Oct 27 19:09 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15591 Oct 27 19:09 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4922 Oct 27 19:09 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   796 Oct 27 19:09 after-run.log
-rw-r--r-- 1 agentuser agentuser  3116 Oct 27 19:09 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 27 19:17 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 27 19:15 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 29785 Oct 27 19:17 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15552 Oct 27 19:17 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 27 19:17 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   671 Oct 27 19:17 before-run.log
-rw-r--r-- 1 agentuser agentuser  3112 Oct 27 19:17 before-timeseries.csv
```
