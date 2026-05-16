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

## 3. Enemies (18 types)

### Base Roster (Map 01~)

#### 3-1. Jelly Slime (Swarm)

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

#### 3-2. Mini Slime (Swarm)

**Design:** Smaller version of Jelly Slime. Lighter green, faster.

| Item | Value |
|------|-------|
| Logical Size | 16x16 px (radius 8) |
| Sprite Size | **32x32 px** |
| Defense | Normal |
| Spawn | From Jelly Carrier / Queen Jelly |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Quick bounce |
| death | 3 | 10 | Tiny pop |

#### 3-3. Jelly Carrier (Swarm)

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

#### 3-4. Laser Pointer (Gimmick)

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

#### 3-5. Mirror Craft (Counter)

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

#### 3-6. Steel Can Gate (Elite)

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

### Tier 1 — Map 02~03

#### 3-7. Jelly Sprinter (Swarm)

**Design:** Streamlined cyan jelly with speed lines. Elongated teardrop shape, small and aerodynamic. Looks like it's always in motion.

| Item | Value |
|------|-------|
| Logical Size | 24x24 px (radius 12) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 8 | Fast dash with motion blur |
| death | 3 | 10 | Splat burst |

#### 3-8. Gel Medic (Support)

**Design:** White/pink jelly with green cross symbol. Gentle glow aura around body. Carries a tiny first-aid kit motif. Non-threatening, healer vibe.

| Item | Value |
|------|-------|
| Logical Size | 32x32 px (radius 16) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Gentle float |
| death | 3 | 10 | Dissolve with sparkles |
| heal | 2 | 4 | Green pulse aura (healing active) |

#### 3-9. Shadow Jelly (Gimmick)

**Design:** Dark purple/black translucent jelly. Nearly invisible, smoky shadow trails. Glowing eyes only visible feature when cloaked.

| Item | Value |
|------|-------|
| Logical Size | 28x28 px (radius 14) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move_cloaked | 4 | 6 | Faint shadow drift (semi-transparent) |
| move_visible | 4 | 6 | Revealed dark jelly movement |
| death | 3 | 10 | Shadow dissipate |
| reveal | 2 | 10 | Cloak break flash |

### Tier 2 — Map 04~06

#### 3-10. Plasma Drone (Counter)

**Design:** Metallic silver flying drone with mirror shell. Small rotating propellers, red targeting laser underneath. Hovers above ground path.

| Item | Value |
|------|-------|
| Logical Size | 36x36 px (radius 18) |
| Sprite Size | **48x48 px** |
| Defense | Mirror |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Hovering glide with propeller spin |
| death | 3 | 10 | Spark explosion and fall |
| attack | 3 | 8 | Red laser beam fires at tower |
| reflect | 2 | 8 | Mirror flash on laser hit |

#### 3-11. Gel Bomber (Gimmick)

**Design:** Bloated yellow-green jelly filled with bubbling liquid. Looks ready to burst. Darker veins visible through translucent body.

| Item | Value |
|------|-------|
| Logical Size | 32x32 px (radius 16) |
| Sprite Size | **48x48 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Wobbly waddle |
| death | 3 | 10 | Burst into slow puddle |
| puddle | 3 | 4 | Expanding goo pool on ground |

#### 3-12. Volt Jelly (Counter)

**Design:** Electric blue jelly with yellow lightning bolt patterns. Sparks crackle across surface. Steel can shell fragments embedded in body.

| Item | Value |
|------|-------|
| Logical Size | 32x32 px (radius 16) |
| Sprite Size | **48x48 px** |
| Defense | Steel Can |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Crackling slide |
| death | 3 | 10 | Electric explosion burst |
| shock | 2 | 8 | Death explosion AoE ring |

### Tier 3 — Map 07~09

#### 3-13. Storm Caller (Support)

**Design:** Dark blue jelly with swirling wind aura. Cloud-like wisps orbit body. Mirror-like reflective surface with storm patterns.

| Item | Value |
|------|-------|
| Logical Size | 40x40 px (radius 20) |
| Sprite Size | **64x64 px** |
| Defense | Mirror |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Floating drift with wind swirl |
| death | 3 | 10 | Storm dissipate |
| aura | 2 | 4 | Speed buff wind pulse |
| reflect | 2 | 8 | Mirror flash on laser hit |

#### 3-14. Cage Jelly (Gimmick)

**Design:** Dark grey armored jelly with cage-like metal bars on exterior. Steel can plating with trap jaw mechanism. Looks like a walking prison cell.

| Item | Value |
|------|-------|
| Logical Size | 40x40 px (radius 20) |
| Sprite Size | **64x64 px** |
| Defense | Steel Can |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Heavy armored crawl |
| death | 3 | 10 | Cage collapse |
| trap | 3 | 8 | Bars close around hero (grab) |

#### 3-15. Iron Express (Elite)

**Design:** Massive elongated steel can with train-like front ram. Red warning lights, exhaust pipes on back. Looks like an armored locomotive.

| Item | Value |
|------|-------|
| Logical Size | 64x48 px (wide body) |
| Sprite Size | **96x72 px** |
| Defense | Steel Can |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Heavy rolling advance |
| death | 3 | 10 | Derail and crumple |
| charge | 4 | 12 | High-speed ram with red glow |

### Tier 4 — Map 10~12

#### 3-16. Phase Shifter (Counter)

**Design:** Translucent purple jelly that flickers between visible and invisible. Prismatic shimmer effect. Mirror-like surface with dimensional crack patterns.

| Item | Value |
|------|-------|
| Logical Size | 36x36 px (radius 18) |
| Sprite Size | **48x48 px** |
| Defense | Mirror |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Flickering glide |
| death | 3 | 10 | Phase collapse |
| teleport | 3 | 12 | Blink out + reappear flash |
| reflect | 2 | 8 | Mirror flash on laser hit |

#### 3-17. Queen Jelly (Elite)

**Design:** Giant dark red jelly with golden crown and royal mantle pattern. Larger than Jelly King but slower. Mini slimes visibly forming inside body.

| Item | Value |
|------|-------|
| Logical Size | 64x64 px (radius 32) |
| Sprite Size | **96x96 px** |
| Defense | Normal |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 4 | Slow regal float |
| death | 4 | 8 | Crown drops, body bursts |
| summon | 3 | 8 | Mini slime emerges from body |

#### 3-18. Gravity Blob (Elite)

**Design:** Massive dark purple-black jelly with swirling gravity distortion field. Objects and light bend around its body. Dense, planet-like appearance with orbiting debris.

| Item | Value |
|------|-------|
| Logical Size | 60x60 px (radius 30) |
| Sprite Size | **96x96 px** |
| Defense | Steel Can |

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| move | 4 | 6 | Heavy gravitational drift |
| death | 4 | 8 | Gravity collapse implosion |
| field | 2 | 3 | Distortion field pulse (miss aura active) |

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
| Enemy | 18 types (6 base + 3 T1 + 3 T2 + 3 T3 + 3 T4) | ~168 |
| Boss | 1 | ~27 |
| **Total** | **21 entities (30 tower sprites)** | **~311 frames** |
