# [PRD] Project: Operation Cat-mosphere (v2.0)

**Description:** 인류가 사라진 지구에서 '치즈냥이' 대장과 고양이 군단이 외계 젤리 생명체로부터 참치 캔 창고를 지키는 액션 건설 디펜스 게임입니다 [cite: 1].

---

## 1. Core System Architecture

### 1.1 Phase Manager (Game Loop)
* **Day Phase (Construction):** 영웅 조종을 통한 필드 자원(스크랩, 캣닢) 수집 및 모듈형 캣타워 건설/수리를 진행합니다 [cite: 1].
* **Night Phase (Combat):** 120초간 지속되는 대규모 웨이브 방어와 실시간 영웅 액션(냥펀치, 패링, 스킬 사용)이 핵심입니다 [cite: 1].
* **Dawn Phase (Reward):** 로그라이크 카드(츄르 박스) 3택 1 시스템을 통해 이번 판의 버프를 선택합니다 [cite: 1].

### 1.2 Modular Tower System
* **Stacking Logic:** [토대 - 층 - 옥상] 순서로 수직 적층하며 자유로운 설계가 가능합니다 [cite: 1].
* **Height Physics:** 층수가 높아질수록 사거리와 치명타율이 증가하나, 특정 하중 초과나 적의 충격 시 붕괴 판정이 발생할 수 있습니다 [cite: 1].
* **Layer Synergy:** 인접한 층의 고양이 종류에 따라 버프(예: 연사력 증가)가 발동하는 시스템입니다.

### 1.3 Tower Stacking Formula
* **최대 층수:** 5층 (토대 1 + 추가 층 3 + 옥상 1)
* **적층 비용:** 모든 층 = 건설 비용 (균일 비용). 적층 vs 분산 배치 간 전략적 선택을 유도하기 위해 층수 배율을 적용하지 않음.
* **사거리 보너스:** `effective_range = base_range × (1.0 + (floor - 1) × 0.15)` — 층당 +15%
* **치명타율:** `crit_chance = 0.05 + (floor - 1) × 0.05` — 기본 5%, 층당 +5%, 최대 25% (5층)
* **치명타 배율:** 2.0x (고정)
* **붕괴 시스템:**
    * 하중 = 현재 총 층수. 내구 임계값 = 토대 HP의 40%.
    * 토대 HP가 임계값 이하로 떨어지면 최상층부터 1층씩 붕괴 (2초 간격).
    * 붕괴된 층은 파괴되며 자원 반환 없음.
    * Elite(Steel Can Gate) 충격 공격: 토대에 ATK × 2 = 고정 50 데미지 (일반 적은 타워를 공격하지 않음).

> **적층 비용 예시 (Fish Bone, 건설 비용 60):** 1층 60 → 2층 +60 → 3층 +60 → 4층 +60 → 5층 +60 = 풀스택 총 300 Scrap

---

## 2. [P0] Combat Statistics & Balance

### 2.1 Hero Baseline Stats
* **HP:** 100 / **ATK:** 10 (per hit) / **Attack Speed:** 1.2 hits/s / **Range:** 2.0 / **SPD:** 5.0
* **냥펀치:** ATK × 2.0 = 20 데미지, 쿨다운 0.5초, 근접 범위 1.5
* **패링:** 투사체를 반사하며 0.3초 판정 프레임, 성공 시 반사 데미지 = 원본 × 1.5, 쿨다운 3초
* **Ultimate (치즈냥이의 포효):** 화면 전체 ATK × 10 = 100 데미지 + 5초 무적, 1스테이지당 1회

### 2.2 Tower Stat Table
| Tower | Type | HP | ATK | Fire Rate | Range | DPS | Build Cost | Repair Cost |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Fish Bone Launcher** | Low-tech | 150 | 5 | 2.0/s | 10 | 10.0 | 60 Scrap | 20 Scrap |
| **Plasma Laser** | Hi-tech | 120 | 8 | 1.0/s | 12 | 8.0 | 80 Scrap | 30 Scrap |
| **Mjolnir Coil** | Mystic | 100 | 12 | 0.6/s | 8 | 7.2 | 100 Scrap | 35 Scrap |

> **설계 의도:** Low-tech = 연사 DPS형, Hi-tech = 장거리 관통형, Mystic = 저연사 고데미지 + 스턴(0.5초, 10초 쿨다운)

### 2.3 Enemy Stat Table
| Unit | Class | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Jelly Slime** | Swarm | 20 | 2.5 | 1 | 가장 기본적인 물량 개체입니다. |
| **Jelly Carrier** | Swarm | 100 | 1.5 | 10 | 처치 시 꼬마 슬라임 5마리를 생성합니다. |
| **Laser Pointer** | Gimmick | 60 | 2.0 | 15 | 타워의 시선을 분산시키는 기믹을 가집니다. |
| **Mirror Craft** | Counter | 80 | 3.0 | 20 | 하이테크 레이저 공격을 반사합니다. |
| **Steel Can Gate** | Elite | 400 | 1.0 | 50 | 높은 방어력을 가진 탱크형 유닛입니다. |
| *(꼬마 슬라임)* | Swarm | 8 | 3.0 | 0 | Jelly Carrier 처치 시 생성, 보상 없음 |

> **Defense Type 분류:** Normal = Jelly Slime, Jelly Carrier, Laser Pointer, 꼬마 슬라임 / Mirror = Mirror Craft / Steel Can = Steel Can Gate
> 향후 적 추가 시 Defense Type(Normal, Mirror, Steel Can) 중 하나를 부여하여 배율표를 적용합니다.

### 2.4 Damage Multiplier Matrix
| Attack \ Defense | Normal | Mirror | Steel Can |
| :--- | :--- | :--- | :--- |
| **Low-tech (Physical)** | 1.0x | 1.5x | 0.5x |
| **Hi-tech (Laser)** | 1.5x | **-1.0x (Reflect)** | 0.2x |
| **Mystic (Lightning)** | 1.0x | 1.2x | 1.5x |

---

## 3. [P0] Wave Timeline (Stage 1~5)

스폰 경로는 1개 (좌→우 단일 경로). Stage 5에서 상/하 2경로 분기.

### Stage 1 — Tutorial (초기 Scrap: 200)
| 시간 | 적 | 수량 | 간격 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 0~60s | Jelly Slime | 20 | 3.0s | 전반 물량, 타워 건설 학습 |
| 65~120s | Jelly Slime | 20 | 2.75s | 후반 가속, 총 40기 |

> 예상 획득: Essence 40, Scrap 드랍 없음 (낮에만 수집)

### Stage 2 — Mass (초기 Scrap: 220)
| 시간 | 적 | 수량 | 간격 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 0~50s | Jelly Slime | 25 | 2.0s | 전반 러시 |
| 55~75s | Jelly Slime | 15 | 1.3s | 중반 가속 |
| 80s | Jelly Carrier | 2 | 3.0s | 처치 시 꼬마 슬라임 ×5 = +10기 |
| 90~120s | Jelly Slime | 10 | 3.0s | 마무리 물량, 총 52기(+꼬마 10) |

### Stage 3 — Gimmick (초기 Scrap: 240)
| 시간 | 적 | 수량 | 간격 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 0~25s | Jelly Slime | 15 | 1.7s | 전초전 |
| 30s | Laser Pointer | 2 | 1.0s | **1차 기습** — 타워 시선 분산 |
| 35~85s | Jelly Slime | 25 | 2.0s | 분산 상태에서 물량 압박 |
| 90s | Laser Pointer | 3 | 1.0s | **2차 기습** — 강화 |
| 95~120s | Jelly Slime | 10 | 2.5s | 마무리, 총 슬라임 50 + 포인터 5 |

### Stage 4 — Counter (초기 Scrap: 260)
| 시간 | 적 | 수량 | 간격 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 0~30s | Jelly Slime | 15 | 2.0s | 전초전 |
| 35~60s | Mirror Craft | 5 | 5.0s | **레이저 반사 학습** — Low-tech/Mystic 필수 |
| 65~90s | Mirror Craft + Jelly Slime | 3 + 15 | 4.0s / 1.7s | 혼합 압박 |
| 95~120s | Mirror Craft | 4 | 6.0s | 마무리, 총 거울 12 + 슬라임 30 |

### Stage 5 — Mini-Boss (초기 Scrap: 300, 2경로 분기)
| 시간 | 적 | 수량 | 간격 | 경로 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 0~40s | Jelly Slime | 20 | 2.0s | 상/하 랜덤 | 전초전 |
| 45~70s | Jelly Carrier | 3 | 8.0s | 상 경로 | 꼬마 슬라임 +15 |
| 45~70s | Mirror Craft | 4 | 6.0s | 하 경로 | 동시 압박 |
| 75~95s | Laser Pointer | 3 | 7.0s | 상/하 랜덤 | 시선 분산 |
| 100s | **Steel Can Gate** | 3 | 4.0s | 하 경로 | **미니보스 — Mystic 필수** |
| 105~120s | Jelly Slime | 10 | 1.5s | 상/하 랜덤 | 최종 러시 |

---

## 4. Entity & Resource Data

### 4.1 Resource Economy
| Resource | 용도 | 획득 방법 | 초기 지급 |
| :--- | :--- | :--- | :--- |
| **Box Scrap** | 타워 건설/수리/적층 | 낮: 필드 수집 (60~100개/Day), 밤: 웨이브 클리어 보너스 20개 | Stage별 상이 (200~300) |
| **Jelly Essence** | 영웅 레벨업 | 밤: 적 처치 시 확정 드랍 (적 테이블 참조) | 0 |
| **Catnip** | 영구 기술 연구 (Cat HQ) | 낮: 필드 희귀 수집 (0~3개/Day, 확률) | 0 |

### 4.2 Economy Balance Check (Stage 1 기준)
* **수입:** 초기 200 Scrap + 웨이브 클리어 보너스 20 = 220 Scrap (밤 중 사용 가능)
* **지출 예시:** Fish Bone 타워 2기 = 120, 여유 100 → 1기 추가 건설 or 기존 타워 적층(+60/층)
* **DPS 검산:** Fish Bone 2기 × 10 DPS = 20 DPS, 120초간 총 출력 2400 → 슬라임 40기 × HP 20 = 800 필요 → **여유 있음** (튜토리얼 의도)
* **Stage 5 검산:** Steel Can Gate HP 400 × 0.5x(Low-tech) = 실질 HP 800 per gate, 3기 = 2400 → Mystic DPS 7.2 × 1.5x = 10.8 실질 DPS, 20초 내 3기 처리 불가 → **영웅 개입 + 복합 타워 필수** (의도된 난이도)

### 4.3 Hero: Cheese Cat (Leader)
* **Traits:** 노랑/흰색 무늬와 흰 발(양말)이 특징인 코리안 숏헤어입니다 [cite: 1].
* **Skill Tree:** Striker(물리), Commander(타워 버프), Master(건설/수리) 경로로 성장합니다 [cite: 1].
* **Ultimate:** 화면 전체를 소탕하고 무적 상태를 부여하는 "치즈냥이의 포효"를 사용합니다 [cite: 1].

---

## 5. Technical Request for AI Developer (Claude Code)

### P0 Implementation Prompt:
"위 수치 테이블과 웨이브 타임라인을 기반으로 디펜스 시스템을 구현해줘.
1. `DamageCalculator`: Section 2.4 배율표 + Defense Type 기반 데미지 계산. Hi-tech → Mirror 반사(-1.0x)는 발사 타워에 데미지를 되돌림.
2. `WaveManager`: 120초 타이머 + Section 3 타임라인 데이터를 읽어 시간/간격/경로에 맞춰 스폰. Stage 5부터 2경로 분기 지원.
3. `ModularTower`: Section 1.3 적층 공식으로 사거리/치명타 실시간 계산. 토대 HP 40% 이하 시 최상층부터 붕괴.
4. `EnemyPool`: Swarm 수백 기를 처리하기 위한 Object Pooling. 꼬마 슬라임(Carrier 파생)도 풀에서 재활용.
5. `ResourceManager`: Section 4.1 자원 테이블 기반 수입/지출 관리. 건설/적층/수리 비용 차감 + 웨이브 보너스 지급."
