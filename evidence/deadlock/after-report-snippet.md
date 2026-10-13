# 실험 스니펫: deadlock-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 21:02:38 KST
- 케이스: `deadlock-after`
- 생존 시간: 118 seconds (2026-10-13 21:02:39 ~ 2026-10-13 21:04:37)
- 종료 방식: RUN_TIMEOUT(120s) 강제 종료

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=50
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 30745)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 30745)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
```

## 앱 로그 (마지막 20줄)

```
2026-10-13 21:04:09,115 [INFO] [CpuWorker] Current Load: 42.31%
2026-10-13 21:04:11,528 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-13 21:04:12,243 [INFO] [CpuWorker] Current Load: 35.02%
2026-10-13 21:04:14,568 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-13 21:04:15,375 [INFO] [CpuWorker] Current Load: 29.58%
2026-10-13 21:04:17,594 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-13 21:04:18,503 [INFO] [CpuWorker] Current Load: 23.97%
2026-10-13 21:04:20,630 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-13 21:04:21,639 [INFO] [CpuWorker] Current Load: 18.82%
2026-10-13 21:04:23,657 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-13 21:04:24,762 [INFO] [CpuWorker] Current Load: 15.57%
2026-10-13 21:04:26,695 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-13 21:04:27,890 [INFO] [CpuWorker] Current Load: 6.57%
2026-10-13 21:04:29,732 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-13 21:04:30,008 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
2026-10-13 21:04:31,015 [INFO] [CpuWorker] Current Load: 5.00%
2026-10-13 21:04:32,748 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-13 21:04:34,141 [INFO] [CpuWorker] Current Load: 10.49%
2026-10-13 21:04:35,762 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-13 21:04:37,270 [INFO] [CpuWorker] Current Load: 13.28%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 21:02:39] PID:30759 PPID:30745 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:11.3% PROC_MEM:0.3% RSS:25640KB SYS_CPU:2.2% SYS_MEM:12.9% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:02:41] PID:30759 PPID:30745 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:5.4% PROC_MEM:0.3% RSS:25736KB SYS_CPU:2.1% SYS_MEM:13.3% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:02:43] PID:30759 PPID:30745 STATE:SNl ELAPSED:00:04 THREADS:3 PROC_CPU:3.8% PROC_MEM:0.6% RSS:51492KB SYS_CPU:1.1% SYS_MEM:13.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 21:04:33] PID:30759 PPID:30745 STATE:SNl ELAPSED:01:55 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428956KB SYS_CPU:2.1% SYS_MEM:18.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:04:35] PID:30759 PPID:30745 STATE:SNl ELAPSED:01:57 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428956KB SYS_CPU:2.2% SYS_MEM:18.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:04:37] PID:30759 PPID:30745 STATE:SNl ELAPSED:01:58 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454572KB SYS_CPU:2.2% SYS_MEM:18.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 21:02 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  8328 Oct 13 21:04 after-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 13 21:02 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 37843 Oct 13 21:04 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 18046 Oct 13 21:04 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2182 Oct 13 21:04 after-run.log
-rw-r--r-- 1 agentuser agentuser  3551 Oct 13 21:14 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2648 Oct 13 21:00 before-app.log
-rw-r--r-- 1 agentuser agentuser   176 Oct 13 21:00 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 34092 Oct 13 21:02 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 17987 Oct 13 21:02 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  5194 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2124 Oct 13 21:02 before-run.log
-rw-r--r-- 1 agentuser agentuser  3492 Oct 13 21:14 before-timeseries.csv
```
