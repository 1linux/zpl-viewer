unit zplview_settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type

  { TFormSettings }

  TFormSettings = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ComRes: TComboBox;
    ComRotate: TComboBox;
    EdtHeight: TEdit;
    EdtWidth: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
  private

  public

  end;

var
  FormSettings: TFormSettings;

implementation

{$R *.lfm}

end.

