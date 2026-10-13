# [Bug] CPU Latency - CpuWorker 부하 임계치 초과에 따른 프로세스 종료 분석

### 1. Description

- **발생 시각**: 2026-10-13 20:57:58 ~ 20:58:28 KST (Before 기준)
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 컨테이너 `codyssey-b1-2-lab`, `--platform linux/amd64`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `CPU_MAX_OCCUPY=90` (단위: %)
  - `MEMORY_LIMIT=512` (단위: MB, OOM이 먼저 발생하지 않도록 최대값으로 고정)
  - `MULTI_THREAD_ENABLE=false` (Deadlock이 끼어들지 않도록 고정)
- **발생 조건**: `CPU_MAX_OCCUPY`를 권장값(50% 이하)보다 높은 90%로 설정한 상태에서 애플리케이션 구동
- **관측한 현상**:
  - 부팅 시 `[ CPU ] Limit: 90% [ WARNING: Recommend Under 50% ]` 경고가 출력됨.
  - `CpuWorker`가 보고하는 부하가 약 3초 간격으로 `5.00%`에서 `51.29%`까지 상승한 직후, `[CRITICAL] [CpuWorker] CPU Threshold Violated! (51.29%)` 로그와 함께 프로세스가 종료됨.

---

### 2. Evidence & Logs

#### (1) 프로그램 실행 로그 ([before-app.log](../evidence/cpu/before-app.log))

```text
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

#### (2) 05-monitor-app-resources.sh 관제 데이터 ([before-timeseries.csv](../evidence/cpu/before-timeseries.csv))

| 시각 | PROC_CPU (%) | SYS_CPU (%) | RSS (KB) | THREADS | STATE |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 20:57:59 | 12.1 | 2.1 | 25,624 | 1 | `SN` |
| 20:58:00 | 5.4 | 2.1 | 25,744 | 1 | `SN` |
| 20:58:26 | 1.3 | 2.1 | 25,788 | 1 | `SN` |
| 20:58:28 | 1.2 | 7.7 | 25,788 | 1 | `SN` |

- 18개 샘플 중 `PROC_CPU` 최대값은 시작 직후의 `12.1%`이며, 이후 계속 감소함.
- 메모리(RSS ~25MB)와 스레드 수(1)는 변화 없음 → OOM·Deadlock 영향 배제.

#### (3) Linux 명령어 출력 (보조 측정)

`05-monitor-app-resources.sh`의 `PROC_CPU`는 `ps -o %cpu` 값으로, **프로세스 시작 이후 누적 평균**이라 순간 급상승을 보여주지 못한다. 그래서 같은 조건(`CPU_MAX_OCCUPY=90`)으로 앱을 따로 띄워 `top -b -n 2 -d 1 -p <PID>`로 **순간 CPU 사용률**을 측정했다 (2026-10-13 20:49~20:50, 별도 실행).

```text
시각       top(순간 CPU)  ps(누적 평균)  앱 로그 Load
20:49:58   1.0%          3.4%          5.00%
20:50:06   3.9%          1.8%          26.13%
20:50:15   3.9%          1.5%          39.31%
20:50:20   0.0%          1.4%          47.86%
20:50:21   (종료)                        CPU Threshold Violated! (50.8%)
```

#### (4) 실행 스크립트 출력 ([before-run.log](../evidence/cpu/before-run.log))

```sh
[INFO] App started (PID: 24180)
[INFO] Run timeout: 120s
[INFO] Exit mode: 앱 자체 종료
```

#### (5) 관련 증적 파일 목록
- [before-app.log](../evidence/cpu/before-app.log) / [after-app.log](../evidence/cpu/after-app.log)
- [before-monitor.log](../evidence/cpu/before-monitor.log) / [after-monitor.log](../evidence/cpu/after-monitor.log)
- [before-timeseries.csv](../evidence/cpu/before-timeseries.csv) / [after-timeseries.csv](../evidence/cpu/after-timeseries.csv)
- [before-report-snippet.md](../evidence/cpu/before-report-snippet.md) / [after-report-snippet.md](../evidence/cpu/after-report-snippet.md)
- [before-env-snapshot.txt](../evidence/cpu/before-env-snapshot.txt) / [after-env-snapshot.txt](../evidence/cpu/after-env-snapshot.txt)
- [before-run.log](../evidence/cpu/before-run.log) / [after-run.log](../evidence/cpu/after-run.log)

---

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실
1. **부하 선형 상승**: 앱 로그에서 `CpuWorker`의 `Current Load`가 약 3초마다 2~9%p씩 올라 28초 만에 `5.00%` ➔ `51.29%`에 도달함.
2. **50% 초과 직후 종료**: `51.29%`가 기록된 지 약 0.1초 뒤 `CPU Threshold Violated!`가 출력되고 프로세스가 종료됨. 설정값은 90%였지만 실제 종료는 50%를 넘은 시점에 일어남 (이전 실행에서도 `50.93%`, `54.35%`, `50.8%`로 모두 50% 직후 종료).
3. **OS 관측값과 불일치**: 같은 구간에서 `top` 기준 순간 CPU는 0~4%, `ps` 누적 평균은 12.1% ➔ 1.2%로 감소. 앱이 보고한 50% 수준의 사용률은 OS 지표에서 관측되지 않음.
4. **README가 예상한 `WATCHDOG`/`SIGTERM` 문자열은 로그에 없음**. 종료 근거는 `[CRITICAL] [CpuWorker] CPU Threshold Violated!` 한 줄이며, 이후 추가 로그 없이 프로세스가 사라짐.

#### (2) 증거를 바탕으로 추론한 원인
- **CPU 상한 설정이 권장 범위를 벗어남**: 앱은 `CPU_MAX_OCCUPY > 50`을 `WARNING`으로 판정하고, 부하를 상한까지 계속 올리는 시나리오로 동작한다. 부하가 내부 안전 기준(약 50%)을 넘는 순간 보호 로직이 프로세스를 종료한 것으로 판단한다.
- **앱의 "Load"는 내부 계산값**: OS가 측정한 실제 CPU 사용률은 낮게 유지되었으므로, `CpuWorker`의 Load는 실제 연산 부하라기보다 Watchdog 판단에 쓰이는 시뮬레이션 값으로 추정한다. 따라서 이 장애의 판단 근거는 OS 지표가 아닌 **앱 로그의 Load 추이와 종료 메시지**이다.

#### (3) 관련 운영체제 동작 원리
- **CPU 과점유와 Latency**: 한 프로세스가 CPU 시간을 독점하면 스케줄러의 실행 큐에서 다른 프로세스의 대기 시간이 늘어 응답 지연이 생긴다. 본 앱은 `nice=10`(`SafetyGuard` 로그, `STATE: SN`의 `N`)으로 우선순위를 낮춰 다른 프로세스에 CPU를 양보하도록 설정되어 있다.
- **`ps %cpu` vs `top %CPU`**: `ps`의 `%cpu`는 `누적 CPU 시간 / 경과 시간`으로 계산되어 시간이 지날수록 순간 변화가 희석된다. 순간 급상승을 보려면 `top`처럼 짧은 간격의 차이로 계산한 값을 써야 한다.
- **Watchdog과 종료 신호**: 일반적인 Watchdog은 임계치 초과 시 `SIGTERM`으로 정상 종료를 요청한다. 본 앱은 내부 `CpuWorker`가 직접 임계치를 판단하고 종료하는 방식이며, 종료 신호 이름은 로그에 남기지 않는다.

---

### 4. Workaround & Verification

#### (1) 변경한 환경변수
- `CPU_MAX_OCCUPY`: `90` ➔ `50` (%)
- (앱 부팅 경고 `[ WARNING: Recommend Under 50% ]`을 반영)

#### (2) 변경 전 결과 (`cpu-before`)
- **생존 시간**: **약 30초** (앱 로그 기준 20:57:58 기동 ~ 20:58:28 종료)
- **앱 보고 최대 부하**: **51.29%**
- **종료 방식**: 앱 자체 종료 (`CPU Threshold Violated!`)

#### (3) 변경 후 결과 (`cpu-after`)
- **앱 시나리오**: `Scenario Selected: [Healthy System Monitoring]`
- **부하 패턴**: 50%에 도달하면 `Peak reached (50.00%). Starting cooldown...` ➔ 5%까지 감소 ➔ `Cooldown complete` ➔ 다시 상승을 반복 (120초 동안 Peak 2회)
- **생존 시간**: **120초 관찰 동안 종료되지 않음**
- **종료 방식**: RUN_TIMEOUT(120s) 강제 종료 ([after-run.log](../evidence/cpu/after-run.log))
  ```sh
  [INFO] App started (PID: 24975)
  [INFO] Run timeout: 120s
  [WARN] App still running after 120s. Killing (PID: 24975)
  [INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
  ```
- **관찰 로그 ([after-app.log](../evidence/cpu/after-app.log))**:
  ```text
  2026-10-13 20:59:01,114 [INFO] [CpuWorker] Current Load: 41.58%
  2026-10-13 20:59:03,234 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  2026-10-13 20:59:04,248 [INFO] [CpuWorker] Current Load: 50.00%
  2026-10-13 20:59:07,374 [INFO] [CpuWorker] Current Load: 46.75%
  ...
  2026-10-13 20:59:37,604 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
  ...
  2026-10-13 21:00:08,823 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  ```

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`CPU_MAX_OCCUPY=90`) | After (`CPU_MAX_OCCUPY=50`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **부팅 판정** | `WARNING: Recommend Under 50%` | `OK` | 권장 범위 진입 |
| **CPU 상승 구간** | 5% ➔ 51.29% (약 28초) | 5% ➔ 50% (약 27초) 후 cooldown | 상승 속도는 동일 |
| **앱 보고 최대 부하** | 51.29% | 50.00% | 상한에서 멈춤 |
| **OS 관측 PROC_CPU 최대** | 12.1% (시작 직후) | 10.5% (시작 직후) | 둘 다 낮음 |
| **생존 시간** | 약 30초 | 120초 이상 | 종료되지 않음 |
| **종료 여부** | `CPU Threshold Violated!` | 종료 없음 (타임아웃으로 중단) | 장애 회피 |

#### (5) 임시 조치의 한계
- `CPU_MAX_OCCUPY=50`은 부하가 50%에 닿을 때 cooldown이 걸리게 만들어 종료를 피했을 뿐, **부하가 계속 상한까지 올라가는 패턴 자체는 그대로**이다.
- 50% 근처에서 반복적으로 부하가 몰리므로, 실제 운영 환경이라면 같은 시간대에 다른 프로세스의 응답 지연이 주기적으로 발생할 수 있다.
- 또한 OS 지표로는 이 부하를 관측할 수 없어, 운영 모니터링에서 앱 로그를 함께 수집하지 않으면 장애 전조를 놓칠 수 있다.

#### (6) 근본적인 해결 제안
1. **부하 생성 로직 개선**: `CpuWorker`가 부하를 무조건 상한까지 올리지 않도록 작업량을 제한하거나, 배치 작업을 쪼개 주기적으로 CPU를 양보하도록 수정.
2. **설정과 실제 기준 일치**: 설정값(90%)과 실제 종료 기준(약 50%)이 다른 문제를 수정하여, 운영자가 설정한 상한이 그대로 적용되도록 함.
3. **리소스 격리**: 컨테이너에 `--cpus`, cgroup `cpu.max` 등으로 CPU 사용 상한을 걸어 한 프로세스가 노드 전체에 영향을 주지 않게 함.
4. **관측 개선**: `05-monitor-app-resources.sh`에 `top` 기반 순간 CPU 사용률과 앱 로그의 Load 값을 함께 기록하여 OS 지표와 앱 지표를 교차 검증.
