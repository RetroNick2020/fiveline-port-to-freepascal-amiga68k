(* Amiga 1.4 Port using freepascal Amiga68K                           *)
(* RetroNick's version of popular fiveline puzzle/logic game          *)
(* This Program is free and open source. Do what ever you like with   *)
(* the code. Tested on freepascal for Dos GO32 target but should work *)
(* on anything that uses the graph unit.                              *)
(*                                                                    *)
(* If you can't sleep at night please visit my github and youtube     *)
(* channel. A sub and follow would be nice :)                         *)
(*                                                                    *)
(* https://github.com/RetroNick2020                                   *)
(* https://www.youtube.com/channel/UCLak9dN2fgKU9keY2XEBRFQ           *)
(* https://twitter.com/Nickshardware                                  *)
(* nickshardware2020@gmail.com                                        *)
(*                                                                    *)

Program FiveLine;
     uses aggraph,pathfind,squeue,
      Exec,AmigaDos, agraphics, Intuition,Utility;

Const
  ProgramName ='Amiga Fiveline v1.4';
  ProgramAuthor = 'RetroNick';
  ProgramReleaseDate = 'October 23 - 2021';

  HSize = 9;   (*if you cange hsize or vsize make sure to change in*)
  VSize = 9;   (*pathfind unit also*)

  GBItemXRadius = 9;
  GBItemYRadius = 7;
  
  GBSQWidth  = 30;
  GBSQHeight = 20;
  GBSQThick  = 2;

  DBDelay = 300;
  AmoveDelay = 200;
  NewBallDelay = 600;

  GBItemEmpty  = 0;
  GBItemCrossHair = 1;
  GBItemLocked    = 2;
  GBItemUnLocked  = 3;

  GBItemBorder       = 4;
  GBItemBorderRemove = 5;

  GBItemRed    = 10;
  GBItemGreen  = 11;
  GBItemBrown  = 12;
  GBItemCyan   = 13;
  GBItemLightBlue = 14;
  GBItemLightGray = 15;
  GBItemBrick     = 16;

  AmigaLeftKey = 1079;
  AmigaRightKey = 1078;
  AmigaDownKey = 1077;
  AmigaUpKey = 1076;

type
GameBoardRec = record
                  Item : integer;
               end;

GameBoard = array[0..8,0..8] of GameBoardRec;

(*used for storing path when performing a MoveTo command*)
(*move piece another valid position*)
pathpoints = record
              x,y : integer;
             end;

(*used for storing all the item/color lines that are 5 items (or more) wide*)
itempoints = record
              x,y,stepx,stepy,item,count : integer;
             end;

 ItemLockRec = record
                 isLocked : boolean;
                 x,y      : integer;
               end;

 CrossHairRec = record
                 isVisible : boolean;
                 x,y      : integer;
                 lastx,lasty : integer;
               end;




 apathpoints = array[0..1000] of pathpoints;

 aitempoints = array[0..1000] of itempoints;

 scoreRec = Record
                 xoff,yoff : integer;
                 score : longint;
                 mx    : integer;
                 pos   : integer;
              end;

 helpRec = record
              xoff,yoff : integer;
           end;

 GBPosRec = Record
              xoff,yoff : integer;
 end;

var
 GB            : GameBoard;
 GBPos         : GBPosRec;
 GBItemLock    : ItemLockRec;
 GBCrossHair   : CrossHairRec;
 GBRowsCleared : Boolean;
 aiCounter     : integer;

 score         : ScoreRec;
 help          : helpRec;
 cheatmode     : boolean;

function IntToStr(num : longint) : string;
var
 TStr :string;
begin
 Str(num,TStr);
 IntToStr:=TStr;
end;

procedure Delay(timeout : longint);
begin
 DOSDelay(timeout div 20);
end;

Procedure InitGameBoard;
var
 i, j : integer;
begin
 for j:=0 to vsize-1 do
 begin
   for i:=0 to hsize-1 do
   begin
     GB[i,j].Item:=GBItemEmpty;
   end;
 end;
end;

Procedure InitItemLock;
begin
  GBItemLock.isLocked:=false;
  GBItemLock.x:=0;
  GBItemLock.y:=0;
end;

Procedure InitCrossHair;
begin
  GBCrossHair.x:=4;
  GBCrossHair.y:=4;
  GBCrossHair.isVisible:=true;
end;

Procedure InitAiQueue;
begin
 aiCounter:=0;
end;

procedure GB_Bar(x,y,x2,y2 : integer);
begin
 Bar(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_Rectangle(x,y,x2,y2 : integer);
begin
 Rectangle(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_Line(x,y,x2,y2 : integer);
begin
 Line(x+GBPos.xoff,y+GBPos.yoff,x2+GBPos.xoff,y2+GBPos.yoff);
end;

procedure GB_FillEllipse(x,y,r1,r2 : integer);
begin
  FillEllipse(x+GBPos.xoff,y+GBPos.yoff,r1,r2);
end;

procedure GB_Ellipse(x,y,r1,r2 : integer);
begin
  Ellipse(x+GBPos.xoff,y+GBPos.yoff,0,360,r1,r2);
end;


procedure DrawFilledRect(x,y : integer);
begin
  GB_Bar(x*GBSQWidth+1,y*GBSQHeight+1,
      x*GBSQWidth+GBSQWidth-1,y*GBSQHeight+GBSQHeight-1);
end;

procedure DrawRect(x,y,Thick : integer);
var
 i : integer;
begin
 for i:=1 to Thick do
 begin
   GB_Rectangle(x*GBSQWidth+i,y*GBSQHeight+i,x*GBSQWidth+GBSQWidth-i,y*GBSQHeight+GBSQHeight-i);
 end;
end;

procedure DrawCross(x,y,w,h,wthick,hthick : integer);
var
 xoff,yoff,wtoff,htoff : integer;
begin
  xoff:=(GBSQWidth-w) div 2;
  yoff:=(GBSQHeight-h) div 2;

  wtoff:=(GBSQHeight-wthick) div 2;
  htoff:=(GBSQWidth-hthick) div 2;

(* - *)
  GB_Bar(x*GBSQWidth+xoff,y*GBSQHeight+wtoff,
      x*GBSQWidth+xoff+w, y*GBSQHeight+wtoff+wthick);

(* | *)
  GB_Bar(x*GBSQWidth+htoff,y*GBSQHeight+yoff,
      x*GBSQWidth+htoff+hthick,y*GBSQHeight+yoff+h);
end;

Procedure DrawFillEllip(x,y,r1,r2 : integer);
var
 xoff,yoff : integer;
begin
  xoff:=GBSQWidth div 2;
  yoff:=GBSQHeight div 2;
  GB_FillEllipse(x*GBSQWidth+xoff,y*GBSQHeight+yoff,r1,r2);
end;

Procedure DrawEllip(x,y,r1,r2 : integer);
var
 xoff,yoff : integer;
begin
  xoff:=GBSQWidth div 2;
  yoff:=GBSQHeight div 2;
  GB_Ellipse(x*GBSQWidth+xoff,y*GBSQHeight+yoff,r1,r2);
end;



Procedure DrawGameBoardItem(x,y,item : integer);
begin
  if item=GBItemEmpty then
  begin
    SetColor(Blue);
    SetFillStyle(SolidFill,Blue);
    DrawFilledRect(x,y);
  end
  else if item=GBItemLocked then
  begin
    SetColor(Brown);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemUnLocked then
  begin
    SetColor(Blue);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBorder then
  begin
    SetColor(Yellow);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBorderRemove then
  begin
    SetColor(Blue);
    DrawRect(x,y,GBSQThick);
  end
  else if item=GBItemBrick then
  begin
    SetColor(Blue);
    SetBkColor(Blue);
    SetFillStyle(SolidFill,Blue);
    DrawFilledRect(x,y);
    SetFillStyle(xHatchFill,Yellow);
    DrawFilledRect(x,y);
  end
  else if item=GBItemCrossHair then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Black);
    DrawCross(x,y,13,13,3,3);
  end
  else if item=GBItemRed then
  begin
    SetFillStyle(SolidFill,Red);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end
  else if item=GBItemGreen then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Green);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end
  else if item=GBItemBrown then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Brown);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end
  else if item=GBItemCyan then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,Cyan);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end
  else if item=GBItemLightGray then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,LightGray);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end
  else if item=GBItemLightBlue then
  begin
    SetColor(Black);
    SetFillStyle(SolidFill,lightblue);
    DrawFillEllip(x,y,GBItemXRadius,GBItemYRadius);
    SetColor(Black);
    DrawEllip(x,y,GBItemXRadius,GBItemYRadius);
  end;
end;

procedure DrawCrossHair;
begin
  DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,GBItemCrossHair);
end;

procedure DrawLocked;
begin
  if GBItemLock.isLocked then
  begin
    DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GBItemLocked);
  end
  else
  begin
    DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GBItemUnLocked);
  end;
end;

procedure MoveCrossHairLeft;
begin
  if GBCrossHair.x > 0 then
  begin
     (* erase cross hair by redrawing item at location x,y*)
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     (* update current *)
     dec(GBCrossHair.x);
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairRight;
begin
  if GBCrossHair.x < (HSIZE-1) then
  begin
     (*erase cross hair by redrawing item at location x,y*)
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     (*update current x*)
     inc(GBCrossHair.x);
     (*draw cross hair at updated x,y*)
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairDown;
begin
  if GBCrossHair.y < (VSIZE-1) then
  begin
     (*erase cross hair by redrawing item at location x,y*)
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);
     (*update current y*)
     inc(GBCrossHair.y);
     (*draw cross hair at updated x,y*)
     DrawCrossHair;
  end;
end;

procedure MoveCrossHairUp;
begin
  if GBCrossHair.y > 0 then
  begin
     (*erase cross hair by redrawing item at location x,y*)
     DrawGameBoardItem(GBCrossHair.x,
                       GBCrossHair.y,
                       GB[GBCrossHair.x,GBCrossHair.y].Item);

     (*update current y*)
     dec(GBCrossHair.y);
     (*draw cross hair at updated x,y*)
     DrawCrossHair;
  end;
end;

Procedure DrawGameGrid;
var
i,j : integer;
begin
 SetFillStyle(SolidFill,Blue);
 GB_Bar(0,0,HSize*GBSQWidth,Vsize*GBSQHeight);

 SetColor(white);
 GB_Rectangle(0,0,HSize*GBSQWidth,VSize*GBSQHeight);

 for i:=1 to HSize-1 do
 begin
   GB_line(i*GBSQWidth,0,i*GBSQWidth,VSize*GBSQHeight);
 end;
 for j:=1 to VSize-1 do
 begin
   GB_line(0,j*GBSQHeight,HSize*GBSQWidth,j*GBSQHeight);
 end;
end;

Procedure DrawGameBoardItems;
var
 i,j : integer;
begin
 for j:=0 to VSIZE-1 do
 begin
  for i:=0 to HSIZE-1 do
  begin
    DrawGameBoardItem(i,j,GB[i,j].Item);
  end;
 end;
 DrawLocked;
 DrawCrossHair;
end;

Procedure DrawGameBoard;
begin
  DrawGameGrid;
  DrawGameBoardItems;
end;

(*as long it is not empty it should be moveable*)
Function canSelectItem(x,y : integer) : Boolean;
begin
  canSelectItem:=(GB[x,y].Item <> GBItemEmpty);
end;

(*from selected position*)
function canMoveTo(x,y : integer) : Boolean;
begin
  canMoveTo:=(GB[x,y].Item = GBItemEmpty);
end;

Procedure MoveGameBoardItem(startx,starty,endx,endy : integer);
begin
 GB[endx,endy].Item:=GB[startx,starty].Item;
 GB[startx,starty].Item:=GBItemEmpty;
end;

function isPosInRange(x,y : integer) : boolean;
var
 maxx,maxy : integer;
begin
 maxx:=HSIZE-1;
 maxy:=VSIZE-1;
 isPosInRange:=(x>=0) and (x<=maxx) and (y>=0) and (y<=maxy);
end;

function isColorSame(Var TGB : GameBoard;x1,y1,x2,y2 : integer) : boolean;
var
 c1,c2 : integer;
begin
 c1:=TGB[x1,y1].Item;
 c2:=TGB[x2,y2].Item;
 IsColorSame:=(c1>0) and (c1=c2);
end;

(*looks for continous color in any direction*)
(*stepx and stepy can be 0 or 1 or -1*)

function FindColorCount(Var TGB : GameBoard;startx,starty,stepx,stepy,count : integer) : integer;
var
 i,c : integer;
 xpos,ypos : integer;
begin
 xpos:=startx;
 ypos:=starty;
 c:=1;
 for i:=1 to count-1 do
 begin
    if isPosInRange(xpos,ypos) and isPosInRange(xpos+stepx,ypos+stepy) then
    begin
      if isColorSame(TGB,xpos,ypos,xpos+stepx,ypos+stepy) then
      begin
        inc(c);
      end
      else
      begin
        FindColorCount:=c;
        exit;
      end;
    end;
    inc(xpos,stepx);
    inc(ypos,stepy);
  end;
  FindColorCount:=c;
end;

procedure AddRowsToQueue(x,y,stepx,stepy,count : integer;
                                   var apoints : aitempoints);

begin
 apoints[aiCounter].item:=GB[x,y].Item;
 apoints[aiCounter].x:=x;
 apoints[aiCounter].y:=y;
 apoints[aiCounter].stepx:=stepx;
 apoints[aiCounter].stepy:=stepy;
 apoints[aiCounter].count:=count;
 inc(aiCounter);
end;

Procedure SetGameBoardPos(xpos,ypos : integer);
begin
 GBPos.xoff:=xpos;
 GBPos.yoff:=ypos;
end;

Procedure SetGameHelpPos(xpos,ypos : integer);
begin
 help.xoff:=xpos;
 help.yoff:=ypos;
end;

Procedure SetGameScorePos(xpos,ypos : integer);
begin
 score.xoff:=xpos;
 score.yoff:=ypos;
end;

procedure DrawTitle(xpos,ypos : integer);
begin
 
 SetColor(White);
 SetBkColor(Black);
 OutTextXY(xpos,ypos,ProgramName+' '+'By '+ProgramAuthor+' - Released on '+ProgramReleaseDate);
end;

procedure DrawGameOver;
begin
 
 SetBkColor(Blue);
 SetColor(Yellow);
 OutTextXY(GBPos.xoff+95,GBPos.yoff+85,'Game Over');
end;

procedure DrawHelp;
var
  w,h : integer;
begin
 w:=290;
 h:=250;
 SetColor(Blue);
 SetFillStyle(SolidFill,Blue);
 SetBkColor(Blue);
 SetFillStyle(SolidFill,Blue);
 Bar(help.xoff,help.yoff,help.xoff+w,help.yoff+h);
 
 
 SetColor(Yellow);
 OutTextXY(help.xoff+10,help.yoff+5, 'How To Play Fiveline');
 SetColor(White);
 OutTextXY(help.xoff+10,help.yoff+17, 'Arrange five or more balls of same');
 OutTextXY(help.xoff+10,help.yoff+29, 'color in any direction to remove');
 OutTextXY(help.xoff+10,help.yoff+41, 'from board. Use azsw keys and Enter');
 OutTextXY(help.xoff+10,help.yoff+53, 'key to select your ball. Move ');
 OutTextXY(help.xoff+10,help.yoff+65, 'crosshair to an empty location and');
 OutTextXY(help.xoff+10,help.yoff+77, 'press ENTER to move your ball.');
 SetColor(Yellow);
 OutTextXY(help.xoff+10,help.yoff+89, 'R = Restart Game');
 OutTextXY(help.xoff+10,help.yoff+101,'X or Q = QUIT');
 OutTextXY(help.xoff+10,help.yoff+113,'C = Enable/Disable cheat mode');
 
 if cheatmode then
 begin
   SetColor(Green);
   OutTextXY(help.xoff+10,help.yoff+125,'Keys 0 1 2 3 4 5 6 are Enabled');
 end;
end;

Procedure DisplayScore(justscore : boolean);
var
 w,h : integer;
begin
 w:=290;
 h:=40;
 SetColor(Blue);
 SetFillStyle(SolidFill,Blue);
 
 if justscore = false then
 begin
   Bar(Score.xoff,score.yoff,Score.xoff+w,score.yoff+h);
   
   SetColor(White);
   SetBkColor(Blue);
   OutTextXY(Score.xoff+10,score.yoff+5,'SCORE:');
 end;

 (*erase previouse score and line points*)
 SetFillStyle(SolidFill,Blue);
 SetColor(Blue);
 Bar(Score.xoff,score.yoff+14,Score.xoff+w,score.yoff+h);
 
 SetBkColor(Blue);
 SetColor(White);
 OutTextXY(Score.xoff+10,score.yoff+17,IntToStr(score.score));
 SetColor(Yellow);
 OutTextXY(Score.xoff+10,score.yoff+29,IntToStr(score.pos)+'x'+IntToStr(score.mx));
end;

procedure UpdateScore(pos, count : integer);
begin
 score.pos:=pos;
 score.mx:=abs(4-count)*10; (*5 line rows = 10 points per ball, 6 line = 20, 7 line =30*)
 Inc(score.Score,score.mx);
 DisplayScore(true);
end;

procedure DrawRowBoarder(x,y,stepx,stepy,count : integer; item : integer);
var
 i : integer;
begin
 for i:=1 to count do
 begin
   DrawGameBoardItem(x,y,item);
   inc(x,stepx);
   inc(y,stepy);

   (*update score as we are removing the row*)
   if item = GBItemEmpty then UpdateScore(i,count);
   Delay(DBDelay);
 end;
end;

procedure DrawRowOfColors(var apoints : aitempoints;item : integer);
var
 i : integer;
begin
 for i:=0 to aiCounter-1 do
 begin
   DrawRowBoarder(apoints[i].x,apoints[i].y,
                  apoints[i].stepx,apoints[i].stepy,
                  apoints[i].count,item);
 end;
end;

procedure DeleteRowFromBoard(var TGB : GameBoard; x,y,stepx,stepy,count : integer);
var
 i : integer;
begin
 for i:=1 to count do
 begin
   TGB[x,y].Item:=GBItemEmpty;
   inc(x,stepx);
   inc(y,stepy);
 end;
end;


function FindRowOfColors(var apoints : aitempoints) : integer;
var
 TGB : GameBoard;
 i,j : integer;
 count : integer;
 rowcount : integer;
begin
 rowcount:=0;
 (*Make Copy GM*)
 TGB:=GB;

 (*horizonatal check*)
 for j:=0 to VSize-1 do   (*//VSIZE-1    0 to 8*)
 begin
   for i:=0 to HSize-5 do (*HSIZE-5    0 to 4*)
   begin
     count:=FindColorCount(TGB,i,j,1,0,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,1,0,count,apoints);
        (*Remove Line from from TGB - solves 6 to 9 in a row duplicate problem*)
        DeleteRowFromBoard(TGB,i,j,1,0,count);
     end;
   end;
 end;

 (*Make Copy GM Again - not a mistake*)
 TGB:=GB;
  (*vertical check*)
 for i:=0 to HSize-1 do   (*HSIZE-1    0 to 8*)
 begin
   for j:=0 to VSize-5 do (*VSIZE-5    0 to 4*)
   begin
     count:=FindColorCount(TGB,i,j,0,1,9);
     if count > 4 then
     begin
       inc(rowcount);
       AddRowsToQueue(i,j,0,1,count,apoints);
       (*Remove Line from from TGB - solves 6 to 9 in a row duplicate problem*)
       DeleteRowFromBoard(TGB,i,j,0,1,count);
     end;
   end;
 end;

 (*Make Copy GM 3rd time*)
 TGB:=GB;

 (*horizonatal down/right*)
 for j:=0 to VSize-5 do     (*VSIZE-5   0 to 4*)
 begin
   for i:=0 to HSize-5 do   (*HSIZE-5   0 to 4*)
   begin
     count:=FindColorCount(TGB,i,j,1,1,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,1,1,count,apoints);
        (*Remove Line from from TGB - solves 6 to 9 in a row duplicate problem*)
        DeleteRowFromBoard(TGB,i,j,1,1,count);
     end;
   end;
 end;

  (*Make Copy GM 4th time*)
 TGB:=GB;
  (*horizonatal down/left*)
 for j:=0 to VSize-5 do      (*VSIZE-5  0 to 4*)
 begin
   for i:=4 to HSize-1 do    (*HSIZE-1  4 to 8*)
   begin
     count:=FindColorCount(TGB,i,j,-1,1,9);
     if count > 4 then
     begin
        inc(rowcount);
        AddRowsToQueue(i,j,-1,1,count,apoints);
        (*Remove Line from from TGB - solves 6 to 9 in a row duplicate problem*)
        DeleteRowFromBoard(TGB,i,j,-1,1,count);
     end;
   end;
 end;
 FindRowOfColors:=rowcount;
end;

Function ValidMovesLeft : integer;
var
 count,i,j : integer;
begin
 count:=0;
 for j:=0 to VSize-1 do
 begin
   for i:=0 to Hsize-1 do
   begin
     if GB[i,j].Item = GBItemEmpty then inc(count);
   end;
 end;
 ValidMovesLeft:=count;
end;

Function isGameOver : boolean;
begin
  isGameOver:=(ValidMovesLeft = 0);
end;

Procedure GetXYForMoveX(mvx : integer;var x,y : integer);
var
 i,j : integer;
 count : integer;
begin
 count:=0;
 x:=-1;
 y:=-1;
 for j:=0 to VSize-1 do
 begin
   for i:=0 to Hsize-1 do
   begin
     if GB[i,j].Item = GBItemEmpty then inc(count);
     if count = mvx then
     begin
       x:=i;
       y:=j;
       exit;
     end;
   end;
 end;
end;

Procedure GetRandomSpot(var x,y : integer);
var
  r : integer;
  vcount : integer;
begin
 x:=-1;
 y:=-1;
 vcount:=ValidMovesLeft;
 if vcount > 0 then
 begin
   r:=random(vcount)+1;
   GetXYForMoveX(r,x,y);
 end;
end;

Function GetRandomItem : integer;
begin
  GetRandomItem:=random(6)+GBItemRed;
end;

(*for debug / cheat mode*)
Procedure PlotItem(item : integer);
begin
  GB[GBCrossHair.x,GBCrossHair.y].Item:=item;
  DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,item);
  DrawCrossHair;
end;

Procedure LockItem;
begin
 if GB[GBCrossHair.x,GBCrossHair.y].Item<>GBItemEmpty then
 begin
   if GBItemLock.isLocked then
   begin
     GBItemLock.isLocked:=false;
     DrawLocked;  (*erase current lock*)
   end;
   GBItemLock.x:=GBCrossHair.x;
   GBItemLock.y:=GBCrossHair.y;
   GBItemLock.isLocked:=true;
   DrawLocked;
 end;
end;

(* Copy GameBoard data to PGrid in a format that our path finding algorithm*)
(* can make use of it. each color ball is considered a wall/obstacle.*)

Procedure CopyGbToPga(Var PGrid : PGA);
var
 i,j : integer;
begin
 For j:=0 to VSize-1 do
 begin
   for i:=0 to  HSize-1 do
   begin
      if GB[i,j].Item<>GBItemEmpty then PlaceWall(PGrid,i,j);
   end;
 end;
end;

function isPathToItem(sx,sy,tx,ty : integer) : boolean;
var
 PGrid : PGA;
 FoundPath : SimpleQueueRec;
begin
  ClearGrid(PGrid);
  CopyGbToPga(PGrid);
  isPathToItem:=FindTargetPath(PGrid,sx,sy,tx,ty,FoundPath);
end;

(*check if the destination location is one block to the right,left,up,down*)
function isNextToMoveBlock(sx,sy,tx,ty : integer) : boolean;
var
 vpos : boolean;
 dx,dy : integer;
begin
  isNextToMoveBlock:=false;
  vpos:=isPosInRange(sx,sy) and isPosInRange(tx,ty);
  if vpos=false then exit;
  dx:=abs(sx-tx);
  dy:=abs(sy-ty);
  isNextToMoveBlock:=((dx=1) and (dy=0)) or ((dx=0) and (dy=1))
end;

Procedure RemoveRows(var apoints : aitempoints; count : integer);
var
 i : integer;
begin
 For i:=0 to count-1 do
 begin
   DeleteRowFromBoard(GB,apoints[i].x,apoints[i].y,
                         apoints[i].stepx,apoints[i].stepy,
                         apoints[i].count);
 end;
 DrawRowOfColors(apoints,GBItemEmpty);
end;

Procedure SetRowsClearedStatus(status : boolean);
begin
  GBRowsCleared:=status;
end;

Function GetRowsClearedStatus : boolean;
begin
  GetRowsClearedStatus:=GBRowsCleared;
end;

Procedure CheckForRows;
var
 count : integer;
 apoints : aitempoints;
begin
 SetRowsClearedStatus(False);
 InitAIQueue;
 count:=FindRowOfColors(apoints);
 if count > 0 then
 begin
    DrawRowOfColors(apoints,GBItemBorder);
    RemoveRows(apoints,count);
    SetRowsClearedStatus(true);
 end;
end;

Procedure AniMoveBoardItem(sx,sy,tx,ty : integer);
var
 PGrid : PGA;
 FoundPath : SimpleQueueRec;
 qr : locationRec;
 i : integer;
 item : integer;
 isPathToItem : boolean;
begin
  ClearGrid(PGrid);
  CopyGbToPga(PGrid);
  InitSQueue(FoundPath);

  isPathToItem:=FindTargetPath(PGrid,sx,sy,tx,ty,FoundPath);
  if isPathToItem = false then exit;

  item:=GB[sx,sy].item;

  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,GBItemBrick);
    Delay(AmoveDelay);
  end;
  DrawGameBoardItem(sx,sy,GBItemEmpty);
  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,Item);
    Delay(AmoveDelay);
    DrawGameBoardItem(qr.x,qr.y,GBItemBrick);
  end;
  DrawGameBoardItem(tx,ty,item);

  for i:=1 to SQueueCount(FoundPath) do
  begin
    SQueueGet(FoundPath,i,qr);
    DrawGameBoardItem(qr.x,qr.y,GBItemEmpty);
    Delay(AMoveDelay);
  end;

end;

Function MovedItem : Boolean;
var
 canMove  : boolean;
 pathMove  : Boolean;
 nextMove : Boolean;
begin
 MovedItem:=false;
 canMove:=false;
 canmove:=GBItemLock.isLocked and canMoveTo(GBCrossHair.x,GBCrossHair.y);
 if canmove = false then exit;

 nextMove:=isNextToMoveBlock(GBItemLock.x,GBItemLock.y,GBCrossHair.x,GBCrossHair.y);

 if nextmove = false then
 begin
    pathmove:=isPathToItem(GBItemLock.x,GBItemLock.y,GBCrossHair.x,GBCrossHair.y);
    if pathmove = false then exit;
 end;

 GBItemLock.isLocked:=false;
 DrawLocked;  (*erase current lock*)

 if pathmove then AniMoveBoardItem(GBItemLock.x,GBItemLock.y,
                                   GBCrossHair.x,GBCrossHair.y);
 MoveGameBoardItem(GBItemLock.x,GBItemLock.y,
                   GBCrossHair.x,GBCrossHair.y);

 GBItemLock.isLocked:=false;
 DrawGameBoardItem(GBItemLock.x,GBItemLock.y,GB[GBItemLock.x,GBItemLock.y].Item);
 DrawGameBoardItem(GBCrossHair.x,GBCrossHair.y,GB[GBCrossHair.x,GBCrossHair.y].Item);

 CheckForRows;
 DrawCrossHair;
 MovedItem:=true;
end;

Procedure ComputerMove;
var
 item,x,y,i : integer;
 count      : integer;
begin
 count:=validMovesLeft;
 if count > 3 then count:=3;
 for i:=1 to count do
 begin
   GetRandomSpot(x,y);
   item:=GetRandomItem;
   GB[x,y].Item:=Item;
   DrawGameBoardItem(x,y,item);
   Delay(NewBallDelay);
 end;
end;


Procedure CheatAction(k : integer);
begin
  if k=ord('1') then PlotItem(GBItemRed);
  if k=ord('2') then PlotItem(GBItemGreen);
  if k=ord('3') then PlotItem(GBItemBrown);
  if k=ord('4') then PlotItem(GBItemCyan);
  if k=ord('5') then PlotItem(GBItemLightBlue);
  if k=ord('6') then PlotItem(GBItemLightGray);
  if k=ord('0') then PlotItem(GBItemEmpty);
end;

Procedure LockOrMove;
begin
 if GBItemLock.isLocked then
 begin
   if GB[GBCrossHair.x,GBCrossHair.y].item <> GBItemEmpty then
   begin
     LockItem;
   end
   else
   begin
     if MovedItem then
     begin
       (* we only drop new balls when a line has NOT been cleared after a move*)
       if GetRowsClearedStatus=false then
       begin
          ComputerMove;  (*drop more balls*)
          CheckForRows;  (*check if one of those balls connected 5 or more*)
          DrawCrossHair;
       end;
     end;
   end;
 end
 else
 begin
   LockItem;
 end;
end;

procedure InitScore;
begin
  score.Score:=0;
  score.mx:=0;
  score.pos:=0;
end;

Procedure StartGame;
begin
  Randomize;
  cheatmode:=false;
  InitScore;
  SetGameBoardPos(30,5);
  SetGameHelpPos(330,50);
  SetGameScorePos(330,5);
 (* DrawTitle(10,5);*)
  DisplayScore(false);
  InitAIQueue;
  InitGameBoard;
  InitItemLock;
  InitCrossHair;
  DrawGameBoard;
  DrawHelp;
  ComputerMove;
  DrawCrossHair;
end;



Const
(*
	LRev		   	= 33; { Nedded Layers.library revision number }
*)
	GRev           = 33; {    -   graphics.library   -       -   }
	IRev           = 33; {    -   Intuition.library  -		  -	}



var
   gd,gm    : integer;
   gameover : boolean;
 

Procedure ProcessKeys( k,q : integer);
begin
 (*  writeln(k,q);*)
  if gameover = false then
  begin
    if (k=ord('a')) or (k=ord('A')) or (k=AmigaLeftKey)  then MoveCrossHairLeft;
    if (k=ord('s')) or (k=ord('S')) or (k=AmigaRightKey) then MoveCrossHairRight;
    if (k=ord('w')) or (k=ord('W')) or (k=AmigaUpKey) then MoveCrossHairUp;
    if (k=ord('z')) or (k=ord('Z')) or (k=AmigaDownKey) then MoveCrossHairDown;
  end;
(*  if k=ord('[') then CheckForRows;*)
(*  if k=ord('g')  then DrawGameBoard;*)
(*  if k=ord('p') then DrawPath;*)

  if (k=ord('r')) or (k=ord('R')) then
  begin
     gameover:=false;
     StartGame;
  end;
  if (k=ord('l')) or (k=ord('L')) or (k=13) then LockOrMove;

  (*check if board is filled up/gave over*)
  gameover:=isGameOver;
  if gameover then DrawGameOver;
  (*if (k=ord('m')) then MovedItem;*)

  if CheatMode then CheatAction(k);
  if (k=ord('c')) or (k=ord('C')) then
  begin
     Cheatmode:=NOT cheatmode;
     DrawHelp;
  end;
end;


procedure HandleEvents;
var
 imsg: pIntuiMessage;
 sigr: long;
 quit : boolean;
 GraphWindow : pWindow;
begin
	GraphWindow:=agGetGraphWindow;
  quit:=false;

  Repeat  
    (* Wait for an event *)
  	sigr := Wait((long(1) shl GraphWindow^.UserPort^.mp_SigBit) or SIGBREAKF_CTRL_C);

	  (* Did we get a break signal *)
	  if (sigr and SIGBREAKF_CTRL_C) <> 0 then quit := true;

	  (* Pull Intuition messages *)
	  imsg := pIntuiMessage(GetMsg(GraphWindow^.UserPort));
	  while imsg <> nil do
	  begin
		  with imsg^ do
		  begin
			  (* Handle each message *)
			  case iClass of
				  IDCMP_RAWKEY:
					   ProcessKeys(1000+code,qualifier); (*qualifier is extra code for shift/control*)
				  IDCMP_VANILLAKEY:
            if (code=ord('q')) or (code=ord('Q')) or (code=ord('x')) or (code=ord('X')) then 
            begin
              quit:=true;
            end
            else
            begin  
					    ProcessKeys(code,qualifier);
            end;  
			  end;
		end;
		(* Done with the message, so reply to it *)
		ReplyMsg(pMessage(imsg));
		imsg := pIntuiMessage(GetMsg(GraphWindow^.UserPort))
	end
 Until quit = true;
end;


begin
 gd:=ega;
 gm:=egalo;
 agSetScreenTitle(ProgramName+' '+ProgramAuthor+' '+ProgramReleaseDate);
 
 initgraph(gd,gm,'');

 gameover:=false;
 StartGame;
 HandleEvents;
 closegraph;
end.
