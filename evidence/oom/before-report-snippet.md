# 실험 스니펫: oom-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:16:59 KST
- 케이스: `oom-before`
- 생존 시간: 10 seconds (2026-10-28 16:17:00 ~ 2026-10-28 16:17:10)
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
[INFO] App started (PID: 1091)
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

2026-10-28 16:17:01,551 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-28 16:17:04,575 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-28 16:17:07,596 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-28 16:17:10,625 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-28 16:17:10,626 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-10-28 16:17:10,626 [CRITICAL] [MemoryGuard] Self-terminating process 1110 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:17:00] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.3% PROC_MEM:0.3% RSS:25592KB SYS_CPU:4.1% SYS_MEM:13.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:02] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:7.4% PROC_MEM:0.6% RSS:51196KB SYS_CPU:2.1% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:04] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.6% PROC_MEM:0.6% RSS:51196KB SYS_CPU:3.1% SYS_MEM:14.3% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:17:06] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:07 THREADS:1 PROC_CPU:3.5% PROC_MEM:0.9% RSS:76800KB SYS_CPU:2.1% SYS_MEM:14.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:08] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:09 THREADS:1 PROC_CPU:2.8% PROC_MEM:1.2% RSS:102404KB SYS_CPU:2.1% SYS_MEM:14.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:10] PID:1110 PPID:1095 STATE:SN+ ELAPSED:00:10 THREADS:1 PROC_CPU:2.3% PROC_MEM:1.2% RSS:102404KB SYS_CPU:3.1% SYS_MEM:13.1% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`before-systools.log`](./before-systools.log) (3회 수집)

**첫 회차:**
```
===== [2026-10-28 16:17:00] sample 1 (app PID: 1110) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    1091    1077  1 16:16 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    1095    1091 10 16:16 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    1110    1095 19 16:16 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 1110 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   1110    1110 SN+  18.6  0.3 25592       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 1110   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1110 agentus+  30  10  467764  51196  10164 S   2.0   0.6   0:00.24 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:17:09] sample 3 (app PID: 1110) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    1091    1077  0 16:16 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    1095    1091  1 16:16 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    1110    1095  2 16:16 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 1110 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   1110    1110 SN+   2.5  1.2 102404      00:10 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 1110   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1110 agentus+  30  10  518972 102404  10164 S   0.0   1.2   0:00.26 agent-l+
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser  544 Oct 28 16:17 .
drwxr-xr-x 1 agentuser agentuser  192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser 2305 Oct 27 19:12 after-app.log
-rw-r--r-- 1 agentuser agentuser  170 Oct 27 19:12 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 8835 Oct 27 19:12 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 4045 Oct 27 19:12 after-monitor.log
-rw-r--r-- 1 agentuser agentuser 4556 Oct 27 19:12 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  658 Oct 27 19:12 after-run.log
-rw-r--r-- 1 agentuser agentuser  862 Oct 27 19:12 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser 1844 Oct 28 16:17 before-app.log
-rw-r--r-- 1 agentuser agentuser  171 Oct 28 16:16 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 3300 Oct 28 16:17 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 1527 Oct 28 16:17 before-monitor.log
-rw-r--r-- 1 agentuser agentuser    0 Oct 28 16:17 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  697 Oct 28 16:17 before-run.log
-rw-r--r-- 1 agentuser agentuser 2819 Oct 28 16:17 before-systools.log
-rw-r--r-- 1 agentuser agentuser  362 Oct 28 16:17 before-timeseries.csv
```
