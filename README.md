# Korean Game Patches

BK927이 제작한 게임 한글 패치를 장기적으로 보관하고 배포하기 위한 저장소입니다.

게임 원본 파일은 포함하지 않습니다. 각 배포본은 정품 게임 파일에 적용되는 변경분과 설치·복구 도구만 제공합니다.

## 패치 목록

| 게임 | 상태 | 최신 버전 | 안내 |
| --- | --- | --- | --- |
| T.K.PUNK (삼국 펑크) | 배포 준비 완료 | v1.1.0 | [설치 및 상세 정보](games/tkpunk/README.md) |
| Absent in the Rain (비가 되어, 사람을 벗다) | 번역 완료 | v1.0.2 | [설치 및 상세 정보](games/amehazu/README.md) |
| 奇迹一刻 Surmount (기적의 순간) | 번역 완료 | v0.1.0 | [설치 및 상세 정보](games/surmount/README.md) |
| outside the door | 릴리스 후보 | v0.1.0-rc1 | [설치 및 상세 정보](games/outsidethedoor/README.md) |
| Benefitship | 릴리스 후보 | v0.1.0-rc1 | [설치 및 상세 정보](games/benefitship/README.md) |
| My succubus Kukula | 릴리스 후보 | v0.2.0-rc1 | [설치 및 상세 정보](games/my-succubus-kukula/README.md) |
| Tiny Shadows: Interwoven Hearts | 릴리스 후보 | v0.1.0-rc1 | [설치 및 상세 정보](games/tiny-shadows-interwoven-hearts/README-KO.md) |

## 저장소 구성

```text
games/
├─ _template/       새 게임을 추가할 때 사용하는 기본 틀
├─ amehazu/         Absent in the Rain 한글 패치
├─ benefitship/     Benefitship 한글 패치
├─ my-succubus-kukula/ My succubus Kukula 한글 패치
├─ outsidethedoor/  outside the door 한글 패치
├─ surmount/        奇迹一刻 Surmount 한글 패치
├─ tiny-shadows-interwoven-hearts/ Tiny Shadows 한글 패치
└─ tkpunk/          T.K.PUNK 한글 패치
   ├─ assets/       소개용 이미지
   ├─ installer/    설치·복구 도구 원본
   └─ README.md     지원 버전과 설치 안내
```

실제 다운로드 파일은 저장소에 직접 넣지 않고 [Releases](https://github.com/BK927/korean-game-patches/releases)에 게임별 태그로 게시합니다. 태그는 `게임-slug/v버전` 형식을 사용합니다.

## 공통 원칙

- 정품 게임 보유자를 위한 비공식 팬 패치입니다.
- 적용 전 대상 파일의 SHA-256을 검사합니다.
- 설치 시 원본 파일을 같은 폴더에 자동 백업합니다.
- 지원하지 않는 게임 버전에는 패치를 강제로 적용하지 않습니다.
- 게임 원본 전체 파일은 배포하지 않습니다.

각 게임과 상표의 권리는 해당 권리자에게 있습니다. 권리자의 정당한 요청이 있으면 관련 자료를 조정하거나 제거할 수 있습니다.
