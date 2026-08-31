# Benefitship 한글 패치

Steam판 `Benefitship`의 비공식 한국어 패치입니다. 대사와 내레이션, 선택지, 메뉴, 설정, 크레딧을 한국어화하며 원문 스크립트 식별자와 Ren'Py 제어 태그는 유지합니다.

## v0.1.0-rc1 적용 범위

- 최신 원문과 정확히 대응하는 대사·내레이션 번역 블록 1,569개
- UI·설정·크레딧 문자열 102개
- 한국어 전용 Noto Sans CJK KR 글꼴 적용
- 한국어 언어 선택 항목 추가
- 한국어 로고가 없을 때 공식 기본 로고로 안전하게 대체
- 메뉴, 옵션, 새 게임 첫 장면 실제 실행 확인

기존에 중단된 패치의 번역을 회수한 뒤 최신 원문과 다시 맞춰 문맥, 인물 말투, 용어 일관성을 검수했습니다. 이전 합본에서 생긴 중복 13개와 최신판에 존재하지 않는 번역 블록 1,235개를 제거했고, 문맥 오류 69건(문자열 102곳)을 직접 교정했습니다. 옵션 탭의 한글이 네모로 표시되던 문제와 한국어 로고 누락으로 메뉴가 중단되던 문제도 함께 수정했습니다.

## 지원 환경

- 플랫폼: Windows / Steam
- Steam AppID: `2404000`
- 게임 표시 버전: `1.2.3`
- 지원 Steam 빌드 ID: `21409340`
- 엔진: Ren'Py `8.5.0.25111603`

설치기는 `game/screens.rpy`와 `game/credits.rpy`의 원본 크기와 SHA-256을 확인합니다. 게임이 업데이트되어 원본 해시가 달라졌다면 강제로 적용하지 마세요.

## 설치 방법

1. [Releases](https://github.com/BK927/korean-game-patches/releases)에서 `Benefitship-Korean-Patch-0.1.0-rc1.zip`을 받습니다.
2. 원하는 폴더에 압축을 완전히 풉니다.
3. 게임을 종료합니다.
4. 압축을 푼 폴더에서 PowerShell을 열고 다음 명령을 실행합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Install `
  -GameRoot "D:\SteamLibrary\steamapps\common\Benefitship"
```

설치 프로그램은 지원 빌드인지 확인하고, 바뀌는 파일을 게임 폴더의 `.korean-patch-backup\Benefitship`에 자동으로 백업합니다.

## 설치 확인과 원상 복구

설치 상태 확인:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Verify `
  -GameRoot "D:\SteamLibrary\steamapps\common\Benefitship"
```

가장 최근 백업으로 복구:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Restore `
  -GameRoot "D:\SteamLibrary\steamapps\common\Benefitship"
```

## 검증 상태와 제한

- 깨끗한 원본에서 설치, 설치 확인, 반복 설치 판정, 원상 복구를 차례로 통과했습니다.
- 한국어 메인 메뉴, 언어 선택, 옵션의 네 개 탭, 새 게임 초반 대사가 깨짐 없이 표시되는 것을 확인했습니다.
- 기본 캡처 렌더러가 검게 나오는 환경에서는 `RENPY_RENDERER=angle2`로 화면 검증했습니다.
- 모든 분기를 처음부터 엔딩까지 연속으로 플레이하는 전 경로 검증은 아직 끝나지 않았습니다.

이 때문에 현재 버전은 정식판이 아닌 릴리스 후보입니다.

## 배포 형식

게임 실행 파일, 원본 스크립트 전체, 원본 로고 이미지는 포함하지 않습니다. 설치기는 정품 게임에 있는 두 스크립트에 필요한 줄만 치환하고 번역 스크립트와 OFL 글꼴을 추가합니다.

## 권리 관계

정품 보유자를 위한 비공식 비영리 팬 패치이며 개발사·배급사·Steam의 공식 지원물이 아닙니다. 게임과 상표, 시나리오를 포함한 모든 권리는 각 권리자에게 있습니다. 글꼴 고지는 `installer/THIRD_PARTY_NOTICES.md`, 기타 고지는 `LEGAL-NOTICE.md`를 참고하세요.
