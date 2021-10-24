unit aggraph;

INTERFACE
uses intuition,exec,agraphics,diskfont,layers;


type
  FillPatternType = array[0..7,0..7] of integer;

const
  Black           =    0;
  Blue            =    1;
  Green           =    2;
  Cyan            =    3;
  Red             =    4;
  Magenta         =    5;
  Brown           =    6;
  LightGray       =    7;
  DarkGray        =    8;
  LightBlue       =    9;
  LightGreen      =   10;
  LightCyan       =   11;
  LightRed        =   12;
  LightMagenta    =   13;
  Yellow          =   14;
  White           =   15;


 xHatchFillPattern : FillPatternType = ((1,0,0,0,0,0,0,1),
                                        (0,1,0,0,0,0,1,0),
                                        (0,0,1,0,0,1,0,0),
                                        (0,0,0,1,1,0,0,0),
                                        (0,0,0,1,1,0,0,0),
                                        (0,0,1,0,0,1,0,0),
                                        (0,1,0,0,0,0,1,0),
                                        (1,0,0,0,0,0,0,1));


 SolidFill = 1;
 xHatchFill = 2;

 EGA = 0;
 EGALo = 1;


procedure agSetFontDefaults(var Font : tTextAttr);
procedure agSetScreenDefaults(var tscreen :tNewScreen);
procedure agSetViewModes(var tscreen :tNewScreen);
procedure agSetScreenFont(var tscreen :tNewScreen; Font : pTextAttr); 
procedure agSetScreenCustom(var tscreen : tNewScreen; Width,Height,Depth : integer; 
                                DefaultTitle : pchar); 
procedure agSetScreen(var tscreen : tNewScreen; width,height,depth : integer);
procedure agSetScreenTitle(title : string); 
function agOpenScreen(var tscreen : tNewScreen): pScreen;

procedure agSetWindowDefaults(var twin : tNewWindow);

function agOpenWindow(twindow: tNewWindow): pWindow;
procedure agSetWindowScreen(var twin :tNewWindow;pNScreen : pScreen);
procedure agSetWindowCustom(var twin :tNewWindow; width,height : integer; Title : pchar);
procedure agSetWindow(var twin :tNewWindow; width,height : integer);


procedure agCloseScreen(screen : pScreen);
procedure agCloseWindow(pwin : pwindow);
function agGetGraphWindow : pWindow;


Procedure Ellipse(x, y : integer; stangle, endangle, xradius, yradius : integer);
Procedure FillEllipse(x, y : integer; xradius, yradius: integer);
procedure OutTextXY(x,y : integer; TextStr : string);
Procedure SetRGBPalette(i,r,g,b : integer);
Procedure SetEGAVGAColors;

procedure SetColor(color : integer);
procedure SetBkColor(color : integer);
procedure SetFillColor(color : integer);
procedure SetFillStyle(FStyle,FColor : Integer);

Procedure Rectangle(x,y,x2,y2 : integer);
Procedure Line(x,y,x2,y2 : integer);
Procedure Bar(x,y,x2,y2 : integer);

procedure initgraph(gd,gm : integer; path : string);
procedure closegraph;

IMPLEMENTATION


var
 agFontName : String; 
 agScreenTitle : string;
 agrp	: pRastPort;
 agpw : pwindow;
 agps : pScreen;

 agts : tNewScreen;
 agtw : tNewWindow;
 agpf : tTextAttr;

 
 CurrentFillPattern : FillPatternType;
 CurrentFillColor : Integer;
 CurrentColor : integer;
 CurrentBkColor : integer;
 CurrentFillStyle : Integer;

procedure agSetFontDefaults(var Font : tTextAttr);
begin
  agFontName:='topaz.font'#0;
  with Font do 
  begin
    ta_Name	:= @agFontName[1];
  	ta_YSize := TOPAZ_EIGHTY;
  	ta_Style := FS_NORMAL;
  	ta_Flags := FPF_ROMFONT;
  end;
end;

(*
ViewModes
These flags select display modes. You can set any or all of them:
HIRES
Selects high-resolution mode (640 pixels across). The default is 320 pixels across.
INTERLACE
Selects interlaced mode (400 lines). The default is 200 lines.
SPRITES
Set this flag if you are want to use sprites in the display.
DUALPF
Set this flag if you want two playfields.
HAM
Set this flag if you want hold-and-modify mode.
*)

procedure agSetScreenDefaults(var tscreen :tNewScreen);
begin
  with tscreen do
  begin
    LeftEdge:=0;
    TopEdge:=0;
	  Width:=640;
	  Height:=200;
	  Depth:=4;
	  DetailPen:=White;
	  BlockPen:=Blue; (* border/ screen color*)
	  ViewModes:=HIRES;
	  SType:= CUSTOMSCREEN_F;
	  Font:= NIL;
	  DefaultTitle:=@agScreenTitle[1];
	  Gadgets:=NIL;
	  CustomBitMap:=NIL;
  end;
end; 

procedure agSetViewModes(var tscreen :tNewScreen);
var
 vmodes : word;
begin
 vmodes:=0;
 if tscreen.height >  320 then vmodes:=HIRES;
 if tscreen.height >= 400 then vmodes:=vmodes+LACE;
 tscreen.ViewModes:=vmodes;
end;

procedure agSetScreenFont(var tscreen :tNewScreen; Font : pTextAttr); 
begin
 tscreen.Font:=Font;
end;

procedure agSetScreenCustom(var tscreen : tNewScreen; Width,Height,Depth : integer; 
                                DefaultTitle : pchar); 
begin
  agSetScreenDefaults(tscreen);
  tscreen.Width:=width;
  tscreen.Height:=height;
  tscreen.Depth:=Depth;
  tscreen.DefaultTitle:=DefaultTitle;
  agSetViewModes(tscreen);
end;

procedure agSetScreen(var tscreen : tNewScreen; width,height,depth : integer);
begin
  agSetScreenDefaults(tscreen);
  tscreen.Width:=width;
  tscreen.Height:=height;
  tscreen.Depth:=depth;
  agSetViewModes(tscreen);
end;

procedure agSetScreenTitle(title : string); 
begin
  agScreenTitle:=title+#0;
end;

function agOpenScreen(var tscreen : tNewScreen): pScreen;
begin
  agOpenScreen:=OpenScreen(@tScreen);
end;

procedure agCloseScreen(screen : pScreen);
var
 d : boolean;
begin
  d:=CloseScreen(screen);
end;

procedure agCloseWindow(pwin : pwindow);
begin
  CloseWindow(pwin);
end;

procedure agSetWindowDefaults(var twin : tNewWindow);
begin
  with twin do
  begin
	LeftEdge:=0;
	TopEdge:=12; 
	Width:=640;
	Height:=200-12;
	DetailPen:=-1;
	BlockPen:=-1;
	Title:=NIL;
  Flags:=WFLG_NOCAREREFRESH or WFLG_SMART_REFRESH or WFLG_BORDERLESS or WFLG_ACTIVATE;
  
  IDCMPflags:=IDCMP_VANILLAKEY or IDCMP_RAWKEY;
	WType:=CUSTOMSCREEN_F;
	FirstGadget:=NIL;
	CheckMark:=NIL;
	Screen:= NIL;
	BitMap:= NIL;
	MinWidth:=Width;
	MinHeight:=Height;
	MaxWidth:=Width;
	MaxHeight:=Height;
  end;  
end;

procedure agSetWindowScreen(var twin :tNewWindow;pNScreen : pScreen);
begin
  twin.screen:=pNScreen;
end;

procedure agSetWindowCustom(var twin :tNewWindow; width,height : integer; Title : pchar);
begin
  agSetWindowDefaults(twin);
  twin.width:=width;
  twin.height:=height;
  twin.MinWidth:=Width;
	twin.MinHeight:=Height;
	twin.MaxWidth:=Width;
	twin.MaxHeight:=Height;
  twin.title:=Title;
end;

procedure agSetWindow(var twin :tNewWindow; width,height : integer);
begin
  agSetWindowDefaults(twin);
  twin.width:=width;
  twin.height:=height;
end;

function agOpenWindow(twindow: tNewWindow): pWindow;
var
 agtpw : pWindow;
begin
  agtpw:=OpenWindow(@twindow);
  agrp := agtpw^.RPort;
  agOpenWindow:=agtpw;
end;

function agGetGraphWindow : pWindow;
begin
  agGetGraphWindow:=agpw;
end;

procedure agEllipse(xc,  yc,  a, b : Integer);
var
 x,y : integer;
 a2,b2 : longint;
 crit1,crit2,crit3 : longint;
 t,dxt,d2xt,dyt,d2yt : longint;
 error : longint;
begin
 x := 0;
 y := b;

 a2 :=a*a;
 b2 :=b*b;
 crit1 := -(a2 div 4 + a mod 2 + b2);
 crit2 := -(b2 div 4 + b mod 2 + a2);
 crit3 := -(b2 div 4 + b mod 2);
 t := -a2*y;
 dxt := 2*b2*x;
 dyt := -2*a2*y;
 d2xt := 2*b2;
 d2yt := 2*a2;

while (y>=0) AND (x<=a) do
begin
  (*putpixel(image,xc+x, yc+y,color,mode);*)
	error := writepixel(agrp, xc+x, yc+y);
  if (x<>0) OR (y<>0) then
  begin
  (*  putpixel(image,xc-x, yc-y,color,mode);*)
  	error := writepixel(agrp, xc-x, yc-y);

    if (x<>0) AND (y<>0) then
    begin
    (*  putpixel(image,xc+x, yc-y,color,mode);
        putpixel(image,xc-x, yc+y,color,mode);*)
    	error := writepixel(agrp, xc+x, yc-y);
    	error := writepixel(agrp, xc-x, yc+y);

    end;
    if (t + b2*x <= crit1) OR  (t + a2*y <= crit3) then
    begin
      inc(x);
      inc(dxt,d2xt);
      inc(t,dxt);
    end
    else if (t - a2*y > crit2)	then
    begin
      dec(y);
      inc(dyt,d2yt);
      inc(t,dyt);
    end
    else
    begin
      inc(x);
      inc(dxt,d2xt);
      inc(t,dxt);

      dec(y);
      inc(dyt,d2yt);
      inc(t,dyt);
    end;
  end;
end;
end;

procedure rLine(x,y,w : integer);
var
 i     : integer;
 error : longint;
begin
  for i:=x to x+w-1 do
  begin
  	error:=writepixel(agrp, i, y);
  end;
end;

procedure SolidRectFill(x,y,x2,y2 : integer);
var
  j : integer;
begin
  for j:=y to y2 do
  begin
    gfxmove(agrp,x,j);
    draw(agrp,x2,j);
  end;
end;

procedure PatternRectFill(x,y,x2,y2 : integer);
var
 i,j : integer;
 col : integer;
 error : longint;
begin
  for j:=y to y2 do
  begin
    for i:=x to x2 do
    begin
      col:=CurrentFillPattern[i mod 8,j mod 8];
      if col > 0  then 
      begin
         error := writepixel(agrp, i, j);
      end;
    end;  
  end;  
end;

Procedure Rectangle(x,y,x2,y2 : integer);
begin
	gfxmove(agrp, x, y);
	draw(agrp, x, y2);
	draw(agrp, x2, y2);
	draw(agrp, x2, y);
	draw(agrp, x, y);
end;

Procedure Line(x,y,x2,y2 : integer);
begin
	gfxmove(agrp, x, y);
	draw(agrp, x2, y2);
end;

Procedure Bar(x,y,x2,y2 : integer);
var
 tcolor : integer;
begin
 tcolor:=CurrentColor;
 SetColor(CurrentFillColor);
 if CurrentFillStyle = SolidFill then
 begin
   SolidRectFill(x,y,x2,y2);
 end
 else
 begin
   PatternRectFill(x,y,x2,y2);
 end;
 
 SetColor(tColor);
 if CurrentColor<>CurrentFillColor then
 begin
    SetColor(CurrentFillColor);
    Rectangle(x,y,x2,y2);
    SetColor(tColor);
 end;
end;

procedure SetFillStyle(FStyle,FColor : Integer);
begin
  CurrentFillStyle:=FStyle;
  CurrentFillColor:=FColor;
  if FStyle = xHatchFill then
  begin
    CurrentFillPattern:=xHatchFillPattern;
  end;
end;

procedure agFillEllipse(xc, yc,  a,  b : integer);
var
 x,y : integer;
 a2,b2 : longint;
 crit1,crit2,crit3 : longint;
 t,dxt,d2xt,dyt,d2yt : longint;
 width : word;
begin
  x := 0;
  y := b;
  width := 1;
  a2 := longint(a)*a;
  b2 := longint(b)*b;
  crit1 := -(a2 div 4 + (a mod 2) + b2);
  crit2 := -(b2 div 4 + (b mod 2) + a2);
  crit3 := -(b2 div 4 + (b mod 2));
  t := -a2*y;
  dxt := 2*b2*x;
  dyt := -2*a2*y;
  d2xt := 2*b2;
  d2yt := 2*a2;

  while (y>=0) AND (x<=a)  do
  begin
   if ((t + b2*x) <= crit1) OR ((t + a2*y) <= crit3) then
   begin
     inc(x);
     inc(dxt,d2xt);
     inc(t,dxt);

      inc(width,2);
    end
    else if ((t - a2*y) > crit2) then
    begin
      rline(xc-x, yc-y, width);
      if (y<>0) then rline(xc-x, yc+y, width);
      dec(y);
      inc(dyt,d2yt);
      inc(t,dyt);
    end
   else
   begin
     rline(xc-x, yc-y, width);
     if (y<>0) then   rline(xc-x, yc+y, width);
     inc(x);
     inc(dxt,d2xt);
     inc(t,dxt);

     dec(y);
     inc(dyt,d2yt);
     inc(t,dyt);

     inc(width,2);
   end;
  end;
  if (b = 0) then rline(xc-a, yc, 2*a+1);
end;

Procedure Ellipse(x, y : integer; stangle, endangle, xradius, yradius : integer);
begin
 agEllipse(x,y,xradius,yradius);
end;


Procedure FillEllipse(x, y : integer; xradius, yradius: integer);
var
 tcolor : integer;
begin
 tcolor:=CurrentColor;
 SetColor(CurrentFillColor);
 agFillEllipse(x,y,xradius,yradius);
 
 SetColor(tcolor);
 if CurrentColor<>CurrentFillColor then
 begin
    SetColor(CurrentFillColor);
    Ellipse(x,y,0,360,xradius,yradius);
    SetColor(tColor);
 end;
 
end;



procedure OutTextXY(x,y : integer; TextStr : string);
begin
  setdrmd(agrp, JAM1);
	gfxmove(agrp, x, y+6);
	gfxtext(agrp, @TextStr[1], Length(TextStr));
end;

Procedure SetRGBPalette(i,r,g,b : integer);
begin
	SetRGB4(@agps^.ViewPort, i, r shr 2, g shr 2, b shr 2);
end; 

Procedure SetEGAVGAColors;
begin
  (* Turbo Pascal Palette Commands, 16 Colors, Format=6 Bit *)
SetRGBPalette( 0, 0, 0, 0);
SetRGBPalette( 1, 0, 0, 42);
SetRGBPalette( 2, 0, 42, 0);
SetRGBPalette( 3, 0, 42, 42);
SetRGBPalette( 4, 42, 0, 0);
SetRGBPalette( 5, 42, 0, 42);
SetRGBPalette( 6, 42, 21, 0);
SetRGBPalette( 7, 42, 42, 42);
SetRGBPalette( 8, 21, 21, 21);
SetRGBPalette( 9, 21, 21, 63);
SetRGBPalette( 10, 21, 63, 21);
SetRGBPalette( 11, 21, 63, 63);
SetRGBPalette( 12, 63, 21, 21);
SetRGBPalette( 13, 63, 21, 63);
SetRGBPalette( 14, 63, 63, 21);
SetRGBPalette( 15, 63, 63, 63);
end;

procedure SetColor(color : integer);
begin
  CurrentColor:=color;
	SetAPen(agrp, CurrentColor);
end;

procedure SetBkColor(color : integer);
begin
  CurrentBKColor:=color;
	SetBPen(agrp, color);
end;

procedure SetFillColor(color : integer);
begin
  CurrentFillColor:=color;
  SetAPen(agrp, CurrentFillColor);
end;

procedure initgraph(gd,gm : integer; path : string);
begin
  agSetFontDefaults(agpf);
  agSetScreenDefaults(agts);
(*  agSetScreen(agts,640,200,4);*)
  agSetWindowDefaults(agtw);
  (*agSetWindow(agtw,640,200);*)
  agSetScreenFont(agts, @agpf); 

  agps:=agOpenScreen(agts);
  agSetWindowScreen(agtw,agps);
  agpw:=agOpenWindow(agtw);
  SetEGAVGAColors;
end;

Procedure CloseGraph;
begin
  agCloseWindow(agpw);
  agCloseScreen(agps);
end;


Procedure InitVars;
begin
 agScreenTitle:='Set Title'#0;
end;

begin
 InitVars;
end.
