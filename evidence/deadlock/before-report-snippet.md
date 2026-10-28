# 실험 스니펫: deadlock-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:20:24 KST
- 케이스: `deadlock-before`
- 생존 시간: 117 seconds (2026-10-28 16:20:25 ~ 2026-10-28 16:22:22)
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
[INFO] App started (PID: 5713)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 5713)
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

2026-10-28 16:20:26,474 [WARNING] [AgentWorker] Initializing concurrent transaction processors...
2026-10-28 16:20:26,475 [WARNING] [System] CAUTION: Strict resource locking is enabled.
2026-10-28 16:20:31,492 [INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
2026-10-28 16:20:31,493 [INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
2026-10-28 16:20:31,493 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
2026-10-28 16:20:31,493 [INFO] [AgentWorker][Worker-Thread-1] Processing critical data in Memory A...
2026-10-28 16:20:31,493 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-10-28 16:20:31,493 [INFO] [AgentWorker] Waiting for worker threads to complete transactions...
2026-10-28 16:20:31,493 [INFO] [AgentWorker][Worker-Thread-2] Establishing network connections in Pool B...
2026-10-28 16:20:33,509 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-10-28 16:20:33,509 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-10-28 16:20:33,509 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
2026-10-28 16:20:33,509 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:20:25] PID:5734 PPID:5717 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.3% PROC_MEM:0.3% RSS:25604KB SYS_CPU:3.2% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:20:27] PID:5734 PPID:5717 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:6.8% PROC_MEM:0.3% RSS:25604KB SYS_CPU:3.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:20:29] PID:5734 PPID:5717 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.2% PROC_MEM:0.3% RSS:25604KB SYS_CPU:2.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:22:18] PID:5734 PPID:5717 STATE:SNl+ ELAPSED:01:54 THREADS:3 PROC_CPU:0.2% PROC_MEM:0.2% RSS:18500KB SYS_CPU:2.1% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:22:20] PID:5734 PPID:5717 STATE:SNl+ ELAPSED:01:56 THREADS:3 PROC_CPU:0.2% PROC_MEM:0.2% RSS:18500KB SYS_CPU:10.5% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:22:22] PID:5734 PPID:5717 STATE:SNl+ ELAPSED:01:58 THREADS:3 PROC_CPU:0.2% PROC_MEM:0.2% RSS:18500KB SYS_CPU:3.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`before-systools.log`](./before-systools.log) (27회 수집)

**첫 회차:**
```
===== [2026-10-28 16:20:25] sample 1 (app PID: 5734) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    5713    5699  1 16:20 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    5717    5713 10 16:20 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    5734    5717 19 16:20 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 5734 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   5734    5734 SN+  18.6  0.3 25604       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 5734   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   5734 agentus+  30  10  442168  25604  10168 S   0.0   0.3   0:00.22 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:22:20] sample 27 (app PID: 5734) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    5713    5699  0 16:20 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    5717    5713  0 16:20 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    5734    5717  0 16:20 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 5734 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   5734    5734 SNl+  0.1  0.2 18500       01:56 futex_wait           agent-leak-app-
   5734    5899 SNl+  0.0  0.2 18500       01:49 futex_wait           agent-leak-app-
   5734    5900 SNl+  0.0  0.2 18500       01:49 futex_wait           agent-leak-app-

$ top -H -b -n 2 -d 1 -p 5734   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   5734 agentus+  30  10  589536  18500   3088 S   0.0   0.2   0:00.23 agent-l+
   5899 agentus+  30  10  589536  18500   3088 S   0.0   0.2   0:00.00 agent-l+
   5900 agentus+  30  10  589536  18500   3088 S   0.0   0.2   0:00.00 agent-l+
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   544 Oct 28 16:22 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8235 Oct 27 19:19 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 27 19:17 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 32887 Oct 27 19:19 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15605 Oct 27 19:19 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4917 Oct 27 19:19 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   792 Oct 27 19:19 after-run.log
-rw-r--r-- 1 agentuser agentuser  3165 Oct 27 19:19 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 28 16:22 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 28 16:20 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 29821 Oct 28 16:22 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15554 Oct 28 16:22 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 28 16:22 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   825 Oct 28 16:22 before-run.log
-rw-r--r-- 1 agentuser agentuser 32900 Oct 28 16:22 before-systools.log
-rw-r--r-- 1 agentuser agentuser  3114 Oct 28 16:22 before-timeseries.csv
```
