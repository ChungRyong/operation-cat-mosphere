# Operation Cat-mosphere - Development Plan

**Created:** 2026-05-03
**Based on:** PRD v2.0 (Operation_Cat-mosphere.md)

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
- [ ] Stage select / restart flow

## Phase 2 - Combat System Polish

**Goal:** All enemy mechanics working, performance optimized

- [ ] Steel Can Gate: attack nearest tower foundation (ATK x2 = 50 fixed damage)
- [ ] Laser Pointer: force aggro on all towers in range (strengthen priority targeting)
- [ ] Enemy Object Pooling (handle 100+ Swarm units)
- [ ] Hero i-frame on hit

## Phase 3 - Tower Interaction UI

**Goal:** Full tower management during gameplay

- [ ] Click tower to select -> info panel (HP/DPS/floor level)
- [ ] Add floor button (cost display, max 5)
- [ ] Repair button (repair_cost deduction)
- [ ] Sell button (50% refund)
- [ ] Build Mode toggle (B key wired up)

## Phase 4 - Growth Systems

**Goal:** Progression across stages

- [ ] Hero level-up: spend Essence -> HP/ATK/SPD increase
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
