unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, mProtokoll;

type
  TfmAskForm = class(TForm)
    cbxWhichOne: TComboBox;
    Label1: TLabel;
    btAskHim: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btAskHimClick(Sender: TObject);
  private
    { Private-Deklarationen }
    filled : boolean;
  public
    { Public-Deklarationen }
    procedure FillList(CommaText : String);
  end;

var
  fmAskForm: TfmAskForm;

implementation

{$R *.dfm}
uses unit1;

procedure TfmAskForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  cbxWhichOne.Clear;
  filled := false;
end;


procedure TfmAskForm.FormCreate(Sender: TObject);
begin
  filled := false;
end;

procedure TfmAskForm.FormShow(Sender: TObject);
begin
  cbxWhichOne.ItemIndex := 0;
  if not filled then
    begin
      raise Exception.Create('First fill the telephonebook!');
    end;
end;

procedure TfmAskForm.btAskHimClick(Sender: TObject);
begin
  fmClient.MySocket.Socket.SendText(Syntax[cmdAskForHelp].Text+#13+cbxWhichOne.Items[cbxWhichOne.ItemIndex]+#13);
  fmClient.StatusBar1.Panels[0].Text := 'Please wait for the other player to help you...';
end;

procedure TfmAskForm.FillList(CommaText: string);
begin
  cbxWhichOne.Items.CommaText := CommaText;
  filled := true;
  cbxWhichOne.ItemIndex := 0;
end;

end.
