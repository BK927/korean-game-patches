


image syq_ = LayeredImageProxy("syq", Transform(yzoom = 0.45, xzoom=-0.45, yoffset=700))

image side syq_ = LayeredImageProxy("syq", Transform(yzoom = 0.45, xzoom=-0.45, yoffset=700))

image text_ctc:
    "gui/custom/dialog/dialog_waiting.png"
    xpos 1546
    ypos 997
    linear 1 alpha 0.0
    linear 1 alpha 1.0
    repeat

screen ctc(arg=None):

    add "text_ctc"


define e = Character(_("수유칭"), image="syq_")
define l = Character(_("린모"))
define s = Character(_("？？？"), image="syq_")
define servant = Character(_("종업원"))
define vendor_a = Character(_("노점상 A"))
define vendor_b = Character(_("노점상 B"))
define vendor_ab = Character(_("노점상 A&B"))
define passer = Character(_("행인 A"))
define rude_uncle = Character(_("아저씨"))
define clerk = Character(_("점원"))
define colleague_a = Character(_("동료 A"))
define supervisor = Character(_("팀장"))
define king = Character(_("왕 이사"))
define boss_chen = Character(_("천 대표"))
define comment_paid = Character(_("슈퍼챗"))
define danmu = Character(_("채팅"))
define yrj = Character(_("유에란쨩"))
define young_artist = Character(_("젊은 일러스트레이터"))
define otaku_a = Character(_("오타쿠 A"))
define otaku_b = Character(_("오타쿠 B"))
define otaku_c = Character(_("오타쿠 C"))
define otaku_d = Character(_("오타쿠 D"))
define staff = Character(_("직원"))

init python:

    _CLOTHES_POSTURES = {"clothes1_front", "clothes1_side", "clothes2_front", "clothes2_side"}

    def syq_adjuster(names):
        """기본 clothes_posture(clothes1_front)를 주입하고 스타킹 선택을 처리합니다"""
        atts = list(names[1:])
        
        
        if not (_CLOTHES_POSTURES & set(atts)):
            atts.append("clothes1_front")
        
        
        atts = [a for a in atts if a not in ("bare", "white_silk", "black_silk")]
        if persistent.stockings_color == 0:
            atts.append("bare")
        elif persistent.stockings_color == 1:
            atts.append("white_silk")
        elif persistent.stockings_color == 2:
            atts.append("black_silk")
        
        return tuple([names[0]] + atts)

define config.adjust_attributes["syq_"] = syq_adjuster
# Decompiled by unrpyc: https://github.com/CensoredUsername/unrpyc
