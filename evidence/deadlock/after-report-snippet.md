# 실험 스니펫: deadlock-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-28 16:22:27 KST
- 케이스: `deadlock-after`
- 생존 시간: 118 seconds (2026-10-28 16:22:28 ~ 2026-10-28 16:24:26)
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
[INFO] App started (PID: 8489)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 8489)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
2026-10-28 16:23:58,153 [INFO] [CpuWorker] Current Load: 41.96%
2026-10-28 16:24:00,276 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-10-28 16:24:00,524 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-28 16:24:01,282 [INFO] [CpuWorker] Current Load: 50.00%
2026-10-28 16:24:03,538 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-28 16:24:04,404 [INFO] [CpuWorker] Current Load: 46.62%
2026-10-28 16:24:06,550 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-28 16:24:07,534 [INFO] [CpuWorker] Current Load: 43.31%
2026-10-28 16:24:09,567 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-28 16:24:10,659 [INFO] [CpuWorker] Current Load: 37.64%
2026-10-28 16:24:12,582 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-28 16:24:13,782 [INFO] [CpuWorker] Current Load: 33.66%
2026-10-28 16:24:15,610 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-28 16:24:16,908 [INFO] [CpuWorker] Current Load: 24.08%
2026-10-28 16:24:18,641 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-28 16:24:20,028 [INFO] [CpuWorker] Current Load: 17.27%
2026-10-28 16:24:21,681 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-28 16:24:23,152 [INFO] [CpuWorker] Current Load: 14.86%
2026-10-28 16:24:24,705 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-28 16:24:26,283 [INFO] [CpuWorker] Current Load: 14.28%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-28 16:22:28] PID:8510 PPID:8493 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:17.9% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.1% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:22:30] PID:8510 PPID:8493 STATE:SNl+ ELAPSED:00:03 THREADS:3 PROC_CPU:8.9% PROC_MEM:0.6% RSS:51456KB SYS_CPU:2.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:22:32] PID:8510 PPID:8493 STATE:SNl+ ELAPSED:00:05 THREADS:3 PROC_CPU:5.6% PROC_MEM:0.6% RSS:51456KB SYS_CPU:3.1% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-28 16:24:22] PID:8510 PPID:8493 STATE:SNl+ ELAPSED:01:54 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428904KB SYS_CPU:3.1% SYS_MEM:18.4% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:24:24] PID:8510 PPID:8493 STATE:SNl+ ELAPSED:01:56 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428904KB SYS_CPU:2.2% SYS_MEM:18.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-28 16:24:26] PID:8510 PPID:8493 STATE:SNl+ ELAPSED:01:58 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454520KB SYS_CPU:2.1% SYS_MEM:19.0% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시스템 도구 출력 (ps -ef / ps -L / top -H)

원본: [`after-systools.log`](./after-systools.log) (27회 수집)

**첫 회차:**
```
===== [2026-10-28 16:22:28] sample 1 (app PID: 8510) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    8489    8475  1 16:22 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    8493    8489 11 16:22 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    8510    8493 20 16:22 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 8510 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   8510    8510 SN+  19.6  0.3 25600       00:01 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 8510   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   8510 agentus+  30  10  442184  25696  10168 S   2.0   0.3   0:00.25 agent-l+
```

**마지막 회차:**
```
===== [2026-10-28 16:24:23] sample 27 (app PID: 8510) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    8489    8475  0 16:22 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    8493    8489  0 16:22 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    8510    8493  1 16:22 pts/0    00:00:01 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 8510 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   8510    8510 SNl+  0.2  5.2 428904      01:56 futex_wait           agent-leak-app-
   8510    8568 SNl+  0.4  5.2 428904      01:53 do_select            agent-leak-app-
   8510    8575 SNl+  0.9  5.2 428904      01:53 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 8510   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   8568 agentus+  30  10 1114884 454520   3528 S   1.0   5.5   0:00.49 agent-l+
   8510 agentus+  30  10 1114884 454520   3528 S   0.0   5.5   0:00.27 agent-l+
   8575 agentus+  30  10 1114884 454520   3528 S   0.0   5.5   0:01.07 agent-l+
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   576 Oct 28 16:24 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8234 Oct 28 16:24 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 28 16:22 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 32863 Oct 28 16:24 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15606 Oct 28 16:24 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 28 16:24 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   820 Oct 28 16:24 after-run.log
-rw-r--r-- 1 agentuser agentuser 33232 Oct 28 16:24 after-systools.log
-rw-r--r-- 1 agentuser agentuser  3166 Oct 28 16:24 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 28 16:22 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 28 16:20 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 29821 Oct 28 16:22 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15554 Oct 28 16:22 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  7636 Oct 28 16:22 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   952 Oct 28 16:22 before-run.log
-rw-r--r-- 1 agentuser agentuser 32900 Oct 28 16:22 before-systools.log
-rw-r--r-- 1 agentuser agentuser  3114 Oct 28 16:22 before-timeseries.csv
```
