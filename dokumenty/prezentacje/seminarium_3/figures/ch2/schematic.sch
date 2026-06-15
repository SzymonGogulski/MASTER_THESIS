# File saved with Nlview 7.8.0 2024-04-26 e1825d835c VDI=44 GEI=38 GUI=JA:21.0 TLS
# 
# non-default properties - (restore without -noprops)
property -colorscheme classic
property attrcolor #000000
property attrfontsize 8
property autobundle 1
property backgroundcolor #ffffff
property boxcolor0 #000000
property boxcolor1 #000000
property boxcolor2 #000000
property boxinstcolor #000000
property boxpincolor #000000
property buscolor #008000
property closeenough 5
property createnetattrdsp 2048
property decorate 1
property elidetext 40
property fillcolor1 #ffffcc
property fillcolor2 #dfebf8
property fillcolor3 #f0f0f0
property gatecellname 2
property instattrmax 30
property instdrag 15
property instorder 1
property marksize 12
property maxfontsize 12
property maxzoom 5
property netcolor #19b400
property objecthighlight0 #ff00ff
property objecthighlight1 #ffff00
property objecthighlight2 #00ff00
property objecthighlight3 #0095ff
property objecthighlight4 #8000ff
property objecthighlight5 #ffc800
property objecthighlight7 #00ffff
property objecthighlight8 #ff00ff
property objecthighlight9 #ccccff
property objecthighlight10 #0ead00
property objecthighlight11 #cefc00
property objecthighlight12 #9e2dbe
property objecthighlight13 #ba6a29
property objecthighlight14 #fc0188
property objecthighlight15 #02f990
property objecthighlight16 #f1b0fb
property objecthighlight17 #fec004
property objecthighlight18 #149bff
property objecthighlight19 #0000ff
property overlaycolor #19b400
property pbuscolor #000000
property pbusnamecolor #000000
property pinattrmax 20
property pinorder 2
property pinpermute 0
property portcolor #000000
property portnamecolor #000000
property ripindexfontsize 4
property rippercolor #000000
property rubberbandcolor #000000
property rubberbandfontsize 10
property selectattr 0
property selectionappearance 2
property selectioncolor #0000ff
property sheetheight 44
property sheetwidth 68
property showmarks 1
property shownetname 0
property showpagenumbers 1
property showripindex 1
property timelimit 1
#
module new top1 work:top1:NOFILE -nosplit
load symbol oscillator work:oscillator:NOFILE HIERBOX pin ro_out output.right boxcolor 1 fillcolor 2 minwidth 13%
load symbol RTL_INV1 work INV pin I0 input pin O output fillcolor 1
load port ro_out output -pg 1 -lvl 2 -x 570 -y 60
load inst u_osc oscillator work:oscillator:NOFILE -autohide -attr @cell(#000000) oscillator -attr @fillcolor #fafafa -pg 1 -lvl 1 -x 20 -y 74
load inst u_osc|s1_i RTL_INV1 work -hier u_osc -attr @cell(#000000) RTL_INV -attr @name s1_i -pg 1 -lvl 1 -x 90 -y 84
load inst u_osc|s2_i RTL_INV1 work -hier u_osc -attr @cell(#000000) RTL_INV -attr @name s2_i -pg 1 -lvl 2 -x 220 -y 84
load inst u_osc|s3_i RTL_INV1 work -hier u_osc -attr @cell(#000000) RTL_INV -attr @name s3_i -pg 1 -lvl 3 -x 350 -y 84
load net ro_out -port ro_out -pin u_osc ro_out
netloc ro_out 1 1 1 550J 60n
load net u_osc|ro_out -attr @name ro_out -hierPin u_osc ro_out -pin u_osc|s1_i I0 -pin u_osc|s3_i O
netloc u_osc|ro_out 1 0 4 40 134 NJ 134 NJ 134 450
load net u_osc|s1 -attr @name s1 -pin u_osc|s1_i O -pin u_osc|s2_i I0
netloc u_osc|s1 1 1 1 NJ 84
load net u_osc|s2 -attr @name s2 -pin u_osc|s2_i O -pin u_osc|s3_i I0
netloc u_osc|s2 1 2 1 NJ 84
levelinfo -pg 1 0 20 570
levelinfo -hier u_osc * 90 220 350 *
pagesize -pg 1 -db -bbox -sgen 0 0 670 180
pagesize -hier u_osc -db -bbox -sgen 20 44 480 144
show
zoom 1.64938
scrollpos -76 -193
#
# initialize ictrl to current module top1 work:top1:NOFILE
ictrl init topinfo |
