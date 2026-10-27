# B1-2 시스템 장애 분석 및 트러블슈팅

이 미션에서는 Linux 환경에서 실행되는 `agent-leak-app`에서 `메모리 부족`, `CPU 과점유`, `교착상태`가 발생했을 때 원인을 찾는 방법을 학습한다. 프로그램이 종료되거나 멈췄다는 결과만 보는 것이 아니라, `05-monitor-app-resources.sh`, 프로그램 로그, Linux 명령어의 출력 결과를 증거로 사용한다.

각 장애를 재현한 뒤 관련 환경변수를 변경하여 다시 실행한다. 변경 전과 변경 후의 결과를 비교하고, 분석 내용을 `GitHub Issue` 형식의 기술 리포트 3건으로 작성한다.

<br>
<br>

## 최종 결과물

- [x] OOM Crash 분석 리포트 ([01-oom-report.md](./reports/01-oom-report.md))
- [x] CPU Latency 분석 리포트 ([02-cpu-report.md](./reports/02-cpu-report.md))
- [x] Deadlock 분석 리포트 ([03-deadlock-report.md](./reports/03-deadlock-report.md))
- [x] 각 장애의 Before & After 증거 ([evidence/](./evidence/))
- [x] 실행 방법과 실험 결과 정리 ([실행 방법](./docs/03-scripts.md#실행-방법), [결과 비교](#결과-비교))

<br>
<br>

## 미션 목표

### 학습 목표

- 메모리 구조를 이해하고, 메모리 누수가 시스템 전체에 미치는 영향을 설명할 수 있다.
- 특정 프로세스의 CPU 과점유가 시스템 지연을 유발하는 원리를 설명할 수 있다.
- 자원 경쟁으로 인해 발생하는 교착상태(Deadlock)의 개념을 이해하고, 프로세스가 멈춘 상태를 시스템 도구로 식별하여 진단할 수 있다.
- 로그와 관제 데이터를 증거로 제시하여 육하원칙에 맞게 장애 상황을 기술하고, GitHub Issue를 통해 동료 개발자와 명확하게 소통할 수 있다.

### 장애 분석 흐름

1. 실행 환경과 환경변수를 확인한다.
2. `agent-leak-app`과 `05-monitor-app-resources.sh`를 실행한다.
3. 프로세스의 CPU 사용률과 메모리 사용량을 관찰한다.
4. 장애가 발생한 시점의 로그와 명령어 출력을 수집한다.
5. 수집한 증거를 바탕으로 장애 원인을 추론한다.
6. 장애와 관련된 환경변수 하나만 변경한다.
7. 같은 조건에서 프로그램을 다시 실행한다.
8. 변경 전후의 생존 시간, 자원 사용량, 종료 여부를 비교한다.
9. 분석 결과를 장애 리포트로 작성한다.

한 번의 실험에서 여러 환경변수를 동시에 변경하지 않는다. 여러 값을 함께 변경하면 어떤 설정이 결과에 영향을 주었는지 판단하기 어렵기 때문이다.

<br>
<br>

## 요구사항별 수행 내용

| 요구사항 | 수행 내용 | 확인 위치 |
|---|---|---|
| 실행 조건 충족 | 일반 사용자(`agentuser`), 필수 환경변수, 디렉터리, `secret.key`, `0.0.0.0:15034` 바인딩을 스크립트로 준비 | [02-environment.md](./docs/02-environment.md), [02-provision-runtime.sh](./scripts/02-provision-runtime.sh) |
| OOM 증거 | 관제 로그의 RSS 상승 수치, `Memory limit exceeded` / `SELF-TERMINATED` 로그, `MEMORY_LIMIT` 100 → 256 두 번 실행 비교 | [01-oom-report.md](./reports/01-oom-report.md), [evidence/oom/](./evidence/oom/) |
| CPU 증거 | 부하 상승 구간(관제 로그, `ps`, `top`), 종료 로그, `CPU_MAX_OCCUPY` 90 → 50 비교 | [02-cpu-report.md](./reports/02-cpu-report.md), [evidence/cpu/](./evidence/cpu/) |
| Deadlock 증거 | 120초 동안 PID 유지, 관제 로그의 CPU/RSS 정체와 `THREADS:3` `STATE:SNl` 유지, 마지막 `WAITING ... BLOCKED` 로그, 순환 대기 추론, `MULTI_THREAD_ENABLE` true → false 비교 | [03-deadlock-report.md](./reports/03-deadlock-report.md), [evidence/deadlock/](./evidence/deadlock/) |
| 리포트 형식 | 세 리포트 모두 `[Bug]` 제목, Description / Evidence & Logs / Root Cause Analysis / Workaround & Verification 구조 | [reports/](./reports/) |
| 관련 OS 동작 원리 | 메모리 누수, RSS, Watchdog, SIGTERM, Deadlock 4대 조건, Lock | [01-concepts.md](./docs/01-concepts.md) |
| 표준 명령어 사용 | `ps`, `top`, `kill`, 관제 스크립트만 사용. 바이너리 디컴파일 없음 | [04-analysis.md](./docs/04-analysis.md#증거-수집-명령어) |

<br>
<br>

## 빠른 실행

레포 루트에서 실행한다. 컨테이너 준비부터 6개 케이스 실험, 증거 저장까지 한 번에 진행된다.

```bash
# 전체: 셋업 + 6개 실험 (약 8분)
bash scripts/00-run-all-experiments.sh

# 특정 케이스만
bash scripts/00-run-all-experiments.sh cpu-before cpu-after

# 셋업 없이 특정 케이스만 (컨테이너가 이미 준비된 경우)
SKIP_SETUP=1 bash scripts/00-run-all-experiments.sh deadlock-before
```

단계별 개별 실행, 케이스별 설정값, 관제 로그 형식은 [03-scripts.md](./docs/03-scripts.md)에 정리했다.

<br>
<br>

## 결과 비교

### Before와 After 기록

2026-10-13 `bash scripts/00-run-all-experiments.sh` 실행 결과이다. 자세한 분석은 각 리포트를 참고한다.

| 장애 | 변경 환경변수 | Before | After | 리포트 |
|---|---|---|---|---|
| OOM | `MEMORY_LIMIT` 100 → 256 | 약 11초 생존, RSS 102,432KB에서 `Memory limit exceeded (100MB >= 100MB)`로 자가 종료 | 약 32초 생존, RSS 281,660KB에서 `Memory limit exceeded (275MB >= 256MB)`로 자가 종료. 증가 속도(25MB/3초)는 동일 | [01](./reports/01-oom-report.md) |
| CPU | `CPU_MAX_OCCUPY` 90 → 50 | 앱 보고 부하 5% → 51.29% 상승 후 `CPU Threshold Violated!`로 약 30초 만에 종료 | 50%에서 cooldown 반복, 120초 관찰 동안 종료 없음 (타임아웃으로 중단) | [02](./reports/02-cpu-report.md) |
| Deadlock | `MULTI_THREAD_ENABLE` true → false | 9초 후 두 스레드 `WAITING ... BLOCKED`, 이후 로그 정지·CPU 0.1%·PID 유지 (120초 무응답) | Lock 경합 없이 로그 계속 진행, 120초 관찰 동안 정상 동작 (타임아웃으로 중단) | [03](./reports/03-deadlock-report.md) |

- CPU 실험에서 OS 지표(`ps`/`top`)의 실제 CPU 사용률은 0~12%로 낮았다. 앱 로그의 `Current Load`는 앱 내부 계산값으로 보이며, CPU 장애 판단은 앱 로그를 근거로 했다.

<br>
<br>

## 상세 문서

| 문서 | 내용 |
|---|---|
| [01-concepts.md](./docs/01-concepts.md) | 프로세스, PID, OOM, 메모리 누수, RSS, MemoryGuard, CPU 과점유, Watchdog, Deadlock, Lock |
| [02-environment.md](./docs/02-environment.md) | 실행 필수 조건, 환경변수 예시, 필수 디렉터리와 파일 생성 |
| [03-scripts.md](./docs/03-scripts.md) | Repository 구조, 스크립트별 역할, 실행 방법, 케이스별 설정값, 관제 로그 지표 |
| [04-analysis.md](./docs/04-analysis.md) | 장애 유형별 분석 절차, 증거 수집 명령어, 리포트 템플릿, 관측 사실과 추론 구분 |
| [05-study.md](./docs/05-study.md) | 일반 사용자 실행 이유, Heap과 Stack, OOM Killer, 누수 해결 방법, 운영 환경 완화책 |
