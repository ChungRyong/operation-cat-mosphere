# Tools Documentation

## process_enemy_sprite.py

Enemy concept 이미지의 배경 제거, 리사이즈, `.tres` 텍스처 연결을 자동화하는 스크립트.

### 요구사항

- Python 3.10+
- Pillow (`pip3 install Pillow`)

### 전제 조건

- 이미지를 `assets/sprites/enemies/`에 `{이름}_Concept.png` 형식으로 배치
- `.tres` 파일이 `resources/enemies/`에 snake_case 이름으로 존재해야 자동 연결
  - 예: `MiniSlime_Concept.png` → `mini_slime.tres`

### 기본 사용법

```bash
python3 tools/process_enemy_sprite.py <이름>
```

### 스프라이트 유형별 사용법

**초록/컬러 계열** (JellySlime, MiniSlime, JellyCarrier 등)

```bash
python3 tools/process_enemy_sprite.py MiniSlime
```

**빔/이펙트가 있는 스프라이트** (LaserPointer 등)

```bash
python3 tools/process_enemy_sprite.py LaserPointer --body-only
```

**은색/회색 금속 계열** (MirrorCraft, SteelCanGate 등)

```bash
python3 tools/process_enemy_sprite.py SteelCanGate --strategy metallic --outline-body
```

### 옵션

| 옵션 | 기본값 | 설명 |
|---|---|---|
| `--strategy green` | green | 일반 회색 체크무늬 배경 제거 |
| `--strategy metallic` | - | 은색/회색 스프라이트용 정밀 배경 감지 |
| `--body-only` | off | 빔/이펙트 제거, 본체만 추출 (밀도 기반) |
| `--outline-body` | off | 외곽 글로우 경계 기반 본체 추출 (금속 스프라이트용) |
| `--size <px>` | 64 | 출력 크기 (정사각형) |
| `--skip-tres` | off | `.tres` 텍스처 연결 건너뛰기 |

### 처리 과정

1. `assets/sprites/enemies/`에서 이름이 매칭되는 `*Concept*.png` 파일 탐색
2. 선택된 전략(green/metallic)으로 체크무늬 배경 flood-fill 제거
3. `--body-only` 또는 `--outline-body` 옵션 시 빔/이펙트 분리
4. 콘텐츠 영역 크롭 후 지정 크기로 Nearest Neighbor 리사이즈 (픽셀아트 보존)
5. 파일명 공백 제거 후 저장
6. 대응하는 `.tres` 파일에 텍스처 `ext_resource` 및 `texture` 필드 자동 추가

### 전략 선택 가이드

- **green** — 스프라이트가 배경 회색(avg 40~120)과 확실히 다른 색상일 때
- **metallic** — 스프라이트 자체가 회색/은색이라 배경과 겹칠 때. `--outline-body`와 함께 사용 권장
