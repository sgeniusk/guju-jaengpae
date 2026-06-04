# 릴리스 리스크 — v0.7.0 후보

이 문서는 G084 기준 알려진 리스크와 미지원 범위를 한곳에 고정한다. 태그, push, GitHub release 생성은 사용자 확인 전 실행하지 않는다.

## 지원 기준
- 현세 위·촉·오 3국 군주 선택, 보드 배치, 전투, 보상, 상점, 칙령, 계략, 보패, 저장·재개·해금.
- stage 5 동탁, stage 10 장각, stage 15 여포 보스와 최종 승리·패배 결과 화면.
- 핵심 UI tooltip/피드백, 첫 전투·보상 온보딩, HUD 아이콘, realm/stage 배경, walk 시트, 최소 BGM/SFX.
- macOS Desktop preset, pack export, full app export zip, export 앱 stage 1 첫 전투 도달 smoke.

## 미지원·보류 범위
| 항목 | 상태 | 이유와 다음 조건 |
|---|---|---|
| 천계·마계 6국 playable 확장 | 보류 | 사용자/편집장 정본 승인 전 nation id, 군주, 카드 Resource를 확정하지 않는다. |
| 온라인·멀티플레이 | v1.0 비범위 | 현재 목표는 싱글 플레이 로그라이크 런 완성이다. |
| notarization·서명 배포 | 미지원 | 현재 export는 로컬 ad-hoc 검증이다. Apple credential과 release signing은 별도 사용자 승인·비밀값 경계가 필요하다. |
| GitHub release 게시 | 보류 | `git push origin main`, tag push, release 생성은 사용자 확인 후에만 실행한다. |
| 장기런 수동 QA | 제한 | 첫 15스테이지 구조, 보스, 결과 화면, export 첫 전투는 검증했지만 장시간 반복 플레이 체감은 후속 사람/agy QA가 필요하다. |
| 표적 지정 체감 튜닝 | 제한 | 장수 명령 경로는 구현되어 있으나 전투 중 조작감은 장기런 수동 QA에서 재확인한다. |
| attack/idle/death 고급 애니메이션 | 비필수 | 현재 제품 기준은 주요 유닛 walk 시트와 정적 fallback이다. |
| 최종 음악·효과음 | 제한 | BGM/SFX는 최소 placeholder 수준이며 최종 사운드 디자인은 별도 phase로 둔다. |
| 공개 구버전 저장 마이그레이션 | 제한 | versioned primitive payload와 newer major 거부는 테스트되어 있으나, 공개 배포 이력이 없는 실제 구버전 save migration은 아직 없다. |

## 알려진 운영 리스크
- `build/` 산출물은 `.gitignore`로 제외한다. pack export와 full app export zip은 로컬 검증 산출물이며 소스에 포함하지 않는다.
- full app export에는 Godot 4.6.3 export templates가 필요하다. `project.godot`의 ETC2/ASTC import 설정은 macOS universal export를 위해 유지한다.
- release export에서는 Resource 디렉터리 항목이 `.tres.remap`으로 보일 수 있다. 현재 카드·군주 카탈로그는 이 경로를 정규화하지만, 새 Resource 디렉터리를 만들 때도 같은 경계를 검토해야 한다.
- macOS headless 실행에서 `get_system_ca_certificates` 경고가 보일 수 있다. 현재 검증에서는 종료 코드 0이며 기능 실패로 보지 않는다.
- 단위 테스트 종료 시 ObjectDB/resource 사용 경고가 간헐적으로 보일 수 있다. 현재 `./init.sh`는 2375/2375 green으로 종료 0이고, 누수 원인 추적은 별도 안정화 이슈다.
- G055/G056/G058/G060/G061/G062 계열 9세력 확장 목표는 정본 승인 전 보류한다. 승인 없이 playable 천계·마계 nation id나 Resource를 추가하지 않는다.

## 태그 전 stop condition
- `docs/release-checklist.md`의 preflight가 모두 통과해야 한다.
- `./init.sh`는 카드 22개와 2375 단언 green이어야 한다.
- fresh clone green, pack export, full app export 첫 전투 smoke 증거가 유지되어야 한다.
- 이 문서의 보류·미지원 범위가 릴리스 노트나 사용자 안내에 반영되어야 한다.
- 사용자 확인 전에는 push, tag, GitHub release를 실행하지 않는다.
