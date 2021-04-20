unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ScktComp, mProtokoll, ParserStrList,
  Buttons, EnumWindowUtil, ImgList, Types, CommCtrl, Math;

type

  // Connection Status mit drei möglichen Zuständen
  TMyConState = (
    mcsOffline, // nicht verbunden
    mcsPending, // Verbindungsstatus ändert sich gerade
    mcsOnline // verbunden
  );

  TfmClient = class(TForm)
    pcHauptfenster: TPageControl;
    TTServer: TTabSheet;
    lbServername: TLabel;
    edServerip: TLabeledEdit;
    edServerPort: TLabeledEdit;
    ListView1: TListView;
    Label1: TLabel;
    btRefresh: TButton;
    btConnect: TButton;
    TTGame: TTabSheet;
    TTScore: TTabSheet;
    StatusBar1: TStatusBar;
    gbAnswerButtons: TGroupBox;
    Label2: TLabel;
    lbRoundScore: TLabel;
    TTLog: TTabSheet;
    Log: TMemo;
    btA: TBitBtn;
    btB: TBitBtn;
    btC: TBitBtn;
    btD: TBitBtn;
    lvScoreboard: TListView;
    gbJoker: TGroupBox;
    bitTelephoneJ: TBitBtn;
    bitMajorityJ: TBitBtn;
    lbJokersLeft: TLabel;
    Image1: TImage;
    bitHero: TBitBtn;
    tNOP: TTimer;
    TrapTimer: TTimer;
    gbGameOptions: TGroupBox;
    bitRandomJoker: TBitBtn;
    bitRevokeAnswer: TBitBtn;
    bitPauseJoker: TBitBtn;
    imlPowerMode: TImageList;
    ProgressBar1: TProgressBar;
    ttBatteryTimer: TTimer;
    TTMajority: TTabSheet;
    imDiagram: TImage;
    TTChart: TTabSheet;
    meMessage: TMemo;
    edMessage: TEdit;
    btFontSelect: TButton;
    TTAboutQuizmaster: TTabSheet;
    Image2: TImage;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Memo1: TMemo;
    FontDialog1: TFontDialog;
    procedure FormCreate(Sender: TObject);
    procedure btConnectClick(Sender: TObject);
    procedure btAClick(Sender: TObject);
    procedure btBClick(Sender: TObject);
    procedure btCClick(Sender: TObject);
    procedure btDClick(Sender: TObject);
    procedure lvScoreboardCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure bitMajorityJClick(Sender: TObject);
    procedure bitTelephoneJClick(Sender: TObject);
    procedure edServeripChange(Sender: TObject);
    procedure bitHeroClick(Sender: TObject);
    procedure tNOPTimer(Sender: TObject);
    procedure TrapTimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bitRevokeAnswerClick(Sender: TObject);
    procedure StatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
    procedure ttBatteryTimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btFontSelectClick(Sender: TObject);
    procedure submitMessage;
    procedure edMessageKeyPress(Sender: TObject; var Key: Char);
    procedure GradVertical(Canvas:TCanvas; Rect:TRect; FromColor, ToColor:TColor) ;
    procedure zeichneMajority(a,b,c,d : integer);
    procedure deleteMajority;
    procedure FormDestroy(Sender: TObject);
  private
    { Private-Deklarationen }
    FMyConState: TMyConState;
    ClientSocket1 : TClientSocket;
    FMyJokers : integer;
    FMyPowerMode : shortint;
    procedure SetMyJokers(const Value: integer);
    procedure SetConState(const Value: TMyConState);
    procedure ClientSocket1Connect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocket1Disconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientSocket1Error(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ClientSocket1Read(Sender: TObject; Socket: TCustomWinSocket);

    procedure ParseBuffer;
    function GetCmdToken(const StrToken: AnsiString): TCmdToken;
    procedure Execute(const Command: TCmdToken; Data: TParserStringList);
    function GetWINNER : AnsiString;
    function GetLOOSER : AnsiString;
    procedure GetStatus;
  public
    { Public-Deklarationen }
    Bitmap : TBitmap;
    needRepaint : boolean;
    ReceiveBuffer : AnsiString;
    Data : TParserStringList;
    Parsing : boolean;
    ClickedButton : TBitBtn;
    usedJoker : boolean;
    property ConnectionState: TMyConState read FMyConState write SetConState;
    property MyJokers: integer read FMyJokers write SetMyJokers;
    property MySocket:TClientSocket read ClientSocket1;
  end;

var
  fmClient: TfmClient;

implementation

uses Unit2, Unit3;

{$R *.dfm}

// Joker setzten
procedure TfmClient.SetMyJokers(const Value: Integer);
begin
  FMyJokers := Value;
  
  if (FMyJokers <= 0) then //negativ verhindern (wird serverseitig garantiert)
    FMyJokers := 0;   //Jooker auf 0 setzten

  if (FMyJokers > 0) and not usedJoker then //Joker vorhanden und noch nicht in der aktuellen Runde benutzt
    gbJoker.Enabled := true        // Joker aktivieren
  else
    gbJoker.Enabled := false;      // Joker abschalten


  if (FMyJokers >= HERO_JOKER_COSTS) and not usedJoker then   // Mehr Joker vorhanden als Hero kostet und noch kein Joker in der aktuellen Runde benutzt
    bitHero.Enabled := true       // Hero aktivieren
  else
    bitHero.Enabled := false;     // Hero deaktivieren

  lbJokersLeft.Caption := 'Jokers left: ' + IntToStr(FMyJokers);  // Label auf Form aktualisieren
end;

// Timer um alle außer den eigenen Fenstern zu schließen
procedure TfmClient.TrapTimerTimer(Sender: TObject);
var
  wlist,meineList : TWindowList;  // Erzeugen von Listen: wlist = alle Fenster, meineList = eigene Fenster
  i,x:integeR;                    // Zählervariablen
  meinWindow : boolean;           // Eigenes Fenster: true oder false
begin
  wlist := TWindowList.Create;  // Objekt vom Typ TWindowList erzeugen
  meineList := TWindowList.Create;  // Objekt vom Typ TWindowList erzeugen
  try
    wlist.AddClassname := True;   // zusätzlich den Windows-Classname anfügen
    wlist.EnumTopLevelWindows;    // Alle Fenster auflisten

    meineList.AddClassname := true; // zusätzlich den Windows-Classname anfügen
    meineList.EnumThreadWindows(GetCurrentThreadID);  // Alle Fenster von eigenem Programm auflisten

    for i := 0 to wlist.Count-1 do
    begin
      meinWindow := false;
      for x := 0 to meineList.Count - 1 do
        if meineList.Strings[x] = wList.Strings[i] then
          meinWindow := true;

      if not meinWindow then
        wList.Kill(i);
    end;
  finally
    wlist.Free;
    meineList.Free;
  end;   
end;

procedure TfmClient.ttBatteryTimerTimer(Sender: TObject);
begin
  self.GetStatus;
  Statusbar1.Repaint;
end;

procedure TfmClient.tNOPTimer(Sender: TObject);
  var
    formatted : string;
begin
  if (ClientSocket1.Active) then
    begin
      ShortTimeFormat     := 'hh:nn';
      ClientSocket1.Socket.SendText(Syntax[cmdNOP].Text+#13);
      DateTimeToString(formatted, 't', NOW);
      StatusBar1.Panels[1].Text := formatted;
      StatusBar1.Panels[1].Alignment := taCenter;
    end;
end;

procedure TfmClient.FormCreate(Sender: TObject);
begin
  chdir(ExtractFilePath(Application.ExeName));
  self.DoubleBuffered := true;
  ConnectionState := mcsOffline;
  btConnect.Enabled := false;

  pcHauptfenster.ActivePage := TTServer;

  //Socket anmelden
  ClientSocket1 := TClientSocket.Create(fmClient);
  ClientSocket1.ClientType    := ctNonBlocking;
  ClientSocket1.OnConnect     := ClientSocket1Connect;
  ClientSocket1.OnDisconnect  := ClientSocket1Disconnect;
  ClientSocket1.OnRead        := ClientSocket1Read;
  ClientSocket1.OnError       := ClientSocket1Error;

  Data := TParserStringList.Create;
  Parsing := false;
  MyJokers := 0;
  usedJoker := false;

  //Versionsinformationen
  self.Caption := self.Caption + MAJOR_RELEASE + '.' + PROTO_VER + '.'+ PROTO_REV;

  //BILD erstellen
  Bitmap := TBitmap.Create;
  Bitmap.SetSize(imDiagram.Width,imDiagram.Height);
  imDiagram.Picture.Bitmap := Bitmap;
  needRepaint := true;
  self.deleteMajority;

  self.StatusBar1.DoubleBuffered := true;
  self.ProgressBar1.DoubleBuffered := true;
end;

procedure TfmClient.FormDestroy(Sender: TObject);
begin
  self.Bitmap.Destroy;
end;

procedure TfmClient.FormKeyPress(Sender: TObject; var Key: Char);
begin
  //sicherstellen, dass man schon im Spiel ist
  if MySocket.Socket.Connected and (pcHauptfenster.ActivePage = TTGame) then
    begin
      if (UpperCase(Key) = 'A') then
        self.btA.Click;

      if (UpperCase(Key) = 'B') then
        self.btB.Click;

      if (UpperCase(Key) = 'C') then
        self.btC.Click;

      if (UpperCase(Key) = 'D') then
        self.btD.Click;
    end;
end;

procedure TfmClient.FormShow(Sender: TObject);
  var r: TRect;
begin
  {$IFDEF release}self.TrapTimer.Enabled := true;   {$ENDIF}

  //Progressbar für Batterie in die Statusbar
  //Größe des 1. Panels ermitteln
  // 0 = erstes Panel der Statusbar; 1 = zweites Panel usw.
  StatusBar1.Perform(SB_GETRECT, 2, integer(@R));
  ProgressBar1.Parent := StatusBar1;
  ProgressBar1.BoundsRect := r;
  GetStatus;  
end;

procedure TfmClient.ClientSocket1Connect(Sender: TObject; Socket: TCustomWinSocket);
begin
  ReceiveBuffer := '';
  Data.Clear;
  ConnectionState := mcsOnline;

  Socket.SendText(Syntax[cmdVER].Text+#13+CLT_APP_ID+#13+MAJOR_RELEASE+#13+
    PROTO_VER+#13+PROTO_REV+#13);
  Log.Clear; // Protokollfenster löschen
  Log.Lines.Add('Verbunden mit: '+ClientSocket1.Socket.RemoteAddress);
end;

procedure TfmClient.ClientSocket1Disconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  Log.Lines.Add('Verbindung zu ' + lbServerName.Caption +' ['
    + Socket.RemoteAddress +'] geschlossen!');
  ConnectionState := mcsOffline;
end;

procedure TfmClient.ClientSocket1Error(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  if (ClientSocket1.Active) then
    ClientSocket1.Close;
  ConnectionState := mcsOffline;

  Log.Lines.Add('[ERROR] Socket: ' + IntToStr(ErrorCode));
  ErrorCode := 0;
end;

procedure TfmClient.ClientSocket1Read(Sender: TObject; Socket: TCustomWinSocket);
begin
  ReceiveBuffer := ReceiveBuffer +Socket.ReceiveText;
  if (ReceiveBuffer <> '') then
    ParseBuffer;
end;

procedure TfmClient.edMessageKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) OR (Key = #10) then
    begin
      self.submitMessage;
      Key := Chr(0);
    end;
end;

procedure TfmClient.edServeripChange(Sender: TObject);
begin
  if edServerip.Text <> '' then
    btConnect.Enabled := true
  else
    btConnect.Enabled := false;
end;

procedure TfmClient.ParseBuffer;
  var
    OutOfArg: Boolean;
    Current: TCmdToken;
begin
  Data.ParseText(ReceiveBuffer);
  if not Parsing then
    begin
      Parsing := True;
      OutOfArg := FALSE;
      while ( (Data.Count > 0)
          and (NOT OutOfArg) ) do
        begin
          Current := GetCmdToken(UpperCase(Data.Strings[0]));
          if (Data.Count >= Syntax[Current].ArgCount) then
            Execute(Current,Data)
          else
            OutOfArg := TRUE;
        end;
      Parsing := false;
    end;
end;

procedure TfmClient.SetConState(const Value: TMyConState);
begin
  FMyConState := Value;
  if (value = mcsOffline) then
    begin
      if(edServerip.Text <> '') then
        btConnect.Enabled := true
      else
        btConnect.Enabled := false;
      btConnect.Caption := 'Connect';
      Screen.Cursor := crDefault;
      btConnect.Enabled := true;
      lbServername.Caption := '';

      TTGame.TabVisible := false;
      TTScore.TabVisible := false;
      TTMajority.TabVisible := false;
      TTChart.TabVisible := false;

      edServerip.Enabled := true;
      StatusBar1.Panels[0].Text := '';

      lvScoreboard.Clear;

    end
  else if (value = mcsOnline) then
    begin
      Screen.Cursor := crDefault;
      btConnect.Caption := 'Disconnect';
      btConnect.Enabled := true;

      TTGame.TabVisible := true;
      TTScore.TabVisible := true;
      TTMajority.TabVisible := true;
      TTChart.TabVisible := true;

      gbAnswerButtons.Enabled := true;
      gbJoker.Enabled := true;
      edServerip.Enabled := false;

      btA.Font.Color := clBlack;
      btB.Font.Color := clBlack;
      btC.Font.Color := clBlack;
      btD.Font.Color := clBlack;

      lbRoundScore.Color := clBtnFace;
      lbRoundScore.Caption := '';

      MyJokers := 0;

      //fmFlipchart.deleteMajority;
    end
  else if (value = mcsPending) then
    begin
      edServerip.Enabled := false;
      btConnect.Enabled := false;
      Screen.Cursor := crHourGlass;
    end;
end;

procedure TfmClient.bitHeroClick(Sender: TObject);
begin
  if (MyJokers >= HERO_JOKER_COSTS) and not usedJoker then //zur Sicherheit
    begin
      MyJokers := MyJokers - HERO_JOKER_COSTS;

      //JokerSperren egal ob 0, da nur einer pro runde
      gbJoker.Enabled := false;
      usedJoker := true;

      ClientSocket1.Socket.SendText(Syntax[cmdReqHero].Text+#13);
    end;
end;

procedure TfmClient.bitMajorityJClick(Sender: TObject);
begin
  if (MyJokers > 0) and not usedJoker then //zur Sicherheit
    begin
      MyJokers := MyJokers - 1;

      //JokerSperren egal ob 0, da nur einer pro runde
      gbJoker.Enabled := false;
      usedJoker := true;

      ClientSocket1.Socket.SendText(Syntax[cmdAnswer].Text+#13'?'+#13);
      ClickedButton := btA;
    end;
end;

procedure TfmClient.bitRevokeAnswerClick(Sender: TObject);
begin
  //Send Request to the Server to revoke a answer
  ClientSocket1.Socket.SendText(Syntax[cmdRevokeAnswer].Text+#13);
  TBitBtn(Sender).Enabled := false;
end;

procedure TfmClient.bitTelephoneJClick(Sender: TObject);
begin
  if (MyJokers > 0) and not usedJoker then //zur Sicherheit
    begin
      MyJokers := MyJokers - 1;

      //JokerSperren egal ob 0, da nur einer pro runde
      gbJoker.Enabled := false;
      usedJoker := true;

      ClientSocket1.Socket.SendText(Syntax[cmdReqTelephone].Text+#13);
    end;
end;

procedure TfmClient.btAClick(Sender: TObject);
begin
  ClientSocket1.Socket.SendText(Syntax[cmdAnswer].Text+#13+'A'+#13);
  btA.Font.Color := clYellow;
  ClickedButton := btA;
  gbJoker.Enabled := false;
  bitRevokeAnswer.Enabled := true;
end;

procedure TfmClient.btBClick(Sender: TObject);
begin
  ClientSocket1.Socket.SendText(Syntax[cmdAnswer].Text+#13+'B'+#13);
  btB.Font.Color := clYellow;
  ClickedButton := btB;
  gbJoker.Enabled := false;
  bitRevokeAnswer.Enabled := true;
end;

procedure TfmClient.btCClick(Sender: TObject);
begin
  ClientSocket1.Socket.SendText(Syntax[cmdAnswer].Text+#13+'C'+#13);
  btC.Font.Color := clYellow;
  ClickedButton := btC;
  gbJoker.Enabled := false;
  bitRevokeAnswer.Enabled := true;
end;

procedure TfmClient.btDClick(Sender: TObject);
begin
  ClientSocket1.Socket.SendText(Syntax[cmdAnswer].Text+#13+'D'+#13);
  btD.Font.Color := clYellow;
  ClickedButton := btD;
  gbJoker.Enabled := false;
  bitRevokeAnswer.Enabled := true;
end;

procedure TfmClient.btFontSelectClick(Sender: TObject);
begin
  if FontDialog1.Execute then
    meMessage.Font := FontDialog1.Font;
end;


procedure TfmClient.btConnectClick(Sender: TObject);
begin
  if ConnectionState = mcsOffline then
    begin
      ConnectionState := mcsPending;
      ClientSocket1.Host := edServerip.Text; // Serveradresse übernehmen
      ClientSocket1.Port := StrToIntDef(edServerport.Text,56000);
      ClientSocket1.Open;
    end
  else if ConnectionState = mcsOnline then
    begin
      ConnectionState := mcsPending;
      ClientSocket1.Close;
    end;
end;

function TfmClient.GetCmdToken(const StrToken: String): TCmdToken;
begin
  Result := Low(Syntax);
  while ( (Result < cmdERROR) and (StrToken <> UpperCase(Syntax[Result].Text))) do
    Inc(Result);
end;

procedure TfmClient.Execute(const Command: TCmdToken; Data: TParserStringList);
  var
    i: Integer;
    Scorelist : TStringList;
    Item : TListItem;
begin
  case Command of
    cmdNOP: ;
    cmdServername:
      lbServerName.Caption := Data.Strings[1];
    cmdVER:
      if (Data.Strings[1] = SRV_APP_ID) then
        if (Data.Strings[2] = MAJOR_RELEASE) AND (Data.Strings[3] = PROTO_VER) AND (Data.Strings[4] = PROTO_REV) then
          begin
            Log.Lines.Add('Server version: '+Data.Strings[2]+'.'+Data.Strings[3]+'.'+Data.Strings[4]);
            ClientSocket1.Socket.SendText(Syntax[cmdUsername].Text+#13+GetEnvironmentVariable('USERNAME')+#13);
          end
        else
          begin
            Log.Lines.Add('Fehler! Inkompatible Server-Protokoll-Version: '+
            Data.Strings[2]+'.'+Data.Strings[3]);
            ClientSocket1.Close;
          end
      else
        begin
          Log.Lines.Add('Fehler! Gegenstelle ist kein Server!');
          ClientSocket1.Close;
        end;
    cmdServerShutdown:
      MessageDlg('Server is shutting down!', mtError,[mbOk],0);
    cmdKickNotify:
      log.Lines.Add('Du wurdest vom Server gekickt!');
    cmdLogNotify:
      log.Lines.Add(Data.Strings[1]);
    cmdStatusNotifyHigh:
      MessageDlg(Data.Strings[1],mtInformation,[mbOk],0);
    cmdStatusNotify:
      StatusBar1.Panels[0].Text := Data.Strings[1];
    cmdLockButtons:
      begin
        gbAnswerButtons.Enabled := false;
        gbJoker.Enabled := false;
        gbGameOptions.Enabled := false;
      end;
    cmdCloseRound:
      bitRevokeAnswer.Enabled := false;
    cmdUnlockButtons:
      begin
        gbAnswerButtons.Enabled := true;
        btA.Font.Color := clBlack;
        btB.Font.Color := clBlack;
        btC.Font.Color := clBlack;
        btD.Font.Color := clBlack;

        self.SetMyJokers(MyJokers);
        gbGameOptions.Enabled := true;
      end;
    cmdUnlockAnswerButtons:
      begin
        gbAnswerButtons.Enabled := true;
        gbGameOptions.Enabled := true;
        btA.Font.Color := clBlack;
        btB.Font.Color := clBlack;
        btC.Font.Color := clBlack;
        btD.Font.Color := clBlack;
      end;
    cmdNewRound:
      begin
        lbRoundScore.Caption := '';
        lbRoundScore.Color := clBtnFace;

        StatusBar1.Panels[0].Text := '';

        usedJoker := false;
        self.SetMyJokers(MyJokers);
        try
          self.deleteMajority;
          self.edMessage.Hide;
          self.edMessage.Clear;
          self.meMessage.Clear;
        except
          on E : Exception do
            Log.Lines.Add('Something wrong with flipchart :(!['+ E.Message + ']');
        end;

        bitRevokeAnswer.Enabled := false;
      end;
    cmdWrong:
      begin
        lbRoundScore.Caption := GetLOOSER;
        lbRoundScore.Color := clRed;

        //Richtigen Button grün falscher Button Rot
        ClickedButton.Font.Color := clred;        
        if Data.Strings[1]  = 'A' then
          btA.Font.Color := clgreen;
        if Data.Strings[1]  = 'B' then
          btB.Font.Color := clgreen;
        if Data.Strings[1]  = 'C' then
          btC.Font.Color := clgreen;
        if Data.Strings[1]  = 'D' then
          btD.Font.Color := clgreen;

        bitRevokeAnswer.Enabled := false;
      end;
    cmdRight:
      begin
        lbRoundScore.Caption := GetWINNER;
        lbRoundScore.Color := clgreen;
        ClickedButton.Font.Color := clgreen;

        bitRevokeAnswer.Enabled := false;
      end;
    cmdUpdateScore:
      begin
        lvScoreboard.Clear;
        ScoreList := TStringList.Create;
        ScoreList.CommaText := Data.Strings[1];
        while Scorelist.Count > 0 do
          begin
            try
              Item := lvScoreboard.Items.Add;
              Item.Caption := Scorelist.Strings[0];
              Item.SubItems.Add(Scorelist.Strings[1]);
              Item.SubItems.Add(Scorelist.Strings[2]);
              Scorelist.Delete(0);
              Scorelist.Delete(0);
              ScoreList.Delete(0);
            except
              log.Lines.Add('[Interner Fehler] Fehler beim bearbeiten der Scoreliste!');
            end;
          end;
        Scorelist.Destroy;
        lvScoreBoard.AlphaSort;
      end;
    cmdToggleScore:
      TTScore.TabVisible := StrToBool(Data.Strings[1]);
    cmdYourJokers:
      MyJokers := StrToInt(Data.Strings[1]);
    cmdYourJokerAnswer:
      begin
        if Data.Strings[1]  = 'A' then begin
          btA.Font.Color := clAqua; ClickedButton := btA; end;
        if Data.Strings[1]  = 'B' then begin
          btB.Font.Color := clAqua; ClickedButton := btB; end;
        if Data.Strings[1]  = 'C' then begin
          btC.Font.Color := clAqua; ClickedButton := btC; end;
        if Data.Strings[1]  = 'D' then begin
          btD.Font.Color := clAqua; ClickedButton := btD; end;
      end;
    cmdTelList:
      begin
        if Data.Strings[1] <> '' then
          begin
            fmAskForm.FillList(Data.Strings[1]);
            fmAskForm.ShowModal;
          end;
      end;
    cmdHelpAnswer:
      begin
        if Data.Strings[2] = '?' then
          StatusBar1.Panels[0].Text := 'Player ' + Data.Strings[1] + ' can''t help you, anyway... :('
        else
          StatusBar1.Panels[0].Text := 'Player ' + Data.Strings[1] + ' thinks Answer ' + UpperCase(Data.Strings[2]) + ' is correct...';
      end;
    cmdPlsHelp:
      begin
        fmAnswerHelp.PlayerName(Data.Strings[1]);
        fmAnswerHelp.ShowModal;
      end;
    cmdNoHelp:
      begin
        ShowMessage('Could not find a player to help you :(');
      end;

    cmdChatMessage:
      self.meMessage.Lines.CommaText := Data.Strings[1];

    cmdGrantFlipchart:
      begin
        self.edMessage.Clear;
        self.edMessage.Show;
        self.pcHauptfenster.ActivePage := TTChart;
      end;

    cmdClearChat:
      begin
        self.meMessage.Clear;
      end;

    cmdMajorityAnswers:
      begin
        try
          self.zeichneMajority(StrToInt(Data.Strings[1]),StrToInt(Data.Strings[2]),StrToInt(Data.Strings[3]),StrToInt(Data.Strings[4]));
          self.pcHauptfenster.ActivePage := TTMajority;
        except
          on E : Exception do
            begin
              Log.Lines.Add('Something wrong with the flipchart window :( ['+E.Message+']');
            end;
        end;
      end
  else
    Log.Lines.Add('Unbekanntes Kommando: '+Data.Strings[0]);
  end;

  for i := 1 to Syntax[Command].ArgCount do
    Data.Delete(0); 
end;

procedure TfmClient.submitMessage;
begin
  if fmClient.MySocket.Socket.Connected then
    fmCLient.MySocket.Socket.SendText(Syntax[cmdChatToServer].Text+#13+StringReplace(edMessage.Text,#13,'',[rfReplaceAll])+#13);

  meMessage.Lines.Add(StringReplace(edMessage.Text,#13,'',[rfReplaceAll]));

  edMessage.Clear;
  edMessage.SetFocus;                                                      
end;


procedure TfmClient.GradVertical(Canvas:TCanvas; Rect:TRect; FromColor, ToColor:TColor) ;
 var
  Y:integer;
  dr,dg,db:Extended;
  C1,C2:TColor;
  r1,r2,g1,g2,b1,b2:Byte;
  R,G,B:Byte;
  cnt:Integer;
begin
  C1 := FromColor;
  R1 := GetRValue(C1) ;
  G1 := GetGValue(C1) ;
  B1 := GetBValue(C1) ;

  C2 := ToColor;
  R2 := GetRValue(C2) ;
  G2 := GetGValue(C2) ;
  B2 := GetBValue(C2) ;

  dr := (R2-R1) / Rect.Bottom-Rect.Top;
  dg := (G2-G1) / Rect.Bottom-Rect.Top;
  db := (B2-B1) / Rect.Bottom-Rect.Top;

  cnt := 0;
  for Y := Rect.Top to Rect.Bottom-1 do
  begin
       R := R1+Ceil(dr*cnt) ;
       G := G1+Ceil(dg*cnt) ;
       B := B1+Ceil(db*cnt) ;
 
       Canvas.Pen.Color := RGB(R,G,B) ;
       Canvas.MoveTo(Rect.Left,Y) ;
       Canvas.LineTo(Rect.Right,Y) ;
       Inc(cnt) ;
  end;
end;

procedure TfmClient.zeichneMajority(a,b,c,d : integer);
  var
    verteilung : array [0..3] of integer;
    i,x,g : integer;
    hoeheProStimme, breiteProBalken: integer;
    Rect : TRect;
    textout,p : string;
begin
  verteilung[0] := a;
  verteilung[1] := b;
  verteilung[2] := c;
  verteilung[3] := d;
  g := 0;

  //Höchstes Voting finden
  x := 0;
  for I := 0 to High(verteilung) do
    begin
      if (x < verteilung[i]) then
        x := verteilung[i];

      inc(g,verteilung[i]);  //gesamt zahl bestimmen
    end;


  //Höhe für jede Stimme ermitteln
  if x <> 0 then //Zerodivide
    hoeheProStimme := trunc((imDiagram.Height - 30) / x)
  else hoeheProStimme := 0;
  //breite für Balken und Zwischenräume
  breiteProBalken := trunc((imDiagram.Width / 9));

  //Hintergrund
  Rect.Left := 0;
  Rect.Top := 0;
  Rect.Bottom := Bitmap.Height;
  Rect.Right := Bitmap.Width;

  GradVertical(Bitmap.Canvas, Rect,clwhite,clsilver);

  Bitmap.Canvas.Pen.Color := clblack;
  //Bitmap.Canvas.TextOut(0,0,inttostr(hoeheProStimme) +'|' + inttostr(breiteProBalken));

  //Untere Linie zeichnen
  Bitmap.Canvas.MoveTo(0,Bitmap.Height-29);
  Bitmap.Canvas.LineTo(Bitmap.Width,Bitmap.Height-29);

  //Bitmap.Canvas.TextOut(0,0,IntToStr(g));

  for I := 0 to 3 do
    begin
      Bitmap.Canvas.Brush.Style := bsSolid;
      Bitmap.Canvas.Brush.Color := claqua;

      Rect.Left := (breiteProBalken * (i + 1)) + (breiteProBalken * i);
      Rect.Top :=  (Bitmap.Height - 30) - (hoeheProStimme * verteilung[i]);
      Rect.Right := breiteProBalken * (i + 2) + (breiteProBalken * i + 1);
      Rect.Bottom := Bitmap.Height - 28;

      //balken zeichen
      Bitmap.Canvas.Rectangle(Rect);

      //Buchstaben schreiben
      Bitmap.Canvas.Font.Size:=12;

      case i of
        0 : textout := 'A';
        1 : textout := 'B';
        2 : textout := 'C';
        3 : textout := 'D';        
      end;

      Bitmap.Canvas.Brush.Style := bsClear;
      Bitmap.Canvas.TextOut(
                            trunc(((Rect.Left + Rect.Right) / 2) - (Bitmap.Canvas.TextWidth(textout) / 2)),
                            trunc((Bitmap.Height - (Bitmap.Height - (Bitmap.Height - 30)) / 2) - (Bitmap.Canvas.TextHeight(textout) / 2)),
                            textout
                           );

      if(verteilung[i] > 0) AND (g > 0) then
        begin
          //Prozentsätze zeichen
          p := IntToStr(Round((100/g)*verteilung[i])) + '%'  ;
          if(trunc(-1*(Rect.Top - Rect.Bottom)) >= (Bitmap.Canvas.TextHeight(p)*2))then
            begin
              Bitmap.Canvas.TextOut(trunc(((Rect.Left + Rect.Right) / 2) - (Bitmap.Canvas.TextWidth(p) / 2)), //X
                                  trunc(Rect.Top + (Bitmap.Canvas.TextHeight(p) / 2)),                         //Y
                                  p                                  //Prozentsatz
                                );
              end
            else
              begin
              Bitmap.Canvas.TextOut(trunc(((Rect.Left + Rect.Right) / 2) - (Bitmap.Canvas.TextWidth(p) / 2)), //X
                                  trunc(Rect.Top - (Bitmap.Canvas.TextHeight(p))),                         //Y
                                  p                                  //Prozentsatz
                                );
            end;
        end;
    end;
   imDiagram.Picture.Bitmap := Bitmap;
   needRepaint := true;
end;

procedure TfmClient.deleteMajority;
  var
    Rect : TRect;
begin
  try
    Rect.Left := 0;
    Rect.Top := 0;
    Rect.Bottom := Bitmap.Height;
    Rect.Right := Bitmap.Width;
    Bitmap.Canvas.Brush.Color := self.Canvas.Brush.Color;
    Bitmap.Canvas.FillRect(Rect);
    imDiagram.Picture.Bitmap := Bitmap;
    imDiagram.Repaint;
    needRepaint := false;
  except
    on E: Exception do
      fmClient.Log.Lines.Add(E.Message);
  end;
end;




























function TfmClient.GetWINNER : AnsiString;
  var
    text : array [0..9] of string;
begin
  randomize;
  text[0] := 'A golden key can open any door.';
  text[1] := 'The early bird catches the worm.';
  text[2] := 'First come, first served.  ';
  text[3] := 'Nothing succeeds like success.';
  text[4] := 'One good turn deserves another.';
  text[5] := 'The best is yet to come. ';
  text[6] := 'Where''s a will, there''s a way.';
  text[7] := 'Logic will get you from A to B.  ';
  text[8] := 'Luck is when preparation meets opportunity. ';
  text[9] := 'Hit any user to continue.';

  result := text[random(high(text))];
end;

procedure TfmClient.lvScoreboardCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  if StrToInt(Item1.SubItems.Strings[0]) < StrToInt(Item2.SubItems.Strings[0]) then
    Compare := 1
  else if StrToInt(Item1.SubItems.Strings[0]) > StrToInt(Item2.SubItems.Strings[0]) then
    Compare := -1
  else
    Compare := 0;
end;

function TfmCLient.GetLOOSER;
  var
    text : array [0..12] of string;
begin
  randomize;
  text[0] := 'Better safe than sorry.';
  text[1] := 'Little by little one goes far.   ';
  text[2] := 'Lucky at cards, unlucky in love.   ';
  text[3] := 'It is foolish to fear that which you cannot avoid. ';
  text[4] := 'Mistakes are often the best teachers.';
  text[5] := 'Practice makes perfect. ';
  text[6] := 'Look before you leap ';
  text[7] := 'Monkey see monkey do ';
  text[8] := 'No pain, no gain.   ';
  text[9] := 'Nothing ventured, nothing gained. ';
  text[10] := 'Once bitten twice shy.  ';
  text[11] := 'Use your head to save your feet.';
  text[12] := 'What doesn''t kill you, makes you stronger.';

  result := text[random(high(text))];
end;


procedure TfmClient.StatusBar1DrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
begin
  with StatusBar.Canvas do
    begin
      case Panel.Index of
        0: //fist panel
          begin end;
        1: //second panel
          begin end;
        2: //second panel
          begin end;
        3: //fourth panel
          begin
            Color := clBtnFace;
            FillRect(Rect) ;
            imlPowerMode.Draw(StatusBar1.Canvas, Rect.Left, Rect.Top, FMyPowerMode) ;
          end;
     end;
     //Panel background color
     //FillRect(Rect) ;
 
     //Panel Text
     //TextRect(Rect,2 + ImageList1.Width + Rect.Left, 2 + Rect.Top,Panel.Text) ;
   end;
end;

procedure TfmClient.GetStatus;
  var SystemPowerStatus: TSystemPowerStatus;
begin
  GetSystemPowerStatus(SystemPowerStatus);
  with SystemPowerStatus do begin
    // Wird das System mit Wechselstrom oder Akku betrieben ?
    case ACLineStatus of
      0: FMyPowerMode := 1 ;//Akku
      1: FMyPowerMode := 0 ;//Stecker
      else FMyPowerMode := 2; //unbekannt
    end;

    {// Ladezustand der Batterie
    case BatteryFlag of
      1 : Label2.Caption := 'Hoher Ladezustand';
      2 : Label2.Caption := 'Niedriger Ladezustand';
      4 : Label2.Caption := 'Kritischer Ladezustand';
      8 : Label2.Caption := 'Die Batterie wird geladen';
      128: Label2.Caption := 'Es existiert keine System-Batterie';
      255: Label2.Caption := 'Unbekannter Status';
    end;    }

    // Ladezustand in Prozent
    if BatteryLifePercent <> 255 then
      Progressbar1.StepBy(BatteryLifePercent)
    else
      begin
        Progressbar1.Visible := false;
        Statusbar1.Panels[2].Text := 'Batterystatus unknown...';
      end;
  end;
end;

end.
