# feat-024 — 전투 연출 (데미지 숫자·타격감)

## 목표
전투에 "주스"를 넣는다 — 플로팅 데미지 숫자, 타격 플래시, 공격/스킬 트윈. 첨부 화면의 흩날리는 숫자(흰·빨강·보라·"!" 크리)를 재현.

## 전제
- feat-022 완료(`VfxLayer` 존재). 정본 [docs/render-architecture.md](../render-architecture.md).
- **순수 로직 유지** — `last_skill_casts`와 동일한 "이벤트 노출" 패턴을 데미지에도 적용.

## 범위 (파일)
- `scripts/battle/battle_sim.gd` — `last_damage_events: Array` **추가**(스텝 시작 시 clear, `last_skill_casts`와 같은 수명). 일반공격·스킬 데미지 발생 지점에서 append. 기존 데미지 계산·승패 로직은 불변.
- `scripts/battle/skill_system.gd` — 스킬 데미지도 이벤트로 기록(있으면).
- `scripts/battle/battle.gd` — `VfxLayer`에 플로팅 숫자·플래시 렌더.

## 구현
1. **데미지 이벤트 노출** — `step()`에서 `target.take_damage(dmg)` 직후
   ```
   last_damage_events.append({ "target": target, "amount": dmg, "px": target.px, "py": target.py, "team": target.team, "is_crit": <상성배수 ≥ 1.5 등>, "kind": "attack" })
   ```
   스킬 데미지는 `kind:"skill"`. **결정성 유지**(순회 순서 그대로). 이벤트 노출이 sim 결과를 바꾸지 않음을 테스트로 보장.
2. **플로팅 숫자** — 뷰가 매 프레임 `last_damage_events`를 읽어 `field_to_screen(px,py)` 위에 Label 생성. 위로 떠오르며(tween position.y -=) 페이드아웃 후 `queue_free`. 색 — 일반 흰/연노, 크리 빨강 + "!", 스킬 보라. 픽셀 폰트(`assets/fonts/pixel.ttf`, 없으면 기본).
3. **타격 플래시** — 피격 유닛 스프라이트 modulate 흰 깜빡(현 스킬 플래시 패턴 재사용). 사망 시 작은 페이드/스케일.
4. **공격 트윈** — 근접 공격 시 살짝 전진 후 복귀(선택, 가벼우면). 스킬 시전은 현 플래시 유지·강화.
5. **성능** — 숫자 노드 풀링 또는 상한(동시 N개). 대량 전투에서 프레임 드랍 방지.

## 검증
- `./init.sh` green. `test_damage_events` 신설 — 동일 시드/배치에서 `last_damage_events` 합이 실제 가한 피해와 일치, 이벤트 노출 전후 `run_to_completion` 결과 동일(결정성 회귀 0).
- 헤드리스 부팅 무에러(뷰는 헤드리스에서 노드만 생성·소멸).

## 스코프 밖
- 파티클·셰이더 고급 VFX = 후속. 사운드 = 후속(audio 비어있음).
