# outside the door 한글 패치

러시아어 원문과 공식 영어 번역을 함께 대조해 만든 비공식 한국어 패치입니다. 게임의 `english` 언어 슬롯을 한국어로 교체하며 대사, 선택지, 설정 메뉴, 이미지형 캡션을 적용합니다.

## v0.1.0-rc1 적용 범위

- 활성 대사 1,760개 원문 대조 및 런타임 렌더 검증
- UI 문자열 537개 전수 검토
- 문맥·표현·표기 문제 319건 수정
- 이미지 캡션 53개 키, 191개 배치 중 실제 표시 171줄 한국어화
- 메뉴 74개와 선택지 168개 전수 한국어 렌더 및 분기 진입 검증
- 시작 화면, 설정 화면, 새 게임 첫 장면 실제 실행 확인

인명과 호칭, 세계관 용어는 대사 전체에서 통일했습니다. 스크립트 식별자와 제어 태그는 원형을 유지합니다.

## 지원 환경

- 플랫폼: Windows / Steam
- Steam AppID: `2680680`
- 게임 표시 버전: `1.0`
- 기준 빌드 시각: `2026-07-14 06:30:18 UTC`
- 기준 원본: 패키지 `manifest.json`에 기록된 6개 파일의 크기와 SHA-256

원본 해시가 다르면 설치를 중단합니다. 게임이 업데이트된 경우 강제로 적용하지 마세요.

## 설치 방법

1. [Releases](https://github.com/BK927/korean-game-patches/releases)에서 `OutsideTheDoor-Korean-Patch-0.1.0-rc1.zip`을 받습니다.
2. 원하는 폴더에 압축을 완전히 풉니다.
3. 게임을 종료합니다.
4. 압축을 푼 폴더에서 PowerShell을 열고 다음 명령을 실행합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Install `
  -GameRoot "D:\SteamLibrary\steamapps\common\OutsideTheDoor"
```

설치 프로그램은 대상 파일의 원본 해시를 확인한 뒤 게임 폴더의 `.korean-patch-backup\OutsideTheDoor`에 자동 백업합니다.

## 설치 확인과 원상 복구

설치 상태 확인:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Verify `
  -GameRoot "D:\SteamLibrary\steamapps\common\OutsideTheDoor"
```

가장 최근 백업으로 복구:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Restore `
  -GameRoot "D:\SteamLibrary\steamapps\common\OutsideTheDoor"
```

## 검증 상태와 제한

- 1,760개 대사, 537개 UI 문자열, 168개 선택지의 렌더 검증을 통과했습니다.
- 모든 선택지를 실제 게임의 해당 분기 첫 지점까지 진입시키는 검증을 통과했습니다.
- 실제 설치본에서 시작 메뉴, 설정 메뉴, 새 게임 첫 대사가 깨짐 없이 표시되는 것을 확인했습니다.
- 모든 분기를 처음부터 엔딩까지 연속 플레이하는 전 경로 검증은 아직 끝나지 않았습니다.
- Steam 업적, 업데이트, 파일 무결성 검사와의 상호작용은 검증하지 않았습니다.

이 때문에 현재 버전은 정식판이 아닌 릴리스 후보로 배포합니다.

## 배포 형식

실행 파일, DLL, 원본 RPA 아카이브, 원본 이미지와 폰트는 포함하지 않습니다. 번역 스크립트와 설치·복구 도구만 제공합니다.

## 권리 관계

정품 보유자를 위한 비공식 비영리 팬 패치이며 개발사·배급사·Steam의 공식 지원물이 아닙니다. 게임과 상표, 시나리오를 포함한 모든 권리는 각 권리자에게 있습니다. 자세한 고지는 `LEGAL-NOTICE.md`를 참고하세요.
