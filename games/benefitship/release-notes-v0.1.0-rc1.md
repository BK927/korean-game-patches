# Benefitship 한글 패치 v0.1.0-rc1

Steam판 `Benefitship`의 비공식 한국어 패치 릴리스 후보입니다.

## 포함 내용

- 최신 원문과 정확히 대응하는 대사·내레이션 번역 블록 1,569개
- UI·설정·크레딧 문자열 102개
- 한국어 언어 선택과 Noto Sans CJK KR 글꼴
- 원본 해시 검사, 자동 백업, 설치 확인과 원상 복구

기존에 중단된 번역을 최신 원문에 다시 맞춘 뒤 문맥과 인물 말투, 용어 일관성 기준으로 검수했습니다. 이전 합본의 중복 13개와 고아 번역 1,235개를 제거하고 문맥 오류 69건(문자열 102곳)을 직접 교정했습니다. 한국어 로고 파일이 없을 때 실행이 중단되던 문제와 옵션 탭 글자가 네모로 나오던 문제도 고쳤습니다.

## 설치

압축을 완전히 푼 다음 게임을 종료하고 PowerShell에서 다음 명령을 실행하세요.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Mode Install `
  -GameRoot "D:\SteamLibrary\steamapps\common\Benefitship"
```

자세한 설치·복구 방법과 지원 빌드는 저장소의 `games/benefitship/README.md`를 확인하세요.

## 현재 제한

메인 메뉴, 옵션, 새 게임 첫 장면과 설치·복구 왕복 검증은 통과했지만 모든 분기를 엔딩까지 연속 플레이하지는 않았습니다. 문제를 발견하면 게임 빌드 ID, 재현 경로, 화면을 함께 알려 주세요.
