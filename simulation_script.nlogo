extensions[csv]

turtles-own
[
  node-clustering-coefficient
  distance-from-other-turtles
  ;; we have added the variables to use later on
  strategy
  ind_score
  old_score
  ind_string
  ind_string2
  ind_score2
  social_string
  social_score
  turtle_color ;; 2 = green (Best member), 1 = blue (conformity), 0 = red (individual)
]

links-own
[
  rewired?                    ;; keeps track of whether the link has been rewired or not
]

globals
[rewiring-probability         ;; important to define the network topology with the WS-model
 clustering-coefficient       ;; the clustering coefficient of the network (mean of all the individual ones)
 average-path-length          ;; average path length of the network (mean of individual average path length)
  infinity                    ;; used to calculate path length
  average-degree
  ;; added the global "true problem solution" string
  global_string
  mean_payoff_all
  mean_payoff_ind
  mean_payoff_soc
  Ls00
  payoff00
  Ls01
  payoff01
  Ls11
  payoff11
  Ls10
  payoff10
  Ls
  payoff
]


to setup
  clear-all
  reset-ticks
  set infinity 99999  ;; arbitrary, used in the calculation of path length to avoid looping in the void if there is no path from A to B
  set-default-shape turtles "circle"
  ask patches [set pcolor white]
  ;;depending on the network you want, choose the acoording procedure
  ;;if you want a scale-free, use the BA-model. Otherwise, use the WS-model
  ifelse n-type = "sf" [network_BA-model] [ifelse n-type = "full" [fullyconnected_network][network_WS-model]]
  if resize-nodes? [resize-nodes]
  do-calculations
  plot-dist
  ;; we add an initialize string section
  if task_environment = "simple"[
    initialize-strings-simple]
  if task_environment = "complex"[
    intialize-strings-complex]
end

to make-turtles
  ;;create our turtles in accordance with the proportion_conformity slider
  if SL_Strategy = "Best member"[
  create-turtles num-nodes [ifelse random-float 100 < proportion_ind
    [set color red]
      [set color green] ]]
  if SL_Strategy = "Conformity" [
    create-turtles num-nodes [ifelse random-float 100 < proportion_ind
    [set color red]
    [set color blue] ]]
  ;; arrange them in a circle sorting them by who number
  layout-circle (sort turtles) max-pxcor - 1
end

;;;; not sure we use these
;to-report listr [lst n]
  ;report n-values n [item ( i mod length lst) lst]
;end


to initialize-strings-simple
  ;;; we make the global string with three items randomly either 0 or 1
  set global_string (list random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2)
  ;; payoff - not in yet
  ;; we ask the turtles to create individual string with three items, randomly either 0 or 1
  ask turtles[
    set ind_string (list random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2)
  update-score-simple]
end

to intialize-strings-complex
  set Ls00 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/s00.csv"
  set payoff00 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/payoff00.csv"
  set Ls01 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/s01.csv"
  set payoff01 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/payoff01.csv"
  set Ls10 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/s10.csv"
  set payoff10 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/payoff10.csv"
  set Ls11 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/s11.csv"
  set payoff11 csv:from-file "/Users/lineelgaard/Documents/Social and Cultural Dynamics/NetLogo/Social learning exam/r_dfs_complex_task/payoff11.csv"

  ask turtles[
    set ind_string (list random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2 random 2)
    update-score-complex]
end

to go
  if task_environment = "simple"[
  ;; overview of the play and sections of it
  ;; the old score is defined as the individual score at the first step, before a new score is calculated
  ask turtles[
  ;; turtles go out and do social learning, getting social string and social score
  do_learning
  ;; they update score according to new string after learning
  update-score-simple
  ;; they compare current score with old_score and update strategy if they have not improved
  ]
  get_mean_score_all
  get_mean_score_ind
  get_mean_score_soc
  tick]

  if task_environment = "complex"[
   ask turtles[
      do_learning
      update-score-complex
    ]
  get_mean_score_all
  get_mean_score_ind
  get_mean_score_soc
  tick]
end


to get_mean_score_all
  set mean_payoff_all mean [ind_score] of turtles
end

to get_mean_score_ind
  ifelse proportion_ind = 0[
    set mean_payoff_ind 0][
    set mean_payoff_ind mean [ind_score] of turtles with [color = red]]
end

to get_mean_score_soc
  ifelse proportion_ind = 100[
    set mean_payoff_soc 0][
  if SL_Strategy = "Conformity"[
    set mean_payoff_soc mean [ind_score] of turtles with [color = blue]]
  if SL_Strategy = "Best member"[
    set mean_payoff_soc mean [ind_score] of turtles with [color = green]]
  ]
end

;;;;;;;;;;;;;;;;;;; Generating a fully connected network ;;;;;;;;;;;;;;;;;;;
to fullyconnected_network
  make-turtles
  ask turtles [ create-links-with other turtles]
  layout-circle (sort turtles) max-pxcor - 1

end

;;;;;;;;;;;;;;;;;;; Generating Lattice, Small World and Random network ;;;;;;;
to network_WS-model
  ;;we create our turtles and arrange the layout
  make-turtles
  ;;we first wire them as a nearest-neighbours lattice
  wire-them
  ;;depending on the type of network we want, we change the rewiring probability
  if n-type = "nn" [ ;;nearest neighbours
    set rewiring-probability 0 ]
  if n-type = "sw" [ ;;small world
    set rewiring-probability 0.1 ]
  if n-type = "r" [ ;;random
    set rewiring-probability 1 ]
  ;;we rewire
  rewire-all
end

to do_learning
  ;; ask turtles to count neighbour links and list three of them randomly in list "f"
  let n-friends count link-neighbors
    let f (list random n-friends random n-friends random n-friends)

   ;; take the blue turtles (conformity strategy) we want them to find 3 friends and take the most frequent string. if that string is better than their own, we want them to switch string.
  if color = blue[
      let stringf1 ([ind_string] of turtle (item 0 f))     ;;; the individual string of first item (turtle) in list f is called stringf1
    let stringf2 ([ind_string] of turtle (item 1 f))       ;;; the individual string of second item (turtle) in list f is called stringf2
    let stringf3 ([ind_string] of turtle (item 2 f))       ;;; the individual string of third item (turtle) in list f is called stringf3
    ifelse stringf1 = stringf2[                            ;;; if the stringf1 is the same as f2,
       set social_string stringf1][                        ;;; then we have the most frequent, and it should be social_string
        ifelse stringf1 = stringf3[                        ;;; if not then look at stringf1 and see if it is the same as f3,
          set social_string stringf1][                     ;;; if it is then we have the most frequent, and it should be social_string
          ifelse stringf2 = stringf3[                      ;;; if not then look at string f2 and see if it is the same as f3,
            set social_string stringf2][                   ;;; if it is then it is the social_string
            set social_string ind_string]]]                         ;;; if it is not then set the social string to 0 ?? not sure about this
      ifelse social_string = ind_string[
        set social_score ind_score][
        ifelse social_string = stringf1[                         ;;; if the social string is f1
          set social_score ([ind_score] of turtle (item 0 f))][  ;;;then get the ind_score of turle item 0 of list f and call this social_score
          set social_score ([ind_score] of turtle (item 1 f))]]] ;;; if not then it must be f2 (item 1 of list f), get the ind_score of this turtle and call it social_score

    ;;; take the red turtles (best member strategy). we want them to find 3 frinds and take the string from the turtle with the highest score
  if color = green[
    let scoref1 ([ind_score] of turtle (item 0 f))        ;;; the individual score of first item (turtle) in list f is called stringf1
    let scoref2 ([ind_score] of turtle (item 1 f))        ;;; the individual score of second item (turtle) in list f is called stringf2
    let scoref3 ([ind_score] of turtle (item 2 f))        ;;; the individual score of third item (turtle) in list f is called stringf3
    ifelse scoref1 > scoref2 and scoref1 > scoref3[       ;;; if the score f1 is higher than score of f2 and f3
        set social_score scoref1][                        ;;; then this is the social_score
        ifelse scoref2 > scoref1 and scoref2 > scoref3[   ;;; if not then look whether f2 is higher than f1 and f3
          set social_score scoref2][                      ;;; if so then this is the social_score
          set social_score scoref3]]                      ;;; if neither of the above, then f3 must be best and thus the social score
      ifelse social_score = scoref1[                               ;;; if the social score was f1
        set social_string ([ind_string] of turtle (item 0 f))][    ;;; then take the ind_string of f1 and call this social_string
         ifelse social_score = scoref2[                            ;;; if the social_score was f2
          set social_string ([ind_string] of turtle (item 1 f))][  ;;; then take the ind_string of f2 and call this social_string
          set social_string ([ind_string] of turtle (item 2 f))]]] ;;; if neither then take the ind_string of f3 and call this social_string

    ;;; compare to own score, to decide whether to do individual learning or social learning

    if color = green[
    ifelse social_score > ind_score                        ;;; if the social score is higher than the individual score
    ;[if (random-float 100) < 80                           ;;; 80 % chance of adopting the better string
      [set ind_string social_string][
      ;if (random-float 100) < 20[
      set ind_string ind_string]]

    if color = blue[
    ifelse social_score > ind_score                        ;;; if the social score is higher than the individual score
    ;[if (random-float 100) < 80[                           ;;; 80 % chance of adopting the better string
      [set ind_string social_string][
      ;if (random-float 100) < 20[
      set ind_string ind_string]]

    if color = red[
    let d random (length ind_string)                      ;;; and do individual learning and take n item at random from ind_string
      ifelse item d ind_string = 0[                       ;;; if item n in the ind_string is 0
      set ind_string2 replace-item d ind_string 1][       ;;; then replace it with the number 1
      set ind_string2 replace-item d ind_string 0]       ;;; if item n is not 0 but 1, then replace by 0

    ifelse Task_environment = "simple"[
      update-score-simple-2][
      update-score-complex-2]

     ifelse ind_score2 > ind_score[
        ;if (random-float 100) < 80[
          set ind_string ind_string2][
        ;if (random-float 100) < 20[
          set ind_string ind_string]
    ]
end

to update-score-simple-2
  ;;; now the turtle has a new string, and thus we want to reset the score and calculate a new
  set ind_score2 0
  let i 0
  ;; loop over n items in global string. if n in ind_string equal n in global_string update score with 1
  while [i < length global_string][
    ifelse item i ind_string2 = item i global_string[
   set ind_score2 ind_score2 + 0.066666667][
   set ind_score2 ind_score2]
   set i i + 1]
end

to update-score-complex-2
  check2
end


to update-score-simple
  ;;; now the turtle has a new string, and thus we want to reset the score and calculate a new
  set ind_score 0
  let i 0
  ;; loop over n items in global string. if n in ind_string equal n in global_string update score with 1
  while [i < length global_string][
    ifelse item i ind_string = item i global_string[
   set ind_score ind_score + 0.066666667][
   set ind_score ind_score]
   set i i + 1]
end

to update-score-complex
 check
end

to check
    ifelse item 0 ind_string = 0

    [ifelse item 1 ind_string = 0
      [  set Ls Ls00
  set payoff payoff00]
      [  set Ls Ls01
  set payoff payoff01]
    ]

    [ifelse item 1 ind_string = 0
      [  set Ls LS10
  set payoff payoff10]
      [  set Ls Ls11
  set payoff payoff11]
    ]
  search
end

to check2
    ifelse item 0 ind_string2 = 0

    [ifelse item 1 ind_string2 = 0
      [  set Ls Ls00
  set payoff payoff00]
      [  set Ls Ls01
  set payoff payoff01]
    ]

    [ifelse item 1 ind_string2 = 0
      [  set Ls LS10
  set payoff payoff10]
      [  set Ls Ls11
  set payoff payoff11]
    ]
  search2
end

to search
    let i 0
    let found False
   while [i < length Ls and found = False]
    [
      if ind_string = item i Ls[
        set ind_score item 0 (item i payoff)
        set found True]
      set i i + 1]
end

to search2
    let i 0
    let found False
   while [i < length Ls and found = False]
    [
      if ind_string2 = item i Ls[
        set ind_score2 item 0 (item i payoff)
        set found True]
      set i i + 1]
end

to make-edge [node1 node2]
  ;;used in wire-them
  ask node1 [ create-link-with node2  [
    set rewired? false
  ] ]
end

to wire-them
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 4, where each turtle connect to the two following ones
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    set n n + 1
  ]
end

to rewire-all
    ask links [

      ;; whether to rewire it or not?
    ;;remember, we have a bag of numbers from 0 to 1. For every link, we draw a number.
    ;;Everything between 0 and rewiring-probability is a 'Yes, rewire'
      if (random-float 1) < rewiring-probability
      [
        ;; we rewire -> we only change the destination of the link, thus we keep the source (end1)
        let node1 end1
        ;; we can only rewire if node1 is not connected to everybody
      ;; we count the number of links node1 has, then compare it to the number of nodes minus itself
      ;; "number of links = number of nodes-1" would mean that node1 is connected to everyone already
        if [ count link-neighbors ] of end1 < (count turtles - 1)
        [
          ;; find a node distinct from node1 and not already a neighbor of node1
        ;; we don't want node1 to rewire the link to himself, or to a node it is already connected to.
          let node2 one-of turtles with [ (self != node1) and (not link-neighbor? node1) ]
          ;; wire the new edge
          ask node1 [ create-link-with node2 [ set color green  set rewired? true ] ]
          set rewired? true
        ]
      ]
      ;; remove the old edge
    ;;What we actually did is create a new link between A and C for a link between A and B.
    ;;For the rewiring to be complete (not just adding edges) we need to get rid of A to B.
      if (rewired?)
      [
        die
      ]
  ]
end


;;;;;;;;;;;;;;;;;;;; Generating Scale-free network ;;;;;;;;;;;;;;;;;;;;;;;;;;;
to network_BA-model
  ;;create a first pair of nodes
  growth nobody
  growth turtle 0
  ;;Loop the process. Every iteration, create a node and connect it to the node obtained via pref-attachment
  let n 0
  while [n < num-nodes][
  growth pref-attachment
  ;; update the layout of the network to avoid a big mess
  layout
  set n n + 1
  ]
end

to growth [partner]
  ;;create a turtle and connect it to the specified partner
  create-turtles 1
  [
    set color red
    if partner != nobody
      [ create-link-with partner [ set color green ]
        ;; position the new node near its partner
        move-to partner
        fd 8
      ]
  ]
end

to-report pref-attachment
  ;;in the list of all the links, select a link, then select a node at one of the end of that link
  ;;this way, there is more chance to end up with on one of the highly connected nodes (with a lot of links).
  report [one-of both-ends] of one-of links
end

to layout ;code to make the network visually more appealing
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display  ;; for smooth animation
  ]
end


;;;;;;;;;;;;;;;;; Aesthetics ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to resize-nodes
  ifelse resize-nodes?
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask turtles [ set size sqrt count link-neighbors ]
    set resize-nodes? False
  ]
  [
    ;;resize everyone to the same size
    ask turtles [ set size 1 ]
    set resize-nodes? True
  ]
end




;;;;;;;;;;;;;;;;;; Calculus ;;;;;;;;;;;;;;;;;;;;;;
to do-calculations

  ;; set up a variable so we can report if the network is disconnected
  let connected? true

  ;; find the path lengths in the network
  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-turtles)] of turtles

  ;; In a connected network on N nodes, we should have N(N-1) measurements of distances between pairs,
  ;; and none of those distances should be infinity.
  ;; If there were any "infinity" length paths between nodes, then the network is disconnected.
  ;; In that case, calculating the average-path-length doesn't really make sense.
  ifelse ( num-connected-pairs != (count turtles * (count turtles - 1) ))
  [
      set average-path-length infinity
      ;; report that the network is not connected
      set connected? false
  ]
  [
    set average-path-length (sum [sum distance-from-other-turtles] of turtles) / (num-connected-pairs)
  ]
  ;; find the clustering coefficient and add to the aggregate for all iterations
  find-clustering-coefficient
  ;; calculate average degree
  set average-degree (sum [count link-neighbors] of turtles / count turtles)
end

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

to find-path-lengths
  ;; reset the distance list
  ask turtles
  [
    set distance-from-other-turtles []
  ]

  let i 0
  let j 0
  let k 0
  let node1 one-of turtles
  let node2 one-of turtles
  let node-count count turtles
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 turtle i
      set node2 turtle j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [
          set distance-from-other-turtles lput 0 distance-from-other-turtles
        ]
      ]
      [
        ;; 1 from a node to it's neighbor
        ifelse [ link-neighbor? node1 ] of node2
        [
          ask node1 [
            set distance-from-other-turtles lput 1 distance-from-other-turtles
          ]
        ]
        ;; infinite to everyone else
        [
          ask node1 [
            set distance-from-other-turtles lput infinity distance-from-other-turtles
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [k < node-count]
  [
    set i 0
    while [i < node-count]
    [
      set j 0
      while [j < node-count]
      [
        ;; alternate path length through kth node
        set dummy ( (item k [distance-from-other-turtles] of turtle i) +
                    (item j [distance-from-other-turtles] of turtle k))
        ;; is the alternate path shorter?
        if dummy < (item j [distance-from-other-turtles] of turtle i)
        [
          ask turtle i [
            set distance-from-other-turtles replace-item j distance-from-other-turtles dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set k k + 1
  ]

end

to plot-dist
  histogram [count link-neighbors] of turtles
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
23
14
89
47
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
105
15
168
48
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
12
93
150
138
n-type
n-type
"full" "nn" "sw" "r" "sf"
0

SLIDER
12
55
184
88
num-nodes
num-nodes
0
25
200.0
1
1
NIL
HORIZONTAL

SWITCH
12
145
156
178
resize-nodes?
resize-nodes?
1
1
-1000

BUTTON
14
393
83
426
resize
resize-nodes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
12
237
161
297
num-nodes
200.0
1
0
Number

SLIDER
12
303
210
336
proportion_ind
proportion_ind
0
100
52.0
1
1
NIL
HORIZONTAL

MONITOR
663
20
810
65
NIL
clustering-coefficient
17
1
11

MONITOR
663
78
805
123
NIL
average-path-length
17
1
11

MONITOR
665
133
776
178
NIL
average-degree
17
1
11

PLOT
664
189
864
339
Degree Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot-dist"

CHOOSER
11
342
149
387
SL_Strategy
SL_Strategy
"Best member" "Conformity"
0

CHOOSER
13
184
152
229
Task_environment
Task_environment
"simple" "complex"
1

BUTTON
113
422
176
455
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
670
365
951
515
Mean payoffs
Time
Payoff
0.0
200.0
0.0
1.0
false
true
"" ""
PENS
"All" 1.0 0 -4699768 true "" "plot mean_payoff_all"
"Individual learners" 1.0 0 -2674135 true "" "plot mean_payoff_ind"
"Social learners" 1.0 0 -11881837 true "" "plot mean_payoff_soc"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="first_run" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>mean_payoff_all</metric>
    <metric>mean_payoff_ind</metric>
    <metric>mean_payoff_soc</metric>
    <enumeratedValueSet variable="resize-nodes?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportion_ind">
      <value value="10"/>
      <value value="30"/>
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SL_Strategy">
      <value value="&quot;Best member&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-type">
      <value value="&quot;nn&quot;"/>
      <value value="&quot;full&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Task_environment">
      <value value="&quot;simple&quot;"/>
      <value value="&quot;complex&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
