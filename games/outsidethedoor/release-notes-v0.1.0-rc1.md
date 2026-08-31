# outside the door 한글 패치 v0.1.0-rc1

Steam판 `outside the door`의 비공식 한국어 패치 릴리스 후보입니다.

## 포함 내용

- 대사 1,760개
- UI 문자열 537개
- 이미지 캡션 171줄
- 메뉴 74개, 선택지 168개
- 원본 해시 검사와 자동 백업·복구 설치기

러시아어 원문과 공식 영어 번역을 대조했고, 문맥과 인물별 말투 및 고유명사 표기를 통일했습니다. 시작 메뉴·설정 메뉴·새 게임 첫 장면은 실제 설치본에서 한글 깨짐 없이 표시되는 것을 확인했습니다.

## 설치

압축을 완전히 푼 다음 게임을 종료하고, PowerShell에서 다음 명령을 실행하세요.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Install `
  -GameRoot "D:\SteamLibrary\steamapps\common\OutsideTheDoor"
```

자세한 설치·복구 방법과 현재 검증 범위는 저장소의 `games/outsidethedoor/README.md`를 확인하세요.

## 현재 제한

모든 선택지와 분기 첫 지점은 검증했지만, 모든 경로를 처음부터 엔딩까지 연속 플레이하는 전 경로 검증은 아직 끝나지 않았습니다. 문제를 발견하면 재현 경로와 화면, 게임 버전을 함께 알려 주세요.
