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
| walk | 6 | 8 | Left-right with horizontal flip |
| punch | 3 | 12 | Cat punch forward motion |
| parry | 2 | 8 | Shield stance + sparkle |
| ultimate | 5 | 10 | Roar effect with screen glow |
| hit | 2 | 10 | Damage blink |
| death | 4 | 6 | Fall down |

---

## 2. Towers (3 types x 5 floors)

**Structure:** Separate per-floor sprites stacked vertically in code. Floor 5 (rooftop) has unique decoration.

| Item | Value |
|------|-------|
| Logical Size | 48x12 px per floor (code: half 24, floor height 12) |
| Sprite Size | **96x24 px per floor** |
| Full Stack (5F) | 96x120 px |
| Pivot | Center-bottom (foundation base) |

### 2-1. Fish Bone Launcher (Low-tech)

**Design:** DIY launcher made of wood/cardboard, fires fish bones. Crude and handmade aesthetic.

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 2 | 2 | Slight vibration |
| shoot | 3 | 12 | Recoil with bone popping out |
| hit | 2 | 10 | Damage flash |
| collapse | 3 | 6 | Top floor falls off |

### 2-2. Plasma Laser (Hi-tech)

**Design:** Sleek metal/LED device firing laser beams. Blue glow, futuristic look.

| Animation | Frames | FPS | Description |
|-----------|--------|-----|-------------|
| idle | 2 | 2 | LED pulsing |
| shoot | 3 | 12 | Blue beam charge + fire |
| hit | 2 | 10 | Damage flash |
| collapse | 3 | 6 | Top floor falls off |

### 2-3. Mjolnir Coil (Mystic)

**Design:** Mystical coil emitting purple lightning. Heavy, arcane feeling with electric sparks.

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
| Tower | 3 types x 5 floors | ~45 (15 floors + 30 anim) |
| Enemy | 6 | ~60 |
| Boss | 1 | ~27 |
| **Total** | **12 entities** | **~158 frames** |
