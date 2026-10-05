# [Bug] Deadlock - 두 워커 스레드의 Lock 순환 대기로 인한 무응답 상태 분석

### 1. Description

- **발생 시각**: <!-- TODO: YYYY-MM-DD HH:MM:SS ~ HH:MM:SS KST (Before 기준) -->
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 LTS 컨테이너 환경, hostname: `codyssey-b1-2-lab`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `AGENT_HOME=/workspace/runtime`
  - `AGENT_PORT=15034`
  - `MEMORY_LIMIT=512` (단위: MB / OOM 장애와 분리하기 위해 메모리는 충분히 확보)
  - `CPU_MAX_OCCUPY=50` (단위: % / CPU 장애와 분리하기 위해 권고치로 고정)
  - `MULTI_THREAD_ENABLE=true`
- **발생 조건**: `MULTI_THREAD_ENABLE=true`로 멀티스레드 동시 실행을 허용한 상태에서 애플리케이션(`agent-leak-app-x86`) 구동
- **관측한 현상**:
  - 부트 시퀀스에서 `[ THREAD ] Concurrency: True [ WARNING ]`와 `>>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.` 경고가 출력됨.
  - 두 워커 스레드가 각각 다른 자원의 Lock을 먼저 획득한 뒤, 상대가 보유한 자원을 요청하면서 `WAITING ... (Status: BLOCKED)` 로그 이후 **새로운 로그가 더 이상 기록되지 않음**.
  - 프로세스는 종료되지 않고 PID가 유지되나, CPU 사용률 0%, RSS 고정, 로그 정지 상태가 관측 종료 시점까지 지속됨 (무응답).

---

### 2. Evidence & Logs

#### (1) 프로그램 실행 로그 ([before-app.log](../evidence/deadlock/before-app.log))

로그가 멈춘 **마지막 위치**가 핵심 증거이다.

```text
<!-- TODO: evidence/deadlock/before-app.log 의 Lock 획득 ~ BLOCKED 구간 붙여넣기

관측 형태 예시:
[WARNING] [System] CAUTION: Strict resource locking is enabled.
[INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
[INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
[INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
[INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
[INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
[INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
[INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
[INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
(이후 로그 없음)
-->
```

#### (2) monitor.sh 관제 데이터 ([before-monitor.log](../evidence/deadlock/before-monitor.log))

앱 로그가 멈춘 이후에도 관제 로그는 계속 기록되며, **PID는 살아 있는데 자원 사용량이 정체**된 것을 보여준다.

```text
<!-- TODO: 앱 로그가 멈춘 시각 이후의 monitor.log 구간 붙여넣기 (STATE / THREADS / PROC_CPU / RSS 변화 없음) -->
```

- 로그 정지 시각: <!-- TODO -->
- 관제 마지막 기록 시각: <!-- TODO -->
- **무응답 지속 시간**: <!-- TODO -->초

#### (3) 스레드 상태 확인 ([before-cmd-snapshot.txt](../evidence/deadlock/before-cmd-snapshot.txt))

```text
<!-- TODO: cmd-snapshot.txt 의 ps -L 블록 붙여넣기

관측 형태 예시:
  PID   TID STAT %CPU %MEM     ELAPSED COMMAND
 7602  7602 SNl   0.0  0.1       01:38 agent-leak-app-
 7602  7838 SNl   0.0  0.1       01:31 agent-leak-app-
 7602  7839 SNl   0.0  0.1       01:31 agent-leak-app-
-->
```

- `STAT`의 `S`는 인터럽트 가능한 대기(Sleep), `l`은 멀티스레드 프로세스, `N`은 낮은 우선순위(nice)를 의미한다.
- 모든 TID가 `S` 상태이고 `%CPU`가 0.0%이므로, 스레드들이 **연산 중이 아니라 대기 중**임을 알 수 있다.

#### (4) 시계열 데이터 요약 ([before-timeseries.csv](../evidence/deadlock/before-timeseries.csv))

| 시각 (Timestamp) | PROC_CPU (%) | RSS (KB) | 스레드 | 상태 | 앱 로그 진행 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| <!-- TODO --> | | | | | |

#### (5) 관련 증적 파일 목록

| 구분 | Before (`MULTI_THREAD_ENABLE=true`) | After (`MULTI_THREAD_ENABLE=false`) |
| :--- | :--- | :--- |
| 앱 로그 | [before-app.log](../evidence/deadlock/before-app.log) | [after-app.log](../evidence/deadlock/after-app.log) |
| 관제 로그 | [before-monitor.log](../evidence/deadlock/before-monitor.log) | [after-monitor.log](../evidence/deadlock/after-monitor.log) |
| 시계열 CSV | [before-timeseries.csv](../evidence/deadlock/before-timeseries.csv) | [after-timeseries.csv](../evidence/deadlock/after-timeseries.csv) |
| 명령어 출력 | [before-cmd-snapshot.txt](../evidence/deadlock/before-cmd-snapshot.txt) | [after-cmd-snapshot.txt](../evidence/deadlock/after-cmd-snapshot.txt) |
| 실험 스니펫 | [before-report-snippet.md](../evidence/deadlock/before-report-snippet.md) | [after-report-snippet.md](../evidence/deadlock/after-report-snippet.md) |
| 환경변수 스냅샷 | [before-env-snapshot.txt](../evidence/deadlock/before-env-snapshot.txt) | [after-env-snapshot.txt](../evidence/deadlock/after-env-snapshot.txt) |

---

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실

1. **프로세스는 살아 있다**: 관제 로그에서 PID <!-- TODO -->가 관측 종료까지 계속 조회되었고, 포트 15034도 리슨 상태를 유지했다. 즉 비정상 종료(Crash)가 아니다.
2. **자원 사용량이 정체되었다**: `PROC_CPU`가 0.0%로 고정되고 `RSS`도 <!-- TODO -->KB에서 변하지 않았다. 연산도, 메모리 할당도 일어나지 않고 있다.
3. **로그가 특정 지점에서 멈췄다**: 앱 로그의 마지막 두 줄이 `WAITING for [Socket_Pool_B]... (Status: BLOCKED)`와 `WAITING for [Shared_Memory_A]... (Status: BLOCKED)`이며, 이후 <!-- TODO -->초 동안 어떤 로그도 추가되지 않았다.
4. **교차 Lock 획득 순서가 기록되었다**: `Worker-Thread-1`은 `Shared_Memory_A`를 보유한 채 `Socket_Pool_B`를 요청하고, `Worker-Thread-2`는 `Socket_Pool_B`를 보유한 채 `Shared_Memory_A`를 요청했다.
5. **스레드가 모두 대기 상태다**: `ps -L` 결과 3개 TID 전부 `S`(Sleep) 상태이며 CPU 사용률은 0.0%이다.

#### (2) 증거를 바탕으로 추론한 원인

- **Lock 획득 순서 불일치로 인한 순환 대기(Deadlock)**: 두 워커가 동일한 두 자원을 **서로 반대 순서**로 획득하려 하면서, 각자 상대가 보유한 Lock의 해제를 기다리는 원형 대기 구조가 형성되었다. 어느 쪽도 보유한 Lock을 놓지 않으므로 대기는 영구히 끝나지 않는다.
- **단순 지연이 아닌 교착상태로 판단한 근거**: 작업이 느린 것이라면 CPU 사용률이나 RSS에 변화가 있거나 로그가 간헐적으로라도 진행된다. 그러나 본 장애는 CPU 0%, RSS 고정, 로그 완전 정지가 동시에 나타났고, 마지막 로그가 `BLOCKED` 상태를 명시하고 있다.
- **멀티스레드 활성화가 발생 조건**: `MULTI_THREAD_ENABLE=true`일 때만 두 워커가 동시에 실행되어 Lock 경합이 발생한다. `false`에서는 작업이 순차 실행되므로 경합 자체가 성립하지 않는다.

#### (3) Deadlock 네 가지 조건의 충족 여부

| 조건 | 본 장애에서의 충족 근거 |
| :--- | :--- |
| **상호 배제 (Mutual Exclusion)** | `LOCK ACQUIRED` 로그 — 각 자원을 한 번에 한 스레드만 점유한다. |
| **점유 대기 (Hold and Wait)** | Thread-1은 `Shared_Memory_A`를 `(Holding...)` 상태로 유지한 채 `Socket_Pool_B`를 요청한다. |
| **비선점 (No Preemption)** | 어느 스레드도 상대의 Lock을 강제로 회수하지 못하고 `WAITING` 상태로 남는다. |
| **순환 대기 (Circular Wait)** | Thread-1 → `Socket_Pool_B`(Thread-2 보유), Thread-2 → `Shared_Memory_A`(Thread-1 보유)로 대기 사이클이 닫힌다. |

#### (4) 관련 운영체제 동작 원리

- **프로세스 상태와 Sleep**: Lock 대기에 들어간 스레드는 CPU를 점유하지 않고 커널의 대기 큐로 이동하여 `S`(interruptible sleep) 상태가 된다. 그래서 교착상태에서는 CPU 사용률이 0%에 가깝게 나타난다. 바쁜 대기(Busy-wait)라면 반대로 CPU가 100%로 치솟는다.
- **PID 존재와 정상 동작은 다른 문제다**: 커널은 프로세스가 대기 중인지 작업 중인지 구분하지 않고 PID를 유지한다. 따라서 `ps -ef`로 PID가 조회된다는 사실만으로 헬스 체크를 통과시키면 교착상태를 탐지할 수 없고, CPU·메모리 변화와 로그 진행 여부를 함께 봐야 한다.
- **포트 리슨도 헬스 체크 근거가 되지 못한다**: 소켓은 커널이 관리하므로 애플리케이션 스레드가 모두 멈춰도 리슨 상태는 유지된다. 본 장애에서도 포트 15034는 계속 열려 있었다. TCP 연결 성공 여부만 보는 헬스 체크는 이 장애를 정상으로 오판한다.

---

### 4. Workaround & Verification

#### (1) 변경한 환경변수

- `MULTI_THREAD_ENABLE`: `true` ➔ `false`
- `MEMORY_LIMIT`, `CPU_MAX_OCCUPY`는 Before와 동일하게 유지하여 변수 하나만 변경하였다.

#### (2) 변경 전 결과 (`deadlock-before`)

- **PID 유지 여부**: 유지됨 (종료되지 않음)
- **CPU / 메모리 변화**: `PROC_CPU` 0.0% 고정, `RSS` <!-- TODO -->KB 고정
- **로그 마지막 위치**: `WAITING for [...]... (Status: BLOCKED)`
- **스레드 상태**: TID <!-- TODO -->개 전부 `S`(Sleep)
- **무응답 발생 여부**: 발생 (<!-- TODO -->초 이상 지속)

#### (3) 변경 후 결과 (`deadlock-after`)

- **PID 유지 여부**: 유지됨 (정상 동작 중)
- **CPU / 메모리 변화**: 작업 진행에 따라 변동 발생
- **로그 마지막 위치**: 정상 작업 로그가 계속 기록됨 (`BLOCKED` 로그 미발생)
- **무응답 발생 여부**: 미발생

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`true`) | After (`false`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **PID 유지** | 유지 | 유지 | 두 경우 모두 프로세스는 종료되지 않음 |
| **PROC_CPU 변화** | 0.0% 고정 | 변동 있음 | 작업 진행 여부의 핵심 지표 |
| **RSS 변화** | 고정 | 변동 있음 | |
| **로그 진행** | `BLOCKED` 이후 정지 | 계속 기록 | |
| **`BLOCKED` 로그** | 발생 | 미발생 | |
| **무응답** | 발생 | 미발생 | 멀티스레드 자원 경합이 원인임을 뒷받침 |

#### (5) 임시 조치의 한계

- `MULTI_THREAD_ENABLE=false`는 동시 실행을 없애 Lock 경합 자체를 성립하지 않게 만들어 무응답을 회피한다.
- 그러나 **Lock을 서로 다른 순서로 획득하는 코드는 그대로 남아 있다.** 동시성을 다시 켜는 순간 동일한 교착상태가 재발한다.
- 또한 모든 작업을 순차 처리하므로 **병렬 처리 성능을 포기**하는 조치이다. 처리량이 중요한 운영 환경에서는 그대로 쓸 수 없다.

#### (6) 근본적인 해결 제안

1. **Lock 획득 순서 통일 (Lock Ordering)**: 모든 스레드가 자원에 전역 순서(예: `Shared_Memory_A` ➔ `Socket_Pool_B`)를 정해 동일한 순서로만 획득하도록 규약을 세운다. 순환 대기 조건이 깨지므로 Deadlock이 원천 차단된다.
2. **Lock 타임아웃 적용 (`tryLock`)**: 무기한 대기 대신 `tryLock(timeout)`을 사용하여, 획득 실패 시 보유한 Lock을 모두 반납하고 백오프 후 재시도한다. 점유 대기 조건을 완화하는 방식이다.
3. **Lock 범위 최소화와 단일 Lock 통합**: 임계 구역을 최소화하고, 함께 쓰이는 자원은 하나의 Lock으로 묶어 중첩 Lock을 제거한다.
4. **교착상태 탐지 가능한 헬스 체크 구성**: PID·포트 생존만 보는 헬스 체크를 **애플리케이션 레벨 헬스 체크**(워커가 실제로 하트비트를 갱신하는지 확인)로 전환하고, 일정 시간 하트비트가 멈추면 Liveness Probe가 재기동하도록 구성한다.
