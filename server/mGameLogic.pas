unit mGameLogic;

interface

uses mPlayer, mProtokoll, StdCtrls, mServer, Classes, SysUtils, ComCtrls;

type
  TGameLogic = class
    private
      MyServer : TServer;
      acChart : TPlayer;
      roundCount : integer;
      acHero : TPlayer;
    public
      constructor Create(LogMemo : TMemo);
      destructor  Destroy;  override;

      property Server : TServer read MyServer;

      procedure ServerStart;
      procedure ServerStop;

      procedure GrantFlipcharRight(Player : TPlayer);
      procedure CloseRound;

      procedure SendTheRightAnswer(Answer : Char);

      procedure UpdateScoreAtClients;
      procedure toggleScoreforClients;

      procedure nextRoundStartUp;

      procedure registerAnAnswer(Player:TPlayer; Answer: Char);
      procedure setInitialValues;

      function checkAllAnswered : boolean;
      procedure sendeMajorityAnswers;

      function isFlipchartActive : boolean;
      function isHeroInPlace : boolean;

      procedure revokeAnswer(Player: TPlayer);

      property rounds : integer read roundCount;

      procedure requestHero(Player : TPlayer);

      procedure handleIncomingChartMessage(Player : TPlayer; pMessage : string);
      procedure handleOutgoingChartMessages(pMessages : string);
      procedure denyChart;
  end;

implementation

uses
  mMain;

function TGameLogic.isFlipchartActive : boolean;
begin
  result := self.acChart <> nil;
end;

function TGameLogic.isHeroInPlace;
begin
  result := self.acHero <> nil;
end;

constructor TGameLogic.Create(LogMemo : TMemo);
begin
  //Eigenen Server erstellen
  MyServer := TServer.Create;
  MyServer.LogMemo := LogMemo;
end;

destructor TGameLogic.Destroy;
begin
  self.ServerStop;
  MyServer.Destroy;
end;

procedure TGameLogic.setInitialValues;
begin
  acHero := nil;
  acChart := nil;
  roundCount := 0;
end;

procedure TGameLogic.ServerStart;
begin
  if MyServer.Open('56000') then     //open on port
    begin
      self.setInitialValues;
      sleep(100);
    end;

  fmMain.toggleServerRelated(MyServer.Active);
end;

procedure TGameLogic.ServerStop;
begin
  if MyServer.Active then
    begin
      MyServer.Close;
      sleep(1000);
    end;

  fmMain.toggleServerRelated(MyServer.Active);
end;

procedure TGameLogic.GrantFlipcharRight(Player: TPlayer);
begin
  if acChart = nil then
    begin
      //first save who has flipchart rights
      acChart := Player;
      //send the message to the client
      Player.getSocket.SendText(Syntax[cmdGrantFlipchart].Text+#13);
    end;
end;

procedure TGameLogic.CloseRound;
begin
  Server.SendToAll(Syntax[cmdLockButtons].Text+#13);
  Server.SendToAll(Syntax[cmdCloseRound].Text+#13);
end;

procedure TGameLogic.SendTheRightAnswer(Answer: Char);
  var
    i: integer;
    Player : TPlayer;
begin
  for i := 0 to Server.ClientList.Count - 1 do
    begin
      Player := TPlayer(Server.ClientList.Objects[i]); //get the Playercontainer

      if UpperCase(Player.getAnswer) = UpperCase(Answer) then   //if the answer of the Player is the right answer
        begin
          //send Congratulations to the client ;)
          Player.getSocket.SendText(Syntax[cmdRIGHT].Text+#13+Answer+#13);   
          if acHero = Player then //if the player is a hero... give him 2 points ;)
            Player.addPoints(2)
          else
            Player.addPoints(1);
        end
      else
        begin
          //tell the client that he is a looooooooser xD
          Player.getSocket.SendText(Syntax[cmdWRONG].Text+#13+Answer+#13);

          if acHero <> nil then //if there is a hero
            begin
              if acHero = Player then
                Player.addPoints(-2)
              else
                Player.addPoints(1);
            end;
        end;
    end;     
  fmMain.afterRoundCleanup;
end;

procedure TGameLogic.UpdateScoreAtClients;
  var
    Scorelist : TStringList;
    i : integer;
begin
  //neuen score an alle verteilen...
  Scorelist := TStringList.Create;       //create a stringlist for serialization
  for i := 0 to fmMain.lvOverallScoreboard.Items.Count - 1 do
    begin
      Scorelist.Add(fmMain.lvOverallScoreboard.Items.Item[i].Caption);
      Scorelist.Add(fmMain.lvOverallScoreboard.Items.Item[i].SubItems.Strings[0]);
      Scorelist.Add(fmMain.lvOverallScoreboard.Items.Item[i].SubItems.Strings[1])
    end;
  Server.SendToAll(Syntax[cmdUpdateScore].Text+#13+Scorelist.CommaText+#13);
  Scorelist.Clear;
  Scorelist.Destroy;
end;

procedure TGameLogic.toggleScoreforClients;
begin
  if fmMain.cbScoreboardAvail.Checked then
    UpdateScoreAtClients;

  Server.SendToAll(Syntax[cmdToggleScore].Text+#13
    +BoolToStr(fmMain.cbScoreboardAvail.Checked)+#13);
end;

procedure TGameLogic.nextRoundStartUp;
  var
    i : integer;
    Player : TPlayer;
begin
  inc(roundCount);
  fmMain.lbRoundCount.Caption := 'Rounds: ' + IntToStr(roundCount);

  //reset flipchart user and hero
  acChart := nil;
  acHero := nil;

  Server.SendToAll(Syntax[cmdUnlockButtons].Text+#13);
  Server.SendToAll(Syntax[cmdNewRound].Text+#13);

  for i := 0 to Server.ClientList.Count - 1 do
    begin
      Player := TPlayer(Server.ClientList.Objects[i]);
      Player.setAnswer();   //empty Answer
      //if Jokers are allowed                                                                   to prevent 0 mod 0 = undefined ;)
      if  not('Disabled' = fmMain.cbxGrantJoker.Items[fmMain.cbxGrantJoker.ItemIndex])
          and not (roundCount = 0)
          //    if the round count equals the interval for new jokers                                       special case - round is the first one
          and (((roundCount mod StrToInt(fmMain.cbxGrantJoker.Items[fmMain.cbxGrantJoker.ItemIndex])) = 0)
          or (roundCount = 1))
      then
        Player.addJoker;
    end;
end;

procedure TGameLogic.registerAnAnswer(Player: TPlayer; Answer: Char);
  var
    i : integer;
begin
  if (acHero <> nil) then //there is a hero
    begin
      if (Player = acHero) then      //only accept answer from the hero
        begin
          for I := 0 to Server.ClientList.Count - 1 do     //set hero answer for every Player in AuthedList
            TPlayer(Server.ClientList.Objects[i]).setAnswer(Answer);

          //JOKER NACHRICHT AN ALLE
          Server.SendToAll(Syntax[cmdYourJokerAnswer].Text+#13+Answer+#13);
          //RUNDE ZUMACHEN
          fmMain.btCloseRound.Click;
        end;
    end
  else
    begin
      if (Answer = '?') and (Player.getAnswer = '') then //Majority  Joker send
        begin
          Player.decJoker;
          Player.getSocket.SendText(Syntax[cmdUnlockAnswerButtons].Text+#13);
          Player.setAnswer(Answer);
        end
      else if (Player.getAnswer = '') or (Player.getAnswer() = '?') then
        begin
          Player.setAnswer(Answer);
          //BUTTONSSPERREN
          Player.getSocket.SendText(Syntax[cmdLockButtons].Text+#13);
        end;
    end;

    self.sendeMajorityAnswers;

    if fmMain.cbAutoClose.Checked AND self.checkAllAnswered then
      fmMain.AutoClose;
end;

function TGameLogic.checkAllAnswered;
  var
    i : integer;
begin
  result := true;
  for i := 0 to Server.ClientList.Count - 1 do
    if not (TPlayer(Server.ClientList.Objects[i]).getAnswer() in ['A'..'Z'])then
      result := false;
end;

procedure TGameLogic.sendeMajorityAnswers;
  var
    a,b,c,d,i : integer;
    Player : TPlayer;
begin
  //antworten zusammen zählen
  a := 0;
  b := 0;
  c := 0;
  d := 0;

  with Server.ClientList do
    begin
      for I := 0 to Count - 1 do
        begin
          Player := TPlayer(Objects[i]);
          if LowerCase(Player.getAnswer) = 'a' then
            inc(a);
          if LowerCase(Player.getAnswer) = 'b' then
            inc(b);
          if LowerCase(Player.getAnswer) = 'c' then
            inc(c);
          if LowerCase(Player.getAnswer) = 'd' then
            inc(d);
        end;

      //spieler mit majority joker ermitteln
      for I := 0 to Count - 1 do
        begin
           Player := TPlayer(Objects[i]);
          if Player.getAnswer = '?' then
            Player.getSocket.SendText(Syntax[cmdMajorityAnswers].Text+#13
                                                                + IntToStr(a)+#13
                                                                + IntToStr(b)+#13
                                                                + IntToStr(c)+#13
                                                                + IntToStr(d)+#13);
        end;
    end;
end;

procedure TGameLogic.revokeAnswer(Player: TPlayer);
begin
  if acHero = nil then //issn Hero... also keine Möglichkeit
    begin
      Player.setAnswer();
      Player.getSocket.SendText(Syntax[cmdUnlockButtons].Text+#13);
      self.sendeMajorityAnswers;
    end;
end;

procedure TGameLogic.requestHero(Player: TPlayer);
  var
    x:integer;
begin
  if (acHero = nil) then //es gitb noch keinen Hero
    begin
      //als erstes CLientssperren
      Server.SendToAll(Syntax[cmdLockButtons].Text+#13);
      Server.SendToAll(Syntax[cmdStatusNotify].Text+#13+'I guess, we have a hero...'+#13);

      //nur Hero wieder freischalten und hinterlegen
      Player.getSocket.SendText(Syntax[cmdUnlockAnswerButtons].Text+#13);
      acHero :=  Player;
      Player.getSocket.SendText(Syntax[cmdStatusNotifyHigh].Text+#13+'Go Hero, GO!'+#13);

      //hero die Joker abziehen
      Player.decJoker(HERO_JOKER_COSTS);
      
      //Für alle anderen eine Antwort eintragen
      for x := 0 to Server.ClientList.Count - 1 do
        TPlayer(Server.ClientList.Objects[x]).setAnswer('!');
    end
  else
    Player.getSocket.SendText(Syntax[cmdStatusNotify].Text+#13+'We already have a hero!'+#13);
end;

procedure TGameLogic.handleIncomingChartMessage(Player: TPlayer; pMessage: string);
begin
  if acChart = Player then
    fmMain.addChatMessage('['+Player.getName+'] '+ pMessage);
end;

procedure TGameLogic.handleOutgoingChartMessages(pMessages: string);
begin
  Server.SendToAll(Syntax[cmdChatMessage].Text+#13+ pMessages +#13);
end;

procedure TGameLogic.denyChart;
begin
  TPlayer(acChart).getSocket.SendText(Syntax[cmdClearChat].Text+#13);
end;
end.
