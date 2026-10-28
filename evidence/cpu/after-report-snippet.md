# 실험 스니펫: cpu-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:18:20 KST
- 케이스: `cpu-after`
- 생존 시간: 118 seconds (2026-10-28 16:18:21 ~ 2026-10-28 16:20:19)
- 종료 방식: RUN_TIMEOUT(120s) 강제 종료
- 종료 코드: 143 (SIGTERM)

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 2939)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 2939)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
2026-10-28 16:19:51,383 [INFO] [CpuWorker] Current Load: 30.72%
2026-10-28 16:19:53,717 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-28 16:19:54,509 [INFO] [CpuWorker] Current Load: 40.31%
2026-10-28 16:19:56,733 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-28 16:19:57,630 [INFO] [CpuWorker] Current Load: 49.12%
2026-10-28 16:19:59,756 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-10-28 16:19:59,757 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-28 16:20:00,767 [INFO] [CpuWorker] Current Load: 50.00%
2026-10-28 16:20:02,790 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-28 16:20:03,898 [INFO] [CpuWorker] Current Load: 41.23%
2026-10-28 16:20:05,819 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-28 16:20:07,028 [INFO] [CpuWorker] Current Load: 39.41%
2026-10-28 16:20:08,840 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-28 16:20:10,156 [INFO] [CpuWorker] Current Load: 30.71%
2026-10-28 16:20:11,868 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-28 16:20:13,300 [INFO] [CpuWorker] Current Load: 28.77%
2026-10-28 16:20:14,892 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-28 16:20:16,423 [INFO] [CpuWorker] Current Load: 25.15%
2026-10-28 16:20:17,920 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-28 16:20:19,549 [INFO] [CpuWorker] Current Load: 15.53%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:18:21] PID:2960 PPID:2943 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.8% PROC_MEM:0.3% RSS:25612KB SYS_CPU:3.1% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:18:23] PID:2960 PPID:2943 STATE:SNl+ ELAPSED:00:03 THREADS:3 PROC_CPU:9.0% PROC_MEM:0.6% RSS:51484KB SYS_CPU:2.2% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:18:25] PID:2960 PPID:2943 STATE:SNl+ ELAPSED:00:05 THREADS:3 PROC_CPU:5.6% PROC_MEM:0.6% RSS:51484KB SYS_CPU:2.1% SYS_MEM:14.1% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:20:15] PID:2960 PPID:2943 STATE:SNl+ ELAPSED:01:54 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:432692KB SYS_CPU:2.1% SYS_MEM:18.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:20:17] PID:2960 PPID:2943 STATE:SNl+ ELAPSED:01:56 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:432692KB SYS_CPU:2.1% SYS_MEM:19.0% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:20:19] PID:2960 PPID:2943 STATE:SNl+ ELAPSED:01:58 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:458308KB SYS_CPU:3.2% SYS_MEM:18.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`after-systools.log`](./after-systools.log) (27회 수집)

**첫 회차:**
```
===== [2026-10-28 16:18:21] sample 1 (app PID: 2960) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    2939    2925  1 16:18 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    2943    2939 12 16:18 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    2960    2943 20 16:18 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 2960 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   2960    2960 SN+  19.4  0.3 25612       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 2960   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   2960 agentus+  30  10  442184  25692  10168 S   1.0   0.3   0:00.24 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:20:16] sample 27 (app PID: 2960) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    2939    2925  0 16:18 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    2943    2939  0 16:18 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    2960    2943  1 16:18 pts/0    00:00:01 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 2960 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   2960    2960 SNl+  0.2  5.2 432692      01:56 futex_wait           agent-leak-app-
   2960    3016 SNl+  0.4  5.2 432692      01:53 do_select            agent-leak-app-
   2960    3018 SNl+  0.9  5.2 432692      01:53 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 2960   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   3016 agentus+  30  10 1114884 458308   7320 S   1.0   5.6   0:00.48 agent-l+
   2960 agentus+  30  10 1114884 458308   7320 S   0.0   5.6   0:00.27 agent-l+
   3018 agentus+  30  10 1114884 458308   7320 S   0.0   5.6   0:01.06 agent-l+
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   576 Oct 28 16:20 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8233 Oct 28 16:20 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 28 16:18 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 33036 Oct 28 16:20 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15606 Oct 28 16:20 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 28 16:20 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   790 Oct 28 16:20 after-run.log
-rw-r--r-- 1 agentuser agentuser 33232 Oct 28 16:20 after-systools.log
-rw-r--r-- 1 agentuser agentuser  3166 Oct 28 16:20 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2042 Oct 28 16:18 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 28 16:17 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  6159 Oct 28 16:18 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  3049 Oct 28 16:18 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  6515 Oct 28 16:18 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   840 Oct 28 16:18 before-run.log
-rw-r--r-- 1 agentuser agentuser  5451 Oct 28 16:18 before-systools.log
-rw-r--r-- 1 agentuser agentuser   654 Oct 28 16:18 before-timeseries.csv
```
