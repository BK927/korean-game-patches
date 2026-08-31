# Dream Date Korean recovery — delta release candidate

> 저장소 소스에는 배포용 `.vcdiff` 바이너리를 넣지 않습니다. 실제 설치는
> GitHub Releases의 `Dream-Date-Korean-recovery-0.1.0-rc1.zip`을 받아 진행하세요.

이 폴더는 원본 게임 자산을 포함하지 않는 설치용 릴리스 후보입니다.
`delta/`의 VCDIFF 파일은 매니페스트의 정확한 원본 해시가 일치할 때만
적용됩니다. 새 패치나 다른 버전에는 적용하지 마세요.

## 요구 사항

- Dream Date 설치본과 Steam 종료 상태
- xdelta3 3.x (`xdelta3.exe`가 PATH에 있거나 `-XdeltaPath`로 지정)

## 설치

PowerShell에서 다음을 실행합니다.

```powershell
.\install.ps1 -Force
```

설치 스크립트는 현재 파일 해시를 두 입력 변형(기존 활성 패치 또는
깨끗한 원본 백업) 중 하나와 대조하고, 자동 백업을 만든 뒤 임시 파일을
검증하고 원자적으로 교체합니다. 실패하면 가능한 범위에서 자동 롤백합니다.

## 검증·복구

```powershell
.\verify.ps1 -State patched
.\restore.ps1 -Force -BackupRoot <설치 시 출력된 백업 폴더>
.\verify.ps1 -State source
```

자세한 변경·라이선스 조건은 `RELEASE-NOTES.md`, `LEGAL-NOTICE.md`,
`RUNTIME-QA.md`, `manifest.json`을 확인하세요.
