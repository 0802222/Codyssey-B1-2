# 실험 스니펫: cpu-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:17:50 KST
- 케이스: `cpu-before`
- 생존 시간: 21 seconds (2026-10-28 16:17:52 ~ 2026-10-28 16:18:13)
- 종료 방식: 앱 자체 종료
- 종료 코드: 143 (SIGTERM)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=90
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 2299)
[INFO] Run timeout: 120s
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 90%  		[ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False 		[ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-10-28 16:17:53,385 [INFO] [CpuWorker] Started. Maximum CPU Limit: 90%
2026-10-28 16:17:53,388 [INFO] [CpuWorker] Current Load: 5.00%
2026-10-28 16:17:56,527 [INFO] [CpuWorker] Current Load: 12.65%
2026-10-28 16:17:59,650 [INFO] [CpuWorker] Current Load: 22.17%
2026-10-28 16:18:02,766 [INFO] [CpuWorker] Current Load: 26.24%
2026-10-28 16:18:05,881 [INFO] [CpuWorker] Current Load: 34.70%
2026-10-28 16:18:08,999 [INFO] [CpuWorker] Current Load: 41.68%
2026-10-28 16:18:12,126 [INFO] [CpuWorker] Current Load: 43.03%
2026-10-28 16:18:15,246 [INFO] [CpuWorker] Current Load: 51.54%
2026-10-28 16:18:15,351 [CRITICAL] [CpuWorker] CPU Threshold Violated! (51.540000000000006%).

>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:17:52] PID:2320 PPID:2303 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.8% PROC_MEM:0.3% RSS:25608KB SYS_CPU:3.2% SYS_MEM:14.0% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:54] PID:2320 PPID:2303 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:7.7% PROC_MEM:0.3% RSS:25712KB SYS_CPU:3.0% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:17:56] PID:2320 PPID:2303 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.9% PROC_MEM:0.3% RSS:25748KB SYS_CPU:3.2% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:18:10] PID:2320 PPID:2303 STATE:SN+ ELAPSED:00:19 THREADS:1 PROC_CPU:2.0% PROC_MEM:0.3% RSS:25768KB SYS_CPU:2.1% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:18:11] PID:2320 PPID:2303 STATE:RN+ ELAPSED:00:21 THREADS:1 PROC_CPU:1.9% PROC_MEM:0.3% RSS:25768KB SYS_CPU:3.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:18:13] PID:2320 PPID:2303 STATE:SN+ ELAPSED:00:22 THREADS:1 PROC_CPU:1.9% PROC_MEM:0.3% RSS:25768KB SYS_CPU:2.1% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`before-systools.log`](./before-systools.log) (6회 수집)

**첫 회차:**
```
===== [2026-10-28 16:17:52] sample 1 (app PID: 2320) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    2299    2285  1 16:17 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    2303    2299 12 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    2320    2303 20 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 2320 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   2320    2320 SN+  19.3  0.3 25608       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 2320   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   2320 agentus+  30  10  443200  25712  10168 S   2.0   0.3   0:00.25 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:18:14] sample 6 (app PID: 2320) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    2299    2285  0 16:17 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    2303    2299  0 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    2320    2303  1 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 2320 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   2320    2320 SN+   1.8  0.3 25768       00:23 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 2320   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   544 Oct 28 16:18 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8232 Oct 27 19:15 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 27 19:13 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 32888 Oct 27 19:15 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15606 Oct 27 19:15 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4906 Oct 27 19:15 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   757 Oct 27 19:15 after-run.log
-rw-r--r-- 1 agentuser agentuser  3166 Oct 27 19:15 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2042 Oct 28 16:18 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 28 16:17 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  6159 Oct 28 16:18 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  3049 Oct 28 16:18 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 28 16:18 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   723 Oct 28 16:18 before-run.log
-rw-r--r-- 1 agentuser agentuser  5451 Oct 28 16:18 before-systools.log
-rw-r--r-- 1 agentuser agentuser   654 Oct 28 16:18 before-timeseries.csv
```
