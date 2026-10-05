# [Bug] CPU Latency - CpuWorker의 CPU 임계치 초과에 따른 프로세스 강제 종료 분석

### 1. Description

- **발생 시각**: <!-- TODO: YYYY-MM-DD HH:MM:SS ~ HH:MM:SS KST (Before 기준) -->
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 LTS 컨테이너 환경, hostname: `codyssey-b1-2-lab`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `AGENT_HOME=/workspace/runtime`
  - `AGENT_PORT=15034`
  - `MEMORY_LIMIT=512` (단위: MB / OOM 장애와 분리하기 위해 메모리는 충분히 확보)
  - `CPU_MAX_OCCUPY=100` (단위: %)
  - `MULTI_THREAD_ENABLE=false` (Deadlock 장애와 분리하기 위해 단일 스레드로 고정)
- **발생 조건**: `CPU_MAX_OCCUPY`를 권고치(50%)보다 높은 `100`으로 설정한 상태에서 애플리케이션(`agent-leak-app-x86`) 구동
- **관측한 현상**:
  - 부트 시퀀스의 자원 점검 단계에서 `[ CPU ] Limit: 100% [ WARNING: Recommend Under 50% ]` 경고가 출력됨.
  - 이후 `CpuWorker`가 보고하는 CPU Load가 약 3초 간격으로 단계적으로 상승하다가, **50%를 초과한 시점**에 `[CRITICAL] [CpuWorker] CPU Threshold Violated!` 로그와 함께 프로세스가 종료됨.
  - 생존 시간: <!-- TODO: N초 -->

---

### 2. Evidence & Logs

#### (1) monitor.sh 관제 데이터 ([before-monitor.log](../evidence/cpu/before-monitor.log))

```text
<!-- TODO: evidence/cpu/before-monitor.log 에서 시작 ~ 종료 구간 붙여넣기 -->
```

#### (2) 프로그램 실행 로그 ([before-app.log](../evidence/cpu/before-app.log))

```text
<!-- TODO: evidence/cpu/before-app.log 의 부트 시퀀스 + CpuWorker 구간 붙여넣기

관측 형태 예시:
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 100%  		[ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False 		[ OK ]
...
[INFO] [CpuWorker] Started. Maximum CPU Limit: 100%
[INFO] [CpuWorker] Current Load: 5.00%
[INFO] [CpuWorker] Current Load: 18.91%
...
[INFO] [CpuWorker] Current Load: 51.60%
[CRITICAL] [CpuWorker] CPU Threshold Violated! (51.6%).
-->
```

#### (3) 시계열 데이터 요약 ([before-timeseries.csv](../evidence/cpu/before-timeseries.csv))

`PROC_CPU`는 OS가 측정한 **순간 CPU 점유율**(코어 1개 = 100% 기준), `PROC_CPU_AVG`는 `ps`가 제공하는 **프로세스 시작 이후 누적 평균**이다.

| 시각 (Timestamp) | 앱 보고 Load (%) | PROC_CPU (%) | PROC_CPU_AVG (%) | RSS (KB) | 스레드 | 상태 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| <!-- TODO --> | | | | | | |

#### (4) Linux 명령어 출력 ([before-cmd-snapshot.txt](../evidence/cpu/before-cmd-snapshot.txt))

```text
<!-- TODO: cmd-snapshot.txt 에서 CPU Load가 가장 높았던 시각 부근의 ps / top / ps -L 블록 붙여넣기 -->
```

#### (5) 관련 증적 파일 목록

| 구분 | Before (`CPU_MAX_OCCUPY=100`) | After (`CPU_MAX_OCCUPY=50`) |
| :--- | :--- | :--- |
| 앱 로그 | [before-app.log](../evidence/cpu/before-app.log) | [after-app.log](../evidence/cpu/after-app.log) |
| 관제 로그 | [before-monitor.log](../evidence/cpu/before-monitor.log) | [after-monitor.log](../evidence/cpu/after-monitor.log) |
| 시계열 CSV | [before-timeseries.csv](../evidence/cpu/before-timeseries.csv) | [after-timeseries.csv](../evidence/cpu/after-timeseries.csv) |
| 명령어 출력 | [before-cmd-snapshot.txt](../evidence/cpu/before-cmd-snapshot.txt) | [after-cmd-snapshot.txt](../evidence/cpu/after-cmd-snapshot.txt) |
| 실험 스니펫 | [before-report-snippet.md](../evidence/cpu/before-report-snippet.md) | [after-report-snippet.md](../evidence/cpu/after-report-snippet.md) |
| 환경변수 스냅샷 | [before-env-snapshot.txt](../evidence/cpu/before-env-snapshot.txt) | [after-env-snapshot.txt](../evidence/cpu/after-env-snapshot.txt) |

---

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실

1. **설정값 자체가 경고 대상**: 부트 시퀀스의 자원 점검에서 `CPU_MAX_OCCUPY=100`에 대해 `[ WARNING: Recommend Under 50% ]`가 출력되었다. 즉 애플리케이션은 50%를 안전 운영 한계로 제시한다.
2. **CPU Load의 단계적 상승**: `CpuWorker`가 약 3초 간격으로 Load를 보고하며 <!-- TODO: 5.00% ➔ ... ➔ XX% -->로 단조 증가했고, 한 번도 감소하지 않았다.
3. **50% 초과 시점에 즉시 종료**: Load가 50%를 넘어선 <!-- TODO: 시각 -->에 `[CRITICAL] [CpuWorker] CPU Threshold Violated! (<!-- TODO -->%)` 로그가 출력되고 프로세스가 종료되었다.
4. **관제 데이터와의 시각 교차 검증**: `monitor.log`의 마지막 기록 시각(<!-- TODO -->)이 앱 로그의 `CRITICAL` 시각과 1초 이내로 일치하여, 종료 원인이 임계치 위반임을 확인하였다.

#### (2) 증거를 바탕으로 추론한 원인

- **작업 부하의 무제한 증가**: `CpuWorker`가 작업량을 단계적으로 늘리면서 스스로 산출한 CPU 점유율을 보고하는데, 이 값이 감소하지 않고 계속 상승한다. OOM 장애에서 메모리가 반환되지 않고 누적된 것과 동일한 구조(해제 없는 단조 증가)이다.
- **임계치 기반 보호 동작에 의한 종료**: 애플리케이션 내부 감시 로직이 보고된 Load가 안전 한계(50%)를 초과한 것을 감지하고, 시스템 전체의 응답 지연을 막기 위해 프로세스를 종료시켰다.
- **`CPU_MAX_OCCUPY`의 역할**: 이 값은 `CpuWorker`가 끌어올릴 수 있는 부하의 상한이다. 100으로 설정하면 워커가 안전 한계(50%)를 넘어서는 구간까지 부하를 올릴 수 있게 되어 위반이 발생한다. 즉 **값을 높게 주는 것이 장애의 유발 조건**이다.

#### (3) 관련 운영체제 동작 원리

- **CPU 스케줄링과 응답 지연(Latency)**: CPU는 한 시점에 코어 수만큼의 스레드만 실행할 수 있고, 나머지는 런큐(Run Queue)에서 대기한다. 특정 프로세스가 CPU를 길게 점유하면 다른 프로세스의 대기 시간이 늘어나 전체 시스템의 응답 지연으로 이어진다.
- **`ps %cpu`와 순간 점유율의 차이**: `ps`의 `%cpu`는 `(utime + stime) / elapsed`, 즉 **프로세스 시작 이후의 누적 평균**이다. 따라서 실행 후반에 발생한 급격한 CPU 상승은 평균에 희석되어 낮게 보인다. 본 실험의 관제 스크립트는 `/proc/<pid>/stat`의 `utime + stime`을 1초 간격으로 비교하여 **순간 점유율**을 별도로 기록한다 (`PROC_CPU`). 두 값을 비교하면 누적 평균 지표만으로는 과점유 구간을 식별할 수 없다는 점이 드러난다.
- **nice 값과 우선순위**: 앱은 기동 시 `[SafetyGuard] Process priority lowered (nice=10)`로 자신의 우선순위를 낮춘다(관제 로그의 `STATE:SN`의 `N`). 우선순위가 낮으면 CPU 경합 시 다른 프로세스에 먼저 CPU가 배분되므로, 동일한 부하에서도 시스템 전체에 주는 영향이 완화된다.

---

### 4. Workaround & Verification

#### (1) 변경한 환경변수

- `CPU_MAX_OCCUPY`: `100` ➔ `50` (%)
- 앱 로그의 권고문 `[ WARNING: Recommend Under 50% ]`을 반영하여 안전 한계값으로 하향 조정하였다.
- `MEMORY_LIMIT`, `MULTI_THREAD_ENABLE`은 Before와 동일하게 유지하여 변수 하나만 변경하였다.

#### (2) 변경 전 결과 (`cpu-before`)

- **생존 시간**: <!-- TODO -->
- **앱 보고 최대 Load**: <!-- TODO -->%
- **관측된 최대 PROC_CPU**: <!-- TODO -->%
- **종료 여부**: 종료됨 (`CPU Threshold Violated!`)

#### (3) 변경 후 결과 (`cpu-after`)

- **생존 시간**: <!-- TODO --> (관측 종료 시점까지 생존)
- **앱 보고 최대 Load**: <!-- TODO -->% (50% 미도달)
- **관측된 최대 PROC_CPU**: <!-- TODO -->%
- **종료 여부**: 종료되지 않음 (`CRITICAL` 로그 미발생)

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`CPU_MAX_OCCUPY=100`) | After (`CPU_MAX_OCCUPY=50`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **생존 시간** | <!-- TODO --> | <!-- TODO --> | |
| **앱 보고 최대 Load** | <!-- TODO --> | <!-- TODO --> | |
| **최대 PROC_CPU** | <!-- TODO --> | <!-- TODO --> | |
| **임계치 위반 로그** | 발생 | 미발생 | |
| **프로세스 종료 여부** | 종료 | 생존 | |

#### (5) 임시 조치의 한계

- `CPU_MAX_OCCUPY`를 50으로 낮추면 `CpuWorker`의 부하가 안전 한계 아래에서 묶이므로 임계치 위반과 강제 종료는 발생하지 않는다.
- 그러나 **작업 부하가 시간에 따라 계속 증가하는 로직 자체는 그대로 남아 있다.** 부하 상한에 눌려 종료만 유예된 상태이며, 처리해야 할 작업량이 늘어나면 상한 안에서도 처리가 지연되거나 작업이 적체될 수 있다.
- 또한 상한을 낮추는 것은 애플리케이션이 쓸 수 있는 처리 능력을 깎는 조치이므로, 실제 운영에서는 처리량(Throughput) 저하라는 대가를 지불하게 된다.

#### (6) 근본적인 해결 제안

1. **부하 증가 로직 수정 (Root Cause Fix)**: 작업량을 단조 증가시키는 대신, 작업 완료 후 점유율이 기준선으로 복귀하도록 워커 루프를 수정한다. 바쁜 대기(Busy-wait) 구간이 있다면 이벤트 기반 대기나 적절한 `sleep`으로 전환한다.
2. **작업 큐와 동시 실행 수 제한 (Bounded Concurrency)**: 유입되는 작업을 큐에 적재하고 동시 처리 개수를 제한하여, 부하가 선형으로 증가하지 않도록 상한을 구조적으로 보장한다.
3. **알고리즘 복잡도 개선 및 프로파일링**: `perf`, `py-spy` 등으로 CPU 시간을 많이 쓰는 함수를 특정하고, 반복 계산을 캐싱하거나 복잡도를 낮춘다.
4. **점진적 대응 체계 구축**: 임계치 초과 시 즉시 종료하는 대신, 80% 구간에서 신규 요청 수락을 중단(Readiness Probe 해제)하고 알림을 발송하여 기존 작업을 안전하게 마무리할 시간을 확보한다.
