# 실험 스니펫: deadlock-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:17:28 KST
- 케이스: `deadlock-after`
- 생존 시간: 118 seconds (2026-10-27 19:17:29 ~ 2026-10-27 19:19:27)
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
[INFO] App started (PID: 7138)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 7138)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
2026-10-27 19:18:59,153 [INFO] [CpuWorker] Current Load: 46.92%
2026-10-27 19:19:01,571 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-27 19:19:02,272 [INFO] [CpuWorker] Current Load: 48.00%
2026-10-27 19:19:04,389 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-10-27 19:19:04,594 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-27 19:19:05,398 [INFO] [CpuWorker] Current Load: 50.00%
2026-10-27 19:19:07,608 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-27 19:19:08,526 [INFO] [CpuWorker] Current Load: 42.07%
2026-10-27 19:19:10,636 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-27 19:19:11,647 [INFO] [CpuWorker] Current Load: 38.78%
2026-10-27 19:19:13,670 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-27 19:19:14,771 [INFO] [CpuWorker] Current Load: 31.82%
2026-10-27 19:19:16,699 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-27 19:19:17,896 [INFO] [CpuWorker] Current Load: 25.85%
2026-10-27 19:19:19,727 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-27 19:19:21,007 [INFO] [CpuWorker] Current Load: 22.95%
2026-10-27 19:19:22,756 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-27 19:19:24,127 [INFO] [CpuWorker] Current Load: 16.73%
2026-10-27 19:19:25,785 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-27 19:19:27,244 [INFO] [CpuWorker] Current Load: 14.24%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:17:29] PID:7153 PPID:7141 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:22.7% PROC_MEM:0.3% RSS:25600KB SYS_CPU:5.5% SYS_MEM:13.1% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:17:32] PID:7153 PPID:7141 STATE:SNl+ ELAPSED:00:03 THREADS:3 PROC_CPU:9.8% PROC_MEM:0.6% RSS:51456KB SYS_CPU:2.2% SYS_MEM:13.6% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:17:34] PID:7153 PPID:7141 STATE:SNl+ ELAPSED:00:05 THREADS:3 PROC_CPU:6.7% PROC_MEM:0.6% RSS:51492KB SYS_CPU:2.1% SYS_MEM:14.0% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:19:23] PID:7153 PPID:7141 STATE:SNl+ ELAPSED:01:55 THREADS:3 PROC_CPU:1.7% PROC_MEM:5.2% RSS:432696KB SYS_CPU:3.2% SYS_MEM:18.3% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:19:25] PID:7153 PPID:7141 STATE:SNl+ ELAPSED:01:57 THREADS:3 PROC_CPU:1.7% PROC_MEM:5.2% RSS:428692KB SYS_CPU:3.1% SYS_MEM:18.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:19:27] PID:7153 PPID:7141 STATE:SNl+ ELAPSED:01:59 THREADS:3 PROC_CPU:1.7% PROC_MEM:5.5% RSS:454372KB SYS_CPU:4.1% SYS_MEM:18.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 27 19:19 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8235 Oct 27 19:19 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 27 19:17 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 32887 Oct 27 19:19 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15605 Oct 27 19:19 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 27  2026 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   667 Oct 27 19:19 after-run.log
-rw-r--r-- 1 agentuser agentuser  3165 Oct 27 19:19 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 27 19:17 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 27 19:15 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 29785 Oct 27 19:17 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15552 Oct 27 19:17 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  5243 Oct 27 19:17 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   798 Oct 27 19:17 before-run.log
-rw-r--r-- 1 agentuser agentuser  3112 Oct 27 19:17 before-timeseries.csv
```
