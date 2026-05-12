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
    * 타워 공격 적(Steel Can Gate, Plasma Drone, Iron Express 등): 토대에 고정 데미지 (일반 적은 타워를 공격하지 않음).

> **적층 비용 예시 (Fish Bone, 건설 비용 60):** 1층 60 → 2층 +60 → 3층 +60 → 4층 +60 → 5층 +60 = 풀스택 총 300 Scrap

---

## 2. [P0] Combat Statistics & Balance

### 2.1 Hero Baseline Stats
* **HP:** 100 / **ATK:** 10 (per hit) / **Attack Speed:** 1.2 hits/s / **Range:** 2.0 / **SPD:** 5.0
* **냥펀치:** ATK × 2.0 = 20 데미지, 쿨다운 0.5초, 근접 범위 1.5
* **패링:** 투사체를 반사하며 0.3초 판정 프레임, 성공 시 반사 데미지 = 원본 × 1.5, 쿨다운 3초
* **Ultimate (치즈냥이의 포효):** 화면 전체 ATK × 10 = 100 데미지 + 5초 무적, 1스테이지당 1회

### 2.2 Tower Stat Table

각 Attack Type별 단일타겟형(기본)과 다중타겟형(해금) 2종씩, 총 6종으로 구성됩니다.

#### 기본 타워 (Map 01~)
| Tower | Type | HP | ATK | Fire Rate | Range | DPS(1체) | Build Cost | Repair Cost |
| :--- | :--- | ---: | ---: | :--- | ---: | ---: | :--- | :--- |
| **Fish Bone Launcher** | Low-tech | 150 | 5 | 2.0/s | 150 | 10.0 | 60 Scrap | 20 Scrap |
| **Plasma Laser** | Hi-tech | 120 | 8 | 1.0/s | 180 | 8.0 | 80 Scrap | 30 Scrap |
| **Mjolnir Coil** | Mystic | 100 | 12 | 0.6/s | 120 | 7.2 | 100 Scrap | 35 Scrap |

> **설계 의도:** Fish Bone = 연사 단일타겟 DPS, Plasma = 장거리 정밀 사격, Mjolnir = 저연사 고데미지 + 스턴(0.5초, 10초 쿨다운)

#### 해금 타워
| Tower | Type | HP | ATK | Fire Rate | Range | DPS(1체) | Build Cost | Repair Cost | 해금 |
| :--- | :--- | ---: | ---: | :--- | ---: | ---: | :--- | :--- | :--- |
| **Hairball Mortar** | Low-tech | 130 | 8 | 0.6/s | 120 | 4.8 | 80 Scrap | 25 Scrap | Map 02 |
| **Prism Array** | Hi-tech | 100 | 6 | 0.8/s | 150 | 4.8 | 100 Scrap | 35 Scrap | Map 04 |
| **Spirit Lantern** | Mystic | 90 | 7 | 0.8/s | 130 | 5.6 | 120 Scrap | 40 Scrap | Map 06 |

> **설계 의도:** 해금 타워는 단일타겟 DPS가 기본 타워 대비 낮으나(40~60%), 다중타겟 특성으로 보상합니다. 같은 Attack Type 내에서 "엘리트 1체 집중 vs 물량 다수 소탕"의 선택지를 제공합니다.

### 2.2.1 Tower Mechanic Details

#### Hairball Mortar (Low-tech AoE)
* **폭발 반경:** 60px. 범위 내 모든 적에게 동일 데미지를 가합니다.
* **투사체:** 포물선 궤적, 속도 300 (Fish Bone의 500보다 느림).
* **역할:** Swarm 소탕 특화. Jelly Sprinter(SPD 4.5) 밀집 투입 시 핵심 대응.
* **밸런스:** Slime 5기 밀집 시 8 × 1.0x × 5체 × 0.6/s = 24.0 유효 DPS (Fish Bone 10.0의 2.4배). 단일 엘리트에는 DPS 4.8로 Fish Bone 대비 절반 이하.
* **적층 시너지:** 사거리 120 → 5층 시 192px. 크릿(2.0x) 시 16 × 범위 적중 = 대규모 피해.

#### Prism Array (Hi-tech Pierce)
* **관통 빔:** 사거리 끝까지 직선 관통, 경로 위 모든 적에게 동일 데미지.
* **투사체:** 즉발 빔.
* **Mirror 위험:** 빔 경로 상 Mirror 적 적중 시 **반사 발동** — 이후 관통 중단, 타워에 피해 귀환.
* **역할:** 종대 편대(한 줄 진격) 관통. Normal 밀집 시 극히 유효.
* **밸런스:** Normal 3체 관통 시 6 × 1.5x × 3체 × 0.8/s = 21.6 유효 DPS (Plasma 12.0의 1.8배). Mirror 1기라도 섞이면 반사 위험 → 편대 구성 확인 후 배치 판단 필수.

#### Spirit Lantern (Mystic Chain + Detection)
* **체인 번개:** 주 타겟 적중 후 80px 이내 적 2체에 순차 연쇄. 바운스당 데미지 70% 감쇠 (1차: 7 → 2차: 4.9 → 3차: 3.4, 총 15.3/발).
* **투사체:** 속도 700 (번개).
* **은신 감지:** 사거리 내 Shadow Jelly를 자동 감지하여 타겟 가능. 감지된 적은 다른 타워도 공격할 수 있습니다.
* **역할:** 혼합 웨이브 대응 + Shadow Jelly 카운터.
* **밸런스:** Steel Can 3체 연쇄 시 15.3 × 1.5x × 0.8/s = 18.4 유효 DPS (Mjolnir 10.8의 1.7배). 스턴 없음(Mjolnir 고유) — 단일 보스/엘리트에는 Mjolnir가 우위.

### 2.3 Enemy Stat Table

**Enemy Class:** Swarm, Gimmick, Counter, Elite, Support
**Defense Type:** Normal, Mirror, Steel Can — 배율표(§2.4) 적용

#### 기본 로스터 (Map 01~)
| Unit | Class | Defense | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **Jelly Slime** | Swarm | Normal | 20 | 2.5 | 1 | 기본 물량 개체 |
| **Jelly Carrier** | Swarm | Normal | 100 | 1.5 | 10 | 처치 시 꼬마 슬라임 5마리 생성 |
| **Laser Pointer** | Gimmick | Normal | 60 | 2.0 | 15 | 타워 시선 분산 (어그로 강제) |
| **Mirror Craft** | Counter | Mirror | 80 | 3.0 | 20 | Hi-tech 공격 반사 |
| **Steel Can Gate** | Elite | Steel Can | 400 | 1.0 | 50 | 타워 공격 (50 고정 데미지) |
| *(꼬마 슬라임)* | Swarm | Normal | 8 | 3.0 | 0 | Carrier 파생, 보상 없음 |

#### Tier 1 — Map 02~03 합류
| Unit | Class | Defense | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **Jelly Sprinter** | Swarm | Normal | 12 | 4.5 | 2 | 초고속 돌파형 (§2.5.1) |
| **Gel Medic** | Support | Normal | 50 | 1.8 | 12 | 주변 아군 HP 회복 (§2.5.2) |
| **Shadow Jelly** | Gimmick | Normal | 35 | 2.0 | 8 | 근접까지 은신, 타겟 불가 (§2.5.3) |

#### Tier 2 — Map 04~06 합류
| Unit | Class | Defense | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **Plasma Drone** | Counter | Mirror | 70 | 2.5 | 25 | 비행 + 타워 원거리 공격 (§2.5.4) |
| **Gel Bomber** | Gimmick | Normal | 45 | 2.0 | 10 | 사망 시 슬로우 장판 생성 (§2.5.5) |
| **Volt Jelly** | Counter | Steel Can | 60 | 2.5 | 18 | 사망 시 전기 폭발, 타워 피해 (§2.5.6) |

#### Tier 3 — Map 07~09 합류
| Unit | Class | Defense | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **Storm Caller** | Support | Mirror | 90 | 1.5 | 30 | 주변 아군 속도 버프 오라 (§2.5.7) |
| **Cage Jelly** | Gimmick | Steel Can | 120 | 2.8 | 25 | 영웅 접촉 시 이동 구속 (§2.5.8) |
| **Iron Express** | Elite | Steel Can | 300 | 1.5 | 60 | 주기적 돌진, 타워 대형 피해 (§2.5.9) |

#### Tier 4 — Map 10~12 합류
| Unit | Class | Defense | HP | SPD | Essence | Mechanism |
| :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **Phase Shifter** | Counter | Mirror | 100 | 2.0 | 35 | 피격 누적 시 순간이동 (§2.5.10) |
| **Queen Jelly** | Elite | Normal | 250 | 0.8 | 80 | 생존 중 꼬마 슬라임 지속 생산 (§2.5.11) |
| **Gravity Blob** | Elite | Steel Can | 350 | 1.2 | 70 | 투사체 빗나감 중력장 (§2.5.12) |

> **Defense Type 분포:** Normal 9종 / Mirror 4종 / Steel Can 5종
> **역할 분포:** Swarm 4종 / Gimmick 5종 / Counter 4종 / Elite 4종 / Support 2종

### 2.4 Damage Multiplier Matrix
| Attack \ Defense | Normal | Mirror | Steel Can |
| :--- | :--- | :--- | :--- |
| **Low-tech (Physical)** | 1.0x | 1.5x | 0.5x |
| **Hi-tech (Laser)** | 1.5x | **-1.0x (Reflect)** | 0.2x |
| **Mystic (Lightning)** | 1.0x | 1.2x | 1.5x |

### 2.5 Enemy Mechanic Details

#### 2.5.1 Jelly Sprinter
* **역할:** 초고속 돌파. 타워 사각지대와 교전 중 빈틈을 이용해 기지에 도달합니다.
* **밸런스:** Fish Bone 사거리(150px) 내 체류 ≈ 0.56초 → 1~2발 사격 가능. HP 12로 2발 이상 필요하여 밀집 투입 시 누수가 발생합니다.

#### 2.5.2 Gel Medic
* **치유량:** 5 HP/초
* **치유 범위:** 100px
* **자체 공격:** 없음
* **역할:** Jelly Slime(HP 20)을 4초 만에 풀회복합니다. 우선 처치하지 않으면 물량 소모전에서 불리해집니다.
* **밸런스:** Fish Bone 10 DPS vs HP 50 → 5초 소요. 그 동안 주변 적 약 35 HP를 회복합니다.

#### 2.5.3 Shadow Jelly
* **은신:** 타워 유효 사거리의 60% 이내 진입 시 은신이 해제됩니다. 해제 후에는 영구 가시 상태입니다.
* **역할:** Fish Bone(150px) 기준 90px에서 가시화 → 체류 약 0.75초. HP 35로 생존 확률이 높습니다.
* **대응:** 영웅 펀치(20 dmg)로 즉시 처리 가능하여, 영웅 포지셔닝의 중요도가 상승합니다.

#### 2.5.4 Plasma Drone
* **비행:** 경로(Path)를 무시하고 맵 가장자리에서 기지 방향으로 직선 이동합니다.
* **타워 공격:** ATK 8, 간격 2.0초 (4 DPS). 사거리 내 가장 가까운 타워를 공격합니다.
* **Mirror 방어:** Hi-tech 사용 시 자기 타워에 반사 피해 → Low-tech(1.5x) 또는 Mystic(1.2x) 사용 필수.
* **밸런스:** Low-tech 실질 DPS 15 vs HP 70 → 4.7초 처치. 그 동안 타워에 약 18 피해.

#### 2.5.5 Gel Bomber
* **사망 장판:** 반경 60px, 지속 5초, 영웅 이동속도 -50%.
* **역할:** 물량 진입 전 선발대로 투입하여 영웅 기동력을 제한합니다. 타워에는 영향 없습니다.

#### 2.5.6 Volt Jelly
* **사망 폭발:** 반경 100px, 타워에 30 고정 데미지.
* **역할:** 타워 밀집 배치 시 페널티를 부여합니다. 분산 배치 또는 Mystic으로 원거리 격파하여 대응합니다.
* **밸런스:** Steel Can 방어 — Low-tech 실질 HP 120, Hi-tech 실질 HP 300, **Mystic 실질 HP 40**. 폭발 30은 타워 HP(100~150)의 20~30%.

#### 2.5.7 Storm Caller
* **속도 오라:** 반경 120px 내 아군 SPD +50%.
* **비 맵 강화:** Map 07(비 내리는 지붕 위)에서 오라 효과가 SPD +100%로 증폭됩니다.
* **역할:** Slime SPD 2.5 → 3.75(일반) / 5.0(비 맵). 최우선 처치 대상입니다.
* **밸런스:** Mirror 방어 — Low-tech 1.5x(실질 HP 60), Mystic 1.2x(실질 HP 75).

#### 2.5.8 Cage Jelly
* **구속:** 영웅에게 접촉 시 2초간 이동 불가.
* **구속 쿨다운:** 8초.
* **역할:** 물량과 동시 투입하여 영웅을 무력화합니다. 패링/궁극기 타이밍 관리를 강요합니다.
* **밸런스:** Steel Can 방어 — Mystic 1.5x(실질 HP 80), Low-tech 0.5x(실질 HP 240).

#### 2.5.9 Iron Express
* **통상 속도:** SPD 1.5
* **돌진:** 10초 간격으로 SPD 6.0 돌진 발동. 경로 위 첫 번째 타워에 80 고정 데미지.
* **역할:** Steel Can Gate의 상위 호환 위협. 돌진 타이밍에 맞춘 타워 수리/영웅 개입이 필요합니다.
* **밸런스:** Steel Can 방어 — Mystic 실질 HP 200. Mjolnir 2기 집중(21.6 DPS) → 약 9.3초 처치. 그 동안 돌진 1회(80 dmg = 타워 HP의 53~80%).

#### 2.5.10 Phase Shifter
* **순간이동:** 피격 3회 누적 시 경로 전방 5% 지점으로 순간이동합니다.
* **역할:** 연사형(Low-tech 2.0/s)은 1.5초마다 이동을 유발하고, 저연사형(Mystic 0.6/s)은 5초마다 유발합니다. **저연사 고데미지 타워가 유리합니다.**
* **밸런스:** Low-tech 격파 시 약 7회 피격 → 이동 2회(경로 10% 단축). Mystic은 이동 1회 이하.

#### 2.5.11 Queen Jelly
* **지속 소환:** 3.0초 간격으로 꼬마 슬라임(HP 8)을 생성합니다. Carrier와 달리 사망이 아닌 생존 중 지속 생산합니다.
* **역할:** SPD 0.8로 극저속이지만, 오래 생존할수록 슬라임이 기하급수적으로 누적됩니다.
* **밸런스:** Normal 방어로 모든 공격 유형 유효. 총 DPS 80 기준 → 3.1초 처치(슬라임 약 1마리). DPS 40이면 → 6.3초 처치(슬라임 약 2마리).

#### 2.5.12 Gravity Blob
* **중력장:** 반경 120px 내 모든 투사체에 40% 빗나감(miss) 확률을 부여합니다.
* **영웅 펀치:** 근접 공격은 miss 판정 미적용 → 영웅 직접 개입이 핵심 대응책입니다.
* **역할:** 최종 맵의 최고 위협 개체. Map 12(달 기지)의 저중력 환경과 시너지를 형성합니다.
* **밸런스:** Steel Can 방어 — 중력장 포함 실질 HP: Mystic 약 389, Low-tech 약 1,167. 영웅 없이는 처리가 극히 어렵습니다.

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
