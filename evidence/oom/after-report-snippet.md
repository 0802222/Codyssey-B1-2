# 실험 스니펫: oom-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:17:13 KST
- 케이스: `oom-after`
- 생존 시간: 31 seconds (2026-10-28 16:17:15 ~ 2026-10-28 16:17:46)
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
[INFO] App started (PID: 1455)
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 137 (SIGKILL)
```

## 앱 로그 (마지막 20줄)

```
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-28 16:17:16,330 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-28 16:17:19,353 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-28 16:17:22,379 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-28 16:17:25,392 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-28 16:17:28,430 [INFO] [MemoryWorker] Current Heap: 125MB
2026-10-28 16:17:31,464 [INFO] [MemoryWorker] Current Heap: 150MB
2026-10-28 16:17:34,494 [INFO] [MemoryWorker] Current Heap: 175MB
2026-10-28 16:17:37,520 [INFO] [MemoryWorker] Current Heap: 200MB
2026-10-28 16:17:40,543 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-28 16:17:43,569 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-28 16:17:46,596 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-28 16:17:46,597 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
2026-10-28 16:17:46,597 [CRITICAL] [MemoryGuard] Self-terminating process 1474 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:17:15] PID:1474 PPID:1459 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.0% PROC_MEM:0.3% RSS:25596KB SYS_CPU:3.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:17] PID:1474 PPID:1459 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:7.1% PROC_MEM:0.6% RSS:51200KB SYS_CPU:2.1% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:19] PID:1474 PPID:1459 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.4% PROC_MEM:0.6% RSS:51200KB SYS_CPU:2.1% SYS_MEM:14.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:17:42] PID:1474 PPID:1459 STATE:SN+ ELAPSED:00:28 THREADS:1 PROC_CPU:1.1% PROC_MEM:3.1% RSS:256032KB SYS_CPU:3.1% SYS_MEM:16.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:44] PID:1474 PPID:1459 STATE:SN+ ELAPSED:00:30 THREADS:1 PROC_CPU:1.0% PROC_MEM:3.4% RSS:281636KB SYS_CPU:2.1% SYS_MEM:16.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:46] PID:1474 PPID: STATE: ELAPSED: THREADS:0 PROC_CPU:% PROC_MEM:% RSS:KB SYS_CPU:2.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`after-systools.log`](./after-systools.log) (8회 수집)

**첫 회차:**
```
===== [2026-10-28 16:17:15] sample 1 (app PID: 1474) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    1455    1441  1 16:17 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    1459    1455 11 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    1474    1459 19 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 1474 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   1474    1474 SN+  18.4  0.3 25596       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 1474   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1474 agentus+  30  10  467764  51200  10164 S   1.0   0.6   0:00.23 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:17:46] sample 8 (app PID: 1474) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    1455    1441  0 16:17 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    1459    1455  0 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    1474    1459  1 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 1474 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   1474    1474 SN+   1.0  3.4 281636      00:32 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 1474   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser  576 Oct 28 16:17 .
drwxr-xr-x 1 agentuser agentuser  192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser 2306 Oct 28 16:17 after-app.log
-rw-r--r-- 1 agentuser agentuser  170 Oct 28 16:17 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 9272 Oct 28 16:17 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 4241 Oct 28 16:17 after-monitor.log
-rw-r--r-- 1 agentuser agentuser    0 Oct 28 16:17 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  693 Oct 28 16:17 after-run.log
-rw-r--r-- 1 agentuser agentuser 7259 Oct 28 16:17 after-systools.log
-rw-r--r-- 1 agentuser agentuser  862 Oct 28 16:17 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser 1844 Oct 28 16:17 before-app.log
-rw-r--r-- 1 agentuser agentuser  171 Oct 28 16:16 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 3300 Oct 28 16:17 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 1527 Oct 28 16:17 before-monitor.log
-rw-r--r-- 1 agentuser agentuser 6495 Oct 28 16:17 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  814 Oct 28 16:17 before-run.log
-rw-r--r-- 1 agentuser agentuser 2819 Oct 28 16:17 before-systools.log
-rw-r--r-- 1 agentuser agentuser  362 Oct 28 16:17 before-timeseries.csv
```
