# [Bug] CPU Latency - CpuWorker 부하 임계치 초과에 따른 프로세스 종료 분석

<br>

### 1. Description

- **발생 시각**: 2026-10-28 16:17:51 ~ 16:18:15 KST (Before 기준)
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 컨테이너 `codyssey-b1-2-lab`, `--platform linux/amd64`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `CPU_MAX_OCCUPY=90` (단위: %)
  - `MEMORY_LIMIT=512` (단위: MB, OOM이 먼저 발생하지 않도록 최대값으로 고정)
  - `MULTI_THREAD_ENABLE=false` (Deadlock이 끼어들지 않도록 고정)
- **발생 조건**: `CPU_MAX_OCCUPY`를 권장값(50% 이하)보다 높은 90%로 설정한 상태에서 애플리케이션 구동
- **관측한 현상**:
  - 부팅 시 `[ CPU ] Limit: 90% [ WARNING: Recommend Under 50% ]` 경고가 출력됨.
  - `CpuWorker`가 보고하는 부하가 약 3초 간격으로 `5.00%`에서 `51.54%`까지 상승한 직후, `[CRITICAL] [CpuWorker] CPU Threshold Violated! (51.54%)` 로그와 `>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<` 배너가 출력되고 프로세스가 종료됨.
  - 종료 코드는 `143 (SIGTERM)`.

---

<br>

### 2. Evidence & Logs

#### (1) 프로그램 실행 로그 ([before-app.log](../evidence/cpu/before-app.log))

```text
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

#### (2) 05-monitor-app-resources.sh 관제 데이터 ([before-timeseries.csv](../evidence/cpu/before-timeseries.csv))

| 시각 | PROC_CPU (%) | SYS_CPU (%) | RSS (KB) | THREADS | STATE |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 16:17:52 | 17.8 | 3.2 | 25,608 | 1 | `SN+` |
| 16:17:54 | 7.7 | 3.0 | 25,712 | 1 | `SN+` |
| 16:18:02 | 2.5 | 3.2 | 25,752 | 1 | `SN+` |
| 16:18:13 | 1.9 | 2.1 | 25,768 | 1 | `SN+` |

- 12개 샘플 중 `PROC_CPU` 최대값은 시작 직후의 `17.8%`이며, 이후 계속 감소함.
- `STATE`의 `+`는 앱이 가상 터미널(pty)의 포그라운드 프로세스 그룹에서 실행 중이라는 뜻이다. 종료 배너를 수집하기 위해 `script`로 실행한 결과이다 ([06-troubleshooting.md](../docs/06-troubleshooting.md)).
- 메모리(RSS ~25MB)와 스레드 수(1)는 변화 없음 → OOM·Deadlock 영향 배제.

#### (3) 시스템 도구 출력 ([before-systools.log](../evidence/cpu/before-systools.log))

`05-monitor-app-resources.sh`의 `PROC_CPU`는 `ps -o %cpu` 값으로, **프로세스 시작 이후 누적 평균**이라 순간 급상승을 보여주지 못한다. 그래서 실험 스크립트가 같은 실행 중에 3초마다 `ps -L`과 `top -H -b -n 2 -d 1`(1초 간격 2회 측정 중 2회차 = **직전 1초의 순간 CPU**)을 함께 기록하도록 했다.

```text
===== [2026-10-28 16:18:05] sample 4 (app PID: 2320) =====
$ ps -ef | grep agent-leak-app-x86
agentus+    2299    2285  0 16:17 ?        00:00:00 /usr/bin/script script -qefc exec /workspace/bin/agent-leak-app-x86 /dev/null
agentus+    2303    2299  1 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86
agentus+    2320    2303  2 16:17 pts/0    00:00:00 /workspace/bin/agent-leak-app-x86 /workspace/bin/agent-leak-app-x86

$ ps -L -p 2320 -o pid,tid,stat,%cpu,%mem,rss,etime,wchan:20,comm
    PID     TID STAT %CPU %MEM   RSS     ELAPSED WCHAN                COMMAND
   2320    2320 SN+   2.2  0.3 25768       00:14 do_select            agent-leak-app-

$ top -H -b -n 2 -d 1 -p 2320   (2nd iteration)
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   2320 agentus+  30  10  443208  25768  10168 S   3.9   0.3   0:00.36 agent-l+
```

6회 수집한 값을 앱 로그 Load와 나란히 놓으면 다음과 같다.

| 수집 시각 | `top` 순간 CPU | `ps` 누적 평균 | `TIME+` | 직전 앱 로그 Load |
| :---: | :---: | :---: | :---: | :---: |
| 16:17:52 | 2.0% | 19.3% | 0:00.25 | (CpuWorker 시작 전) |
| 16:17:56 | 0.0% | 4.8% | 0:00.27 | 5.00% |
| 16:18:01 | 0.0% | 2.8% | 0:00.29 | 22.17% |
| 16:18:05 | 3.9% | 2.2% | 0:00.36 | 26.24% |
| 16:18:09 | 0.0% | 2.1% | 0:00.40 | 41.68% |
| 16:18:14 | (측정 중 종료) | 1.8% | - | 43.03% |

- 앱이 보고한 Load는 5% ➔ 43%로 오르는데, `top` 순간 CPU는 0~3.9%, 누적 CPU 시간(`TIME+`)은 22초 동안 0.15초만 늘었다.
- `ps` 누적 평균은 시작 직후 19.3%에서 계속 떨어진다. 시작 직후 값이 높은 것은 부팅 작업 때문이다.
- 마지막 회차는 `top`이 1초 측정하는 사이 Watchdog이 앱을 종료해 출력이 없다 (16:18:15.351 종료).

#### (4) 실행 스크립트 출력 ([before-run.log](../evidence/cpu/before-run.log))

```sh
[INFO] App started (PID: 2299)
[INFO] Run timeout: 120s
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 143 (SIGTERM)
```

- 종료 코드 143은 `128 + 15`이며, 15번 신호는 `SIGTERM`이다. 타임아웃(120초)보다 먼저 종료됐으므로 SIGTERM은 앱 내부 Watchdog이 보낸 것이다.

#### (5) 관련 증적 파일 목록
- [before-app.log](../evidence/cpu/before-app.log) / [after-app.log](../evidence/cpu/after-app.log)
- [before-monitor.log](../evidence/cpu/before-monitor.log) / [after-monitor.log](../evidence/cpu/after-monitor.log)
- [before-systools.log](../evidence/cpu/before-systools.log) / [after-systools.log](../evidence/cpu/after-systools.log)
- [before-timeseries.csv](../evidence/cpu/before-timeseries.csv) / [after-timeseries.csv](../evidence/cpu/after-timeseries.csv)
- [before-report-snippet.md](../evidence/cpu/before-report-snippet.md) / [after-report-snippet.md](../evidence/cpu/after-report-snippet.md)
- [before-env-snapshot.txt](../evidence/cpu/before-env-snapshot.txt) / [after-env-snapshot.txt](../evidence/cpu/after-env-snapshot.txt)
- [before-run.log](../evidence/cpu/before-run.log) / [after-run.log](../evidence/cpu/after-run.log)

---

<br>

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실
1. **부하 선형 상승**: 앱 로그에서 `CpuWorker`의 `Current Load`가 약 3초마다 1~10%p씩 올라 약 22초 만에 `5.00%` ➔ `51.54%`에 도달함.
2. **50% 초과 직후 종료**: `43.03%`까지는 유지되다가 `51.54%`가 기록된 지 약 0.1초 뒤 `CPU Threshold Violated!`가 출력되고 프로세스가 종료됨. 설정값은 90%였지만 실제 종료는 50%를 넘은 첫 시점에 일어남 (다른 실행에서도 `55.10%`, `51.29%`, `50.36%`, `52.05%`, `58.93%`로 모두 50%를 처음 넘은 직후 종료).
3. **Watchdog의 SIGTERM 종료**: 종료 직후 `>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<` 배너가 기록되었고, 실행 스크립트가 받은 종료 코드도 `143 (SIGTERM)`으로 일치함.
4. **OS 관측값과 불일치**: 같은 실행에서 `top` 기준 순간 CPU는 0~3.9%, `ps` 누적 평균은 19.3% ➔ 1.8%로 감소, 누적 CPU 시간은 22초 동안 0.15초 증가. 앱이 보고한 50% 수준의 사용률은 OS 지표에서 관측되지 않음.

#### (2) 증거를 바탕으로 추론한 원인
- **CPU 상한 설정이 권장 범위를 벗어남**: 앱은 `CPU_MAX_OCCUPY > 50`을 `WARNING`으로 판정하고, 부하를 상한까지 계속 올리는 시나리오로 동작한다. 부하가 내부 안전 기준(약 50%)을 넘는 순간 보호 로직이 프로세스를 종료한 것으로 판단한다.
- **앱의 "Load"는 내부 계산값**: OS가 측정한 실제 CPU 사용률은 낮게 유지되었으므로, `CpuWorker`의 Load는 실제 연산 부하라기보다 Watchdog 판단에 쓰이는 시뮬레이션 값으로 추정한다. 따라서 이 장애의 판단 근거는 OS 지표가 아닌 **앱 로그의 Load 추이와 종료 메시지**이다.

#### (3) 관련 운영체제 동작 원리
- **CPU 과점유와 Latency**: 한 프로세스가 CPU 시간을 독점하면 스케줄러의 실행 큐에서 다른 프로세스의 대기 시간이 늘어 응답 지연이 생긴다. 본 앱은 `nice=10`(`SafetyGuard` 로그, `STATE: SN`의 `N`)으로 우선순위를 낮춰 다른 프로세스에 CPU를 양보하도록 설정되어 있다.
- **`ps %cpu` vs `top %CPU`**: `ps`의 `%cpu`는 `누적 CPU 시간 / 경과 시간`으로 계산되어 시간이 지날수록 순간 변화가 희석된다. 순간 급상승을 보려면 `top`처럼 짧은 간격의 차이로 계산한 값을 써야 한다.
- **Watchdog과 종료 신호**: Watchdog은 임계치 초과 시 `SIGTERM`으로 종료를 요청한다. `SIGTERM`은 프로세스가 정리 작업을 할 수 있는 종료 요청이고, 종료 코드는 `128 + 15 = 143`이 된다. 참고로 OOM 실험의 `MemoryGuard`는 `SIGKILL`(137)로 종료되어 두 보호 장치의 종료 방식이 다르다.
- **출력 버퍼링**: 처음 수집한 로그에는 WATCHDOG 배너가 없었다. 출력이 파일로 리다이렉트되면 일반 출력은 블록 단위로 버퍼링되고, 버퍼를 비우기 전에 SIGTERM으로 종료되어 배너가 사라졌다. 가상 터미널(`script`)로 실행해 줄 단위 출력이 되도록 바꾼 뒤 배너를 수집했다. 자세한 과정은 [06-troubleshooting.md](../docs/06-troubleshooting.md)에 정리했다.

---

### 4. Workaround & Verification

<br>

#### (1) 변경한 환경변수
- `CPU_MAX_OCCUPY`: `90` ➔ `50` (%)
- (앱 부팅 경고 `[ WARNING: Recommend Under 50% ]`을 반영)

#### (2) 변경 전 결과 (`cpu-before`)
- **생존 시간**: **약 24초** (앱 로그 기준 16:17:51 기동 ~ 16:18:15 종료)
- **앱 보고 최대 부하**: **51.54%**
- **종료 방식**: Watchdog 자체 종료 (`CPU Threshold Violated!` ➔ `WATCHDOG ... (SIGTERM)`), 종료 코드 `143`

#### (3) 변경 후 결과 (`cpu-after`)
- **앱 시나리오**: `Scenario Selected: [Healthy System Monitoring]`
- **부하 패턴**: 50%에 도달하면 `Peak reached (50.00%). Starting cooldown...` ➔ 5%까지 감소 ➔ `Cooldown complete` ➔ 다시 상승을 반복 (120초 동안 Peak 2회)
- **생존 시간**: **120초 관찰 동안 종료되지 않음**
- **종료 방식**: RUN_TIMEOUT(120s) 강제 종료 ([after-run.log](../evidence/cpu/after-run.log)). 이때의 143은 스크립트가 보낸 SIGTERM이며 Watchdog 종료가 아니다.
  ```sh
  [INFO] App started (PID: 2939)
  [INFO] Run timeout: 120s
  [WARN] App still running after 120s. Killing (PID: 2939)
  [INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
  [INFO] Exit code: 143 (SIGTERM)
  ```
- **관찰 로그 ([after-app.log](../evidence/cpu/after-app.log))**:
  ```text
  2026-10-28 16:18:58,241 [INFO] [CpuWorker] Current Load: 49.71%
  2026-10-28 16:19:00,362 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  2026-10-28 16:19:01,369 [INFO] [CpuWorker] Current Load: 50.00%
  2026-10-28 16:19:04,474 [INFO] [CpuWorker] Current Load: 42.13%
  ...
  2026-10-28 16:19:28,480 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
  ...
  2026-10-28 16:19:59,756 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  ```
- **부팅 배너**: `>>> [SYSTEM] ALL CONFIGURATIONS OPTIMAL. RUNNING STABILITY TEST... <<<` (모든 설정이 권장 범위)
- **시스템 도구 출력** ([after-systools.log](../evidence/cpu/after-systools.log)): 27회 수집 동안 `top` 순간 CPU는 스레드별 0~4.9%로, Before와 마찬가지로 앱 Load 값과 무관하게 낮았다.
- **참고**: After에서는 `MemoryWorker`도 함께 동작해 Heap이 525MB까지 올랐다가 `>>> [SYSTEM] MEMORY RECOVERED (Cache Cleared) <<<`와 함께 50MB로 회수되었다. 모든 값이 권장 범위인 `Healthy System Monitoring` 시나리오의 정상 동작이며, CPU 장애와는 별개이다.

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`CPU_MAX_OCCUPY=90`) | After (`CPU_MAX_OCCUPY=50`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **부팅 판정** | `WARNING: Recommend Under 50%` | `OK` | 권장 범위 진입 |
| **CPU 상승 구간** | 5% ➔ 51.54% (약 22초) | 5% ➔ 50% (약 37초) 후 cooldown | 상승 폭은 실행마다 달라짐, 둘 다 50% 근처까지 상승 |
| **앱 보고 최대 부하** | 51.54% | 50.00% | 상한에서 멈춤 |
| **OS 관측 PROC_CPU 최대** | 17.8% (시작 직후) | 17.8% (시작 직후) | 둘 다 시작 직후만 높고 이후 낮음 |
| **`top` 순간 CPU** | 0~3.9% | 0~4.9% | 앱 Load와 무관하게 둘 다 낮음 |
| **생존 시간** | 약 24초 | 120초 이상 | 종료되지 않음 |
| **종료 여부** | `WATCHDOG ... (SIGTERM)`, 종료 코드 143 | 종료 없음 (타임아웃으로 중단) | 장애 회피 |

#### (5) 임시 조치의 한계
- `CPU_MAX_OCCUPY=50`은 부하가 50%에 닿을 때 cooldown이 걸리게 만들어 종료를 피했을 뿐, **부하가 계속 상한까지 올라가는 패턴 자체는 그대로**이다.
- 50% 근처에서 반복적으로 부하가 몰리므로, 실제 운영 환경이라면 같은 시간대에 다른 프로세스의 응답 지연이 주기적으로 발생할 수 있다.
- 또한 OS 지표로는 이 부하를 관측할 수 없어, 운영 모니터링에서 앱 로그를 함께 수집하지 않으면 장애 전조를 놓칠 수 있다.

#### (6) 근본적인 해결 제안
1. **부하 생성 로직 개선**: `CpuWorker`가 부하를 무조건 상한까지 올리지 않도록 작업량을 제한하거나, 배치 작업을 쪼개 주기적으로 CPU를 양보하도록 수정.
2. **설정과 실제 기준 일치**: 설정값(90%)과 실제 종료 기준(약 50%)이 다른 문제를 수정하여, 운영자가 설정한 상한이 그대로 적용되도록 함.
3. **리소스 격리**: 컨테이너에 `--cpus`, cgroup `cpu.max` 등으로 CPU 사용 상한을 걸어 한 프로세스가 노드 전체에 영향을 주지 않게 함.
4. **관측 개선**: 이번 실험에서는 `07-capture-system-tools.sh`로 `top` 순간 CPU를 함께 기록했다. 운영 관제에서도 순간 CPU와 앱 로그의 Load 값을 같은 시계열로 수집해 OS 지표와 앱 지표를 교차 검증해야 한다.
