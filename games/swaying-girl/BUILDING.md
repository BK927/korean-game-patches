# Swaying Girl 패치 재빌드

저장소에는 번역문, 빌더, 설치·복구 도구와 검증 기록만 보관합니다. 게임 원본 자산과 배포용 `.vcdiff`는 커밋하지 않으며, 완성된 설치 ZIP은 GitHub Releases에만 올립니다.

## 준비물

- 정품 Steam 설치본
- Python 3.11 이상과 `UnityPy`
- `xdelta3` 3.x
- 아래 네 종류의 입력 파일
  - 순정 `sharedassets1.assets`
  - 순정 `level1`
  - 기존 미완성 한패 상태의 `sharedassets1.assets`
  - 기존 미완성 한패 상태의 `level1`

빌더는 기본적으로 게임 폴더의 `sharedassets1.assets.orig`, `level1.codex_monmusu_swaying.bak`을 순정 입력으로 사용합니다. 다른 위치에 있다면 환경 변수로 정확한 경로를 지정합니다.

```powershell
$env:SWAYING_GAME_ROOT = 'D:\SteamLibrary\steamapps\common\Swaying Girl'
$env:SWAYING_ORIGINAL_SHAREDASSETS = 'D:\safe-inputs\sharedassets1.assets'
$env:SWAYING_ORIGINAL_LEVEL1 = 'D:\safe-inputs\level1'
$env:SWAYING_PREVIOUS_ROOT = 'D:\safe-inputs\previous-korean-patch'

python .\tools\build_release_candidate.py --xdelta 'C:\path\to\xdelta3.exe'
```

`SWAYING_PREVIOUS_ROOT`에는 기존 미완성 한패 상태의 두 파일이 있어야 합니다. 번역문 위치를 바꾸려면 `SWAYING_TRANSLATION_ROOT`를 지정할 수 있습니다.

## 빌더가 확인하는 항목

- `Girl11`, `Girl21`의 비공백 행 수와 숫자 제어 접두사 보존
- 번역문과 UI 문자열의 중국어·일본어 잔존 여부
- `sharedassets1.assets`에서 TextAsset 2개만 변경됐는지
- `level1`에서 허용된 MonoBehaviour 26개만 변경됐는지
- 두 입력 상태용 VCDIFF의 인코딩·디코딩 왕복과 출력 SHA-256
- 실제 실행 스모크 테스트 기록 포함 여부

출력은 `games/swaying-girl/dist/` 아래에 만들어지며 이 폴더는 저장소에서 제외됩니다. 원본 게임 파일이나 미리 패치된 완성 자산은 어떤 형태로도 배포하지 마세요.
