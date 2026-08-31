image title_bg_3_a:
    "images/jianbian.png"

screen fullscreen_text(cg, position, position_en, name):
    zorder 100

    add cg
    add "title_bg_3_a"

    vbox:
        xalign 1.3
        yalign 0.45
        text position:
            min_width 1000
            text_align 0.5
            color "#FFF"
            size 48
            outlines [(1, "#332e3e", 0, 0)]
            kerning 2
        text position_en:
            ypos 10
            min_width 1000
            text_align 0.5
            color "#767171"
            size 18
        text name:
            ypos 50
            min_width 1000
            text_align 0.5
            color "#332e3e"
            size 36
            kerning 2
            line_spacing 10

label end:
    play music "audio/bgm/maou_bgm_piano_song_ahurera.mp3" fadeout 1.0 fadein 2.0

    hide screen quick_menu
    scene chunbai
    with dissolve


    $ _cg510 = "cg510"
    if persistent.stockings_color == 0:
        $ _cg510 = "cg512"
    elif persistent.stockings_color == 1:
        $ _cg510 = "cg511"

    show screen fullscreen_text(_cg510,_("기획"),"Game Planner",_("감자꽃 제작팀"))
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text("cg2",_("시나리오"),"Scenario","치자스 RL")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text("cg30",_("원화"),"Original Art","ula 양배추")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text("cg40",_("성우"),"Character Voice","중국어: 첸밍링\n일본어: 祈里マリヱ")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5

    show screen fullscreen_text("cg1",_("오디오 후반 작업"),"Voice Post-Production","첸밍링, w샤오리")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text("SD10",_("UI 디자인/PV 제작"),"UI Designer/PV Maker","상자 속 고양이")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text("SD201",_("일본어 현지화"),"Japanese Localization","SakuyatheLonER")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5


    show screen fullscreen_text(_cg510,_("홍보 이미지"),"Poster","렁단")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5

    $ _cg520 = "cg520"
    if persistent.stockings_color == 0:
        $ _cg520 = "cg522"
    elif persistent.stockings_color == 1:
        $ _cg520 = "cg521"


    show screen fullscreen_text(_cg520,_("프로그래밍"),"Programmer","샤댜오노팡콰이")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 2.5

    $ _cg530 = "cg530"
    if persistent.stockings_color == 0:
        $ _cg530 = "cg532"
    elif persistent.stockings_color == 1:
        $ _cg530 = "cg531"


    show screen fullscreen_text(_cg530,_("공용 소재"),"Public Resources","BGM: 음악의 알, 마왕혼\n\n배경: Koala\n33 조전상색\n샤오예 배경점\n싱샤미면\n배경전문점 미니쿠루\nPansy")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 6.5


    show screen fullscreen_text(_cg510,_("특별 감사"),"Special Thanks","CnGal 자료실\n캣닢 제작팀\nAozoraSoftware\nMirreams")
    with Dissolve(1)
    $ renpy.pause(0.5, hard=True)
    pause 6.5

    hide screen fullscreen_text
    with Dissolve(1)
    pause 0.5

    $ persistent.gallery_unlocked_new = True

    jump extra1
return
# Decompiled by unrpyc: https://github.com/CensoredUsername/unrpyc
