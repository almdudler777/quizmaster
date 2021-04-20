unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,mProtokoll;

type
  TfmAnswerHelp = class(TForm)
    cbxAnswer: TComboBox;
    label2: TLabel;
    btHelp: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btHelpClick(Sender: TObject);
  private
    { Private-Deklarationen }
    named,answered : boolean;
    WhichOne : string;
  public
    { Public-Deklarationen }
    procedure PlayerName(Name : String);
  end;

var
  fmAnswerHelp: TfmAnswerHelp;

implementation

{$R *.dfm}
uses unit1;

procedure TfmAnswerHelp.btHelpClick(Sender: TObject);
begin
  if cbxAnswer.Items[cbxAnswer.ItemIndex] = 'I can''t help...' then
    fmClient.MySocket.Socket.SendText(Syntax[cmdHelpAnswer].Text+#13+WhichOne+#13+'?'+#13)
  else
    fmClient.MySocket.Socket.SendText(Syntax[cmdHelpAnswer].Text+#13+WhichOne+#13+cbxAnswer.Items[cbxAnswer.ItemIndex]+#13);

  answered := true;
end;

procedure TfmAnswerHelp.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  named := false;

  if not answered then
    fmClient.MySocket.Socket.SendText(Syntax[cmdHelpAnswer].Text+#13+WhichOne+#13+'?'+#13);
end;

procedure TfmAnswerHelp.FormCreate(Sender: TObject);
begin
  named := false;
  answered := false;
end;

procedure TfmAnswerHelp.FormShow(Sender: TObject);
begin
  cbxAnswer.ItemIndex := 0;
  if not named then
    begin
      raise Exception.Create('First fill in the name!');
    end;
  answered := false;
end;

procedure TfmAnswerHelp.PlayerName(Name: string);
begin
  named := true;
  btHelp.Caption := 'Help ' + Name;
  WhichOne := Name;
end;

end.
