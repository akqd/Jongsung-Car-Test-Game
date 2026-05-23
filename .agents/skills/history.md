# Development History - 종성이 자동차 테스트 게임 (Jongsung's Car Test Game)

이 문서는 **종성이 자동차 테스트 게임**의 기획 설계 과정, 핵심 기술 의사 결정, 그리고 개발 단계에서 직면한 중대한 GDScript 버그들을 진단하고 정밀 해결해 나간 전체 이력을 기술합니다.

---

## 📅 프로젝트 개요 (Project Overview)

- **프로젝트명**: 종성이 자동차 테스트 게임 (JONGSUNG CAR RACER)
- **개발 엔진**: Godot Engine 4.6.3 (stable)
- **장르**: 2D 탑다운 세로 스크롤 아케이드 회피 레이싱
- **해상도**: `540x960` 세로형 9:16 레드로 픽셀 퍼펙트 뷰포트
- **배경 테마**: 클래식 도심 고속도로 (Classic Highway) 및 레트로 픽셀 비주얼
- **개발자/퍼블리셔**: 신종성 (SHIN JONG SUNG)

---

## 🛠️ 핵심 디자인 및 기획 결정 사항 (/grill-me 합의 사항)

1. **세로형 고품질 픽셀 해상도 (`540x960`)**:
   - 아케이드 캐비닛 및 모바일 화면에 걸맞은 세로 종횡비를 채택하고, Godot의 `viewport` stretch 모드를 활용해 해상도 확대 시에도 뭉개짐 없는 픽셀을 구현했습니다.

2. **관성이 실린 부드러운 횡방향 조향 (Continuous Free Steering)**:
   - 플레이어는 차선 스냅 방식이 아닌, 좌우 입력 시 미끄러지듯 가감속하는 물리 모델을 적용받습니다. 도로 경계선(X: `110.0` ~ `430.0`) 내부로 부드럽게 가두어 가드레일을 벗어나지 못하게 클램핑 처리했습니다.

3. **에너지 쉴드 자가 회복 시스템 (Shield Recharge System)**:
   - 기본 체력(HP) 대신 에너지 쉴드(Max: 100)를 사용합니다.
   - 장애물 충돌 시 쉴드량이 감소하며 1.5초간 무적 상태(차량 깜빡임)에 들어갑니다.
   - 피격 후 약 3초 동안 충돌 없이 생존하면 매 초당 15씩 자동으로 재생되는 역동적인 기믹을 주입했습니다. 쉴드 차단막이 0인 상태에서 충돌하면 즉시 영구 파괴(사망) 처리됩니다.

4. **아슬아슬한 근접 회피 스코어링 (Near-Miss System)**:
   - 물리 히트박스 바깥에 2차 감지 콜리전(`NearMissArea`)을 부착하여, 플레이어가 장애물에 부딪히지 않고 근접하게 스쳐 지날 때마다 **"+250 NEAR MISS!"** 플로팅 텍스트 트윈과 함께 스파크 파티클을 뿜는 하이리스크 하이리턴 아케이드 기믹을 연출했습니다.

5. **고정식 레벨 설계와 3개 난이도 스테이지 (Deterministic Spawner)**:
   - 플레이어가 주행한 실제 거리에 따라 장애물을 정해진 차선에 배치하는 고정 스폰(Fixed Spawn) 시스템입니다.
   - **Stage 1 (Easy - 800m)**: Rocks(바위, 35 데미지) 위주
   - **Stage 2 (Normal - 1200m)**: Broken Cars(고장난 차, 비상등 번갈아 깜빡임, 50 데미지) 추가
   - **Stage 3 (Hard - 1600m)**: Wrong-way Drivers(상단 붉은색 경고 화살표 점멸 후 정면 초고속 돌진 차량, 100 데미지) 대거 등판

6. **완전 절차적 2D 드로잉 (Procedural Vector Drawing)**:
   - 이미지 에셋 로딩이나 임포트 캐시 문제로 게임이 크래시되는 것을 완전 차단하고 최적화를 극대화하기 위해, **도로 차선, alternating 가드레일, 플레이어 레드 스포츠카, 바위 금, 고장난 차의 flashing 비상등, 블루 머슬 적 차량, 체크무늬 피니시 라인**을 모두 100% GDScript의 `_draw()` 함수 코드로 설계했습니다.

---

## 🐛 개발 중 진단 및 정밀 해결한 주요 GDScript 버그 (Debugging History)

개발 과정에서 발견된 치명적인 크래시 및 작동 불능 버그들을 체계적으로 진단하고 해결한 기술적 기록입니다.

### 1. 메인 메뉴 씬 따옴표 누락 구문 에러 (Parse Error)
- **현상**: 프로젝트 체크 및 로드 시 `res://scenes/main_menu.tscn:3 - Parse Error: Expected '=' after identifier` 에러가 나며 씬 로드 실패.
- **원인**: `main_menu.tscn` 파일의 1번 라인 `uid` 속성 값의 닫는 큰따옴표가 누락되어 구문 분석기가 후속 속성을 올바르게 해석하지 못함. (`uid="uid://cx1mainmenu2d]`)
- **조치**: 닫는 큰따옴표(`"`)를 올바르게 추가하여 해결했습니다. (`uid="uid://cx1mainmenu2d"`)

### 2. DecorativePlayer 노드/스크립트 상속 타입 미스매칭
- **현상**: 메인 메뉴 진입 시 `Script inherits from native type 'CharacterBody2D', so it can't be assigned to an object of type 'Node2D'` 오류로 로딩 실패.
- **원인**: `main_menu.tscn`에 장식용으로 세워둔 `DecorativePlayer` 노드의 엔진 타입은 `Node2D`였으나, 여기에 부착된 `player.gd` 스크립트는 `CharacterBody2D`를 상속받아 Godot 엔진이 로딩을 원천 차단함.
- **조치**: `main_menu.tscn`의 `DecorativePlayer` 노드 명세를 `CharacterBody2D`로 수정하여 상속 구조를 일치시켰습니다.

### 3. 장식용 인스턴스 타이머 Null Pointer 크래시 예방
- **현상**: 에디터와 게임 시작 시 장식용 차량 노드에서 자식 타이머를 찾지 못해 `SCRIPT ERROR: Invalid assignment of property or key 'one_shot' with value of type 'bool' on a base object of type 'null instance'` 발생.
- **원인**: `player.gd`는 인게임 동작을 상정하여 `RechargeTimer` 등의 타이머가 존재함을 전제하고 준비(`_ready()`) 단계를 거쳤으나, 메뉴의 장식용 차량에는 해당 노드들이 없어 Null Pointer 참조가 일어남.
- **조치**: `@onready` 타이머를 `get_node_or_null()`로 캐스팅하고, `if recharge_timer:` 조건부 분기 코드를 추가하여 타이머 노드가 없는 데코레이션 상황에서도 크래시 없이 안전하게 예외를 우회하도록 변경했습니다.

### 4. LevelData 컴파일러 미인식 오류 (Autoload 싱글톤 해결)
- **현상**: 게임 실행 후 스테이지 선택 버튼 클릭 시 `SCRIPT ERROR: Parse Error: Identifier "LevelData" not declared in the current scope.` 에러 발생 및 스크롤 프리즈.
- **원인**: `level_data.gd`에 `class_name LevelData`를 추가하여 전역 접근을 시도했으나, Godot 엔진은 에디터 외부에서 클래스명이 바뀌면 `.godot` 스크립트 캐시가 실시간 갱신되지 않는 한계가 있어 단독 런타임에서 `LevelData`를 해석하지 못함. 이로 인해 인게임 매니저(`game.gd`)가 로드조차 되지 않고 씬이 얼어버렸음.
- **조치**: 에디터 cache와 무관하게 부팅 시 무조건 메모리에 주입되는 **`project.godot`의 `[autoload]` 영역에 `LevelData` 싱글톤으로 정식 등록**하고, 클래스 중복 오류를 방지하기 위해 `level_data.gd`에서 `class_name` 코드를 정비했습니다.

### 5. 쉴드바 스타일박스 Read-Only 자원 크래시 차단
- **현상**: 쉴드 에너지 양이 변할 때 `_on_player_shield_changed` 콜백에서 스타일박스 값 수정 시 크래시 위험.
- **원인**: `ProgressBar.get_theme_stylebox("fill")`은 엔진의 공유 리소스를 가리키므로 직접 쓰기를 가하면 Read-Only 에러를 발생시킬 수 있음.
- **조치**: `sb.duplicate()`를 통해 인스턴스 전용 스타일박스를 안전하게 복제한 후 가감 수정을 거쳐 `add_theme_stylebox_override()`로 안전하게 오버라이드 등록 처리했습니다.

### 6. HUD 프로세스 라이프사이클 속성 안전성 가드레일 수립
- **현상**: 씬 전환 및 리로드 시점의 미묘한 로딩 시차로 인한 HUD 스크립트 예외 우려.
- **원인**: 게임 매니저 노드와 HUD 노드의 생성/준비(`_ready()`) 프레임 간 격차로 인해 특정 프레임에서 HUD가 존재하지 않는 속성을 가리키는 리스크 존재.
- **조치**: `_process` 내 참조 시 `if "current_speed" in game_node:` 와 같이 `"property" in object` 기법을 적용해 찰나의 예외 상황에서도 크래시 없이 극도로 부드럽고 강건하게 방어 동작이 흐르도록 고도화했습니다.
