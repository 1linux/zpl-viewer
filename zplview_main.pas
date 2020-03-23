unit zplview_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  StdCtrls, ComCtrls, Sockets, ssockets,fphttpclient,zplview_settings;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    AcceptTimer: TTimer;
    Shape1: TShape;
    StatusBar1: TStatusBar;
    procedure AcceptTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Image1Paint(Sender: TObject);
    procedure Image1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure Shape1EndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure Shape1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Shape1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Shape1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure StatusBar1Click(Sender: TObject);
  private
    socket : TINetServer;
    zpldata : Pointer;
    deg : integer;
    dragDir: Integer;
    dragData: Integer;
    rulers:     array of integer;
    rulertypes: array of integer; // 0=Vertical, 1=horizonal
    RulersVisible : Boolean;
    procedure ReadJetData(Sender: TObject; DataStream: TSocketStream);
    procedure NothingHappened(Sender: TObject);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  GetMem (zpldata, 1000000);        // 1MB sollte für ZPL reichen ?!?
  FillChar (zpldata^,1000000,0);

  socket := TINetServer.Create(9100);
  socket.ReuseAddress:=true;
  socket.MaxConnections:=1;
  socket.OnConnect:=@ReadJetData;
  socket.OnIdle:=@NothingHappened;
  socket.Bind;
  socket.Listen;
  //socket.SetNonBlocking;
  socket.AcceptIdleTimeOut:=100;
  deg:=0;
  SetLength(rulers,0);
  SetLength(rulertypes,0);
  DragDir:=-1;
  RulersVisible:= True;
end;

procedure TForm1.Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
var
  aspect: LongInt;
begin
  if ((Source = Shape1) and (DragDir>-1) and (Image1.Picture.Graphic<>nil) ) then
  begin
    // Drop it like its hot...
    SetLength(rulers,Length(rulers)+1);
    SetLength(rulertypes,Length(rulertypes)+1);
    rulertypes[Length(rulertypes)-1]:=DragDir;
    aspect:= DragData*Image1.Picture.Width div Image1.Width;
    rulers[Length(rulers)-1]:=aspect;
    DragDir:=-1;
    StatusBar1.Panels[2].Text:='';
    Image1.Repaint;
  end;
end;

procedure TForm1.Image1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  pt : tPoint;
begin
  if (Source = Shape1) then
  begin
    Accept := True;
    RulersVisible:=True;
    pt := ScreenToClient(Mouse.CursorPos);
    if DragDir=-1 then
    begin
      // now have FORM position
      if pt.x>=15 then DragDir:=0;  // User wants to drag horizontally
      if pt.y>=15 then DragDir:=1;  // User wants to drag vertically
    end;
    if DragDir=0 then
    begin
      StatusBar1.Panels[2].Text:= 'X = '+IntToStr(pt.x);
      dragData:=pt.x;
    end;

    if DragDir=1 then
    begin
      StatusBar1.Panels[2].Text:= 'Y = '+IntToStr(pt.y);
      dragData:=pt.y;
    end;
    Image1.Repaint;
  end;
end;



procedure TForm1.Image1Paint(Sender: TObject);
var
  n : Integer;
  aspect:LongInt;
begin
  if RulersVisible and (Image1.Picture.Graphic<>nil) then
  begin
    if Length(rulertypes)>0 then
    begin
      Image1.Canvas.Pen.Color:=clGreen;
      for n:=0 to Length(rulertypes)-1 do
      begin
        aspect:= rulers[n]*Image1.Width div Image1.Picture.Width;
        if rulertypes[n]=0 then
        begin
          Image1.Canvas.MoveTo(aspect,0);
          Image1.Canvas.LineTo(aspect,Image1.Canvas.Height);
        end;
        if rulertypes[n]=1 then
        begin
          Image1.Canvas.MoveTo(0,aspect);
          Image1.Canvas.LineTo(Image1.Canvas.Width,aspect);
        end;
      end;
    end;
    if DragDir>-1 then
    begin
      Image1.Canvas.Pen.Color:=clRed;
      if DragDir=0 then
      begin
        Image1.Canvas.MoveTo(DragData,0);
        Image1.Canvas.LineTo(DragData,Image1.Canvas.Height);
      end;
      if DragDir=1 then
      begin
        Image1.Canvas.MoveTo(0,DragData);
        Image1.Canvas.LineTo(Image1.Canvas.Width,DragData);
      end;
    end;
  end;
end;

procedure TForm1.Image1StartDrag(Sender: TObject; var DragObject: TDragObject);
begin

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  FormSettings.ShowModal;
end;


procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.Shape1EndDrag(Sender, Target: TObject; X, Y: Integer);
begin
  DragDir:=-1;
  Image1.Repaint;
end;

procedure TForm1.Shape1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (Image1.Picture.Graphic<>nil) then
  begin
    Shape1.BeginDrag(False);
    if not RulersVisible then
    begin
      RulersVisible:=true;
      Image1.Repaint;
    end;
  end;
  if Button = mbRight then
  begin
    SetLength(rulers,0);
    SetLength(rulertypes,0);
    Image1.Repaint;
  end;
end;


procedure TForm1.Shape1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (X<Shape1.Width) and (Y<Shape1.Height) then
  begin
    RulersVisible:=False;
    Image1.Repaint;
    //StatusBar1.Panels[2].Text:= 'Tilt';
  end;
end;

procedure TForm1.Shape1StartDrag(Sender: TObject; var DragObject: TDragObject);
begin
  DragDir:=-1;
  RulersVisible:=True;
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
  deg:=deg+90;
  if deg>270 then deg:=0;
  StatusBar1.Panels[1].Text:=IntToStr(deg);
  Image1.Picture.Clear;
end;

procedure TForm1.AcceptTimerTimer(Sender: TObject);
begin
  socket.StartAccepting;
end;

procedure TForm1.NothingHappened(Sender: TObject);
begin
  socket.StopAccepting;
end;


procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  socket.Free;
  FreeMem (zpldata,1000000);
end;

procedure TForm1.ReadJetData(Sender: TObject; DataStream: TSocketStream);
var len: LongInt;
    FPHTTPClient: TFPHTTPClient;
    URL: String;
    PostData: TMemoryStream;
    PngData: TMemoryStream;
    offset:LongInt;
begin
  //WriteLn('Accepting client: ', HostAddrToStr(NetToHost(Data.RemoteAddress.sin_addr)));
  offset:=0;
  repeat
    len := DataStream.Read( (zpldata+offset)^ , 1000000-offset);
    if len>0 then offset:=offset+len;
  until len<=0;
  DataStream.Free;

  FPHTTPClient := TFPHTTPClient.Create(nil);
  PostData := TMemoryStream.Create;
  PngData := TMemoryStream.Create;
  try
    FPHTTPClient.AllowRedirect := True;
    PostData.Write(zpldata^,offset);
    PostData.Position := 0;
    FPHTTPClient.RequestBody:=PostData;
    FPHTTPClient.AddHeader('X-Rotation',IntToStr(deg));
    try
      URL:='http://api.labelary.com/v1/printers/8dpmm/labels/6x6/0/';
      FPHTTPClient.Post(URL,PngData);
      PngData.Position := 0;
      Image1.Picture.LoadFromStream(PngData);
      StatusBar1.Panels[0].Text:=DateTimeToStr(Now);
    except
      on E: exception do
        ShowMessage(E.Message);
    end;
  finally
    FreeAndNil(PostData);
    FreeAndNil(PngData);
    FreeAndNil(FPHTTPClient);
  end;
end;


end.

