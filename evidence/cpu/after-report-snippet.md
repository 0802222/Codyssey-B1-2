# 실험 스니펫: cpu-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-27 19:13:21 KST
- 케이스: `cpu-after`
- 생존 시간: 119 seconds (2026-10-27 19:13:22 ~ 2026-10-27 19:15:21)
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
[INFO] App started (PID: 2064)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 2064)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

## 앱 로그 (마지막 20줄)

```
2026-10-27 19:14:52,336 [INFO] [CpuWorker] Current Load: 46.41%
2026-10-27 19:14:54,736 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-27 19:14:55,458 [INFO] [CpuWorker] Current Load: 49.34%
2026-10-27 19:14:57,588 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-10-27 19:14:57,773 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-27 19:14:58,608 [INFO] [CpuWorker] Current Load: 50.00%
2026-10-27 19:15:00,807 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-27 19:15:01,719 [INFO] [CpuWorker] Current Load: 44.32%
2026-10-27 19:15:03,831 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-27 19:15:04,842 [INFO] [CpuWorker] Current Load: 34.49%
2026-10-27 19:15:06,856 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-27 19:15:07,972 [INFO] [CpuWorker] Current Load: 31.29%
2026-10-27 19:15:09,879 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-27 19:15:11,101 [INFO] [CpuWorker] Current Load: 23.23%
2026-10-27 19:15:12,914 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-27 19:15:14,227 [INFO] [CpuWorker] Current Load: 15.44%
2026-10-27 19:15:15,934 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-27 19:15:17,339 [INFO] [CpuWorker] Current Load: 9.25%
2026-10-27 19:15:18,971 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-27 19:15:20,472 [INFO] [CpuWorker] Current Load: 5.42%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-27 19:13:22] PID:2079 PPID:2067 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:15.9% PROC_MEM:0.3% RSS:25604KB SYS_CPU:2.0% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:13:24] PID:2079 PPID:2067 STATE:SNl+ ELAPSED:00:03 THREADS:3 PROC_CPU:8.5% PROC_MEM:0.6% RSS:51488KB SYS_CPU:2.1% SYS_MEM:13.8% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:13:26] PID:2079 PPID:2067 STATE:SNl+ ELAPSED:00:05 THREADS:3 PROC_CPU:5.3% PROC_MEM:0.6% RSS:51524KB SYS_CPU:2.0% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-27 19:15:17] PID:2079 PPID:2067 STATE:SNl+ ELAPSED:01:55 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428940KB SYS_CPU:2.1% SYS_MEM:18.5% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:15:19] PID:2079 PPID:2067 STATE:SNl+ ELAPSED:01:57 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454556KB SYS_CPU:2.1% SYS_MEM:18.9% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-27 19:15:21] PID:2079 PPID:2067 STATE:SNl+ ELAPSED:01:59 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454556KB SYS_CPU:12.6% SYS_MEM:13.2% DISK_USED:4% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 27 19:15 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:23 ..
-rw-r--r-- 1 agentuser agentuser  8232 Oct 27 19:15 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 27 19:13 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 32888 Oct 27 19:15 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 15606 Oct 27 19:15 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 27 19:15 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   642 Oct 27 19:15 after-run.log
-rw-r--r-- 1 agentuser agentuser  3166 Oct 27 19:15 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2091 Oct 27 19:13 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 27 19:12 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  7020 Oct 27 19:13 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  3557 Oct 27 19:13 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  4552 Oct 27 19:13 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser   692 Oct 27 19:13 before-run.log
-rw-r--r-- 1 agentuser agentuser   752 Oct 27 19:13 before-timeseries.csv
```
