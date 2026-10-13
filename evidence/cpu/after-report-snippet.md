# 실험 스니펫: cpu-after

_이 파일은 리포트 작성 시 관측 사실 인용됩니다._

## 실험 조건

- 실험 시각: 2026-10-13 20:58:33 KST
- 케이스: `cpu-after`
- 생존 시간: 117 seconds (2026-10-13 20:58:34 ~ 2026-10-13 21:00:31)
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
[INFO] App started (PID: 24975)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 24975)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
```

## 앱 로그 (마지막 20줄)

```
2026-10-13 21:00:03,584 [INFO] [CpuWorker] Current Load: 46.83%
2026-10-13 21:00:06,058 [INFO] [MemoryWorker] Current Heap: 225MB
2026-10-13 21:00:06,711 [INFO] [CpuWorker] Current Load: 47.80%
2026-10-13 21:00:08,823 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
2026-10-13 21:00:09,086 [INFO] [MemoryWorker] Current Heap: 250MB
2026-10-13 21:00:09,826 [INFO] [CpuWorker] Current Load: 50.00%
2026-10-13 21:00:12,111 [INFO] [MemoryWorker] Current Heap: 275MB
2026-10-13 21:00:12,952 [INFO] [CpuWorker] Current Load: 46.86%
2026-10-13 21:00:15,137 [INFO] [MemoryWorker] Current Heap: 300MB
2026-10-13 21:00:16,078 [INFO] [CpuWorker] Current Load: 39.09%
2026-10-13 21:00:18,167 [INFO] [MemoryWorker] Current Heap: 325MB
2026-10-13 21:00:19,207 [INFO] [CpuWorker] Current Load: 34.18%
2026-10-13 21:00:21,188 [INFO] [MemoryWorker] Current Heap: 350MB
2026-10-13 21:00:22,324 [INFO] [CpuWorker] Current Load: 33.57%
2026-10-13 21:00:24,199 [INFO] [MemoryWorker] Current Heap: 375MB
2026-10-13 21:00:25,450 [INFO] [CpuWorker] Current Load: 29.19%
2026-10-13 21:00:27,214 [INFO] [MemoryWorker] Current Heap: 400MB
2026-10-13 21:00:28,579 [INFO] [CpuWorker] Current Load: 23.02%
2026-10-13 21:00:30,251 [INFO] [MemoryWorker] Current Heap: 425MB
2026-10-13 21:00:31,695 [INFO] [CpuWorker] Current Load: 20.70%
```

## 모니터 로그 발췌

**시작 부근:**
```
[2026-10-13 20:58:34] PID:24989 PPID:24975 STATE:SN ELAPSED:00:01 THREADS:1 PROC_CPU:10.5% PROC_MEM:0.3% RSS:25620KB SYS_CPU:2.1% SYS_MEM:12.9% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:36] PID:24989 PPID:24975 STATE:SN ELAPSED:00:02 THREADS:3 PROC_CPU:5.3% PROC_MEM:0.3% RSS:25732KB SYS_CPU:3.1% SYS_MEM:13.4% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 20:58:37] PID:24989 PPID:24975 STATE:SNl ELAPSED:00:04 THREADS:3 PROC_CPU:3.8% PROC_MEM:0.6% RSS:51488KB SYS_CPU:3.2% SYS_MEM:13.3% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

**종료 부근:**
```
[2026-10-13 21:00:28] PID:24989 PPID:24975 STATE:SNl ELAPSED:01:55 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.2% RSS:428772KB SYS_CPU:3.2% SYS_MEM:18.5% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:00:30] PID:24989 PPID:24975 STATE:SNl ELAPSED:01:57 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454388KB SYS_CPU:3.2% SYS_MEM:18.6% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
[2026-10-13 21:00:31] PID:24989 PPID:24975 STATE:SNl ELAPSED:01:58 THREADS:3 PROC_CPU:1.5% PROC_MEM:5.5% RSS:454388KB SYS_CPU:2.1% SYS_MEM:18.5% DISK_USED:19% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
```

## 시계열 데이터

CSV 원본: [`after-timeseries.csv`](./after-timeseries.csv)


## 파일 목록

```
drwxr-xr-x 1 agentuser agentuser   512 Oct 13 20:58 .
drwxr-xr-x 1 agentuser agentuser   192 Oct 13 21:14 ..
-rw-r--r-- 1 agentuser agentuser  8233 Oct 13 21:00 after-app.log
-rw-r--r-- 1 agentuser agentuser   171 Oct 13 20:58 after-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser 37843 Oct 13 21:00 after-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser 18046 Oct 13 21:00 after-monitor.log
-rw-r--r-- 1 agentuser agentuser     0 Oct 13 21:14 after-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2132 Oct 13 21:00 after-run.log
-rw-r--r-- 1 agentuser agentuser  3551 Oct 13 21:14 after-timeseries.csv
-rw-r--r-- 1 agentuser agentuser  2103 Oct 13 20:58 before-app.log
-rw-r--r-- 1 agentuser agentuser   172 Oct 13 20:57 before-env-snapshot.txt
-rw-r--r-- 1 agentuser agentuser  8962 Oct 13 20:58 before-monitor-stdout.log
-rw-r--r-- 1 agentuser agentuser  4609 Oct 13 20:58 before-monitor.log
-rw-r--r-- 1 agentuser agentuser  4600 Oct 13 21:14 before-report-snippet.md
-rw-r--r-- 1 agentuser agentuser  2002 Oct 13 20:58 before-run.log
-rw-r--r-- 1 agentuser agentuser   930 Oct 13 21:14 before-timeseries.csv
```
