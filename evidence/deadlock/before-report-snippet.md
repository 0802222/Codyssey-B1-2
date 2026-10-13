# 실험 스니펫: deadlock-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 21:00:35 KST
- 케이스: `deadlock-before`
- 생존 시간: 118 seconds (2026-10-13 21:00:37 ~ 2026-10-13 21:02:35)
- 종료 방식: RUN_TIMEOUT(120s) 강제 종료

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=true
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 27864)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 27864)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-13 21:00:38,055 [WARNING] [AgentWorker] Initializing concurrent transaction processors...
2026-10-13 21:00:38,058 [WARNING] [System] CAUTION: Strict resource locking is enabled.
2026-10-13 21:00:43,099 [INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
2026-10-13 21:00:43,101 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
2026-10-13 21:00:43,100 [INFO] [AgentWorker] Waiting for worker threads to complete transactions...
2026-10-13 21:00:43,101 [INFO] [AgentWorker][Worker-Thread-1] Processing critical data in Memory A...
2026-10-13 21:00:43,100 [INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
2026-10-13 21:00:43,102 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-10-13 21:00:43,102 [INFO] [AgentWorker][Worker-Thread-2] Establishing network connections in Pool B...
2026-10-13 21:00:45,114 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-10-13 21:00:45,116 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
2026-10-13 21:00:45,116 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-10-13 21:00:45,117 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 21:00:37] PID:27878 PPID:27864 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:13.2% PROC_MEM:0.3% RSS:25640KB SYS_CPU:2.1% SYS_MEM:13.0% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:00:38] PID:27878 PPID:27864 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:5.7% PROC_MEM:0.3% RSS:25640KB SYS_CPU:2.2% SYS_MEM:13.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:00:40] PID:27878 PPID:27864 STATE:SN ELAPSED:00:04 THREADS:1 PROC_CPU:3.6% PROC_MEM:0.3% RSS:25640KB SYS_CPU:3.1% SYS_MEM:13.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 21:02:31] PID:27878 PPID:27864 STATE:SNl ELAPSED:01:55 THREADS:3 PROC_CPU:0.1% PROC_MEM:0.2% RSS:22440KB SYS_CPU:2.2% SYS_MEM:13.0% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:02:33] PID:27878 PPID:27864 STATE:SNl ELAPSED:01:57 THREADS:3 PROC_CPU:0.1% PROC_MEM:0.2% RSS:22440KB SYS_CPU:2.2% SYS_MEM:13.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:02:35] PID:27878 PPID:27864 STATE:SNl ELAPSED:01:59 THREADS:3 PROC_CPU:0.1% PROC_MEM:0.2% RSS:22440KB SYS_CPU:2.2% SYS_MEM:13.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 21:02 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  8328 Oct 13 21:04 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 13 21:02 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 37843 Oct 13 21:04 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 18046 Oct 13 21:04 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4874 Oct 13 21:10 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2182 Oct 13 21:04 after-run.log
-rw-r--r-- 1 agentuser agentuser  3551 Oct 13 21:10 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 13 21:00 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 13 21:00 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 34092 Oct 13 21:02 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 17987 Oct 13 21:02 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2124 Oct 13 21:02 before-run.log
-rw-r--r-- 1 agentuser agentuser  3492 Oct 13 21:14 before-timeseries.csv
```
