# Dream Date release candidate QA

- 상태: `PASS`
- 조회 시각(UTC): `2026-08-31T03:19:12Z`
- Steam 설치본 수정: `false`
- ZIP: `C:\Users\dead4\Documents\Codex\2026-08-16\d-steamlibrary-steamapps-common-tkpunk-ui\library-audit\work\dream-date-recovery-build\Dream-Date-Korean-recovery-0.1.0-rc1.zip`
- ZIP 크기: `1872627` bytes
- ZIP SHA-256: `991a322affeb4c9eb4e7e9e313501140b54bdaa55498363fff75500ada7cf3fb`

## 배포 안전성

- 전체 Unity 자산 ZIP 포함: `false`
- `.orig` 백업 ZIP 포함: `false`
- 금지 글꼴 바이트 검출: `false`
- Nanum Gothic 해시·고지: `true`
- ZIP sidecar hash: `true`

## 델타 왕복

- active-existing와 original-clean 두 source variant의 VCDIFF가 staging 출력 해시와 일치합니다.
- 각 staging clone에서 install → patched verify/UnityPy parse → restore → source verify를 실행했습니다.

### active-existing

- install: `true`
- patched verify: `true`
- UnityPy parse: `true`
- restore: `true`
- source verify: `true`
- round-trip: `true`

### original-clean

- install: `true`
- patched verify: `true`
- UnityPy parse: `true`
- restore: `true`
- source verify: `true`
- round-trip: `true`

## 변경 범위·주의

- 출력 자산 해시: resources.assets `46d9696160ef585e69b74bdebc1270bd61e1c46072a6886abaf893a5e9c5496c`, sharedassets0.assets `b8bbbae410ddb3d2dcd93a8dd825c145702fab017a5f7e6c54bfd9a9c2196e63`, level2 `5d757c18431f2662060b7f0ac2cc4950fbd52fe3bc4e2e5033140a9cf4baac68`.
- 변경 허용 오브젝트: `MonoBehaviour 3832`, `Font 93/94`, `level2 MonoBehaviour 764/768/776/822`.
- `.resS` 사이드카는 설치/복구 스크립트에서 접근하지 않습니다.
- 이 자동 QA는 시각적 줄바꿈·모든 장면의 수동 플레이 테스트를 대신하지 않습니다.
- 저장소 publish/커밋/푸시는 수행하지 않았습니다.
