unit zplview_settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,Printers;

type
  ZViewSettings = record
    resolution : integer;
    rotation : integer;
    width,height: real;
    save : boolean;
    savepath:string;
    print:boolean;
    printraw:boolean;
    printer:string;
    executescript:boolean;
    scriptpath:string;
    tcpport:integer;
    bindadr:string;
    saverawdata:boolean;
  end;

  { TFormSettings }

  TFormSettings = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    ChbSave: TCheckBox;
    ChbPrint: TCheckBox;
    ChbRaw: TCheckBox;
    ChbScript: TCheckBox;
    ChbSaveRaw: TCheckBox;
    ComPrinter: TComboBox;
    ComRes: TComboBox;
    ComRotate: TComboBox;
    EdtScript: TEdit;
    EdtPort: TEdit;
    EdtPath: TEdit;
    EdtHeight: TEdit;
    EdtBind: TEdit;
    EdtWidth: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormShow(Sender: TObject);
  private

  public
    procedure PutSettings(VAR setup:ZViewSettings);
    procedure GetSettings(VAR setup:ZViewSettings);
  end;

var
  FormSettings: TFormSettings;

implementation

{$R *.lfm}

{ TFormSettings }

procedure TFormSettings.FormShow(Sender: TObject);
begin
  ComPrinter.Items.Assign(Printer.Printers);
end;
procedure TFormSettings.PutSettings(VAR setup:ZViewSettings);
begin
  ComPrinter.Items.Assign(Printer.Printers);
  with setup do begin
    ComRes.Text:= IntToStr(resolution);
    ComRotate.Text:= IntToStr(rotation);
    EdtWidth.Text:=FloatToStr(width);
    EdtHeight.Text:=FloatToStr(height);
    ChbSave.Checked:= save;
    EdtPath.Text:=savepath;
    ChbPrint.Checked:=print;
    ChbRaw.Checked:=printraw;
    ComPrinter.ItemIndex:=ComPrinter.Items.IndexOf(printer);
    ChbScript.Checked:=executescript;
    ChbSaveRaw.Checked:=saverawdata;
    EdtScript.Text:=scriptpath;
    EdtPort.Text:=IntToStr(tcpport);
    EdtBind.Text:=bindadr;
  end;
end;

procedure TFormSettings.GetSettings(VAR setup:ZViewSettings);
begin
  with setup do begin
    resolution:=StrToInt(ComRes.Text);
    rotation:=StrToInt(ComRotate.Text);
    width:=StrToFloat(EdtWidth.Text);
    height:=StrToFloat(EdtHeight.Text);
    save:=ChbSave.Checked;
    savepath:=EdtPath.Text;
    print:=ChbPrint.Checked;
    printraw:=ChbRaw.Checked;
    printer:=ComPrinter.Text;
    executescript:=ChbScript.Checked;
    saverawdata:=ChbSaveRaw.Checked;
    scriptpath:=EdtScript.Text;
    tcpport:=StrToInt(EdtPort.Text);
    bindadr:=EdtBind.Text;
  end;

end;

end.

