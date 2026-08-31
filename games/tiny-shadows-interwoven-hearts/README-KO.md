# Tiny Shadows: Interwoven Hearts 한글 패치

Steam 빌드 `1.28`용 복구 릴리스 후보입니다. 최신 본편과 추가 후일담을 포함한
2,637개 대사, 메인 메뉴와 설정 화면을 한국어화했습니다.

## 설치

1. 게임을 종료합니다.
2. GitHub Releases에서 `Tiny_Shadows_Interwoven_Hearts_Korean_Recovery_Delta.zip`을 내려받아 압축을 풉니다.
3. 압축을 푼 폴더에서 PowerShell을 열고 다음 명령을 실행합니다.

```powershell
.\install.ps1 -GameRoot 'D:\SteamLibrary\steamapps\common\小小的身影，重叠的内心'
```

설치기는 지원하는 게임 파일 해시를 먼저 확인하고, 변경 대상의 검증된 백업을
게임 스크립트 검색 범위 밖에 만든 뒤 임시 파일을 거쳐 적용합니다. 알려진 구형
패치 파일은 정확한 해시가 일치할 때만 제거합니다.

## 복구

게임을 종료한 뒤 같은 폴더에서 실행합니다.

```powershell
.\restore.ps1 -GameRoot 'D:\SteamLibrary\steamapps\common\小小的身影，重叠的内心'
```

설치 후 사용자가 대상 파일을 바꾼 경우에는 덮어쓰지 않습니다. 백업과 현재 설치
해시가 모두 맞아야 복구하며, 복구 뒤에도 원본 해시를 다시 확인합니다.

## 검증 범위

- Ren’Py lint, 제어 토큰, 분기·라벨, 잔여 중국어 검사를 통과했습니다.
- 실제 Steam 설치본에서 메인 메뉴, 설정, 새 게임 첫 장면, 배경, 한글 글꼴과
  두 줄 대사 줄바꿈을 확인했습니다.
- 실제 설치→복구 뒤 원본 해시 불일치와 새 파일 잔존이 모두 0건이었습니다.
- 짧은 퀵 메뉴 표기 `AUTO / SKIP / SAVE / LOAD / LOG / SYS.`는 이번 RC에서
  원문 그대로 남아 있습니다.

원본 `scripts.rpa`, 실행 파일, 이미지·음성·런타임은 배포물에 포함하지 않습니다.
정품 Steam 설치본이 필요합니다. 정확한 지원 해시는 [manifest.json](manifest.json),
상세 결과는 [qa.md](qa.md)에서 확인할 수 있습니다.
