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

sectors: [
    sides:     [180 yello  c-tile img-tile]
    centers:   [180 orange c-dual img-dual]
    diamond:   [  0 pink   c-diam img-diam]
    truchet:   [  0 papaya c-truc img-truc] 
    diagonals: [  0 beige  c-diag img-diag]
]

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
        sectors/:s/:sweep: 360 / 5
        c-tile/data: on
        c-dual/data: on
        c-diam/data: on
        c-truc/data: on
        c-diag/data: on
    ]
]

make-pie: function [
    sect-used
][
    pie: make block! 200
    ;start: either single? sect-used [180][0] 
    start: 270
    collect/into [
        keep [pen black]    
        foreach s sect-used [
            t: sectors/:s
            keep compose [fill-pen (t/:color)]
            ; (arcs)
            keep either single? sect-used [
                compose [circle (cnt) (ard/x)]                
            ][    
                compose [arc (cnt) (ard) (start) (t/:sweep) closed]
            ]    
            
            keep compose/deep [
                rotate (start + (t/:sweep / 2)) (cnt) 
                [image (get t/:img) (as-pair (cnt/x + ard/x + 6) cnt/y - 12)]
            ]
            start: start + t/:sweep
        ]
    ] pie        
    append clear bs-pie/draw pie
]

get-checks: func [caller state /local checked][
    
    checked: collect/into [
        foreach [s sdata] sectors [if get in get sdata/:chkid 'data [keep s]]
    ] make block! 10
    
    len: length? checked
    
    either empty? checked [
        checked: extract sectors 2
        reset-chk checked
        make-pie checked
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
    ]
    make-pie checked
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
    draw []
    ;on-create [get-checks 'sides on]
]
