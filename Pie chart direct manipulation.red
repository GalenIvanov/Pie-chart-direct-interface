Red [
    Title:  "Direct manipulation of Pie chart"
    Author: "Galen Ivanov" 
    needs:  view
]

img-tile: draw 24x24 [fill-pen white pen black line-width 4 box 0x0 24x24]
img-dual: draw 24x24 [fill-pen white pen black line-width 2 box 0x0 24x24
                      line 12x0 12x24 line 0x12 24x12]
img-diam: draw 24x24 [fill-pen white pen black line-width 2 box 0x0 24x24
                      polygon 12x0 24x12 12x24 0x12]
img-truc: draw 24x24 [fill-pen white pen black line-width 2 box 0x0 24x24
                      fill-pen transparent circle 0x0 12 circle 24x24 12]  
img-diag: draw 24x24 [fill-pen white pen black line-width 2 box 0x0 24x24
                      line 0x0 24x24 line 24x0 0x24]                      
                      
cnt: 100x100
ard: 70x70

; indices in sectors sub-blocks 
sweep: 1  
color: 2
chkid: 3
img:   4

drag?: false
sel:  none
start-ang: 0
start-sweep: 0
start: 0

sectors-copy: make block! 10


sectors: [
    sides:     [180 yello  c-tile img-tile]
    centers:   [180 orange c-dual img-dual]
    diamond:   [  0 pink   c-diam img-diam]
    truchet:   [  0 papaya c-truc img-truc] 
    diagonals: [  0 beige  c-diag img-diag]
]

checked: copy [sides: centers]
drag-coords: make block! 10

{
pie: compose/deep[
   pen black
   rotate 5 (cnt) [image (img-tile) (as-pair (cnt/x + ard/x + 6) cnt/y - 12)]
   rotate 205 (cnt) [image (img-diam) (as-pair (cnt/x + ard/x + 6) cnt/y - 12)]
]
}

reset-chk: func [ used ][
    ; set all the checks to true and their share to 20%
    foreach s used [
        sectors/:s/:sweep: 72
        c-tile/data: on
        c-dual/data: on
        c-diam/data: on
        c-truc/data: on
        c-diag/data: on
    ]
]

make-pie: has [ ; function [
    fr-start
][
    pie: make block! 200
    fr-start: start
    
    clear drag-coords
    
    collect/into [
        keep [pen black]    
        foreach s checked [ ;sect-used [
            t: sectors/:s
            keep compose [ fill-pen (t/:color)]
            keep either single? checked [
                compose [circle (cnt) (ard/x)]                
            ][    
                compose [arc (cnt) (ard) (fr-start) (t/:sweep) closed]
            ]    
            keep compose/deep [
                rotate (fr-start + (t/:sweep / 2)) (cnt) 
                [image (get t/:img) (as-pair (cnt/x + ard/x + 6) cnt/y - 12)]
            ]
            
            ; append the center of the circle for coordinates check
            append drag-coords compose [
                (as-pair (cosine (t/:sweep / 2 + fr-start)) * (ard/x + 18) + cnt/x
                         (sine   (t/:sweep / 2 + fr-start)) * (ard/y + 18) + cnt/y)
                (s)
            ]
            fr-start: fr-start + t/:sweep  % 360
        ]
    ] pie
    ;probe drag-coords
    append clear bs-pie/draw pie
]

get-checks: func [caller state][
    
    checked: collect/into [
        foreach [s sdata] sectors [if get in get sdata/:chkid 'data [keep s]]
    ] make block! 10
    
    ;probe checked
    len: length? checked
    
    either empty? checked [
        checked: extract sectors 2
        reset-chk checked
        make-pie ;checked
    ][
        either state [
            ; add the caller sector
            foreach s checked [
                t: sectors/:s/:sweep
                delta: either s = caller [to integer! 360 / len][0 - to integer! t / len]
                sectors/:s/:sweep: t + delta
            ]
        ][ 
            ; remove the caller sector
            sectors/:caller/:sweep: 0
            foreach s checked [
                t: sectors/:s/:sweep
                sectors/:s/:sweep: t + to integer! t / len
            ]
        ]   
        make-pie
    ]
]

check-coords: func [offs /local c t][
    foreach [c t] drag-coords [
        if (c/x - offs/x ** 2) + (c/y - offs/y ** 2) ** 0.5 < 13 [
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

update-sweeps: func [
    offs
    /local delta-ang t total
][
    if drag? [
    
        
        delta-ang: to integer! ((arctangent2 offs/y - cnt/y offs/x - cnt/x) // 360) - start-ang
        total: sectors/:sel/:sweep: to integer! start-sweep + (2 * delta-ang) // 360
        
        
        foreach t checked [
            if t <> sel [
                sectors/:t/:sweep: to integer! sectors-copy/:t/:sweep
             - (2 * delta-ang * sectors/:t/:sweep / (360.0 - sectors/:sel/:sweep)) // 360
                total: total + sectors/:t/:sweep
            ]
        ]
        ; add the remaining delat
        if total < 360 [sectors/:t/:sweep: sectors/:t/:sweep + 360 - total]
        make-pie
    ]
    
]
                     
view [
    title "Pie chart manipulation"
    backdrop sky
    across middle
    style chk: check 70x20 
    style bs: base 24x24
    space 5x20
    bs draw [image img-tile] c-tile: chk "Sides"     on
    [get-checks 'sides c-tile/data] return 
    bs draw [image img-dual] c-dual: chk "Centers"   on
    [get-checks 'centers c-dual/data] return 
    bs draw [image img-diam] c-diam: chk "Diamond"   off
    [get-checks 'diamond c-diam/data] return 
    bs draw [image img-truc] c-truc: chk "Truchet"   off
    [get-checks 'truchet c-truc/data] return 
    bs draw [image img-diag] c-diag: chk "Diagonals" off
    [get-checks 'diagonals c-diag/data] return
    space 20x10
    below return
    
    bs-pie: base 200x200 sky
    all-over 
    draw []
    on-down [check-coords event/offset]
    on-over [update-sweeps event/offset]
    on-up   [drag?: false]
    ;on-create [get-checks 'sides on]
]
