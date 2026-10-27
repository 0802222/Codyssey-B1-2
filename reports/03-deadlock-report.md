# [Bug] Deadlock - 멀티스레드 모드에서 두 Worker 스레드의 순환 대기로 인한 무응답 분석

### 1. Description

<br>

- **발생 시각**: 2026-10-27 19:15:25 ~ 19:17:23 KST (Before 기준, 19:15:34 이후 무응답)
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 컨테이너 `codyssey-b1-2-lab`, `--platform linux/amd64`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `MULTI_THREAD_ENABLE=true`
  - `MEMORY_LIMIT=512` (단위: MB, OOM이 먼저 발생하지 않도록 고정)
  - `CPU_MAX_OCCUPY=50` (단위: %, CPU 임계치 종료가 끼어들지 않도록 권장값으로 고정)
- **발생 조건**: `MULTI_THREAD_ENABLE=true`로 동시 처리 모드를 켠 상태에서 애플리케이션 구동
- **관측한 현상**:
  - 부팅 시 `[ THREAD ] Concurrency: True [ WARNING ]`, `>>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.` 경고 출력.
  - 기동 약 9초 후 두 Worker 스레드가 각각 `WAITING ... (Status: BLOCKED)`를 출력한 뒤 **로그가 완전히 멈춤**.
  - 프로세스는 종료되지 않고 PID가 유지되었으며, 120초 관찰 후 `RUN_TIMEOUT`으로 강제 종료함 (종료 코드 `143 (SIGTERM)`, 스크립트가 보낸 신호).

---

<br>

### 2. Evidence & Logs

#### (1) 프로그램 실행 로그 ([before-app.log](../evidence/deadlock/before-app.log))

```text
 [ MEMORY ] Limit: 512MB 		[ OK ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-27 19:15:27,326 [WARNING] [AgentWorker] Initializing concurrent transaction processors...
2026-10-27 19:15:27,327 [WARNING] [System] CAUTION: Strict resource locking is enabled.
2026-10-27 19:15:32,357 [INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-1] Processing critical data in Memory A...
2026-10-27 19:15:32,358 [INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
2026-10-27 19:15:32,358 [INFO] [AgentWorker] Waiting for worker threads to complete transactions...
2026-10-27 19:15:32,359 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-10-27 19:15:32,359 [INFO] [AgentWorker][Worker-Thread-2] Establishing network connections in Pool B...
2026-10-27 19:15:34,360 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-10-27 19:15:34,360 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
2026-10-27 19:15:34,373 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-10-27 19:15:34,373 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
```

→ 위 마지막 줄(`19:15:34,373`)이 파일의 **마지막 로그**이며, 이후 강제 종료(약 19:17:25)까지 약 110초 동안 새 로그가 없다.

#### (2) 05-monitor-app-resources.sh 관제 데이터 ([before-timeseries.csv](../evidence/deadlock/before-timeseries.csv))

| 시각 | PROC_CPU (%) | RSS (KB) | THREADS | STATE | 비고 |
| :---: | :---: | :---: | :---: | :---: | :--- |
| 19:15:26 | 16.7 | 25,600 | 1 | `SN+` | 기동 직후 |
| 19:15:32 | 3.0 | 25,600 | 1 | `SN+` | |
| 19:15:33 | 2.5 | 25,576 | **3** | `SNl+` | Worker 스레드 2개 생성, Lock 획득 |
| 19:15:35 | 2.0 | 25,576 | 3 | `SNl+` | 두 스레드 BLOCKED |
| 19:17:23 | 0.1 | 18,488 | 3 | `SNl+` | 모니터 마지막 샘플 |

- 61개 샘플 중 57개가 `THREADS:3`, `STATE:SNl+` (`S` 대기, `N` 저우선순위, `l` 멀티스레드, `+` 가상 터미널의 포그라운드 프로세스).
- BLOCKED 이후 `PROC_CPU` 최대 2.0%로 계속 감소 → 아무 연산도 하지 않음.
- RSS는 한 번도 증가하지 않고 25,600KB ➔ 22,416KB ➔ 18,488KB로 줄어든 뒤 고정 → 새 메모리 할당 없음. 감소분은 쓰지 않는 페이지를 커널이 회수한 것으로 추정한다.

#### (2-1) 스레드별 대기 지점 (보조 측정)

같은 조건(`MULTI_THREAD_ENABLE=true`)으로 앱을 따로 띄우고, 두 스레드가 BLOCKED를 출력한 뒤 `/proc/<PID>/task/<TID>/`의 `status`와 `wchan`(커널에서 잠들어 있는 함수)을 읽었다 (2026-10-27 19:22, 별도 실행).

```text
== 9697 (부모: PyInstaller 부트로더)
  tid=9697 state=S wchan=do_wait        ← 자식 프로세스 종료 대기
== 9698 (자식: 실제 앱)
  tid=9698 state=S wchan=futex_wait     ← 메인(AgentWorker): Worker 종료 대기
  tid=9699 state=S wchan=futex_wait     ← Worker-Thread-1: Lock 대기
  tid=9700 state=S wchan=futex_wait     ← Worker-Thread-2: Lock 대기
```

- 3개 스레드가 모두 `S`(sleep) 상태로 `futex_wait`에서 멈춰 있다. `futex`는 Linux에서 Lock 대기를 구현하는 커널 기능이다.
- BLOCKED 직전(기동 9초 시점)에는 Worker 스레드 2개가 `do_select`(작업 중 `sleep`)였다가, BLOCKED 이후 `futex_wait`로 바뀌었다. 즉, 작업 대기가 아니라 Lock 대기로 멈춘 것이다.
- 어떤 TID가 어느 Worker인지는 커널 정보만으로 구분되지 않는다 (스레드 이름이 모두 `agent-leak-app-`). 생성 순서로 대응시켰다.

#### (3) 실행 스크립트 출력 ([before-run.log](../evidence/deadlock/before-run.log))

```sh
[INFO] App started (PID: 4596)
[INFO] Run timeout: 120s
[WARN] App still running after 120s. Killing (PID: 4596)
[INFO] Exit mode: RUN_TIMEOUT(120s) 강제 종료
[INFO] Exit code: 143 (SIGTERM)
```

→ 120초 시점에도 프로세스가 살아 있었음(PID 유지)을 스크립트가 확인하고 종료함.

#### (4) 관련 증적 파일 목록
- [before-app.log](../evidence/deadlock/before-app.log) / [after-app.log](../evidence/deadlock/after-app.log)
- [before-monitor.log](../evidence/deadlock/before-monitor.log) / [after-monitor.log](../evidence/deadlock/after-monitor.log)
- [before-timeseries.csv](../evidence/deadlock/before-timeseries.csv) / [after-timeseries.csv](../evidence/deadlock/after-timeseries.csv)
- [before-report-snippet.md](../evidence/deadlock/before-report-snippet.md) / [after-report-snippet.md](../evidence/deadlock/after-report-snippet.md)
- [before-env-snapshot.txt](../evidence/deadlock/before-env-snapshot.txt) / [after-env-snapshot.txt](../evidence/deadlock/after-env-snapshot.txt)
- [before-run.log](../evidence/deadlock/before-run.log) / [after-run.log](../evidence/deadlock/after-run.log)

---

<br>

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실
1. **PID 유지**: 120초 시점에 `App still running after 120s` — 프로세스는 종료되지 않았다.
2. **로그 정지**: 마지막 로그는 `19:15:34` 두 스레드의 `WAITING ... (Status: BLOCKED)`이며, 이후 약 110초간 로그가 한 줄도 추가되지 않았다.
3. **자원 정체**: BLOCKED 이후 `PROC_CPU`는 2.0% ➔ 0.1%로 감소, RSS는 증가 없이 감소 후 고정, 상태는 `SNl+`(대기)로 유지되었다.
4. **Lock 획득 순서가 서로 반대**: Thread-1은 `Shared_Memory_A`를 잡은 채 `Socket_Pool_B`를, Thread-2는 `Socket_Pool_B`를 잡은 채 `Shared_Memory_A`를 기다린다.

#### (2) 증거를 바탕으로 추론한 원인
- **순환 대기에 의한 Deadlock**: 두 스레드가 서로 상대가 가진 Lock을 기다리며, 어느 쪽도 Lock을 놓지 않아 대기가 끝나지 않는다. 메인 스레드(`AgentWorker`)도 `Waiting for worker threads to complete transactions...` 상태로 두 Worker의 종료를 기다리므로 프로세스 전체가 무응답이 된다.
- 단순히 "프로그램이 멈췄다"는 사실만이 아니라, **PID 유지 + 로그 정지 위치 + CPU/메모리 정체 + 스레드 대기 상태 + 반대 순서의 Lock 획득 로그**가 함께 확인되었으므로 Deadlock으로 판단한다.

#### (3) 관련 운영체제 동작 원리
- **Deadlock 4조건**이 모두 성립한다.
  1. 상호 배제: `Shared_Memory_A`, `Socket_Pool_B`는 한 번에 한 스레드만 Lock 가능 (`Strict resource locking is enabled`).
  2. 점유 대기: 각 스레드가 Lock 하나를 `Holding...`한 채 다른 Lock을 요청.
  3. 비선점: 상대가 가진 Lock을 강제로 빼앗을 수 없음.
  4. 순환 대기: Thread-1 → B(Thread-2 보유) → A(Thread-1 보유) → …
- **Deadlock 상태의 스레드는 CPU를 쓰지 않는다**: Lock을 기다리는 스레드는 커널 스케줄러에서 대기(`S`, sleep) 상태로 빠지므로 CPU 사용률이 0에 수렴한다. 그래서 CPU 과점유와 달리 "자원은 멀쩡한데 응답이 없는" 모습으로 나타난다.
- **프로세스가 종료되지 않는다**: OOM이나 CPU Threshold와 달리 감시자가 종료시킬 기준(메모리/CPU 초과)을 넘지 않으므로, 외부에서 감지·종료하지 않으면 무한히 대기한다.

---

<br>

### 4. Workaround & Verification

#### (1) 변경한 환경변수
- `MULTI_THREAD_ENABLE`: `true` ➔ `false`

#### (2) 변경 전 결과 (`deadlock-before`)
- **Lock 경합 발생**: 기동 약 9초 후(19:15:34) 두 스레드 BLOCKED
- **로그 진행**: 19:15:34 이후 정지
- **PID 유지 / 무응답**: 120초 관찰 동안 유지 / 무응답
- **종료 방식**: RUN_TIMEOUT(120s) 강제 종료, 종료 코드 `143 (SIGTERM)`

#### (3) 변경 후 결과 (`deadlock-after`)
- **앱 시나리오**: `Scenario Selected: [Healthy System Monitoring]` (Lock 경합 로그 없음)
- **로그 진행**: 종료 직전(19:19:27)까지 계속 기록
  ```text
  2026-10-27 19:17:58,775 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  2026-10-27 19:18:32,253 [WARNING] [MemoryWorker] Memory Usage Reached Limit (525MB). Starting cleanup...
  2026-10-27 19:18:32,278 [INFO] [System] Memory Cache Flushed. Process Stabilized.
  >>> [SYSTEM] MEMORY RECOVERED (Cache Cleared) <<<
  2026-10-27 19:18:33,147 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
  2026-10-27 19:19:04,389 [INFO] [CpuWorker] Peak reached (50.00%). Starting cooldown...
  2026-10-27 19:19:25,785 [INFO] [MemoryWorker] Current Heap: 425MB
  2026-10-27 19:19:27,244 [INFO] [CpuWorker] Current Load: 14.24%
  ```
- **자원 변화**: RSS가 증가 ➔ cleanup ➔ 재증가를 반복 (최대 538,004KB), 정상적으로 작업 중임을 보여줌
- **종료 방식**: RUN_TIMEOUT(120s) 강제 종료 ([after-run.log](../evidence/deadlock/after-run.log)) — 정상 동작 중이라 스스로 끝나지 않음

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`MULTI_THREAD_ENABLE=true`) | After (`MULTI_THREAD_ENABLE=false`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **부팅 판정** | `WARNING` + `POTENTIAL DEADLOCK` | `OK` | 경고 해소 |
| **PID 유지** | 120초 유지 | 120초 유지 | 둘 다 살아 있음 |
| **로그 마지막 위치** | 19:15:34 `WAITING ... BLOCKED` | 19:19:27 (종료 직전까지 진행) | **Before만 정지** |
| **CPU 변화** | BLOCKED 이후 2.0% ➔ 0.1% | 앱 Load 5~50% 주기 변동 | Before는 정체 |
| **메모리 변화** | 증가 없이 18,488KB에서 고정 | 증가·cleanup 반복 (최대 538,004KB) | Before는 정체 |
| **스레드 상태** | 3개, `SNl+`, 2개 BLOCKED | 3개, `SNl+`, 정상 작업 | |
| **종료 코드** | 143 (타임아웃 SIGTERM) | 143 (타임아웃 SIGTERM) | 둘 다 스스로 끝나지 않음 |
| **무응답 발생** | **발생** | 발생하지 않음 | 장애 회피 |

#### (5) 임시 조치의 한계
- `MULTI_THREAD_ENABLE=false`는 동시 처리를 꺼서 Lock 경합 상황 자체를 만들지 않는 우회책이다. 코드의 Lock 획득 순서 문제는 그대로 남아 있어, 멀티스레드를 다시 켜면 같은 Deadlock이 재발한다.
- 단일 스레드 처리로 바뀌므로 동시 처리량이 줄어 성능 저하가 생길 수 있다.

#### (6) 근본적인 해결 제안
1. **Lock 획득 순서 고정**: 모든 스레드가 `Shared_Memory_A` → `Socket_Pool_B`처럼 같은 순서로 Lock을 잡도록 수정하여 순환 대기 조건을 제거.
2. **타임아웃 있는 Lock 획득**: `tryLock(timeout)` 방식으로 일정 시간 내 Lock을 얻지 못하면 보유 중인 Lock을 놓고 재시도하여 점유 대기 조건을 깨뜨림.
3. **Lock 범위 축소**: 하나의 Lock을 잡은 상태에서 다른 자원을 요청하지 않도록 작업을 분리.
4. **무응답 감시**: 로그 진행/헬스체크 응답이 일정 시간 없으면 알림을 보내는 Liveness 체크를 두어, CPU·메모리 지표로는 드러나지 않는 Deadlock을 조기에 감지.
