# [Bug] OOM Crash - MemoryGuard 임계치 도달에 따른 프로세스 자가 종료 및 메모리 누수 분석

### 1. Description

- **발생 시각**: 2026-09-10 16:19:27 ~ 16:19:38 KST (Before 기준)
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
  - 프로그램 실행 직후 정상 부팅되었으나, 약 11초 후 `[CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB)` 로그와 함께 프로세스가 강제 자가 종료(`SELF-TERMINATED`)됨.

---

### 2. Evidence & Logs

#### (1) monitor.sh 관제 데이터 ([before-monitor.log](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-monitor.log))

```text
[2026-09-10 16:19:27] PID:7237 PPID:7223 STATE:SN ELAPSED:00:00 THREADS:1 PROC_CPU:4.3% PROC_MEM:0.1% RSS:18352KB SYS_CPU:1.6% SYS_MEM:3.6% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:29] PID:7237 PPID:7223 STATE:SN ELAPSED:00:02 THREADS:1 PROC_CPU:3.1% PROC_MEM:0.2% RSS:43956KB SYS_CPU:0.0% SYS_MEM:3.8% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:30] PID:7237 PPID:7223 STATE:SN ELAPSED:00:03 THREADS:1 PROC_CPU:2.0% PROC_MEM:0.2% RSS:43956KB SYS_CPU:0.0% SYS_MEM:3.8% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:31] PID:7237 PPID:7223 STATE:SN ELAPSED:00:04 THREADS:1 PROC_CPU:1.4% PROC_MEM:0.2% RSS:43956KB SYS_CPU:0.0% SYS_MEM:3.8% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:32] PID:7237 PPID:7223 STATE:SN ELAPSED:00:05 THREADS:1 PROC_CPU:1.8% PROC_MEM:0.4% RSS:69560KB SYS_CPU:1.6% SYS_MEM:4.0% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:34] PID:7237 PPID:7223 STATE:SN ELAPSED:00:07 THREADS:1 PROC_CPU:1.5% PROC_MEM:0.4% RSS:69560KB SYS_CPU:0.0% SYS_MEM:4.1% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:35] PID:7237 PPID:7223 STATE:SN ELAPSED:00:08 THREADS:1 PROC_CPU:1.6% PROC_MEM:0.5% RSS:95164KB SYS_CPU:1.6% SYS_MEM:4.2% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:36] PID:7237 PPID:7223 STATE:SN ELAPSED:00:09 THREADS:1 PROC_CPU:1.4% PROC_MEM:0.5% RSS:95164KB SYS_CPU:0.0% SYS_MEM:4.2% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
[2026-09-10 16:19:38] PID:7237 PPID:7223 STATE:SN ELAPSED:00:10 THREADS:1 PROC_CPU:1.2% PROC_MEM:0.5% RSS:95164KB SYS_CPU:0.0% SYS_MEM:4.1% DISK_USED:1% PORT:15034 FIREWALL:active CMD:/workspace/bin/agent-leak-app-x86
```

#### (2) 프로그램 실행 로그 ([before-app.log](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-app.log))

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
2026-09-10 16:19:27,094 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-09-10 16:19:27,094 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 100MB 		[ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 50%  		[ OK ]
 [ THREAD ] Concurrency: True 		[ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-09-10 16:19:29,137 [INFO] [MemoryWorker] Current Heap: 25MB
2026-09-10 16:19:32,188 [INFO] [MemoryWorker] Current Heap: 50MB
2026-09-10 16:19:35,242 [INFO] [MemoryWorker] Current Heap: 75MB
2026-09-10 16:19:38,288 [INFO] [MemoryWorker] Current Heap: 100MB
2026-09-10 16:19:38,288 [CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB) / (Recommend Over 256MB)
2026-09-10 16:19:38,288 [CRITICAL] [MemoryGuard] Self-terminating process 7237 to prevent system instability.
```

#### (3) 시계열 데이터 요약 ([before-timeseries.csv](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-timeseries.csv))

| 시각 (Timestamp) | 프로세스 CPU (%) | 시스템 CPU (%) | RSS (KB) | RSS 환산 (MB) | 프로세스 상태 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 16:19:27 | 4.3 | 1.6 | 18,352 | ~17.9 MB | `SN` |
| 16:19:29 | 3.1 | 0.0 | 43,956 | ~42.9 MB | `SN` |
| 16:19:30 | 2.0 | 0.0 | 43,956 | ~42.9 MB | `SN` |
| 16:19:31 | 1.4 | 0.0 | 43,956 | ~42.9 MB | `SN` |
| 16:19:32 | 1.8 | 1.6 | 69,560 | ~67.9 MB | `SN` |
| 16:19:34 | 1.5 | 0.0 | 69,560 | ~67.9 MB | `SN` |
| 16:19:35 | 1.6 | 1.6 | 95,164 | ~92.9 MB | `SN` |
| 16:19:36 | 1.4 | 0.0 | 95,164 | ~92.9 MB | `SN` |
| 16:19:38 | 1.2 | 0.0 | 95,164 | ~92.9 MB | `SN` |

#### (4) 관련 증적 파일 목록
- [before-app.log](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-app.log)
- [before-monitor.log](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-monitor.log)
- [before-timeseries.csv](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-timeseries.csv)
- [before-report-snippet.md](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-report-snippet.md)
- [before-env-snapshot.txt](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/before-env-snapshot.txt)

---

### 3. Root Cause Analysis

#### (1) 증거로 직접 확인한 사실
1. **계단식 메모리 증가**: 관제 데이터(`monitor.log`) 상에서 프로세스의 물리 메모리 사용량(RSS)이 초기 `18,352KB`에서 약 3초 간격으로 `+25,604KB`씩 계단식으로 급증(`18MB` ➔ `43MB` ➔ `69MB` ➔ `95MB`)함.
2. **할당 주기와 일치**: 앱 로그(`before-app.log`)에서 `MemoryWorker`가 약 3초 간격으로 정확히 `Current Heap: 25MB ➔ 50MB ➔ 75MB ➔ 100MB`를 기록하며, 메모리가 한 번도 해제(Free/GC)되지 않음.
3. **임계치 도달 즉시 자가 종료**: 힙 메모리가 `100MB`에 도달한 `16:19:38`에 `[CRITICAL] [MemoryGuard] Memory limit exceeded (100MB >= 100MB)` 로그가 출력되고 프로세스 `7237`이 즉각 종료됨.

#### (2) 증거를 바탕으로 추론한 원인
- **애플리케이션 레벨 메모리 누수(Memory Leak)**: `MemoryWorker`가 반복 작업 수행 시 25MB 크기의 청크(Chunk) 데이터를 동적 생성한 후 참조를 해제하지 않아 힙 메모리에 영구 적재되고 있음.
- **MemoryGuard에 의한 의도된 강제 종료**: 운영체제 커널의 OOM Killer가 동작하기 전, 애플리케이션에 내장된 자체 보호 루틴(`MemoryGuard`)이 `MEMORY_LIMIT` 초과를 감지하고 시스템 전체 불능 상태를 막기 위해 스스로 프로세스를 `exit`/`SIGKILL` 처리함.

#### (3) 관련 운영체제 동작 원리
- **가상 메모리와 RSS (Resident Set Size)**:
  - 프로세스는 가상 메모리 공간(VSZ)을 할당받지만, 실제로 물리 RAM(프레임)을 차지하는 영역은 **RSS**이다.
  - `MemoryWorker`가 힙(Heap) 메모리를 동적으로 할당하고 쓰기 작업을 수행하면서 페이지 폴트(Page Fault)가 발생하고, OS 페이지 테이블에 물리 메모리가 매핑되어 RSS가 비례 증가함.
- **애플리케이션 보호(MemoryGuard) vs 커널 OOM Killer**:
  - 본 장애는 리눅스 커널의 OOM Killer에 의해 강제 피살된 것이 아니라, 애플리케이션 레벨의 감시자(`MemoryGuard`)가 프로세스를 안전하게 종료한 것이다.
  - 하지만 이를 방치하여 `MemoryGuard` 임계치를 해제하거나 매우 높게 잡을 경우, 물리 RAM이 고갈되어 커널 OOM Killer가 `badness score`에 따라 다른 필수 서비스나 시스템 프로세스까지 임의로 종료시키는 대형 시스템 장애로 번질 위험이 있다.

---

### 4. Workaround & Verification

#### (1) 변경한 환경변수
- `MEMORY_LIMIT`: `100` ➔ `256` (MB)
- (앱 로그의 경고문 `[ WARNING: Recommend Over 256MB ]`을 반영하여 256MB로 증설)

#### (2) 변경 전 결과 (`oom-before`)
- **생존 시간**: **11초** (16:19:27 ~ 16:19:38)
- **최종 RSS**: **95,164 KB** (~92.9 MB)
- **종료 시점 힙 사용량**: **100MB** (`100MB >= 100MB`)
- **수집 로그 행수**: 9개 행

#### (3) 변경 후 결과 (`oom-after`)
- **생존 시간**: **31초** (16:43:52 ~ 16:44:23)
- **최종 RSS**: **274,268 KB** (~267.8 MB)
- **종료 시점 힙 사용량**: **275MB** (`275MB >= 256MB`)
- **수집 로그 행수**: 26개 행
- **관찰 로그 ([after-app.log](file:///Users/08022220523/Documents/Codyssey-B1-2/evidence/oom/after-app.log))**:
  ```text
  2026-09-10 16:44:20,769 [INFO] [MemoryWorker] Current Heap: 250MB
  2026-09-10 16:44:23,823 [INFO] [MemoryWorker] Current Heap: 275MB
  2026-09-10 16:44:23,823 [CRITICAL] [MemoryGuard] Memory limit exceeded (275MB >= 256MB) / (Recommend Over 256MB)
  2026-09-10 16:44:23,823 [CRITICAL] [MemoryGuard] Self-terminating process 8117 to prevent system instability.
  ```

#### (4) Before & After 비교 요약

| 비교 지표 | Before (`MEMORY_LIMIT=100`) | After (`MEMORY_LIMIT=256`) | 변화 분석 |
| :--- | :---: | :---: | :--- |
| **생존 시간** | 11 초 | 31 초 | **+20 초 (+181% 연장)** |
| **시작 RSS** | 18,352 KB | 18,228 KB | 기동 시 기본 메모리는 동일 (~18MB) |
| **종료 직전 RSS** | 95,164 KB | 274,268 KB | 임계치까지 지속 증가 |
| **최종 도달 힙** | 100 MB | 275 MB | 25MB 청크 단위 누적 |
| **종료 원인** | Memory limit exceeded (100MB) | Memory limit exceeded (256MB) | **동일 원인으로 종료** |
| **프로세스 상태** | SELF-TERMINATED | SELF-TERMINATED | **자가 종료 재발** |

#### (5) 임시 조치의 한계
- `MEMORY_LIMIT`을 256MB로 상향하여 프로세스의 가동 유지 시간을 11초에서 31초로 연장하는 데는 성공하였다.
- 그러나 **메모리 사용량이 3초마다 25MB씩 누적되는 기울기(증가율)는 전혀 개선되지 않았으며**, 메모리가 275MB에 도달하는 순간 동일하게 `MemoryGuard`에 의해 비정상 종료되었다.
- 따라서 환경변수 증설은 장애 발생 시점을 일시적으로 유예하는 **임시 방편(Workaround)**일 뿐이며, 누수 자체가 해소되지 않는 한 근본적인 조치가 될 수 없다.

#### (6) 근본적인 해결 제안
1. **코드 레벨의 메모리 누수 수정 (Root Cause Fix)**:
   - `MemoryWorker`에서 청크 데이터를 처리한 후 전역 컨텍스트나 인메모리 리스트에 무한 보관하지 않고, 작업 종료 즉시 참조를 해제(`del` 또는 스코프 종료)하여 GC 대상이 되도록 리팩토링.
2. **캐시 크기 제한 (Bounded Cache Policy)**:
   - 무제한 메모리 할당 대신 크기 제한이 있는 LRU(Least Recently Used) 캐시 또는 순환 버퍼(Ring Buffer)를 적용하여 최대 점유 한도를 제한.
3. **사전 플러시 및 헬스체크 연동**:
   - 임계치 초과 시 즉시 강제 종료(Crash)하는 대신, 임계치 도달 전 80% 구간에서 메모리 캐시 플러시(`Cache Flush`)를 먼저 수행하고 알림(Alert)을 발송하는 점진적 복구 메커니즘 구축.
