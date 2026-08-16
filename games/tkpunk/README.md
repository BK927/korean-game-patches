# T.K.PUNK (삼국 펑크) 한글 패치

![한글 타이틀 로고](assets/title-logo-ko.png)

중국어 원문을 기준으로 본문, UI, 스토리 대사와 이미지형 UI를 한국어로 옮긴 비공식 팬 패치입니다. 영어·일본어 번역은 중국어 표현이 모호한 경우에만 참고했습니다.

## v1.0.0 적용 범위

- 기본 언어표 고유 문구 3,923개
- 스토리 고유 문구 24,832개
- 내장 다국어 문구 2,586개
- 추가 프리팹 라벨 146개
- 이미지형 UI 53개
- 한글 타이틀 로고와 부제
- 한글 글꼴 11,172자

번역 용어, 플레이스홀더, 리치 텍스트 태그, 줄바꿈과 수치를 교차 검증했으며 실제 게임의 첫 화면과 메인 메뉴까지 실행 확인했습니다.

## 지원 환경

- 플랫폼: Windows / Steam
- 설치 폴더 기본값: `SteamLibrary\steamapps\common\tkpunk`
- 대상 원본 `resources\app.asar` SHA-256:
  `D6F10010E181672B1D1A444BBF500035336D3B35E6D8EE26F7A9ADAC0AB6A09A`
- 패치 적용 후 SHA-256:
  `409B7385CF54616480E6CCD9EC66C0044B420531EDF34C3B9DC35A4ABD67150B`

위 원본 해시와 다른 게임 버전에는 설치되지 않습니다.

## 설치 방법

1. [Releases](https://github.com/BK927/korean-game-patches/releases)에서 `TKPUNK_KoreanPatch_v1.0.0.zip`을 받습니다.
2. 원하는 폴더에 압축을 완전히 풉니다.
3. 게임을 종료합니다.
4. `INSTALL_KOREAN_PATCH.bat`을 실행합니다.
5. 자동으로 게임을 찾지 못하면 `tkpunk` 게임 폴더를 입력합니다.

설치 프로그램은 원본을 `resources\app.asar.korean-patch-backup`으로 보관한 뒤 패치를 적용합니다.

## 원상 복구

패치 폴더의 `RESTORE_ORIGINAL.bat`을 실행합니다. Steam의 파일 무결성 검사로도 원본을 복구할 수 있습니다.

## 알려진 제한

- 튜토리얼 영상 51개에는 중국어 UI가 영상 자체에 포함되어 있어 번역되지 않았습니다.
- 일부 배경 간판과 세계관 장식 문자는 원작 미술을 보존했습니다.
- 게임 업데이트로 `app.asar`가 변경되면 새 버전 대응이 필요합니다.

## 배포 형식

게임 파일 전체 대신 약 11MB의 VCDIFF 변경분만 제공합니다. 설치 시 사용자가 보유한 정품 원본에서 패치본을 재구성합니다.

Xdelta 3.2.0은 Apache License 2.0으로 배포되며 자세한 고지는 배포본의 `THIRD_PARTY_NOTICES.md`에 있습니다.

각 게임과 상표의 권리는 해당 권리자에게 있습니다.
