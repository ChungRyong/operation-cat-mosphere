# Operation Cat-mosphere - Development Plan

**Created:** 2026-05-03
**Based on:** PRD v2.0 (Operation_Cat-mosphere.md), MAP.md (전장 설계도)

---

## Current State (P0 Prototype)

| System | Status | Notes |
|--------|--------|-------|
| GameManager (Phase/Base HP) | Done | Night only, Day/Dawn not implemented |
| ResourceManager (Scrap/Essence/Catnip) | Done | Economy logic working |
| DamageCalculator (3x3 matrix) | Done | Reflection included |
| WaveManager (5 Stage timeline) | Done | Multi-path support |
| Tower (stacking/collapse/firing) | Done | 5-floor stack, crit, stun |
| Enemy (move/HP/death/child spawn) | Done | Carrier -> Mini Slime split |
| Hero (move/punch/parry/ultimate) | Done | Basic combat functional |
| Bullet (homing/reflect) | Done | Hi-tech -> Mirror reflect |
| HUD (resources/timer/build buttons) | Done | Basic UI |
| SfxManager | Skeleton | No sounds implemented |
| Visual Assets | None | sprites/audio/fonts dirs empty |

---

## Phase 1 - Core Loop (Day/Night/Dawn Cycle)

**Goal:** Full playthrough of Stages 1~5

- [x] Day Phase: hero free-roam + scrap node placement/collection + tower building
- [x] Night Phase -> Victory -> Dawn transition
- [x] Dawn Phase: 3-card pick-1 buff selection (Churu Box roguelike cards)
- [x] Stage clear -> auto-advance to next stage
- [x] Tower placement cancel (right-click), Day-only build restriction
- [x] Game speed control (1x/2x/4x via Tab key or UI button)
- [x] Stage select / restart flow

## Phase 2 - Combat System Polish

**Goal:** All enemy mechanics working, performance optimized

- [x] Steel Can Gate: attack nearest tower foundation (ATK x2 = 50 fixed damage)
- [x] Laser Pointer: force aggro on all towers in range (strengthen priority targeting)
- [x] Enemy Object Pooling (handle 100+ Swarm units)
- [x] Hero i-frame on hit

## Phase 3 - Tower Interaction UI

**Goal:** Full tower management during gameplay

- [x] Click tower to select -> info panel (HP/DPS/floor level)
- [x] Add floor button (cost display, max 5)
- [x] Repair button (repair_cost deduction)
- [x] Sell button (50% refund)
- [x] Build Mode toggle (B key wired up)

## Phase 4 - Growth Systems

**Goal:** Progression across stages

- [x] Hero level-up: spend Essence -> HP/ATK/SPD increase
- [ ] Skill Tree basics: 3 paths (Striker/Commander/Master), pick 1 per stage clear
- [ ] Layer Synergy: adjacent floor combo passive buffs
- [ ] Catnip field collection + Cat HQ research tree (permanent upgrades)

## Phase 5 - Visual & Audio

**Goal:** Replace all placeholders with proper assets

- [ ] Cheese Cat hero sprite + animations
- [ ] 3 tower type sprites (stacking visuals per floor)
- [ ] 6 enemy type sprites
- [ ] Effects (explosion, stun, reflect, ultimate)
- [ ] SFX (attack, build, destroy, UI)
- [ ] BGM (Day/Night themes)

## Phase 6 - Balance & Polish

**Goal:** Ship-ready quality

- [ ] PRD-based balance verification (DPS calculations)
- [ ] Per-stage difficulty curve tuning
- [ ] UI theme & font application
- [ ] Tutorial guide (Stage 1)
- [ ] Game over / restart flow polish

---

# P1 — Full Map System (Based on MAP.md)

## Phase 7 - 20-Day Map Structure

**Goal:** P0의 5스테이지 구조를 맵당 20일 로그라이크 루프로 확장

- [x] GameManager 리팩터: Stage → Day(1~20) 주기로 전환
- [x] 동적 경로 확장: Day 5/11/16에서 새 침공 경로 개방 (1→2→3→4)
- [x] 슬롯 기반 타워 배치: 자유 배치 → 고정 건설 슬롯 (Day별 1→2→3→4 확장)
- [x] WaveManager 리팩터: Day별 웨이브 데이터를 Resource 구조 (WaveGroupData/DayData/MapData)
- [x] 실패 시 해당 맵 Day 1 리셋 (로그라이크 A-Type)

## Phase 8 - Meta Progression & Economy

**Goal:** 영구 성장 루프와 맵 간 진행 시스템

- [x] 골드 캔(Gold Can) 영구 재화: 실패해도 유지, 적 처치/Day 클리어 보상
- [x] 로비 화면 (Cat HQ): 영구 강화 구매 UI
- [ ] 영구 업그레이드 트리: 타워 기본 스탯, 히어로 기본 스탯, 자원 수집 효율
- [ ] 맵 해금 진행: Day 20 클리어 → 다음 맵 해금
- [x] 맵 선택 월드맵 UI

## Phase 9 - Boss System

**Goal:** Day 20 맵 보스 전투

- [ ] Boss 기본 프레임워크: 고유 패턴, 페이즈 전환, 체력바 UI
- [ ] 맵 01 보스 구현 (집사 없는 거실)
- [ ] 보스 클리어 보상 (대량 골드 캔 + 맵 해금)
- [ ] 보스 패턴 데이터 리소스화 (.tres)

## Phase 10 - Environment Gimmick Framework

**Goal:** 맵별 고유 환경 기믹 시스템

- [ ] 환경 기믹 베이스 시스템 (GimmickManager autoload)
- [ ] 시야 제한 기믹: 안개/어둠 (맵 03 공포의 지하실)
- [ ] 지형 기믹: 미끄러운 바닥, 고속 루트 (맵 05/06)
- [ ] 기상 기믹: 비 — 전기 속성 증폭 (맵 07)
- [ ] 상호작용 기믹: 동료 구조, 스크린도어, 냉동고 (맵 08/09/10)
- [ ] 물리 기믹: 저중력 — 이동/투사체 궤적 변화 (맵 12)

## Phase 11 - 12 Battlefields

**Goal:** MAP.md 12종 전장 전체 구현

- [ ] 맵 01~04: 집사 없는 거실, 야생의 뒷마당, 공포의 지하실, 캣타워 연구소
- [ ] 맵 05~08: 마의 구역 주방, 벚꽃 핀 놀이터, 비 내리는 지붕 위, 고양이 카페
- [ ] 맵 09~12: 도심 지하철역, 대혼란의 편의점, 외계 모선, 최후의 보루 달 기지
- [ ] 맵별 20일 웨이브 데이터 설계 및 밸런싱
- [ ] 맵별 고유 경로 레이아웃 (4경로 확장 포함)
- [ ] 맵별 보스 구현 (12종)

## Phase 12 - Scale Optimization

**Goal:** 수만 단위 Swarm 쾌적 처리

- [ ] Enemy Object Pooling 고도화: 10,000+ 동시 유닛 처리
- [ ] 렌더링 최적화: MultiMeshInstance2D 기반 대량 드로우
- [ ] 물리/충돌 최적화: 서버 기반 Area 관리, 쿼드트리 공간 분할
- [ ] 프레임 프로파일링 및 병목 해소 (60fps 보장 목표)
