# feat-034 — 9세력 정본·카탈로그 확장 계약

## 목표
Phase 4의 9세력 확장은 콘텐츠 양을 먼저 늘리지 않고, 정본 승인 → 스키마 확장 → 리소스 추가 → UI 반영 순서를 지킨다.

## G054 세부 기준
순서는 반드시 다음과 같다.

1. 명칭 승인 — 천계·마계 6국 이름과 군주를 사용자/편집장 정본으로 확정한다.
2. `docs/worldview.md` 정본 갱신 — 승인된 이름에서 `(제안)`/승인 대기 표기를 제거하고 canon으로 표시한다.
3. `CardVocab.NATIONS`/validator 확장 — 정본에 오른 nation id만 `scripts/resources/card_vocab.gd`에 추가한다.
4. Resource 추가 — 승인된 nation id로 lord/card `.tres`를 추가한다.
5. lord_select 해금 UI — 카탈로그 기반 잠금·해금 표시를 넓힌다.

## 현재 잠금
- 현 시점의 승인 nation은 `wei`, `shu`, `wu`뿐이다.
- 천계 제안 id `kunlun`, `penglai`, `ziwei`와 마계 제안 id `huangtian`, `luoyang`, `wanyao`는 `docs/worldview.md`에는 남기되, 사용자 승인 전에는 `CardVocab.NATIONS`에 넣지 않는다.
- `tools/validate_cards.gd`는 `CardVocab.NATIONS`를 기준으로 Resource nation을 검사한다. 따라서 nation id 확장은 정본 갱신 뒤에만 가능하다.

## G057 세부 기준
- `lord_select`는 화면 로컬 고정 군주 배열을 갖지 않는다.
- 군주 선택 목록은 `CardCatalog`/`CardLibrary`의 카탈로그 API에서 온다.
- 표시 순서는 카탈로그가 안정적으로 정한다. 현세 3국 기본 순서는 유비 → 조조 → 손권이다.
- 잠금·해금 판정은 계속 `ProfileState`/`RunManager`가 소유한다.
- 사용자 승인 전에는 천계·마계 nation id나 Resource를 추가하지 않는다.

## 검증
- `test_nine_faction_gate.gd`는 `CardVocab.NATIONS`가 아직 현세 3국만 허용하는지 검증한다.
- 같은 테스트는 `docs/worldview.md`가 천계·마계 명칭을 제안/사용자 승인 대기로 표시하는지 확인한다.
- 같은 테스트는 이 스펙의 G054 순서가 명칭 승인 → worldview → CardVocab/validator → Resource → lord_select 순으로 적혀 있는지 확인한다.
- `test_card_catalog.gd`는 군주 카탈로그 목록과 기본 표시 순서를 검증한다.
- `test_lord_select.gd`는 `lord_select`가 런타임 카탈로그에 추가된 군주도 렌더하는지 검증한다.
- `./init.sh` 전체 green으로 닫는다.
