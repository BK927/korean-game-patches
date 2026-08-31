# Swaying Girl 한국어 복구 패치 0.1.0-rc1

> 저장소 소스에는 배포용 `.vcdiff` 파일을 넣지 않습니다. 실제 설치는 GitHub Releases의 `Swaying_Girl_Korean_Recovery_0.1.0-rc1.zip`을 내려받아 진행하세요.

Steam AppID 1393350, BuildID 12343356용 릴리스 후보입니다. 중국어 대사 TextAsset 두 개와 장면/UI 문구 26개를 한국어로 교체합니다. 원본 게임 자산은 포함하지 않고 VCDIFF 델타만 제공합니다.

## 설치

1. 게임을 종료합니다.
2. xdelta3 3.x를 설치해 `xdelta3.exe`가 PATH에 있도록 합니다.
3. PowerShell에서 다음을 실행합니다.

```powershell
.\install.ps1 -GameRoot "D:\SteamLibrary\steamapps\common\Swaying Girl" -Force
```

설치 전 두 파일의 SHA-256이 지원 목록과 정확히 일치해야 하며, 원본은 게임 폴더의 `.korean-patch-backup\Swaying-Girl` 아래에 보존됩니다. `restore.ps1`에는 설치 출력에 표시된 정확한 백업 경로를 지정하세요.

정적 자산·델타 왕복 검사와 실제 게임의 메인 화면, 도움말, 첫 대사·선택지 런타임 확인을 통과했습니다. 전체 엔딩과 자유 모드는 이번 스모크 테스트 범위에 포함하지 않았습니다.
