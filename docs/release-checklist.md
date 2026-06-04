# 릴리스 체크리스트 — 구주쟁패

이 문서는 G081 기준 태그와 릴리스 준비 절차다. 실제 `git tag`, `git push`, GitHub release 생성은 사용자 확인 후에만 실행한다.

## 릴리스 후보
- 앱 버전: `0.7.0`
- 태그 후보: `v0.7.0-rc1`
- 최종 태그 후보: `v0.7.0`
- Godot preset: `macOS Desktop`
- pack export 산출물: `build/macos/guju-jaengpae.pck`
- full app export 산출물 후보: `build/macos/guju-jaengpae.zip`

## 현재 완료 기준
- G078 밸런스 계약 완료: 난이도 0.10 step, 칙령 10/20/15%, 둔전·망루·징발·보패 수치 계약.
- G079 export preset 완료: `export_presets.cfg` 추적, credential-free macOS preset, pack export 성공.
- G080 릴리스 문서 동기화 완료: README, CHANGELOG, worldview, asset manifest, handoff/status 문서 갱신.

## 태그 전 게이트
- [ ] `git status --short`로 의도하지 않은 변경을 분리한다.
- [ ] `git log --oneline origin/main..main`으로 미푸시 커밋과 보류 사유를 확인한다.
- [ ] `jq empty feature_list.json`.
- [ ] `wc -l progress.md`가 120 이하.
- [ ] `git diff --check`.
- [ ] `./init.sh` 카드 22개와 2349 단언 green.
- [ ] `godot --headless --path . --export-pack "macOS Desktop" build/macos/guju-jaengpae.pck`.
- [ ] G082 fresh clone 검증 완료.
- [ ] G083 full app export 실행과 첫 전투 도달 완료.
- [ ] G084 알려진 리스크와 미지원 범위 문서화 완료.

## 사용자 확인 후 실행할 명령
```sh
git tag -a v0.7.0-rc1 -m "Prepare Guju Jaengpae v0.7.0 release candidate"
git push origin main
git push origin v0.7.0-rc1
```

최종 릴리스가 준비되면 `v0.7.0` 태그를 같은 방식으로 만든다. rc 태그와 최종 태그는 같은 커밋을 가리킬 수도 있지만, full app export와 알려진 리스크 문서가 끝난 뒤에만 최종 태그를 만든다.

## 릴리스 노트 초안
- 현세 위·촉·오 3국 군주 선택과 unlock-aware 군주 목록.
- 보드 배치, 손패, 건물 경제, 우물, 보상, 상점, 칙령, 계략, 보패.
- stage 5 동탁, stage 10 장각, stage 15 여포 보스와 최종 승리/패배 결과 화면.
- UI tooltip/피드백, 첫 전투·보상 온보딩, HUD 아이콘, realm/stage 배경, walk 시트, 최소 BGM/SFX.
- Phase 7 밸런스 계약과 macOS Desktop export preset.

## 보류 및 리스크
- 천계·마계 6국 playable 확장은 사용자/편집장 정본 승인 전 보류.
- full app export는 Godot export templates가 설치된 환경에서 G083으로 검증한다.
- 현재 pack export 산출물은 `build/` 아래 ignored 산출물이며 소스에 포함하지 않는다.
- `git push origin main`, tag push, GitHub release 생성은 사용자 확인 후에만 실행한다.
