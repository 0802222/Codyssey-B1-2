# [Bug] OOM Crash - MemoryGuard 임계치 도달에 따른 프로세스 자가 종료 및 메모리 누수 분석

<br>

### 1. Description

- **발생 시각**: 2026-10-27 19:11:58 ~ 19:12:09 KST (Before 기준)
- **실행 환경**: Linux x86_64 (Ubuntu 24.04 LTS 컨테이너 환경, hostname: `codyssey-b1-2-lab`), 서비스 계정 `agentuser` (uid=1001)
- **적용한 환경변수**:
  - `APP_NAME=agent-leak-app-x86`
  - `AGENT_HOME=/workspace/runtime`
  - `AGENT_PORT=15034`
  - `MEMORY_LIMIT=100` (단위: MB)
  - `CPU_MAX_OCCUPY=50` (단위: %)
  - `MULTI_THREAD_ENABLE=true`
- **발생 조건**: `MEMORY_LIMIT`이 기본값(100MB)으로 설정된 상태에서 애플리케이션(`agent-leak-app-x86`) 구동
- **관측한 현상**:
  - 프로그램 실행 직후 정상 부팅되었으나, 약 11초 후 `[CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB)` 로그와 `>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<` 배너가 출력되고 프로세스가 강제 자가 종료됨.
  - 종료 코드는 `137 (SIGKILL)`.

---

<br>

### 2. Evidence & Logs

#### (1) 05-monitor-app-resources.sh 관제 데이터 ([before-monitor.log](../evidence/oom/before-monitor.log))

```text
[2026-10-27 19:11:59] PID:370 PPID:360 STATE:SN+ ELAPSED:00:01 THREADS:1 PROC_CPU:16.7% PROC_MEM:0.3% RSS:25600KB SYS_CPU:3.1% SYS_MEM:13.9% DISK_USED:4% PORT:15034 FIREWALL:active
[2026-10-27 19:12:01] PID:370 PPID:360 STATE:SN+ ELAPSED:00:03 THREADS:1 PROC_CPU:7.3% PROC_MEM:0.6% RSS:51204KB SYS_CPU:2.1% SYS_MEM:13.7% DISK_USED:4% PORT:15034 FIREWALL:active
[2026-10-27 19:12:03] PID:370 PPID:360 STATE:SN+ ELAPSED:00:05 THREADS:1 PROC_CPU:4.6% PROC_MEM:0.6% RSS:51204KB SYS_CPU:3.1% SYS_MEM:14.2% DISK_USED:4% PORT:15034 FIREWALL:active
[2026-10-27 19:12:05] PID:370 PPID:360 STATE:SN+ ELAPSED:00:07 THREADS:1 PROC_CPU:3.3% PROC_MEM:0.9% RSS:76808KB SYS_CPU:3.0% SYS_MEM:14.3% DISK_USED:4% PORT:15034 FIREWALL:active
[2026-10-27 19:12:07] PID:370 PPID:360 STATE:SN+ ELAPSED:00:09 THREADS:1 PROC_CPU:2.8% PROC_MEM:1.2% RSS:102412KB SYS_CPU:2.1% SYS_MEM:14.7% DISK_USED:4% PORT:15034 FIREWALL:active
[2026-10-27 19:12:09] PID:370 PPID:360 STATE:SN+ ELAPSED:00:11 THREADS:1 PROC_CPU:2.3% PROC_MEM:1.2% RSS:102412KB SYS_CPU:3.0% SYS_MEM:13.5% DISK_USED:4% PORT:15034 FIREWALL:active
```

#### (2) 프로그램 실행 로그 ([before-app.log](../evidence/oom/before-app.log))

```text
>>> Starting Agent Boot Sequence...
[1/6] Checking User Account               [OK]
   ... Running as service user 'agentuser' (uid=1001)
[2/6] Verifying Environment Variables     [OK]
   ... All required Envs correct
[3/6] Checking Required Files             [OK]
   ... Verified 'secret.key' with correct key string.
[4/6] Checking Port Availability          [OK]
   ... Port 15034 is available.
[5/6] Verifying Log Permission            [OK]
   ... Log directory is writable: /workspace/runtime/logs
[6/6] Verifying Mission Environment       [OK]
   ... MEMORY_LIMIT=100MB, CPU_MAX_OCCUPY=50%, MULTI_THREAD_ENABLE=True
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-10-27 19:11:58,867 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-10-27 19:11:58,869 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-10-27 19:12:00,883 [INFO] [MemoryWorker] Current Heap: 25MB
2026-10-27 19:12:03,907 [INFO] [MemoryWorker] Current Heap: 50MB
2026-10-27 19:12:06,940 [INFO] [MemoryWorker] Current Heap: 75MB
2026-10-27 19:12:09,971 [INFO] [MemoryWorker] Current Heap: 100MB
2026-10-27 19:12:09,972 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-10-27 19:12:09,972 [CRITICAL] [MemoryGuard] Self-terminating process 370 to prevent system instability.

>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
```

#### (2-1) 실행 스크립트 출력 ([before-run.log](../evidence/oom/before-run.log))

```sh
[INFO] App started (PID: 357)
[INFO] Exit mode: 앱 자체 종료
[INFO] Exit code: 137 (SIGKILL)
```

- 종료 코드 137은 `128 + 9`이며, 9번 신호는 `SIGKILL`이다. `MemoryGuard`가 자신에게 SIGKILL을 보내 즉시 종료했음을 뜻한다.
- `App started`의 PID(357)는 앱을 감싼 `script` 프로세스이고, 실제 앱은 그 아래 자식 프로세스(370)이다. 구조는 [01-concepts.md](../docs/01-concepts.md#부모와-자식-프로세스)에 정리했다.

#### (3) 시계열 데이터 요약 ([before-timeseries.csv](../evidence/oom/before-timeseries.csv))

| 시각 (Timestamp) | 프로세스 CPU (%) | 시스템 CPU (%) | RSS (KB) | RSS 환산 (MB) | 프로세스 상태 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 19:11:59 | 16.7 | 3.1 | 25,600 | ~25.0 MB | `SN+` |
| 19:12:01 | 7.3 | 2.1 | 51,204 | ~50.0 MB | `SN+` |
| 19:12:03 | 4.6 | 3.1 | 51,204 | ~50.0 MB | `SN+` |
| 19:12:05 | 3.3 | 3.0 | 76,808 | ~75.0 MB | `SN+` |
| 19:12:07 | 2.8 | 2.1 | 102,412 | ~100.0 MB | `SN+` |
| 19:12:09 | 2.3 | 3.0 | 102,412 | ~100.0 MB | `SN+` |

- `STATE`의 `+`는 앱이 가상 터미널(pty)의 포그라운드 프로세스로 실행 중이라는 뜻이다. 종료 배너를 수집하려고 `script`로 실행했기 때문이다 ([06-troubleshooting.md](../docs/06-troubleshooting.md)).

#### (4) 관련 증적 파일 목록
- [before-app.log](../evidence/oom/before-app.log)
- [before-monitor.log](../evidence/oom/before-monitor.log)
- [before-timeseries.csv](../evidence/oom/before-timeseries.csv)
- [before-report-snippet.md](../evidence/oom/before-report-snippet.md)
- [before-env-snapshot.txt](../evidence/oom/before-env-snapshot.txt)
- [before-run.log](../evidence/oom/before-run.log)

---

<br>

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실
1. **계단식 메모리 증가**: 관제 데이터(`monitor.log`) 상에서 프로세스의 물리 메모리 사용량(RSS)이 초기 `25,600KB`에서 약 3초 간격으로 `+25,604KB`씩 계단식으로 급증(`25MB` ➔ `50MB` ➔ `75MB` ➔ `100MB`)함.
2. **할당 주기와 일치**: 앱 로그(`before-app.log`)에서 `MemoryWorker`가 약 3초 간격으로 정확히 `Current Heap: 25MB ➔ 50MB ➔ 75MB ➔ 100MB`를 기록하며, 메모리가 한 번도 해제(Free/GC)되지 않음.
3. **임계치 도달 즉시 자가 종료**: 힙 메모리가 `100MB`에 도달한 `19:12:09`에 `[CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB)` 로그와 `SELF-TERMINATED` 배너가 출력되고 프로세스 `370`이 즉각 종료됨.
4. **SIGKILL 종료**: 실행 스크립트가 받은 종료 코드는 `137 (SIGKILL)`이다.

#### (2) 증거를 바탕으로 추론한 원인
- **애플리케이션 레벨 메모리 누수(Memory Leak)**: `MemoryWorker`가 반복 작업 수행 시 25MB 크기의 청크(Chunk) 데이터를 동적 생성한 후 참조를 해제하지 않아 힙 메모리에 영구 적재되고 있음.
- **MemoryGuard에 의한 의도된 강제 종료**: 운영체제 커널의 OOM Killer가 동작하기 전, 애플리케이션에 내장된 자체 보호 루틴(`MemoryGuard`)이 `MEMORY_LIMIT` 초과를 감지하고 시스템 전체 불능 상태를 막기 위해 스스로 프로세스를 `SIGKILL`로 종료함 (종료 코드 137로 확인).

#### (3) 관련 운영체제 동작 원리
- **가상 메모리와 RSS (Resident Set Size)**:
  - 프로세스는 가상 메모리 공간(VSZ)을 할당받지만, 실제로 물리 RAM(프레임)을 차지하는 영역은 **RSS**이다.
  - `MemoryWorker`가 힙(Heap) 메모리를 동적으로 할당하고 쓰기 작업을 수행하면서 페이지 폴트(Page Fault)가 발생하고, OS 페이지 테이블에 물리 메모리가 매핑되어 RSS가 비례 증가함.
- **애플리케이션 보호(MemoryGuard) vs 커널 OOM Killer**:
  - 본 장애는 리눅스 커널의 OOM Killer에 의해 강제 피살된 것이 아니라, 애플리케이션 레벨의 감시자(`MemoryGuard`)가 프로세스를 안전하게 종료한 것이다.
  - 하지만 이를 방치하여 `MemoryGuard` 임계치를 해제하거나 매우 높게 잡을 경우, 물리 RAM이 고갈되어 커널 OOM Killer가 `badness score`에 따라 다른 필수 서비스나 시스템 프로세스까지 임의로 종료시키는 대형 시스템 장애로 번질 위험이 있다.

---

<br>

### 4. Workaround & Verification

#### (1) 변경한 환경변수
- `MEMORY_LIMIT`: `100` ➔ `256` (MB)
- (앱 로그의 경고문 `[ WARNING: Recommend Over 256MB ]`을 반영하여 256MB로 증설)

#### (2) 변경 전 결과 (`oom-before`)
- **생존 시간**: **약 11초** (앱 로그 기준 19:11:58 기동 ~ 19:12:09 자가 종료)
- **최종 RSS (모니터 마지막 샘플)**: **102,412 KB** (~100.0 MB)
- **종료 시점 힙 사용량**: **100MB** (`100MB >= 100MB`)
- **종료 방식**: 앱 자체 종료, 종료 코드 `137 (SIGKILL)` ([before-report-snippet.md](../evidence/oom/before-report-snippet.md))

#### (3) 변경 후 결과 (`oom-after`)
- **생존 시간**: **약 32초** (앱 로그 기준 19:12:13 기동 ~ 19:12:45 자가 종료)
- **최종 RSS (모니터 마지막 샘플)**: **281,636 KB** (~275.0 MB)
- **종료 시점 힙 사용량**: **275MB** (`275MB >= 256MB`)
- **종료 방식**: 앱 자체 종료, 종료 코드 `137 (SIGKILL)` ([after-report-snippet.md](../evidence/oom/after-report-snippet.md))
- **관찰 로그 ([after-app.log](../evidence/oom/after-app.log))**:
  ```text
  2026-10-27 19:12:42,771 [INFO] [MemoryWorker] Current Heap: 250MB
  2026-10-27 19:12:45,793 [INFO] [MemoryWorker] Current Heap: 275MB
  2026-10-27 19:12:45,795 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
  2026-10-27 19:12:45,795 [CRITICAL] [MemoryGuard] Self-terminating process 695 to prevent system instability.
  >>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<
  ```

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`MEMORY_LIMIT=100`) | After (`MEMORY_LIMIT=256`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **생존 시간** | 약 11 초 | 약 32 초 | **약 +21 초 (약 2.9배)** |
| **시작 RSS** | 25,600 KB | 25,596 KB | 기동 시 기본 메모리는 동일 (~25MB) |
| **종료 직전 RSS** | 102,412 KB | 281,636 KB | 임계치까지 지속 증가 |
| **최종 도달 힙** | 100 MB | 275 MB | 25MB 청크 단위 누적 |
| **증가 속도** | 약 25MB / 3초 | 약 25MB / 3초 | **변화 없음** |
| **종료 원인** | Memory limit exceeded (100MB) | Memory limit exceeded (256MB) | **동일 원인으로 종료** |
| **프로세스 상태** | SELF-TERMINATED | SELF-TERMINATED | **자가 종료 재발** |
| **종료 코드** | 137 (SIGKILL) | 137 (SIGKILL) | 동일 |

#### (5) 임시 조치의 한계
- `MEMORY_LIMIT`을 256MB로 상향하여 프로세스의 가동 유지 시간을 약 11초에서 약 32초로 연장하는 데는 성공하였다.
- 그러나 **메모리 사용량이 3초마다 25MB씩 누적되는 기울기(증가율)는 전혀 개선되지 않았으며**, 메모리가 275MB에 도달하는 순간 동일하게 `MemoryGuard`에 의해 비정상 종료되었다.
- 따라서 환경변수 증설은 장애 발생 시점을 일시적으로 유예하는 **임시 방편(Workaround)**일 뿐이며, 누수 자체가 해소되지 않는 한 근본적인 조치가 될 수 없다.

#### (6) 근본적인 해결 제안
1. **코드 레벨의 메모리 누수 수정 (Root Cause Fix)**:
   - `MemoryWorker`에서 청크 데이터를 처리한 후 전역 컨텍스트나 인메모리 리스트에 무한 보관하지 않고, 작업 종료 즉시 참조를 해제(`del` 또는 스코프 종료)하여 GC 대상이 되도록 리팩토링.
2. **캐시 크기 제한 (Bounded Cache Policy)**:
   - 무제한 메모리 할당 대신 크기 제한이 있는 LRU(Least Recently Used) 캐시 또는 순환 버퍼(Ring Buffer)를 적용하여 최대 점유 한도를 제한.
3. **사전 플러시 및 헬스체크 연동**:
   - 임계치 초과 시 즉시 강제 종료(Crash)하는 대신, 임계치 도달 전 80% 구간에서 메모리 캐시 플러시(`Cache Flush`)를 먼저 수행하고 알림(Alert)을 발송하는 점진적 복구 메커니즘 구축.
