# Misha's incident 한국어 품질 복구 패치 0.1.0-rc1

Steam AppID 2723520, BuildID 13860399 기준 릴리스 후보입니다. 기존 미완성 한국어 패치를 바탕으로 원문과 장면 문맥을 다시 대조해 전체 3,829개 번역 단위를 검수했고, 그중 800개 문장을 교정했습니다.

배포본에는 게임 원본 JSON을 넣지 않습니다. 78개 데이터 파일 안의 번역 위치 6,193곳에 적용할 한국어 문장과 원문 문자열의 SHA-256만 담습니다. 순정 영문판과 이전 한국어 시험판을 모두 인식하며, 예상하지 못한 값이 하나라도 나오면 설치 전에 중단합니다.

## 설치

1. 게임을 종료합니다.
2. GitHub Releases에서 `Mishas_incident_KoreanPatch_0.1.0-rc1.zip`을 내려받아 압축을 풉니다.
3. PowerShell에서 다음을 실행합니다.

```powershell
.\install.ps1 -Mode Install -GameRoot "D:\SteamLibrary\steamapps\common\Misha's incident"
```

설치기는 변경될 파일만 `.korean-patch-backup\Mishas-incident` 아래에 백업합니다.

## 확인과 복구

```powershell
.\verify.ps1 -GameRoot "D:\SteamLibrary\steamapps\common\Misha's incident"
.\restore.ps1 -GameRoot "D:\SteamLibrary\steamapps\common\Misha's incident"
```

`restore.ps1`은 가장 최근 백업을 복구합니다. 특정 백업을 복구하려면 `-BackupId`를 함께 지정하세요.

## 검증 범위

- 전체 3,829개 번역 단위 전수 문맥 검수
- P1 오역·문법 파손 160건, P2 번역투·말투·용어 640건 교정
- 제어 코드, 변수, 자리표시자, 줄바꿈, 잔여 CJK 자동 검사
- 순정본과 기존 시험판에서 각각 설치 → 6,193개 위치 검증 → 복구 왕복 시험
- 실제 Steam 실행으로 한국어 제목, 메인 메뉴, 첫 장면 대사와 줄바꿈 확인

전체 분기와 엔딩을 직접 플레이한 것은 아니므로 이번 버전은 릴리스 후보로 표시합니다.
