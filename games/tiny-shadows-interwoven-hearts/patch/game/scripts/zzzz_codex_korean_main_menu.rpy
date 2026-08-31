init 999:
    style codex_ko_root_button is button:
        xsize 360
        ysize 76
        background Solid("#4b244e")
        hover_background Solid("#74366f")
        insensitive_background Solid("#7d717d")

    style codex_ko_root_button_text is default:
        font "ChillRoundGothic_Bold.ttf"
        color "#fff7ff"
        hover_color "#ffffff"
        insensitive_color "#ded4de"
        size 38
        xalign 0.5
        yalign 0.5
        text_align 0.5

    style codex_ko_pref_label is default:
        font "ChillRoundGothic_Bold.ttf"
        color "#3a2433"
        size 30

    style codex_ko_pref_value is default:
        font "ChillRoundGothic_Bold.ttf"
        color "#5b4b50"
        size 24

    style codex_ko_pref_button is button:
        xsize 210
        ysize 54
        background Solid("#4b244e")
        hover_background Solid("#74366f")

    style codex_ko_pref_button_text is default:
        font "ChillRoundGothic_Bold.ttf"
        color "#fff7ff"
        hover_color "#ffffff"
        size 24
        xalign 0.5
        yalign 0.5

    style codex_ko_pref_bar is bar:
        xsize 620
        ysize 26
        left_bar Solid("#4b244e")
        right_bar Solid("#d9cbd9")
        hover_left_bar Solid("#74366f")
        hover_right_bar Solid("#d9cbd9")
        thumb Solid("#3a2433")
        thumb_offset 10

screen main_menu():
    tag menu

    add Solid("#edf4d8")

    frame:
        xpos 0
        ypos 0
        xysize (1920, 1080)
        background Solid("#edf4d8")
        padding (0, 0)

        fixed:
            add Solid("#f7e5ef") xpos 0 ypos 0 xysize (650, 1080)
            add Solid("#d9f1dc") xpos 650 ypos 0 xysize (1270, 1080)

            frame:
                xpos 70
                ypos 95
                xysize (560, 250)
                background Solid("#fff8e8")
                padding (28, 24)

                vbox:
                    spacing 8
                    text "작은 그림자," font "ChillRoundGothic_Bold.ttf" size 62 color "#3a2433"
                    text "겹쳐진 마음" font "ChillRoundGothic_Bold.ttf" size 68 color "#3a2433"
                    text "Tiny Shadows ~ Interwoven Hearts" font "ChillRoundGothic_Bold.ttf" size 24 color "#5b4b50"

            vbox:
                xpos 120
                ypos 390
                spacing 26

                textbutton "새 게임" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action Start()
                textbutton "이어하기" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action Continue()
                textbutton "불러오기" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action ShowMenu("load")
                textbutton "설정" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action ShowMenu("preferences")
                textbutton "감상 모드" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action [ShowMenu("gallery"), SetVariable("gallery_page", 1)] sensitive persistent.gallery_unlocked_new
                textbutton "종료" style "codex_ko_root_button" text_style "codex_ko_root_button_text" action Quit(confirm=False)

            frame:
                xpos 1510
                ypos 72
                xysize (260, 92)
                background Solid("#4b244e")
                padding (20, 10)

                vbox:
                    xalign 0.5
                    yalign 0.5
                    spacing 2
                    text "언어" font "ChillRoundGothic_Bold.ttf" size 24 color "#fff7ff" xalign 0.5
                    text "한국어" font "ChillRoundGothic_Bold.ttf" size 34 color "#fff7ff" xalign 0.5

            text "한글패치 적용됨" xpos 1510 ypos 984 font "ChillRoundGothic_Bold.ttf" size 28 color "#5b4b50"

screen preferences():
    tag menu

    add Solid("#edf4d8")

    frame:
        xpos 90
        ypos 70
        xysize (1740, 940)
        background Solid("#fff8e8")
        padding (42, 36)

        fixed:
            text "설정" xpos 0 ypos 0 font "ChillRoundGothic_Bold.ttf" size 56 color "#3a2433"
            text "한국어" xpos 1450 ypos 10 font "ChillRoundGothic_Bold.ttf" size 34 color "#5b4b50"

            vbox:
                xpos 0
                ypos 115
                spacing 30

                hbox:
                    spacing 30
                    text "화면" style "codex_ko_pref_label" xsize 220
                    textbutton "창 모드" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("display", "window")
                    textbutton "전체 화면" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("display", "fullscreen")

                hbox:
                    spacing 30
                    text "스킵" style "codex_ko_pref_label" xsize 220
                    textbutton "읽은 문장" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("skip", "seen")
                    textbutton "전체 문장" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("skip", "all")

                hbox:
                    spacing 30
                    text "전환 효과" style "codex_ko_pref_label" xsize 220
                    textbutton "켜기/끄기" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("transitions", "toggle")

                hbox:
                    spacing 30
                    text "자동 진행" style "codex_ko_pref_label" xsize 220
                    textbutton "켜기/끄기" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("auto-forward", "toggle")

                hbox:
                    spacing 30
                    text "언어" style "codex_ko_pref_label" xsize 220
                    text "한국어" style "codex_ko_pref_value" yalign 0.5

            vbox:
                xpos 0
                ypos 430
                spacing 32

                hbox:
                    spacing 30
                    text "텍스트 속도" style "codex_ko_pref_label" xsize 220
                    bar value Preference("text speed") style "codex_ko_pref_bar" yalign 0.5

                hbox:
                    spacing 30
                    text "자동 속도" style "codex_ko_pref_label" xsize 220
                    bar value Preference("auto-forward time") style "codex_ko_pref_bar" yalign 0.5

                hbox:
                    spacing 30
                    text "전체 음량" style "codex_ko_pref_label" xsize 220
                    bar value Preference("main volume") style "codex_ko_pref_bar" yalign 0.5

                hbox:
                    spacing 30
                    text "음악" style "codex_ko_pref_label" xsize 220
                    bar value Preference("music volume") style "codex_ko_pref_bar" yalign 0.5

                hbox:
                    spacing 30
                    text "효과음" style "codex_ko_pref_label" xsize 220
                    bar value Preference("sound volume") style "codex_ko_pref_bar" yalign 0.5

                hbox:
                    spacing 30
                    text "음성" style "codex_ko_pref_label" xsize 220
                    bar value Preference("voice volume") style "codex_ko_pref_bar" yalign 0.5

            hbox:
                xpos 0
                ypos 820
                spacing 28
                textbutton "전체 음소거" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("all mute", "toggle")
                textbutton "기본값" style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Preference("reset")

            textbutton "뒤로" xpos 1450 ypos 820 style "codex_ko_pref_button" text_style "codex_ko_pref_button_text" action Return()
