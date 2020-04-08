unit zplview_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls,
  StdCtrls, ComCtrls, Sockets, ssockets,fphttpclient,zplview_settings,dateutils,
  INIFiles,Printers,lazlogger;
type

  { TForm1 }

  TForm1 = class(TForm)
    BRenderManual: TButton;
    Image1: TImage;
    MainMenu1: TMainMenu;
    MSourceCode: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    AcceptTimer: TTimer;
    Panel1: TPanel;
    Panel2: TPanel;
    Shape1: TShape;
    StatusBar1: TStatusBar;
    procedure AcceptTimerTimer(Sender: TObject);
    procedure BRenderManualClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Image1Paint(Sender: TObject);
    procedure Image1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
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
    zpldatalen:LongInt;
    dragDir: Integer;
    dragData: Integer;
    rulers:     array of integer;
    rulertypes: array of integer; // 0=Vertical, 1=horizonal
    RulersVisible : Boolean;
    settings : ZViewSettings;
    inifile  : string;
    procedure ReadJetData(Sender: TObject; DataStream: TSocketStream);
    procedure GetLabelaryData;
    procedure NothingHappened(Sender: TObject);
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ResetSettings;
    function  IniFileName():string;
    function  GetLANIp():string;
    procedure RePrint;
    procedure SavePng;
    procedure SaveRaw(data:string);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.GetLANIp():string;
var
  s: TInetSocket;
begin
  try
    s := TInetSocket.Create('1.1.1.1',80);
    GetLANIp:=NetAddrToStr(s.LocalAddress.sin_addr);
  finally
    s.Free;
  end;
end;

function  TForm1.IniFileName():string;
var f,i:string;
begin
  i:=ChangeFileExt(ExtractFileName(Application.ExeName),'.ini');
  if GetEnvironmentVariable('APPDATA')<>'' then
    IniFileName:=GetEnvironmentVariable('APPDATA')+'\'+i
  else if GetEnvironmentVariable('HOME')<>'' then
    IniFileName:=GetEnvironmentVariable('HOME')+'/.config/'+i
  else
    IniFileName:=i;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  GetMem (zpldata, 1000000);        // 1MB sollte für ZPL reichen ?!?
  FillChar (zpldata^,1000000,0);
  zpldatalen:=0;

  inifile:=IniFileName();
  ResetSettings;
  LoadSettings;
  StatusBar1.Panels[3].Text:=GetLANIp()+':'+IntToStr(settings.tcpport);

  socket := TINetServer.Create(settings.bindadr,settings.tcpport);
  socket.ReuseAddress:=true;
  socket.MaxConnections:=1;
  socket.OnConnect:=@ReadJetData;
  socket.OnIdle:=@NothingHappened;
  socket.Bind;
  socket.Listen;
  //socket.SetNonBlocking;
  socket.AcceptIdleTimeOut:=100;

  SetLength(rulers,0);
  SetLength(rulertypes,0);
  DragDir:=-1;
  RulersVisible:= True;
  Panel1.Width:=15;
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
  FormSettings.PutSettings(settings);
  if FormSettings.ShowModal=mrOK then
  begin
    FormSettings.GetSettings(settings);
    StatusBar1.Panels[1].Text:=IntToStr(settings.rotation);
    StatusBar1.Panels[3].Text:=GetLANIp()+':'+IntToStr(settings.tcpport);
    SaveSettings;
    if zpldatalen>0 then GetLabelaryData;
    if socket.Port<>settings.tcpport then
    begin
      socket.Free;
      socket := TINetServer.Create(settings.bindadr, settings.tcpport);
      socket.ReuseAddress:=true;
      socket.MaxConnections:=1;
      socket.OnConnect:=@ReadJetData;
      socket.OnIdle:=@NothingHappened;
      socket.Bind;
      socket.Listen;
      socket.AcceptIdleTimeOut:=100;
    end;
  end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.Panel2Click(Sender: TObject);
begin
  if Panel1.Width<50 then begin
    Form1.Width:=Form1.Width + Form1.Width;
    Panel1.Width:=Panel1.Width + (Form1.Width div 2);
  end
  else begin
    Form1.Width:=Form1.Width div 2;
    Panel1.Width:=15;
  end
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
  with settings do begin
    rotation:=rotation+90;
    if rotation>270 then rotation:=0;
    StatusBar1.Panels[1].Text:=IntToStr(rotation);
  end;
  if zpldatalen>0 then GetLabelaryData;
//  Image1.Picture.Clear;
end;

procedure TForm1.AcceptTimerTimer(Sender: TObject);
begin
  socket.StartAccepting;
end;

procedure TForm1.BRenderManualClick(Sender: TObject);
begin
  if MSourceCode.Lines.Count > 3 then begin
    zpldatalen := MSourceCode.Lines.Text.Length;
    Move(MSourceCode.Lines.Text[1],zpldata^, zpldatalen);
    GetLabelaryData;;
  end;
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

procedure TForm1.SavePng;
var
  filename:string;
begin
  filename:=settings.savepath;
  if filename<>'' then filename:=filename+'/';
  filename:=Format('%s%d.png',[SetDirSeparators(filename),DateTimeToUnix(now)]);
  Image1.Picture.SaveToFile(filename);
end;

procedure TForm1.SaveRaw(data:string);
Var
 File1:TextFile;
 filename:string;
begin
  filename:=settings.savepath;
  if filename<>'' then filename:=filename+'/';
  filename:=Format('%srawdata.txt',[SetDirSeparators(filename)]);
  AssignFile(File1,filename);
  Try
    Rewrite(File1);
    Writeln(File1,data);
  Finally
    CloseFile(File1);
  end;
end;


procedure TForm1.RePrint;
var
  p:integer;
  written: Integer;
  data:string;
begin
  p:=Printer.Printers.IndexOf(settings.printer);
  if p<0 then begin
    ShowMessage('Eingesteller Drucker ungültig');
    exit
  end;
  if zpldatalen=0 then begin
    ShowMessage('Es gibts nichts zu drucken!');
    exit;
  end;
  Printer.PrinterIndex := p;
  if Printer.Printing then Printer.Abort;
  try
    Printer.Title := 'ZPL-View reprint';
    Printer.RawMode:=settings.printraw;
    Printer.BeginDoc;
    if settings.printraw then
      Printer.Write(self.zpldata^,self.zpldatalen, written)
    else
      printer.Canvas.StretchDraw(Classes.Rect(0,0,
        Image1.Picture.Graphic.Width*printer.XDPI div settings.resolution,
        Image1.Picture.Graphic.Height*printer.YDPI div settings.resolution),
        Image1.Picture.Graphic);
  finally
    Printer.EndDoc;
  end;

end;

procedure TForm1.GetLabelaryData;
var FPHTTPClient: TFPHTTPClient;
    Fmt,URL,dpi: String;
    FmtSet:TFormatSettings;
    PostData: TMemoryStream;
    PngData: TMemoryStream;
    //filename:string;
    errormsg:string;
begin
  FPHTTPClient := TFPHTTPClient.Create(nil);
  PostData := TMemoryStream.Create;
  PngData := TMemoryStream.Create;
  try
    FPHTTPClient.AllowRedirect := True;
    PostData.Write(zpldata^,zpldatalen);
    PostData.Position := 0;
    FPHTTPClient.RequestBody:=PostData;
    FPHTTPClient.AddHeader('X-Rotation',IntToStr(settings.rotation));
    try
      case settings.resolution of
        152: dpi:='6dpmm';
        203: dpi:='8dpmm';
        300: dpi:='12dpmm';
        600: dpi:='24dpmm';
      else
        dpi:='8dpmm';
      end;
      FmtSet := DefaultFormatSettings;
      FmtSet.DecimalSeparator := '.';
      Fmt:='http://api.labelary.com/v1/printers/%s/labels/%nx%n/0/';
      //URL:='http://api.labelary.com/v1/printers/8dpmm/labels/6x6/0/';
      URL:=Format(Fmt,[dpi,settings.width,settings.height],FmtSet);
      FPHTTPClient.Post(URL,PngData);
      PngData.Position := 0;
      if FPHTTPClient.ResponseStatusCode=200 then
      begin
        Image1.Picture.LoadFromStream(PngData);
        StatusBar1.Panels[0].Text:=DateTimeToStr(Now);
        if settings.save then SavePng;
        if settings.print then RePrint;
      end
      else begin
        if PngData.Size<100 then begin
          SetString(errormsg, PAnsiChar(PngData.Memory), PngData.Size);
          ShowMessage('Labelary Error:'+errormsg);
        end
        else
          ShowMessage('Labelary Error:'+FPHTTPClient.ResponseStatusText)
      end;
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

procedure TForm1.ReadJetData(Sender: TObject; DataStream: TSocketStream);
var len: LongInt;
    db:string;
begin
  //WriteLn('Accepting client: ', HostAddrToStr(NetToHost(Data.RemoteAddress.sin_addr)));
  zpldatalen:=0;
  repeat
    len := DataStream.Read( (zpldata+zpldatalen)^ , 1000000-zpldatalen);
    if len>0 then zpldatalen:=zpldatalen+len;
  until len<=0;
  SetString(db,PAnsiChar(zpldata),zpldatalen);
  DebugLn(DateTimeToStr(Now));
  DebugLn(db);
  DataStream.Free;
  if MSourceCode.Text='' then MSourceCode.Text:=db;
  if settings.saverawdata then SaveRaw(db);
  GetLabelaryData;
end;


procedure TForm1.LoadSettings;
var
  INI: TINIFile;
begin
  INI    := TINIFile.Create(inifile);
  with settings do begin
    resolution :=INI.ReadInteger('SETTINGS','resolution',203);
    rotation :=INI.ReadInteger('SETTINGS','rotation',0);
    width :=INI.ReadFloat('SETTINGS','width',4.0);
    height :=INI.ReadFloat('SETTINGS','height',3.0);
    save := INI.ReadBool('SETTINGS','save',false);
    savepath:= INI.ReadString('SETTINGS','savepath','');
    print := INI.ReadBool('SETTINGS','print',false);
    printraw := INI.ReadBool('SETTINGS','printraw',false);
    printer:=INI.ReadString('SETTINGS','printer','');
    executescript := INI.ReadBool('SETTINGS','executescript',false);
    saverawdata := INI.ReadBool('SETTINGS','saverawdata',false);
    scriptpath:=INI.ReadString('SETTINGS','scriptpath','');
    tcpport:=INI.ReadInteger('SETTINGS','tcpport',9100);    ;
    bindadr:=INI.ReadString('SETTINGS','bindadr','0.0.0.0');    ;
  end;
  INI.Free;
end;

procedure TForm1.SaveSettings;
var
  INI: TINIFile;
begin
  INI := TINIFile.Create(inifile);
  with settings do begin
    INI.WriteInteger('SETTINGS','resolution',resolution);
    INI.WriteInteger('SETTINGS','rotation',rotation);
    INI.WriteFloat('SETTINGS','width',width);
    INI.WriteFloat('SETTINGS','height',height);
    INI.WriteBool('SETTINGS','save',save);
    INI.WriteString('SETTINGS','savepath',savepath);
    INI.WriteBool('SETTINGS','print',print);
    INI.WriteBool('SETTINGS','printraw',printraw);
    INI.WriteString('SETTINGS','printer',printer);
    INI.WriteBool('SETTINGS','executescript',executescript);
    INI.WriteBool('SETTINGS','saverawdata',saverawdata);
    INI.WriteString('SETTINGS','scriptpath',scriptpath);
    INI.WriteInteger('SETTINGS','tcpport',tcpport);    ;
    INI.WriteString('SETTINGS','bindadr',bindadr);    ;
  end;
  INI.Free;
end;

procedure TForm1.ResetSettings;
begin
  with settings do begin
    resolution :=203;
    rotation := 0;
    width:=4.0;
    height:=3.0;
    save := false;
    savepath:='';
    print:=false;
    printraw:=false;
    printer:='';
    executescript:=false;
    saverawdata:=false;
    scriptpath:='';
    tcpport:=9100;
    bindadr:='0.0.0.0';
  end;
end;

end.

