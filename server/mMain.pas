unit mMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, mProtokoll, Menus, ParserStrList,
  Buttons, mPrintUtils, mGameLogic, mPlayer, mPlayerObserver, ScktComp, Winsock;

const
  INIT_AUTOSTART : integer = 10;
  INIT_AUTOCLOSE : integer = 5;

type
  TfmMain = class(TForm)
    Page: TPageControl;
    TTServer: TTabSheet;
    TTGameAdmin: TTabSheet;
    TTScore: TTabSheet;
    edServername: TLabeledEdit;
    edServerport: TLabeledEdit;
    cbScoreboardAvail: TCheckBox;
    lvClients: TListView;
    Label2: TLabel;
    Label3: TLabel;
    lvOverallscoreboard: TListView;
    btStartServer: TButton;
    btStopServer: TButton;
    TTLog: TTabSheet;
    Log: TMemo;
    pmClients: TPopupMenu;
    DisconnectClient1: TMenuItem;
    gbAnswerButtons: TGroupBox;
    btA: TBitBtn;
    btB: TBitBtn;
    btC: TBitBtn;
    btD: TBitBtn;
    gbCloseRound: TGroupBox;
    btCloseRound: TButton;
    gbNextRound: TGroupBox;
    btNextRound: TButton;
    cbAutoStart: TCheckBox;
    ttAutoStart: TTimer;
    lvAnswers: TListView;
    Label5: TLabel;
    pmAnswers: TPopupMenu;
    RevokeAnswer1: TMenuItem;
    lbRoundCount: TLabel;
    cbxGrantJoker: TComboBox;
    Label6: TLabel;
    btPrintScore: TBitBtn;
    printScore: TPrintDialog;
    GrantFlipchartright1: TMenuItem;
    ttAutoClose: TTimer;
    cbAutoClose: TCheckBox;
    ttChat: TTabSheet;
    meChat: TMemo;
    bitAuthorizeChatMessages: TBitBtn;
    bitDeclineChat: TBitBtn;
    Image1: TImage;
    TabSheet1: TTabSheet;
    Image2: TImage;
    Label4: TLabel;
    Memo1: TMemo;
    Label8: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    cbIPlist: TComboBox;
    Label1: TLabel;

    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btStopServerClick(Sender: TObject);
    procedure btStartServerClick(Sender: TObject);
    procedure btPrintScoreClick(Sender: TObject);
    procedure ttAutoStartTimer(Sender: TObject);
    procedure ttAutoCloseTimer(Sender: TObject);
    procedure DisconnectClient1Click(Sender: TObject);
    procedure GrantFlipchartright1Click(Sender: TObject);
    procedure btCloseRoundClick(Sender: TObject);
    procedure btAClick(Sender: TObject);
    procedure btBClick(Sender: TObject);
    procedure btCClick(Sender: TObject);
    procedure btDClick(Sender: TObject);
    procedure afterRoundCleanup;
    procedure lvOverallscoreboardCompare(Sender: TObject; Item1,
      Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure cbScoreboardAvailClick(Sender: TObject);
    procedure btNextRoundClick(Sender: TObject);
    procedure cbAutoCloseClick(Sender: TObject);
    procedure UpdateAnswerCount(Sender: TObject; Item: TListItem);
    procedure pmClientsPopup(Sender: TObject);
    procedure RevokeAnswer1Click(Sender: TObject);
    procedure lvAnswersCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvAnswersResize(Sender: TObject);
    procedure lvOverallscoreboardResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure meChatChange(Sender: TObject);
    procedure bitAuthorizeChatMessagesClick(Sender: TObject);
    procedure bitDeclineChatClick(Sender: TObject);

  private
    { Private-Deklarationen }
    colorAnswer : boolean;
    rightAnswer : Char;
    Countdown : integer;
    countdown2: integer;
  public
    { Public-Deklarationen }
    GameLogic : TGameLogic;

    procedure AutoStart;
    procedure AutoClose;

    procedure toggleServerRelated(Online : boolean);
    procedure newPlayer(Player : TPlayer);
    procedure deletePlayer(Player : TPlayer);
    procedure LocalIP;
    procedure addChatMessage(pMessage : string);
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.bitAuthorizeChatMessagesClick(Sender: TObject);
begin
  if Length(meChat.Lines.Text) > 0 then
    GameLogic.handleOutgoingChartMessages(meChat.Lines.CommaText);

  meChat.Clear;
end;

procedure TfmMain.bitDeclineChatClick(Sender: TObject);
begin
  meChat.Clear;
  GameLogic.denyChart;
end;

procedure TfmMain.meChatChange(Sender: TObject);
begin
  if Length(meChat.Lines.Text) > 0 then
    begin
      bitAuthorizeChatMessages.Enabled := true;
      bitDeclineChat.Enabled := true;
    end
  else
    begin
      bitAuthorizeChatMessages.Enabled := false;
      bitDeclineChat.Enabled := false;
    end;
end;

procedure TfmMain.UpdateAnswerCount(Sender: TObject; Item: TListItem);
begin
  try
    lvAnswers.Column[0].Caption := 'Player (' + IntToStr(lvAnswers.Items.Count)
    + ' / ' + IntToStr(GameLogic.Server.ClientList.Count) + ')';
  finally

  end;
end;

procedure TfmMain.cbAutoCloseClick(Sender: TObject);
begin
  if cbAutoClose.Checked AND GameLogic.checkAllAnswered then
    AutoClose;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  GameLogic     := TGameLogic.Create(self.Log);    //Create the GameLogic
                        //Gamelogic will be used to separat GUI and Logic

  self.DoubleBuffered := true;          //Doublebuffer form, minimzes flickers

  //Ensuring that when building the project the first tabbed page is the server page
  //this prevents having the last tabbed page different from the designer
  TTGameAdmin.TabVisible := false;    //initially hide this tab, will be activated by state function
  TTScore.TabVisible     := false;    //initially hide this tab, will be activated by state function
  TTChat.TabVisible := false;         //initially hide this tab, will be activated by state function
  Page.ActivePage := TTServer;

  self.Caption := self.Caption + MAJOR_RELEASE + '.' + PROTO_VER + '.'+ PROTO_REV;

  //resize Clientlist to ClientBounds
  lvClients.Columns.Items[0].MinWidth := lvClients.ClientWidth;
  lvClients.Columns.Items[0].MaxWidth := lvClients.ClientWidth;
  lvClients.Columns.Items[0].Width := lvClients.ClientWidth;

  colorAnswer := false;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  GameLogic.ServerStop;
  GameLogic.Destroy;
end;

procedure TfmMain.FormShow(Sender: TObject);
begin
  cbIPlist.Clear;
  self.LocalIP;
  cbIPlist.ItemIndex := cbIPlist.Items.Count-1;
end;

procedure TfmMain.GrantFlipchartright1Click(Sender: TObject);
begin
  if lvClients.SelCount = 1 then
    begin
      GameLogic.GrantFlipcharRight(TPlayer(lvClients.Selected.Data));  //lvClients.Data links a player
      MessageDlg('Granted Flipchartrights to '+ TPlayer(lvClients.Selected.Data).getName, mtInformation, [mbOk],0); //give a notice  
    end;
end;

procedure TfmMain.btCloseRoundClick(Sender: TObject);
begin
  GameLogic.CloseRound;
  btCloseRound.Enabled := false;
  gbAnswerButtons.Enabled := true;

  ttAutoClose.Enabled := false;
  btCloseRound.Caption := 'Close Round';
end;

procedure TfmMain.btNextRoundClick(Sender: TObject);
begin
  ttAutostart.Enabled := false;
  btNextRound.Caption := 'Next Round';
  gbAnswerButtons.Enabled := false;
  btCloseRound.Enabled := true;

  GameLogic.nextRoundStartUp;
  self.UpdateAnswerCount(Sender,nil);
  colorAnswer := false;
  rightAnswer := #0;
end;    

procedure TfmMain.btPrintScoreClick(Sender: TObject);
begin
  PrintListView(lvOverallScoreboard,printScore,edServerName.Text);
end;   

procedure TfmMain.btStartServerClick(Sender: TObject);
begin
  screen.Cursor := crHourGlass;
  GameLogic.ServerStart;
  screen.Cursor := crDefault;
end;    

procedure TfmMain.btStopServerClick(Sender: TObject);
begin
  screen.Cursor := crHourGlass;
  GameLogic.ServerStop;
  screen.Cursor := crDefault;
end;

procedure TfmMain.cbScoreboardAvailClick(Sender: TObject);
begin
  GameLogic.toggleScoreforClients;
end;

procedure TfmMain.DisconnectClient1Click(Sender: TObject);
begin
  if lvClients.SelCount = 1 then
    begin
      GameLogic.Server.KickPlayer(TPlayer(lvClients.Selected.Data));
      MessageDlg('Client was kicked!',mtInformation,[mbOk],0);
    end;
end;

procedure TfmMain.toggleServerRelated(Online: Boolean);
begin
  //toggle Buttons
  btStartServer.Enabled := not Online; //if server is online -> no Startbutton
  btStopServer.Enabled := Online;      //if server online -> StopButton
  edServerName.Enabled := not Online;  //if server online -> no Edit for servername

  TTGameAdmin.TabVisible := Online;    //Tabs are related to the server state
  TTScore.TabVisible := Online;
  TTChat.TabVisible := Online;

  if not Online then      //just to be sure the timers are offline
    begin
      ttAutostart.Enabled := false;
      ttAutoClose.Enabled := false;
      lvAnswers.Clear;
      Self.lvOverallscoreboard.Clear;
      colorAnswer := false;
      rightAnswer := #0;
    end;
end;

//function gets called by GameLogic after a round closed
procedure TfmMain.afterRoundCleanup;
begin
  if fmMain.cbAutoStart.Checked then
    fmMain.AutoStart;    //auto start next round if admin wants to

  if self.cbScoreboardAvail.Checked then
    GameLogic.UpdateScoreAtClients;   //if wanted update the player score

  lvOverallScoreBoard.AlphaSort;  //sort the scoreboard

  colorAnswer := true;
  lvAnswers.Repaint;
end;

{###############################################################################
    Answerbuttons
###############################################################################}

procedure TfmMain.btAClick(Sender: TObject);
begin
  rightAnswer := 'A';
  GameLogic.SendTheRightAnswer('A');
  gbAnswerButtons.Enabled := false;
end;

procedure TfmMain.btBClick(Sender: TObject);
begin
  rightAnswer := 'B';
  GameLogic.SendTheRightAnswer('B');
  gbAnswerButtons.Enabled := false;
end;

procedure TfmMain.btCClick(Sender: TObject);
begin
  rightAnswer := 'C';
  GameLogic.SendTheRightAnswer('C');
  gbAnswerButtons.Enabled := false;
end;

procedure TfmMain.btDClick(Sender: TObject);
begin
  rightAnswer := 'D';
  GameLogic.SendTheRightAnswer('D');
  gbAnswerButtons.Enabled := false;
end;

{###############################################################################
    Autostart and Stop
###############################################################################}

procedure TfmMain.AutoStart;
begin
  countdown := INIT_AUTOSTART;    //reset the counter
  ttAutoStart.Enabled := true;    //start the tTimer
end;

procedure TfmMain.AutoClose;
begin
  countdown2 := INIT_AUTOCLOSE;  //reset the counter
  ttAutoClose.Enabled := true;   //start the tTimer
end;

procedure TfmMain.ttAutoStartTimer(Sender: TObject);
begin
  //countdown zählen
  dec(countdown);

  //write countdown on Button
  btNextRound.Caption := 'Next Round ('+ IntToStr(countdown) + ')';

  //prüfen auf abbruch...
  if countdown = 0 then
    btNextRound.Click;      //nächsteRunde starten
end;

procedure TfmMain.ttAutoCloseTimer(Sender: TObject);
begin
  //countdown zählen
  dec(countdown2);

  //Beschriften
  btCloseRound.Caption := 'Close Round ('+ IntToStr(countdown2) + ')';

  //if autoclose was deselected after starting or someone revoked their answer
  if not cbAutoClose.Checked or not GameLogic.checkAllAnswered then
    begin
      ttAutoClose.Enabled := false;
      btCloseRound.Caption := 'Close Round';
    end;

  //prüfen auf abbruch...
  if countdown2 = 0  then
    btCloseRound.Click;           //nächsteRunde starten
end;

{###############################################################################
###############################################################################}

procedure TfmMain.lvAnswersCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if colorAnswer and (rightAnswer <> #0) then
    begin
      with Sender.Canvas do
        if (Item.SubItems.Strings[0][1] = rightAnswer) then
          begin
            Brush.Color := clGreen ;
            Font.Color := clWhite;
          end
        else
          begin
            Brush.Color := clRed;
            Font.Color := clWhite;
          end;
    end;
end;

procedure TfmMain.lvAnswersResize(Sender: TObject);
begin
  TListView(Sender).Column[0].MinWidth := TListView(Sender).ClientWidth - 50;
  TListView(Sender).Column[0].Width := TListView(Sender).ClientWidth - 50;
  TListView(Sender).Column[0].MaxWidth := TListView(Sender).ClientWidth - 50;
end;

procedure TfmMain.lvOverallscoreboardCompare(Sender: TObject; Item1,Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  if StrToInt(Item1.SubItems.Strings[0]) < StrToInt(Item2.SubItems.Strings[0]) then
    Compare :=  1
  else if StrToInt(Item1.SubItems.Strings[0]) > StrToInt(Item2.SubItems.Strings[0]) then
    Compare := -1
  else
    Compare :=  0;
end;

procedure TfmMain.lvOverallscoreboardResize(Sender: TObject);
begin
  TListView(Sender).Column[0].MinWidth := TListView(Sender).ClientWidth - 100;
  TListView(Sender).Column[0].Width := TListView(Sender).ClientWidth - 100;
  TListView(Sender).Column[0].MaxWidth := TListView(Sender).ClientWidth - 100;
end;

procedure TfmMain.newPlayer(Player : TPlayer);
  var
    tempItem : TListItem;
begin
  //Add Player to the client list
  tempItem := lvClients.Items.Add;
  tempItem.Caption := Player.getName;
  tempItem.Data := Pointer(Player);
  Player.addObserver(TClientListObserver.Create(Player,tempItem));

  //add a Answerlist Observer, this will create its own rows according to the answer state
  Player.addObserver(TAnswerListObserver.Create(Player,lvAnswers));

  //add Player to scoreboard
  tempItem := lvOverallscoreboard.Items.Add;
  tempItem.Caption := Player.getName;
  tempItem.SubItems.Add('0');
  tempItem.SubItems.Add('0');
  tempItem.Data := Pointer(Player);
  Player.addObserver(TScoreBoardObserver.Create(Player,tempItem));
end;

procedure TfmMain.deletePlayer(Player : TPlayer);
  var
    i: integer;
begin
  //remove Player from Clientlist
  for i := 0 to lvClients.Items.Count - 1 do
    if not (lvClients.Items.Item[i] = nil) then
      if TPlayer(lvClients.Items.Item[i].Data) = Player then
        lvClients.Items.Item[i].Delete;

  //remove from lvAnswers if necessary
  for i := 0 to lvAnswers.Items.Count - 1 do
    if not (lvAnswers.Items.Item[i] = nil) then
      if TPlayer(lvAnswers.Items.Item[i].Data) = Player then
        lvAnswers.Items.Delete(i);

  //remove from scoreboard
  for i := 0 to lvOverallscoreboard.Items.Count - 1 do
    if not (lvOverallscoreboard.Items.Item[i] = nil) then
      if TPlayer(lvOverallscoreboard.Items.Item[i].Data) = Player then
        lvOverallscoreboard.Items.Delete(i);
end;


procedure TfmMain.pmClientsPopup(Sender: TObject);
begin
  if lvCLients.SelCount = 1 then
    begin
      self.GrantFlipchartright1.Enabled := not GameLogic.isFlipchartActive();
    end
  else
    Abort;
end;

procedure TfmMain.RevokeAnswer1Click(Sender: TObject);
begin
  if lvAnswers.SelCount = 1 then
    begin
      if not GameLogic.isHeroInPlace then
        GameLogic.revokeAnswer(TPlayer(lvAnswers.Selected.Data))
      else
        MessageDlg('You can''t steal a heroes show!',mtError,[mbOk],0);
    end;
end;

procedure tfmMain.LocalIP;
type
   TaPInAddr = array [0..10] of PInAddr;
   PaPInAddr = ^TaPInAddr;
var
    phe: PHostEnt;
    pptr: PaPInAddr;
    Buffer: array [0..63] of char;
    i: Integer;
    GInitData: TWSADATA;
begin
    WSAStartup($101, GInitData);
    GetHostName(Buffer, SizeOf(Buffer));
    phe :=GetHostByName(buffer);
    if phe = nil then Exit;
    pptr := PaPInAddr(Phe^.h_addr_list);
    i := 0;
    while pptr^[i] <> nil do
    begin
      self.cbIPlist.Items.Add(StrPas(inet_ntoa(pptr^[i]^)));
      Inc(i);
    end;
    WSACleanup;
end;

procedure tfmMain.addChatMessage(pMessage : string);
begin
  meChat.Lines.Add(pMessage);
end;


end.
