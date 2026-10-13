# 실험 스니펫: cpu-before

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 20:57:57 KST
- 케이스: `cpu-before`
- 생존 시간: 29 seconds (2026-10-13 20:57:59 ~ 2026-10-13 20:58:28)
- 종료 방식: 앱 자체 종료

### 환경변수

```

APP_NAME=agent-leak-app-x86
CPU_MAX_OCCUPY=90
MEMORY_LIMIT=512
MULTI_THREAD_ENABLE=false
```

## 실행 스크립트 출력

```sh
[INFO] App started (PID: 24180)
[INFO] Run timeout: 120s
[INFO] Exit mode: 앱 자체 종료
```

## 앱 로그 (마지막 20줄)

```
==================================================
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 90%  		[ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False 		[ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-10-13 20:58:00,184 [INFO] [CpuWorker] Started. Maximum CPU Limit: 90%
2026-10-13 20:58:00,190 [INFO] [CpuWorker] Current Load: 5.00%
2026-10-13 20:58:03,311 [INFO] [CpuWorker] Current Load: 6.85%
2026-10-13 20:58:06,438 [INFO] [CpuWorker] Current Load: 11.39%
2026-10-13 20:58:09,565 [INFO] [CpuWorker] Current Load: 12.41%
2026-10-13 20:58:12,690 [INFO] [CpuWorker] Current Load: 21.81%
2026-10-13 20:58:15,805 [INFO] [CpuWorker] Current Load: 24.05%
2026-10-13 20:58:18,930 [INFO] [CpuWorker] Current Load: 31.57%
2026-10-13 20:58:22,057 [INFO] [CpuWorker] Current Load: 38.84%
2026-10-13 20:58:25,182 [INFO] [CpuWorker] Current Load: 45.41%
2026-10-13 20:58:28,312 [INFO] [CpuWorker] Current Load: 51.29%
2026-10-13 20:58:28,419 [CRITICAL] [CpuWorker] CPU Threshold Violated! (51.290000000000006%).
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 20:57:59] PID:24194 PPID:24180 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:12.1% PROC_MEM:0.3% RSS:25624KB SYS_CPU:2.1% SYS_MEM:13.2% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:00] PID:24194 PPID:24180 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:5.4% PROC_MEM:0.3% RSS:25744KB SYS_CPU:2.1% SYS_MEM:13.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:02] PID:24194 PPID:24180 STATE:SN ELAPSED:00:04 THREADS:1 PROC_CPU:3.6% PROC_MEM:0.3% RSS:25768KB SYS_CPU:2.1% SYS_MEM:13.3% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 20:58:24] PID:24194 PPID:24180 STATE:SN ELAPSED:00:26 THREADS:1 PROC_CPU:1.1% PROC_MEM:0.3% RSS:25788KB SYS_CPU:1.1% SYS_MEM:14.0% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:26] PID:24194 PPID:24180 STATE:SN ELAPSED:00:28 THREADS:1 PROC_CPU:1.3% PROC_MEM:0.3% RSS:25788KB SYS_CPU:2.1% SYS_MEM:14.1% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:28] PID:24194 PPID:24180 STATE:SN ELAPSED:00:30 THREADS:1 PROC_CPU:1.2% PROC_MEM:0.3% RSS:25788KB SYS_CPU:7.7% SYS_MEM:13.8% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`before-timeseries.csv`](./before-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 20:58 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  8233 Oct 13 21:00 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 13 20:58 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 37843 Oct 13 21:00 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 18046 Oct 13 21:00 after-monitor.log
-rw-r--r-- 1 agentuser agentuser  4857 Oct 13 21:10 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2132 Oct 13 21:00 after-run.log
-rw-r--r-- 1 agentuser agentuser  3551 Oct 13 21:10 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2103 Oct 13 20:58 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 13 20:57 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  8962 Oct 13 20:58 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  4609 Oct 13 20:58 before-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2002 Oct 13 20:58 before-run.log
-rw-r--r-- 1 agentuser agentuser   930 Oct 13 21:14 before-timeseries.csv
```
