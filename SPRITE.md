# Operation Cat-mosphere - Sprite Specification

**Viewport:** 1280x720 (canvas_items stretch)
**Target:** FHD 1920x1080 (1.5x upscale)
**Sprite Resolution:** 2x logical size for crisp rendering
**Format:** PNG, transparent background
**Method:** SpriteFrames (AnimatedSprite2D) or individual frames

---

## 1. Hero - Cheese Cat

**Design:** Yellow/white patterned Korean Shorthair with white paws (socks). Cat army leader. Expressive face, confident posture.

| Item | Value |
|------|-------|
| Logical Size | 36x36 px (code: radius 18) |
| Sprite Size | **64x64 px** |
| Pivot | Center-bottom (feet position) |

### Animations

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 4 | 4 | Breathing / tail swaying |
| walk | 3 | 6 | Left-right with horizontal flip |
| punch | 4 | 12 | Cat punch forward motion |
| parry | 2 | 8 | Shield stance + sparkle |
| ultimate | 5 | 10 | Roar effect with screen glow |
| hit | 2 | 10 | Damage blink |
| death | 4 | 6 | Fall down |

---

## 2. Towers (3 types x 5 floors x 2 variants)

**Structure:** Separate per-floor sprites stacked vertically in code. Each floor has a unique visual per position (1F~5F). Every floor has **2 variants**: Top (최고층 — roof cap) and Stackable (위에 층 있음 — open top). Code selects the variant based on whether the floor is currently the topmost.

| Item | Value |
|------|-------|
| Logical Size | 48x24 px per floor (code: half 24, floor height 24) |
| Sprite Size | **96x48 px per floor** |
| Full Stack (5F) | 96x240 px |
| Pivot | Center-bottom (foundation base) |
| Variants per floor | 2 (Top / Stackable) |
| Total sprites | 3 types x 5 floors x 2 variants = **30** |

### Floor Visual Guide

| Floor | Role | Design Notes |
|-------|------|-------------|
| 1F | Foundation | Scratching post base, sturdiest structure, ground contact |
| 2F | Lower body | Lower weapon mount, structural support |
| 3F | Mid body | Main weapon platform, core identity |
| 4F | Upper body | Upper weapon mount, height advantage |
| 5F | Rooftop | Crown decoration, cat flag, antenna/finial |

### Variant Rules

| Variant | When | Visual |
|---------|------|--------|
| **Top** | This floor is the highest built floor | Roof cap / decoration on top, closed upper surface |
| **Stackable** | Another floor exists above this one | Open/flat upper surface, visible connection joint |

### Stacking Examples

```
1F only:  [1F-Top]
2F tower: [2F-Top] + [1F-Stackable]
3F tower: [3F-Top] + [2F-Stackable] + [1F-Stackable]
5F tower: [5F-Top] + [4F-Stackable] + [3F-Stackable] + [2F-Stackable] + [1F-Stackable]
```

### 2-1. Fish Bone Launcher (Low-tech)

**Design:** DIY launcher made of wood/cardboard, fires fish bones. Crude and handmade aesthetic. Cat tree base with scratching post texture, cardboard box body, yarn decorations.

| Floor | Top Variant | Stackable Variant |
|-------|-------------|-------------------|
| 1F | Scratching post base + cardboard roof cap | Scratching post base, open top |
| 2F | Lower cardboard box + yarn roof | Lower cardboard box, flat top joint |
| 3F | Fish bone catapult arm + box roof | Fish bone catapult arm, open top |
| 4F | Ammo basket (fish bones) + lid cap | Ammo basket, open top |
| 5F | Lookout post + cat paw flag | Lookout post, flat top joint |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 2 | 2 | Slight vibration |
| shoot | 3 | 12 | Recoil with bone popping out |
| hit | 2 | 10 | Damage flash |
| collapse | 3 | 6 | Top floor falls off |

### 2-2. Plasma Laser (Hi-tech)

**Design:** Sleek metal/LED device firing laser beams. Blue glow, futuristic look. Luxury cat tree platform base, metallic body, LED strips, cat ear satellite dish.

| Floor | Top Variant | Stackable Variant |
|-------|-------------|-------------------|
| 1F | Metal platform base + dome cap | Metal platform base, open top |
| 2F | Power core (cat toy ball) + panel cap | Power core, flat top connector |
| 3F | Laser turret barrel + sensor dome | Laser turret barrel, open top |
| 4F | LED strip array + shield cap | LED strip array, open top |
| 5F | Cat ear satellite dish + antenna | Cat ear dish, flat top connector |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 2 | 2 | LED pulsing |
| shoot | 3 | 12 | Blue beam charge + fire |
| hit | 2 | 10 | Damage flash |
| collapse | 3 | 6 | Top floor falls off |

### 2-3. Mjolnir Coil (Mystic)

**Design:** Mystical coil emitting purple lightning. Heavy, arcane feeling with electric sparks. Ancient cat shrine base, paw rune symbols, cat bell finial.

| Floor | Top Variant | Stackable Variant |
|-------|-------------|-------------------|
| 1F | Stone shrine base + shrine roof cap | Stone shrine base, open top |
| 2F | Rune-carved pillar + ward cap | Rune-carved pillar, flat top joint |
| 3F | Tesla coil core + lightning dome | Tesla coil core, open top |
| 4F | Purple crystal array + cap stone | Purple crystal array, open top |
| 5F | Cat bell finial + lightning rod | Cat bell, flat top connector |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 2 | 2 | Purple spark crackle |
| shoot | 3 | 12 | Lightning strike |
| hit | 2 | 10 | Damage flash |
| collapse | 3 | 6 | Top floor falls off |

---

## 3. Enemies (6 types)

### 3-1. Jelly Slime (Swarm)

**Design:** Green jelly droplet. Simple, cute, appears in large numbers.

| Item | Value |
|------|-------|
| Logical Size | 28x28 px (radius 14) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Bouncy hop |
| death | 3 | 10 | Pop burst |

### 3-2. Mini Slime (Swarm)

**Design:** Smaller version of Jelly Slime. Lighter green, faster.

| Item | Value |
|------|-------|
| Logical Size | 16x16 px (radius 8) |
| Sprite Size | **32x32 px** |
| Defense | Normal |
| Spawn | 5 from Jelly Carrier on death |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Quick bounce |
| death | 3 | 10 | Tiny pop |

### 3-3. Jelly Carrier (Swarm)

**Design:** Large translucent green jelly. Mini Slimes visible inside body. Slow and bulky.

| Item | Value |
|------|-------|
| Logical Size | 48x48 px (radius 24) |
| Sprite Size | **64x64 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Heavy wobble |
| death | 3 | 10 | Burst open |
| split | 3 | 10 | Body breaks apart releasing minis |

### 3-4. Laser Pointer (Gimmick)

**Design:** Red glowing body. Emits light that distracts towers. Fast and agile.

| Item | Value |
|------|-------|
| Logical Size | 32x32 px (radius 16) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Darting movement |
| death | 3 | 10 | Light flicker out |
| glow | 2 | 4 | Red pulse (distraction active) |

### 3-5. Mirror Craft (Counter)

**Design:** Silver jelly with mirror-like surface. Reflects Hi-tech lasers. Sleek and fast.

| Item | Value |
|------|-------|
| Logical Size | 36x36 px (radius 18) |
| Sprite Size | **48x48 px** |
| Defense | Mirror |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Smooth glide |
| death | 3 | 10 | Shatter |
| reflect | 2 | 8 | Mirror flash on laser hit |

### 3-6. Steel Can Gate (Elite)

**Design:** Massive grey steel can. Armored tank unit that directly attacks tower foundations. Slow and heavy.

| Item | Value |
|------|-------|
| Logical Size | 60x60 px (radius 30) |
| Sprite Size | **96x96 px** |
| Defense | Steel Can |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Heavy stomp |
| death | 3 | 10 | Crumple and collapse |
| attack | 3 | 8 | Ram into tower foundation |

---

## 4. Boss - Jelly King

**Design:** Giant red jelly wearing a crown. Phase 2 (HP <= 50%): color brightens, patterns speed up, rage aura appears.

| Item | Value |
|------|-------|
| Logical Size | 80x80 px (radius 40) |
| Sprite Size | **128x128 px** |
| Defense | Normal |
| Pivot | Center |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 4 | 3 | Floating sway + crown sparkle |
| charge | 4 | 12 | Body stretches forward for rush |
| summon | 4 | 8 | Slimes burst from body |
| aoe | 5 | 10 | Ground slam shockwave |
| phase2 | 4 | 8 | Transition: color shift + rage aura |
| death | 6 | 6 | Explosion + crown drops |

---

## Summary

| Category | Count | Est. Frames |
|----------|-------|-------------|
| Hero | 1 | ~26 |
| Tower | 3 types x 5 floors x 2 variants = 30 sprites | ~90 (30 base + 60 anim) |
| Enemy | 6 | ~60 |
| Boss | 1 | ~27 |
| **Total** | **12 entities (30 tower sprites)** | **~203 frames** |
