define first_choice = 0
define second_choice = 0


label start:
    if persistent.gallery_unlocked_new:
        menu:
            "본편":
                jump part1
            "후일담":
                jump extra1
    else:
        jump part1


label part1:
    scene bg_coffee_1
    with fade
    play music bgm_6 fadeout 1.0 fadein 2.0
    play sound sound_fengling

    call achievement ("1") from _call_achievement_4

    "카페 문을 열자 익숙한 원두 향기가 코끝을 스쳤다."
    "토요일 오후, 햇살이 카페의 통유리창을 통해 나무 바닥 위로 나른하게 쏟아지고 있었다."

    l "……음?"

    scene cg2
    with dissolve

    "평소 내가 즐겨 앉던 '전용' 좌석에 오늘은 웬…… 중학생이 앉아 있었다."
    "——숙제라도 하러 온 건가?"
    "카운터에서 아이스 아메리카노를 주문하며 곁눈질로 그 소녀를 살폈다."
    "소녀는 태블릿 위에 무언가를 그리는 데 열중하고 있었다. 작은 몸을 거의 탁자에 파묻다시피 한 채, 오버니삭스를 신은 다리를 탁자 밑에서 즐겁게 흔들거렸다."

    "……저렇게 즐거운 표정인 걸 보니 숙제는 아닌 모양이다."

    scene bg_coffee_1
    with dissolve

    show syq_ smile at center
    with dissolve

    s "……?"

    with vpunch

    l "아……"

    "찰나의 순간, 눈이 마주친 것 같았다."
    "왠지 모를 찔리는 기분에 나는 얼른 시선을 돌렸다."

    show syq_ smile at left
    with dissolve

    s "……"

    hide syq_
    with dissolve

    "커피를 받아 들고 습관적으로 원래 내 자리로 향하다가, 거의 다다라서야 상황을 깨달았다."

    "하지만 이제 와서 방향을 트는 것도 이상해 보여서, 결국 그녀 맞은편 테이블에 앉기로 했다."

    with Shake((0, 0, 0, 0), 0.5, dist=10)
    l "……으으."

    "아이스 아메리카노를 한 모금 들이켰다. 여전히…… 맛없다."

    l "……"

    "커피잔을 내려놓았다. 평소와 다른 각도로 들어오는 햇살이 조금 눈부셨다."

    scene cg2
    with dissolve

    "나는 시선을 내리고 멍하니 생각에 잠겼다."

    play music bgm_10 fadeout 1.5 fadein 1.5
    play sound "audio/sound/maou_se_sound_fall01.ogg"

    s "아……"

    l "……?"

    "내 발치로 굴러온 무언가를 주워 들었다. 터치펜인가?"
    "이 근처엔 나와 그 소녀뿐이었으니 주인이 누구인지는 뻔했다."

    scene bg_coffee_1
    with dissolve

    show syq_ smile at center
    with dissolve

    l "저기요……"

    "나는 맞은편의 작은 인영을 향해 펜을 들어 보였다."

    l "이거 네 펜이야?"

    show syq_ cat_mouth at center, bounce_small

    s "……히히."

    "많아 봐야 열두세 살 정도로 보이는 소녀는 잠시 주춤하더니, 이내 소악마 같은 짓궂은 미소를 지었다."

    l "……?"

    "소녀는 턱을 괴고는 하얀 니삭스를 신은 두 다리를 가볍게 교차하며 비벼댔다."


    show syq_ cat_mouth at center:
        ease 0.5 xpos 0.45
        ease 0.5 xpos 0.55
        ease 0.5 xpos 0.5


    s "아저씨, 방금 내 다리 훔쳐보고 있었죠?"

    l "……하아?"

    s "시치미 떼지 마시고요~"

    s "풉~ 기분 나빠~ 아저씨 혹시 로리콘이에요?"

    l "………………"

    "나는 소녀의 눈을 잠시 빤히 바라보다가, 결단을 내렸다."
    "——그대로 몸을 돌려 터치펜을 카페 책장에 올려두고는, 내 커피를 챙겨 자리를 떴다."

    show syq_ astonished at center, emphasis_pop

    s "……어?"

    s "야, 너 잠깐만!"

    l "……"

    show syq_ pout at center:
        ease 0.2 xpos 0.45
        ease 0.2 xpos 0.55
        ease 0.2 xpos 0.5
    with dissolve


    s "너…… 일부러 그러는 거지!"

    l "……난 그냥 이상한 꼬맹이랑 엮이기 싫을 뿐이야."

    s "……일부러 내 손 안 닿는 곳에 펜을 두다니!"

    l "어?"

    "나는 당황해서 그녀를 쳐다보았다가 펜을 둔 선반 높이를 확인했다. 상황을 깨닫고 나니 조금 미안해졌다."

    l "그게…… 일부러 그런 건 아니었어."

    "내가 펜을 다시 집어 들자 소녀가 손을 뻗었다. 하지만 나는 펜을 다시 머리 위로 높이 들어 올렸다."

    show syq_ bewilderment at center

    s "?"

    l "'고맙습니다'는 어디 갔어?"

    l "방금 전 일은 내가 미안하게 됐지만, 어른을 놀려 먹는 건 나쁜 버릇이야."

    l "특히 다른 사람이 물건을 주워줬을 때는 더더욱."

    show syq_ wrath at center, glare_shake

    s "내 다리를 뚫어져라 쳐다보던 변태 아저씨한테 해줄 말은 없거든요!"

    l "……누가 아저씨라는 거야, 이 꼬맹아."

    "——내가 아무리 봐도 네 부모님보다는 훨씬 젊을걸!"

    l "그리고 내가 언제 네 다리를 그렇게 빤히 봤다고 그래. 생사람 잡지 마……"

    show syq_ pout at center

    s "앉을 때부터 계속 그랬으면서……"

    l "아……"

    "그 말을 듣고 나서야 나도 상황이 이해가 갔다."

    l "그건 그냥 멍하게 있었던 거야."

    play music bgm_11 fadeout 2.0 fadein 2.0

    show syq_ bewilderment at center
    with dissolve

    s "……멍하게 있었다고요?"

    l "……난 여기 올 때마다 항상 이런 상태야. 못 믿겠으면 카운터 사장님한테 물어보든가."

    show syq_ blush skin_shy at center, shy_shrink

    s "으음……!"

    "소녀의 뽀얀 볼이 눈에 띄게 붉어졌다."

    s "그, 그그, 그럼 처음 들어왔을 때는……"

    l "아…… 그때는 확실히 좀 보긴 했지."

    show syq_ pout skin_blush

    "내가 당당하게 인정하자, 수줍어하던 소녀는 금세 정색하며 눈을 흘겼고, 이내 볼을 빵빵하게 부풀렸다."
    "——표정 변화가 참 다채롭기도 하지."

    show syq_ pout at center

    s "어, 어쨌든 아저씨도 잘한 거 하나도 없거든요!"

    show syq_ shy at center, shy_shrink

    s "그래도…… 고마워요……"

    l "오…… 그래."

    "나는 살짝 눈을 크게 떴다."
    "한참을 더 억지 부릴 줄 알았는데, 오해가 풀리자마자 태도가 싹 바뀌는 게 의외였다."
    "이 꼬맹이, 의외로 속은 깊은 걸지도."

    l "자, 여기."

    "나는 펜을 건네주며 무심결에 그녀의 머리를 쓰다듬었다."

    show syq_ astonished at center, bounce_small

    s "어……?"

    l "그런데 꼬마야, 이름이 뭐야?"

    show syq_ wrath at center, emphasis_pop

    s "우윽……!"

    l "우? 우씨야?"

    hide syq_

    with Shake((0, 0, 0, 0), 0.5, dist=30)

    "갑자기 고개를 숙여 표정을 가린 소녀가 내 발등을 세게 밟았다."

    show syq_ pout at center


    l "아얏……!"

    s "여자애 머리 함부로 만지는 거 아니거든요!"


    show syq_ wrath at right
    with ease
    hide syq_
    with dissolve

    "말을 마친 그녀는 성큼성큼 자리로 돌아가 펜과 태블릿을 가방에 쑤셔 넣고는 씩씩거리며 입구로 향했다."



    show syq_ despise at offscreenright
    with dissolve
    show syq_ despise at right
    with ease


    "두어 걸음 가던 그녀는 무언가 생각났는지 다시 뒤를 돌아왔다."
    "나는 반사적으로 발을 거두며 뒤로 두 걸음 물러났다."



    "하지만 소녀는 나를 매섭게 째려보고는, 자리에 남아 있던 커피를 단숨에 들이켜고 다시 씩씩하게 구두 소리를 내며 사라졌다."
    play sound sound_footsteps

    show syq_ despise at offscreenright
    with ease
    hide syq_

    "……이번엔 정말로 나갔다."

    stop music fadeout 3.0

    l "……"

    "그 꼬맹이, 성격 참 까칠하네."

    call achievement ("2") from _call_achievement_5

    scene bg_office_1
    with Fade(1.0, 0.5, 1.0)
    play music bgm_4 fadeout 1.0 fadein 2.0


    "다음 날, 일요일 오후."
    "원래 쉬어야 할 날이지만, 진행 중인 프로젝트 일정엔 쉴 틈 따위 없었다."
    "물론 우리 회사는 야근을 권장하지 않는다. 언제나 그랬다."
    "——프로젝트에 긴급 사고가 터졌을 때조차 말이다."

    scene bg_coffee_1
    with fade

    "결국 황금 같은 주말에 회사에 나가 무료 봉사(?)를 하고 난 뒤, 나는 습관처럼 이곳을 찾았다. 휴식이라기보다는 주말 출근이라는 비극에서 도망치기 위한 도피처에 가까웠다."
    "졸업 후 프로그래머로 사는 삶은 내 세계를 점점 좁게 만들었다. 회사와 집이라고 부르기 민망한 자취방, 그리고 이 카페가 내 세상의 전부였다."
    "졸업 직후의 그 넘치던 의욕은 일 년도 채 안 되어 바닥을 드러냈다."
    "——참 한심하기도 하지."
    "나는 쓴웃음을 지으며 고개를 저었다. 커피를 한 모금 마시려던 찰나, 근처의 실루엣 하나가 내 시야에 들어왔다."

    play music bgm_6 fadeout 1.0 fadein 2.0

    show SD15
    with dissolve

    if persistent.stockings_color == 0:
        show SD13:
            xalign 0.52
        with dissolve
    elif persistent.stockings_color == 1:
        show SD12:
            xalign 0.52
        with dissolve
    else:
        show SD14:
            xalign 0.52
        with dissolve

    l "……"

    if persistent.stockings_color == 0:
        show SD13:
            xalign 0.5
        with dissolve
    elif persistent.stockings_color == 1:
        show SD12:
            xalign 0.5
        with dissolve
    else:
        show SD14:
            xalign 0.5
        with dissolve


    "또 그 꼬맹이다."


    if persistent.stockings_color == 0:
        show SD13:
            xalign 0.52
        with dissolve
    elif persistent.stockings_color == 1:
        show SD12:
            xalign 0.52
        with dissolve
    else:
        show SD14:
            xalign 0.52
        with dissolve

    "소녀는 나를 등진 채 카페 책장 위쪽을 빤히 바라보고 있었다."

    if persistent.stockings_color == 0:
        show SD13:
            xalign 0.48
        with dissolve
    elif persistent.stockings_color == 1:
        show SD12:
            xalign 0.48
        with dissolve
    else:
        show SD14:
            xalign 0.48
        with dissolve

    "——짐작건대 책장 높은 곳에 있는 책을 꺼내고 싶은 모양이다."


    if persistent.stockings_color == 0:
        show SD13:
            xalign 0.52
        with dissolve
    elif persistent.stockings_color == 1:
        show SD12:
            xalign 0.52
        with dissolve
    else:
        show SD14:
            xalign 0.52
        with dissolve

    l "………………"

    "그녀가 의자를 끌어와 밟고 올라가려는 걸 보고는 더 이상 망설일 수 없었다. 나는 자리에서 일어나 그녀에게 다가갔다."

    if persistent.stockings_color == 0:
        hide SD13
    elif persistent.stockings_color == 1:
        hide SD12
    else:
        hide SD14

    hide SD15

    hide syq_
    with dissolve
    show syq_ smile at left
    with ease
    show syq_ despise at center
    with ease

    s "어? 로리콘 아저씨네요."

    "뒤에서 다가온 게 나라는 걸 알자, 그녀는 고개를 들어 경계심 가득한 눈빛으로 나를 쳐다봤다."

    l "……누가 로리콘 아저씨라는 거야!"

    show syq_ cat_mouth at center, lean_in

    s "그럼…… 다리 성애자 아저씨?"

    l "……"

    s "아, 조용한 걸 보니 맞나 보네."

    "나는 묵묵히 시선을 피했다."

    l "그래서, 도움이 필요해?"

    show syq_ focus at center, bounce_small

    s "에?"

    l "무슨 책 꺼내려고? 이 《동아시아 미식》? 아니면 옆에 있는…… 설마 아니겠지만 《미적분학 해설》?"

    s "……그 사이에 있는 《스타킹 도감》요."

    l "……하아?"

    "내가 일부러 건너뛴 딱 한 권의 책이었다."

    l "……알았어. 꺼내줄게."

    "뭐, 지식에 귀천은 없는 법이니까. 묻고 싶은 게 산더미 같았지만 나는 침묵을 지키며 점잖게 행동하기로 했다."

    l "……여기."

    show syq_ smile at center
    with dissolve

    s "……고마워요."

    "이번엔 그녀의 얼굴에서 장난기나 비웃음이 사라졌다."
    "그제야 가까운 거리에서 평온한 상태인 그녀의 얼굴을 제대로 볼 수 있었다."
    "확실히 앳된 얼굴이었지만, 분위기에선 묘한 성숙함이 느껴졌다. 특히 그 눈빛은 중학생 특유의 천진난만함 대신 무언가 깊이 있는…… 연륜 같은 게 담겨 있었다."

    l "그림 그릴 때 참고하려고?"

    "책을 진지하게 훑어보는 그녀에게 내가 말을 건넸다."

    s "어?"

    l "미안, 실은 지난번에 네 태블릿에 그려진 스케치를 좀 봤거든. 스케치였지만 캐릭터가 참 예쁘더라."

    show syq_ cachinnation at center, bounce_small

    s "오호~"

    "그녀는 눈을 깜빡였고, 경계하던 표정은 호기심으로 바뀌었다."

    s "안목이 좀 있네요, 아저씨."

    l "이봐, 자꾸 아저씨 아저씨 하지 좀 마."

    "내가 그렇게 늙어 보여?"

    l "너 중학생 맞지? 나 대학교 졸업한 지 일 년도 안 됐거든. 오빠라고 불러."

    show syq_ wink at center


    play music bgm_10 fadeout 1.0 fadein 1.0

    s "흥, 내가 중학생이라고 누가 그래요?"

    show syq_ cat_mouth at center, lean_in

    "그녀는 입술을 삐죽이며 장난이 성공했을 때 짓는 특유의 의기양양한 표정을 지었다."

    s "이 몸은 이미 스물세 살이거든요. 아시겠어요?"

    l "……………………"

    l "……어?"

    "나는 눈을 부릅뜨고 그녀를 머리부터 발끝까지 다시 훑어보았다."
    "이 가느다란 팔다리에 절벽이나 다름없는 어린애 같은 몸매인 네가 나보다 나이가 많다고?"

    show syq_ bewilderment at center, bounce_small

    s "……어딜 보는 거예요?"

    l "미, 미안. 그냥 너무 놀라서……"

    show syq_ shy at center
    with dissolve

    s "……이럴 줄 알았어요."

    "그녀는 한숨을 쉬더니 신분증을 꺼내 내 앞에서 살짝 흔들어 보였다."
    "사진은 분명 그녀였고, 생년월일도 그녀 말대로 계산하면 스물세 살이 맞았다. 그리고 이름은……"

    l "수유칭?"

    show syq_ surprised_but skin_blush at center, emphasis_pop

    e "아, 이름 가리는 걸 깜빡했네……"

    "그녀는 조금 당황한 듯 허둥지둥 신분증을 집어넣었다."

    l "나는 린모야. 두 나무 린, 말 없는 모."

    e "어?"

    l "나만 일방적으로 네 이름을 아는 건 좀 불공평하잖아?"

    show syq_ smile at center
    with dissolve

    e "후우……"

    "그녀는 나이에 어울리는 성숙한 미소를 지어 보이더니, 곧 내게 한 손을 내밀어 악수를 청했다."

    e "수유칭…… 어떻게 쓰는지는 이미 봤죠?"

    e "앞으로 잘 부탁해요, 아저씨."

    show syq_ smile at center, bounce_small

    "나는 그녀의 손을 잡았다. 작지만 따뜻하고 부드러운 손이었다."

    pause 1.0

    l "잘 부탁해…… 그런데 아저씨라고 부르는 건 좀 그만해 주면 안 될까? 나 아직 스물둘인데……"

    show syq_ cat_mouth at center, lean_in

    e "이미 직장인이잖아요. 어차피 조만간 아저씨 소리 들을 텐데 너무 버티지 마세요."

    l "……"

    "방금 잠깐 이 독설가 꼬맹이가 어른스러워 보였던 건, 분명 내 착각이었겠지."

    call achievement ("3") from _call_achievement_6

    play music bgm_4 fadeout 1.0 fadein 2.0
    scene bg_office_3
    with Fade(1.0, 0.5, 1.0)


    "——세상은 원래부터 어떻게든 굴러가는 허술한 무대였다."
    "어른인 척하며 회사에 다니기 시작한 뒤로, 나는 어른들이 이루고 있다는 이 세계에 씌워져 있던 필터를 벗겨내게 되었다."
    "회사란 단호하고 유능한 전문가들이 움직이는 은하전함인 줄 알았는데, 실제로는 여기저기 기워 붙여 겨우 달리는 낡은 차에 가까웠다."

    l "하아……"

    "깊은 밤 컴퓨터 앞에서, 나는 몇 번째인지도 모를 긴 한숨을 내쉬었다."
    "원래는 꽤 여유가 있던 일정이었지만, 앞단 작업을 맡은 동료가 계속 미루는 바람에 내 손에 넘어왔을 때는 사흘 안에 열흘 치 넘는 일을 끝내야 하는 상황이 되어 있었다."
    "이렇게 된 이상 죽어라 달리는 수밖에 없었다."

    scene bg_office_2
    with fade

    l "……"

    "사람은 스스로를 몰아붙여 보지 않으면 자신의 한계를 알 수 없다——어디서 본 말인지는 이제 기억나지 않는다."
    "하지만 그 말을 누가 했는지에 관심이 없는 것처럼, 회사 일에 관해서도 내가 밤샘 야근을 어디까지 견딜 수 있는지 알고 싶지 않았다."
    "사흘 안에 진도를 따라잡기 위해 나는 아예 침낭을 회사로 가져갔고, 낮밤을 잊은 코딩 기계가 되었다."
    "회사에서 과로사라도 한다면, 그 자리에서 계속 키보드를 두드리는 원혼이 되지 않을까."
    "다행히 결국 오늘 출근 시간 전까지 살아서 끝내기는 했다."
    "화면의 빌드 진행률을 바라보다가, 내 생각은 점점 다른 곳으로 흘러갔다."
    "창밖 거리에는 새벽빛이 내려앉아 있었다. 밤이 흘리고 간 별빛처럼."

    "나는 점점 번져 가는 빛을 바라보다가, 어째서인지 온몸에서 빛이 나는 듯했던 그 작은 모습을 떠올렸다."

    l "후우…………"

    "——잠 좀 보충하고 나서 카페에 가자."
    "컵에 남은 인스턴트커피를 싱크대에 버리며, 나는 그렇게 생각했다."


    scene bg_coffee_1
    with fade

    play music bgm_6 fadeout 1.0 fadein 2.0



    show syq_ smile at left
    with dissolve
    pause 0.5
    show syq_ smile at center
    with ease

    e "어라, 사축 아저씨 또 오셨네."

    "익숙한 목소리가 옆에서 들려와 고개를 돌리자, 수유칭이 자기 음료를 들고 곧장 내 쪽으로 걸어오고 있었다."
    "지난번에 이야기를 나눈 뒤로 처음의 경계심은 사라진 모양이었지만, 입은 여전히 거침없었다."

    l "왔구나."

    show syq_ cat_mouth at center, lean_in

    e "……아저씨, 왜 이렇게 기운이 없어요?"

    e "그 나이에 벌써 몸이 축난 거예요?"

    l "……야근 때문이야."

    "그렇게 노골적인 말을 듣고도 나는 눈을 굴리지 않을 수 없었다."
    "그녀는 묻지도 않고 내 앞에 털썩 앉아, 자연스럽게 합석한 모양새가 되었다."

    l "그러고 보니 너 일러스트레이터야?"

    "그녀가 태블릿과 터치펜을 꺼내는 것을 보고, 나는 호기심에 물었다."

    show syq_ smile at center
    with dissolve

    e "맞아요. 저, 프로거든요."

    l "어쩐지 그림을 잘 그리더라."

    show syq_ cachinnation at center, bounce_small

    e "당연하죠!"

    "내 칭찬에 그녀는 고개도 들지 않고 대답했지만, 살짝 올라간 입꼬리가 내면의 작은 설렘을 드러내고 있었다."

    l "하지만 출근하는 것처럼 보이지는 않는데…… 프리랜서 일러스트레이터인가요?"

    show syq_ shy at center, shy_shrink

    e "음……"

    "그녀는 잠시 멈칫하더니 눈동자가 흔들렸다. 무언가 좋지 않은 기억이 떠오른 듯했다."
    "하지만 그런 눈빛은 금세 사라졌다."

    show syq_ focus at center

    e "수입은 불안정하지만, 적어도 매일 지하철에 끼어 타지 않아도 되고 직장 내 인간관계로 고민할 필요도 없으니까요……"

    "가냘픈 소녀가 동정 어린 눈빛으로 나를 쳐다보았다."

    e "어떤 사축 아저씨처럼 996(아침 9시부터 밤 9시까지 주 6일 근무)을 할 필요도 없고요."

    l "996?"

    "나는 쓴웃음을 지었다."
    "——그녀는 내가 말한 야근이 996이라고 생각하는 걸까?"

    l "정말 996이기만 해도 좋겠네. 난 요 며칠 거의 007(24시간 내내 주 7일 근무) 수준이었으니까……"

    show syq_ astonished at center, deny_shake_small

    "그녀는 눈을 살짝 크게 뜨더니 고개를 저었다."

    e "쯧쯧, 역시 사축이네."

    show syq_ surprised_but at center

    e "그런데 아저씨, 이렇게 힘들게 일하면 월급은 엄청 많겠지?"

    l "……더 물어보면 울어버릴지도 몰라?"

    show syq_ bewilderment at center
    with dissolve

    e "으음……"

    e "그럼 왜 계속 이 일을 하는 거야?"

    l "왜냐니……"

    play music bgm_4 fadeout 2.0 fadein 2.0

    "나는 커피잔을 만지작거리며, 생각지도 못한 이 질문에 대해 고민했다."
    "왜일까? 익숙해져서일까? 아니면 다른 길을 찾지 못해서일까?"

    l "……"

    pause 1.5

    l "아마도, 딱히 바꾸고 싶은 이유를 찾지 못해서겠지."

    "나는 수유칭이 오기 전까지 읽고 있던 책을 덮어 테이블 구석에 놓았다."

    l "이 책처럼 말이야. 나한테는 읽어도 그만, 안 읽어도 그만인 거지."

    l "그렇다고 일어나서 다른 책을 찾아볼 만큼 흥미가 있는 것도 아니고."

    show syq_ bewilderment at center

    e "……"

    show syq_ despise at center, lean_in

    e "정말 지루하게 사네, 아저씨 인생."

    "나는 솔직하게 고개를 끄덕였다."

    l "하지만…… 다들 비슷하게 살지 않아? 그냥 흐르는 대로, 딱히 좋아하지도 않는 일을 하면서……"

    "말을 내뱉고 나서야 바로 눈앞에 반례가 있다는 사실을 깨달았다."

    l "큼큼……"

    show syq_ pout at center
    with dissolve

    "내가 뭐라고 하기도 전에, 소녀는 꽤 불만스럽다는 듯 볼을 부풀렸다."

    show syq_ smile at center
    with dissolve

    e "난 그림 그리는 거 꽤 좋아하는데?"

    e "의뢰를 받을 때 불쾌한 일도 겪긴 하지만, 그림 그리는 것 자체는 나한테 큰 즐거움이야."

    l "……내가 생각이 짧았네."

    l "사실 여기서 너를 처음 봤을 때, 즐겁게 그림에 몰두하는 모습에 끌렸던 거거든."

    play music bgm_11 fadeout 2.0 fadein 2.0

    l "……내가 마지막으로 무언가에 온전히 몰입했던 게 언제였는지 기억조차 안 나네……"

    show syq_ shy skin_blush at center, shy_shrink

    e "우우……"

    show syq_ shy skin_blush at center, deny_shake_small

    "그녀는 조금 쑥스러운지 몸을 움찔거렸다."

    e "내가 그렇게…… 즐거워 보였어?"

    l "그랬어."


    l "난 네가 그렇게 집중하고 있는 모습이 참 좋더라."

    show syq_ despise at center

    e "그, 그럼 외모 때문이 아니었어?"

    l "어……"

    l "……확실히 너도 귀엽긴 해."

    pause 2.0

    e "……"

    l "……"

    "그녀는 손에 든 터치펜 너머로 나를 30초 동안 뚫어지게 쳐다보더니, 갑자기 조금 복잡한 표정을 지었다."


    show syq_ smile at center
    with Dissolve(1.0)

    e "이제 아저씨가 로리콘이 아니라는 걸 믿어줄게."

    l "……오늘에서야 믿어주는 거야!?"

    l "그런데 왜 나랑 합석한 건데?"

    show syq_ cat_mouth at center, bounce_small

    e "그전에는 로리콘이긴 하지만 착한 사람인 줄 알았지!"

    "로리콘과 착한 사람이라니…… 참으로 보기 드문 조합이군."

    scene bg_coffee_1
    with Fade(1.0, 0.5, 1.0)
    play music bgm_6 fadeout 2.0 fadein 2.0

    "그 후 몇 주 동안, 우리는 카페에서 자주 '우연히' 마주쳤다."
    "우연이라고는 하지만, 사실 서로의 방문 시간을 짐작하며 맞춘 무언의 약속이라는 걸 우리 둘 다 알고 있었다."
    "우리가 이 묵계를 유지하는 이유라면……"

    scene cg2
    with dissolve

    servant "꼬마야, 여기서 혼자 숙제하고 있는 거니?"

    e "저 꼬마 아니거든요. 그리고 숙제하는 것도 아니에요."

    "수유칭의 목소리에서 피로가 묻어났다."
    "이 카페에 새로운 아르바이트생이 올 때마다 이런 대화가 반복되곤 한다."

    servant "어? 하지만……"

    "새로 온 아르바이트생은 분명 의아하다는 표정을 지었다."
    "오랫동안 혼자 있는 아이에게 관심을 갖는 건 인지상정이겠지만, 평소 소악마 같은 수유칭조차 이런 상황에서는 상대를 놀려먹지 못했다."


    l "이 친구 꼬마 아니에요. 제 친구입니다."

    "막 도착한 내가 그 장면을 보고 다가가 그녀를 도와주었다."

    servant "……친구라고요?"

    "아르바이트생은 정의로운 눈빛으로 나를 바라보았다. 의구심이 풀리기는커녕 경계심만 더 강해진 것 같았다."

    e "……직장 동료예요."

    servant "아…… 죄송합니다……"

    "그녀의 말을 듣고 그는 미심쩍은 듯 사과하더니, 나를 몇 초간 쳐다본 뒤에야 자리를 떴다."

    e "고마워, 사축 아저씨."

    l "……이게 벌써 몇 번째지?"

    e "익숙해졌어."

    "그녀는 어깨를 으쓱하며 체념한 듯한 표정을 지었다."

    l "차라리 사장님한테 부탁해서 네 사진을 직원 휴게실에 붙여두는 게 어때? 그러면……"

    scene bg_coffee_1
    with dissolve


    show syq_ pout at center
    with dissolve

    e "……바보야?"

    e "누가 지명 수배자처럼 사진이 걸리고 싶겠냐고!"

    l "……그렇게 말하니까 좀 이상하긴 하네……"

    "나는 머리를 긁적이며 평소처럼 그녀의 맞은편에 앉았다."
    "——나와 함께 앉아 있으면 아까 같은 상황은 거의 일어나지 않는다."
    "이것이 그녀가 나와의 합석 묵계를 유지하는 이유 중 하나일 것이다."
    "확실히 그녀의 외모로 카페에 혼자 있는 건 너무 눈에 띄니까."

    show syq_ bewilderment at center, shy_shrink

    e "하아……"

    play music bgm_12 fadeout 2.0 fadein 2.0

    "수유칭은 펜을 내려놓았다. 마음속에 쌓여 있던 불만이 둑이 터진 것처럼 쏟아져 나왔다."


    e "지하철 탈 때 뜬금없이 학생 표를 사라고 안내받고, 은행 업무 보러 가니까 보호자 동반했냐고 묻고……"

    e "맥주 두 캔 사려는데 점원이 꼬치꼬치 캐묻지를 않나……"

    e "가끔은 그냥 신분증을 목에 걸고 다닐까 생각도 한다니까……"

    l "……그러면 더 이름표 달고 다니는 초등학생 같지 않겠어?"

    show syq_ shy at center, shy_shrink

    e "……"

    "그녀는 멍하니 있다가, 바람 빠진 공처럼 테이블 위에 엎드려 버렸다."

    show syq_ focus at center

    e "……근데 아저씨는 좀 특별한 것 같아."

    "수유칭은 고개를 옆으로 돌린 채 생각에 잠긴 듯 나를 바라보았다."

    l "특별하다고?"

    e "대부분은 선입견을 품고 나를 돌봐줘야 할 어린애로 보거나, 아니면……"

    show syq_ bewilderment skin_black at center, lean_in

    "그녀는 잠시 말을 멈췄고, 얼굴에 불쾌함이 스쳤다."

    e "……아니면 이상한 생각을 품거나 말이지."

    with Dissolve(1.0)

    l "……"

    "그녀가 무엇을 말하는지 대충 짐작이 갔다."
    "어린 외모에 자주 혼자 다니는 여성이라면, 불순한 의도를 가진 사람들과 마주치기 쉬울 것이다."

    show syq_ smile skin_blush at center, bounce_small
    with dissolve

    e "그런데 아저씨는 나한테…… 참 스스럼없단 말이야."

    e "내 진짜 나이를 알게 된 후에도 아주 평범하게 대해주고."

    play music bgm_11 fadeout 2.0 fadein 2.0

    l "난 그저 사람에 대한 존중이 겉모습에 의해 결정되어서는 안 된다고 생각할 뿐이야."

    show syq_ focus skin_blush at center, emphasis_pop

    e "아……"

    l "그리고……"

    l "애당초 여자든 여자아이든 어떻게 대해야 할지 잘 모르겠어서, 그냥 똑같이 대하기로 한 거기도 하고."


    show syq_ cachinnation at center:
        ease 0.3 zoom 1.0
        ease 0.2 ypos 0.95
        ease 0.2 ypos 1.0
    with dissolve

    e "푸하핫!"

    play music bgm_7 fadeout 1.5 fadein 1.5

    e "\"그렇게 번지르르하게 말하다니, 아저씨 지금 자기가 동정이라고 광고하는 거야?\""

    l "……좀 작게 말해줄래? 아르바이트생이 아까부터 나 째려보고 있거든."

    e "미안 미안, 이렇게 대놓고 자기가 동정이라고 말하는 아저씨는 처음이라서~"

    l "내가 도대체 언제 대놓고 동정이라고 했다고……"

    show syq_ cat_mouth at center, lean_in

    e "에헤이~"

    "그녀는 장난을 치려는 듯한 미소를 띠며 내 눈을 뚫어지게 쳐다보았다."

    e "아니라고 말하고 싶은 거야?"

    l "……………………"

    "나는 커피를 한 모금 마시며 대답을 거부했다."

    e "그럴 줄 알았어……"

    play music bgm_3 fadeout 1.5 fadein 1.5

    play sound sound_vibrate

    "그녀가 무언가 더 말하려 할 때, 테이블 위에 놓인 핸드폰이 갑자기 예고 없이 진동하기 시작했다."

    show syq_ astonished at center, emphasis_pop

    "마침 고개를 숙여 커피를 마시던 내 눈에 화면이 켜지며 나타난 알림이 들어왔다."
    "——\"예약하신 유에란쨩의 방송이 곧……\""
    "시간을 확인하기도 전에 그녀는 잽싸게 핸드폰을 낚아채더니, 긴장한 기색으로 화면을 몇 번 터치하고는 나와 눈을 맞추었다."

    show syq_ bewilderment at center
    with dissolve

    e "……봤어?"

    l "미안, 고의는 아니었어……"

    l "네가 구독하는 스트리머야?"

    show syq_ shy at center
    with dissolve

    e "어?"

    e "어…… 뭐, 그렇다고 할 수 있지……"

    "그녀는 핸드폰을 꽉 쥔 채 시선을 피했다."

    l "……"

    "나는 턱을 만지작거리며 눈앞의 소녀를 진지하게 바라보았다."

    l "이 유에란쨩이라는 분…… 방송 내용이 어디 내놓기 부끄러운 거야?"

    show syq_ wrath at center
    with dissolve

    e "누가 부끄러운 방송을 한다는 거야!"

    hide syq_

    with Shake((0, 0, 0, 0), 0.5, dist=30)

    l "……으윽!!!!"

    show syq_ pout at center

    "그녀는 테이블 밑에서 구두로 내 정강이를 세게 걷어찼다."
    "어찌나 힘껏 찼는지 정강이뼈에 금이 간 게 아닐까 의심될 정도였다."
    "\"그럼 도대체 무슨 방송을 하는 건데\" —— 이 말을 내뱉기도 전에, 내가 겨우 정신을 차렸을 때 그녀는 이미 화가 머리끝까지 난 채 입구 너머로 사라지고 없었다."

    hide syq_
    with dissolve

    l "……"

    "……이상하네, 왜 그렇게 화를 낸 거지?"
    "나는 차인 정강이 앞부분을 문지르며, 마음속에서 대담한 가설 하나를 떠올렸다."

    scene bg_boy_room_3
    with Fade(1.0, 0.5, 1.0)

    play music bgm_12 fadeout 2.0 fadein 2.0

    "그날 밤, 나는 가장 유명한 플랫폼 몇 군데에서 '유에란쨩'이라는 이름을 검색했다."
    "방송을 하지 않는 동명 ID들을 제외하고 나니, 오늘 밤 8시에 방송 예정인 계정이 하나 남았다. 분명 내가 찾는 그 사람일 것이다."
    "8시까지 몇 분 남은 상황에서 나는 미리 방송 채널에 들어갔다."
    "방송이 시작되기도 전인데 벌써 많은 시청자가 모여 채팅을 나누고 있었다."

    danmu "「유에란쨩 오늘 뭐 방송해?」"
    danmu "「저번에는 게임 방송이었으니까 이번에는 그림 방송이겠지?」"
    danmu "「유에란쨩의 누님 목소리 진짜 최고다. 유에란쨩이랑 결혼만 시켜준다면 평생 호강하며 살아도 여한이 없겠어.」"



    l "어……"

    "——어쨌든 이 유에란쨩이라는 분, 인기가 상당한 모양이다."
    "아수라장 같은 채팅창을 보고 있을 때, 방송이 갑자기 시작되었다."
    "화면에는 화려한 드레스를 입고 분홍색 긴 머리를 늘어뜨린 누님이 나타났다. 온몸에 꽃 장식도 가득 달려 있었다."
    "성숙한 누님 캐릭터로 보였다."
    "하지만……"

    l "설마 버츄얼 스트리머였을 줄이야……"

    "수유칭이 예약한 게 버츄얼 스트리머의 방송일 줄은 몰랐다."

    yrj "여러분 안녕하세요, 오래 기다리셨죠~"

    "이어폰을 통해 들려오는 목소리는 캐릭터 이미지 그대로 성숙하고 부드러운 누님 톤이었다."
    "채팅창의 메시지들이 눈을 뗄 수 없을 정도로 빠르게 올라갔다."
    "하지만 유에란쨩은 그 빠른 채팅 속에서도 소통할 주제를 잘 찾아내며 여유롭게 대화를 이어나갔다."

    yrj "……자, 그럼 그림 그리기 시작해 볼까요?"

    yrj "오늘은 지난번에 그리던 그림을 마저 그릴 거예요. 쉬는 동안 몰래 선화를 다 따두었답니다."

    l "……응?"

    "화면이 전환되자마자 아주 낯익은 그림이 눈에 들어왔다."

    l "……저거, 꼭 그녀의 그림 같은데……"

    "하지만 세부적인 부분이 미묘하게 달랐다."

    l "……"

    l "과연 그렇군."

    "상황 파악이 끝났다."

    scene bg_coffee_3
    with Fade(1.0, 0.5, 1.0)

    play music bgm_3 fadeout 2.0 fadein 2.0

    "다음 날, 나는 평소 수유칭이 집으로 돌아가기 전 시간에 맞춰 카페에 도착했다."

    show syq_ bewilderment at center
    with dissolve

    "가게에 들어서니 한 손으로 턱을 괸 채 건성으로 태블릿에 선을 긋고 있는 수유칭이 보였다."

    show syq_ focus at center
    with dissolve

    e "……!"

    "그리고 그녀가 고개를 들었을 때 내 시선과 정면으로 부딪혔다."

    l "……"

    "나는 성큼성큼 다가가 거의 우리 전용석이 된 테이블로 향했다. 턱을 괴고 있던 그녀는 왠지 모르게 허리를 꼿꼿이 폈다."

    show syq_ smile
    with dissolve

    e "……오늘은 꽤 늦었네."

    l "오늘은 야근 좀 했어."

    e "역시나. 사축 아저씨가 또 야근하는 건 아닌가 생각하고 있었지."

    l "……실은 낮에 집중을 못 해서 남아서 마무리하느라 늦은 거야."

    l "그도 그럴 게, 어젯밤 방송이 아주 흥미진진했거든."

    "나는 짐짓 아무렇지 않게 툭 내뱉었다."

    show syq_ astonished skin_blush at center, shy_shrink
    with vpunch

    e "……!"

    "그녀는 손에 든 터치펜을 떨어뜨릴 뻔하며 눈에 띄게 당황했다."

    e "너, 너 지금 무슨 방송을 말하는 거야!"

    l "그 왜…… 유에란쨩 방송 말이야."

    l "그런데 그림이 너랑 참 비슷하더라. 뭐 짐작 가는 거 없어?"

    show syq_ bewilderment skin_blush at center, deny_shake_small

    e "나, 난 무슨 소린지 모르겠네. 별하늘이랑 소녀는 아주 흔한 조합이라고!"

    "그녀는 필사적으로 고개를 저었지만, 귓불은 이미 붉게 달아오르고 있었다."

    e "아, 아니지. 사실 그분 방송을 보고 모작한 거라서 비슷한 거야!"

    l "……정말?"

    e "그, 그렇다니까……"

    "얼굴을 붉히며 우기는 모습을 보고 나는 한숨을 쉬며 고개를 저었다."

    with Dissolve(1.0)
    play music bgm_1 fadeout 1.0 fadein 1.0

    l "……하지만 난 이미 간파했지. 진실은 언제나 하나!"

    show syq_ astonished skin_blush at center, emphasis_pop
    with vpunch

    e "……!"

    l "너 지금 거짓말하고 있어!"

    show syq_ shy skin_shy at center, shy_shrink

    e "으윽……"

    "그녀는 갑자기 몸을 웅크렸다. 평소보다 더 작아진 느낌이었다."

    l "진실은 바로, 유에란쨩이 네 언니라는 거지!"

    show syq_ bewilderment skin_blush at center, bounce_small

    e "맞아, 사실 내가…… 어?"

    l "다 이해해. 스트리머는 컨셉이 중요하잖아!"

    l "그래서 유에란쨩의 컨셉은 미소녀 일러스트레이터인데, 언니는 그림을 못 그리니까 네가 대리 작업을 해주는 거지!"

    e "……"

    l "그럼 유에란쨩이 그림 방송을 가끔 하는 것도 설명이 되고 말이야!"

    l "뭐, 버츄얼 스트리머가 시청자를 속이는 건 좋지 않지만, 내가 입 밖으로 내지는 않을 테니 안심해."

    show syq_ wrath skin_blush at center, emphasis_pop
    with vpunch

    e "……너 진짜……"

    l "응?"

    e "이제 적당히 좀 해!"

    e "컨셉이니 뭐니, 무슨 소린지 하나도 모르겠거든!"

    e "그리고 난 외동딸이야! 언니 같은 거 없다고!"

    l "……그럼 다른 누구인 건데……?"

    show syq_ bewilderment at center
    with dissolve

    e "……"

    "자신도 모르게 일어섰던 수유칭이 다시 자리에 앉았다."
    "그녀는 일그러진 표정으로 관자놀이를 지그시 누르며 깊은 한숨을 내쉬었다."

    show syq_ shy skin_shy at center, shy_shrink

    play music bgm_9 fadeout 3.0 fadein 3.0

    e "……내가 유에란쨩이야."

    with vpunch
    with Dissolve(1.5)

    l "……"

    l "……어?"


    jump part2

    return
return
# Decompiled by unrpyc: https://github.com/CensoredUsername/unrpyc
