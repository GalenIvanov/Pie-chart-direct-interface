Red [
    Title:  "Direct manipulation of Pie chart"
    Author: "Galen Ivanov" 
    needs:  view
]

img-tile: draw 20x20 [fill-pen white pen black line-width 4 box 0x0 20x20]
img-dual: draw 20x20 [fill-pen white pen black line-width 2 box 0x0 20x20
                      line 10x0 10x20 line 0x10 20x10]
img-diam: draw 20x20 [fill-pen white pen black line-width 2 box 0x0 20x20
                      polygon 10x0 20x10 10x20 0x10]
img-truc: draw 20x20 [fill-pen white pen black line-width 2 box 0x0 20x20
                      fill-pen transparent circle 0x0 10 circle 20x20 10]  
img-diag: draw 20x20 [fill-pen white pen black line-width 2 box 0x0 20x20
                      line 0x0 20x20 line 20x0 0x20]                      
                      
cnt: 120x120 ;100x100
ard: 90x90 ;70x70

; indices in sectors sub-blocks 
sweep: 1  
color: 2
chkid: 3
img:   4

drag?: false
sel:  none
start-ang: 0
delta-ang: 0
start-sweep: 0
start: 0

sectors: [
    sides:     [360 yello       c-tile img-tile]
    centers:   [  0 255.170.120 c-dual img-dual]
    diamond:   [  0 pink        c-diam img-diam]
    truchet:   [  0 papaya      c-truc img-truc] 
    diagonals: [  0 beige       c-diag img-diag]
]
sectors-copy: make block! 10
checked: copy [sides:]
drag-coords: make block! 10

reset-chk: func [ used ][
    ; set all the checks to true and their share to 20%
    foreach s used [sectors/:s/:sweep: 72]
    c-tile/data: on
    c-dual/data: on
    c-diam/data: on
    c-truc/data: on
    c-diag/data: on
]

make-pie: has [ ; function [
    fr-start
][
    pie: make block! 200
    fr-start: start
    
    clear drag-coords
    
    collect/into [
        keep [pen black]    
        foreach [s t] sectors [
            if t/:sweep > 0 [
                keep compose [ fill-pen (t/:color)]
                keep either single? checked [
                    compose [circle (cnt) (ard/x)]                
                ][    
                    compose/deep [scale 0.1 0.1 [pen white line-width 10 arc (cnt * 10) (ard * 10) (fr-start) (t/:sweep) closed]]
                ]    
                keep compose/deep [
                    rotate (fr-start + (t/:sweep / 2)) (cnt) 
                    [image (get t/:img) (as-pair (cnt/x + ard/x + 10) cnt/y - 10)]
                ]
                append drag-coords compose [
                    (as-pair (cosine (t/:sweep / 2 + fr-start)) * (ard/x + 18) + cnt/x
                             (sine   (t/:sweep / 2 + fr-start)) * (ard/y + 18) + cnt/y)
                    (s)
                ]
                fr-start: fr-start + t/:sweep  // 360
            ]
        ]
    ] pie
    update-texts
    append clear bs-pie/draw pie
]

get-checks: func [
    caller state
    /local 
        len spl total 
][
    checked: collect/into [
        foreach [s sdata] sectors [if get in get sdata/:chkid 'data [keep s]]
    ] make block! 10
    
    len: length? checked
    
    either empty? checked [
        checked: extract sectors 2
        reset-chk checked
    ][
        total: 0
        either state [
            ; add the caller sector
            foreach s checked [
                t: sectors/:s/:sweep
                delta: either s = caller [to integer! 360 / len][0 - to integer! t / len]
                total: total + sectors/:s/:sweep: t + delta
            ]
        ][ 
            ; remove the caller sector
            spl: sectors/:caller/:sweep
            sectors/:caller/:sweep: 0
            foreach s checked [
                t: sectors/:s/:sweep
                total: total + sectors/:s/:sweep: t + to integer! spl / len
            ]
            sectors/:s/:sweep: sectors/:s/:sweep + 360 - total
        ]
    ]
    make-pie
]

check-coords: func [offs /local c t][
    foreach [c t] drag-coords [
        if (c/x - offs/x ** 2) + (c/y - offs/y ** 2) ** 0.5 < 12 [
            sel: t
            drag?: true
            start-ang: to integer! modulo arctangent2 offs/y - cnt/y offs/x - cnt/x 360
            sect: head sectors
            ; set the start agnle to the start of the selected type
            while [sect/1 <> sel][
                start: start + sect/2/:sweep // 360 
                if sect/2/:sweep > 0 [move checked tail checked]
                move/part sect tail sect 2
                
            ]
            start-sweep: sectors/:sel/:sweep
            sectors-copy: copy/deep sectors
            break
        ]
    ]
]

test-sectors: func [
    offs
    /locals t total sct
][
    sct: copy/deep sectors
    delta-ang: to integer! ((arctangent2 offs/y - cnt/y offs/x - cnt/x) // 360) - start-ang
    total: sct/:sel/:sweep: to integer! start-sweep + (2 * delta-ang)
    
    foreach t next checked [
        sct/:t/:sweep: max 4 to integer! (old: sectors-copy/:t/:sweep)
      - (2 * delta-ang * old / (360.0 - sectors-copy/:sel/:sweep))
        total: total + sct/:t/:sweep
    ]
    ; add the remaining sweep
    sct/:t/:sweep: sct/:t/:sweep + 360 - total   ;
    sct
]

update-texts: has [obj c sum][
    sum: 0
    foreach [k v] sectors [
        obj: get v/:chkid
        obj/text: form c: to integer! round v/:sweep / 360.0 * 100
        if v/:sweep > 0 [to-fix: obj]
        sum: sum + c
    ]
    to-fix/text: form (to integer! to-fix/text) + 100 - sum
]

update-sweeps: func [
    offs
    /local t total sect res
][
    if all [drag? not single? checked]  [
        sect: test-sectors offs
        res: on
        foreach t checked [
		   ; if sect/:t/:sweep < 5 [probe t probe sect probe checked]
		    res: res and (sect/:t/:sweep >= 4)]
        if res [
            sectors: copy/deep sect
            make-pie
        ]
    ]
]
                     
view [
    title "Pie chart manipulation"
    backdrop sky
    across middle
    style chk: check 35x20 
    style bs: base 20x20
    space 5x30
    bs draw [image img-tile] c-tile: chk "Sides"     on
    [get-checks 'sides c-tile/data] return 
    bs draw [image img-dual] c-dual: chk "Centers"   off
    [get-checks 'centers c-dual/data] return 
    bs draw [image img-diam] c-diam: chk "Diamond"   off
    [get-checks 'diamond c-diam/data] return 
    bs draw [image img-truc] c-truc: chk "Truchet"   off
    [get-checks 'truchet c-truc/data] return 
    bs draw [image img-diag] c-diag: chk "Diagonals" off
    [get-checks 'diagonals c-diag/data] return
    space 20x10
    below return
    
    bs-pie: base 240x240 sky
    all-over 
    draw []
    on-down [check-coords event/offset]
    on-over [update-sweeps event/offset]
    on-up   [drag?: false]
    on-create [make-pie]
]
