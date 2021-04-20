unit mServer;

interface

uses
  ScktComp, mProtokoll, StdCtrls, Classes, SysUtils, mPlayer, ParserStrList, Forms;

type
  TServer = class
  private
    ServerSocket : TServerSocket;

    PreAuthList    : TStringList;
    AuthList       : TStringList;
      
    procedure ServerSocket1ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1ClientError(Sender: TObject;Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ServerSocket1ClientRead(Sender: TObject;Socket: TCustomWinSocket);

    procedure LogIt(pMessage : string);

    procedure ParseBuffer(Player : TPlayer);
    function  GetCmdToken(const StrToken: AnsiString): TCmdToken;

    procedure DeleteClient(Socket: TCustomWinSocket);
    procedure AddClient(Socket : TCustomWinSocket);
    procedure Execute(const Command: TCmdToken; Player:TPlayer);

    function getSocketIdent(Socket:TCustomWinSocket) : string;
  public
    LogMemo : TMemo;

    constructor Create;
    destructor  Destroy; reintroduce;

    function  Open(pPort : string) : boolean;
    procedure Close;

    function Active : boolean;

    property ClientList : TStringList read AuthList;

    procedure AuthorizePlayer(Player : TPlayer);
    procedure KickPlayer(Player : TPlayer);

    procedure SendToAll(pMessage : string; PreAuthStateToo : boolean = false);
  end;

implementation

uses mMain, mGameLogic;

procedure TServer.AuthorizePlayer(Player: TPlayer);
  var
    i : integer;
begin
  i := PreAuthList.IndexOfObject(Player);
  if i > -1 then //if still unauthed player
    begin
      PreAuthList.Delete(i);
      AuthList.AddObject(getSocketIdent(Player.getSocket),Player);
      //give new Player to GUI
      fmMain.newPlayer(Player);
    end;
end;

function TServer.Active;
begin
  result := ServerSocket.Active;
end;

function TServer.getSocketIdent(Socket:TCustomWinSocket) : string;
begin
  result := Socket.RemoteAddress +':'+ IntToStr(Socket.RemotePort);
end;

constructor TServer.Create;
begin
  ServerSocket := TServerSocket.Create(fmMain);
  ServerSocket.OnClientConnect     := ServerSocket1ClientConnect;
  ServerSocket.OnClientDisconnect  := ServerSocket1ClientDisconnect;
  ServerSocket.OnClientError       := ServerSocket1ClientError;
  ServerSocket.OnClientRead        := ServerSocket1ClientRead;

  //Init and reserve the UserLists
  PreAuthList := TStringList.Create;
  AuthList := TStringList.Create;
end;

destructor TServer.Destroy;
begin
  //kill the server socket
  self.ServerSocket.Destroy;
  //Kill the lists
  PreAuthList.Destroy;
  AuthList.Destroy;
  //kill inherited
  inherited Destroy;
end;

procedure TServer.LogIt(pMessage: string);
begin
  if Assigned(LogMemo) then   //if there is a memo assigned
    LogMemo.Lines.Add(pMessage);
end;

function TServer.GetCmdToken(const StrToken: String): TCmdToken;
begin
  Result := Low(Syntax);  //start with the lowest token cmdNOP = No Operation
  while ( (Result < cmdERROR) and (StrToken <> UpperCase(Syntax[Result].Text))) do //search until last token: cmdERROR
    Inc(Result);
  //Result should be an integer Token
end;

procedure TServer.ServerSocket1ClientConnect(Sender: TObject;Socket: TCustomWinSocket);
begin
  //Log the new connection
  LogIt('New Connection @ '+ getSocketIdent(Socket));
  //add the client; e.g. link data & socket + put to unauth state
  AddClient(Socket);
  //send version information
  Socket.SendText(Syntax[cmdVER].Text+#13+SRV_APP_ID+#13+MAJOR_RELEASE+#13+
    PROTO_VER+#13+PROTO_REV+#13);
end;

procedure TServer.ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  //log that user disconnected
  LogIt(TPlayer(Socket.Data).getName +'@'+ getSocketIdent(Socket) +' (User disconnect)');
  //delete the client
  DeleteClient(Socket);
end;

procedure TServer.ServerSocket1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  //log the Error
  LogIt(TPlayer(Socket.Data).getName +' @ '+ getSocketIdent(Socket) +' - (error: connection closed)');
  //delete the client
  DeleteClient(Socket);
  //if socket is still connected kill it
  if (Socket.Connected) then
    Socket.Close;
  //set the errorcode to zero, to avoid MessageDlg for exception
  ErrorCode := 0;
end;

procedure TServer.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
  var
    Player: TPlayer;
    s: ansistring;
    KnownUser : boolean;
begin
  Player := nil;   //to prevent Pascal Notice
  KnownUser := true;

  try
    Player := TPlayer(Socket.Data);  //cast to the right PlayerContainer
  except
    KnownUser := false;
  end;

  s := Socket.ReceiveText;         //get the receivetext from the socket (can only be done once!)

  if KnownUser then
    begin
      if Length(s) > 0  then           //if there is really some text
        begin
          Player.AddReceiveText(s);    //add it to the player's receivebuffer
          if (Player.getReceiveTextLength > 0) then //if the player has some buffered input
            ParseBuffer(Player);                    // go for it and parse it...
        end;
    end
  else
    LogIt('Unknown Data: '+Socket.ReceiveText);
end;  

procedure TServer.ParseBuffer(Player: TPlayer);
  var
    Data: TParserStringList;
    Current: TCmdToken;
    OutOfArg: Boolean;
    s : ansistring;
begin
  Data := Player.getParser;   //just put a link to the client Parser
  s := Player.Buffer;         //get the Playerbuffer - Attention: Buffer is a property and will be rewritten by ParseText()
  Data.ParseText(s);          //get any commands out of the buffer
  if not(Player.parsing) then //due to asynchronous network code - only Parse when not already parsing...
    begin
      Player.parsing := true; // activate the parser flag
      OutOfArg := FALSE;      // suppose we 're not out of Args
      while ( (Data.Count > 0)
            and (NOT OutOfArg) ) do
        begin
          Current := GetCmdToken(UpperCase(Data.Strings[0]));    //get the next token
          if (Data.Count >= Syntax[Current].ArgCount) then      // are there enough arguments for that token?
            Execute(Current,Player) //go and excecute the command
          else
            OutOfArg := TRUE;
        end;

       Player.parsing := false; // deavtivate parser flag
    end;
end;

procedure TServer.AddClient(Socket: TCustomWinSocket);
  var
    Player : TPlayer;
begin
  //We need a new PlayerContainer (TPlayer) to store Player Information
  Player := TPlayer.Create();
  //Give the container a link to its Socket
  Player.setSocket(Socket);
  //Put the Player into UnAuthed mode
  PreAuthList.AddObject(getSocketIdent(Socket),Player);
  //Link the socket with its PlayerContainer
  Socket.Data := Pointer(Player);
end;

procedure TServer.DeleteClient(Socket: TCustomWinSocket);
  var
    i : integer;
begin
  //first search in the PreAuthList
  i := PreAuthList.IndexOfObject(Socket.Data);
  if (i > -1) then
    begin
      fmMain.deletePlayer(TPlayer(Socket.Data));
      PreAuthList.Delete(i);        //Kick Element from List
      TPlayer(Socket.Data).Destroy;    //Destroy the PlayerContainer
    end;

  //else find it in the Authorized List
  i := AuthList.IndexOfObject(Socket.Data);
  if (i > -1) then
    begin
      fmMain.deletePlayer(TPlayer(Socket.Data));
      AuthList.Delete(i);             //Kick Element from List
      TPlayer(Socket.Data).Destroy;    //Destroy the PlayerContainer
    end;
end;

procedure TServer.Execute(const Command: TCmdToken; Player:TPlayer);
  var
    Data : TParserStringList;
    i    : integer;
    Logic : TGameLogic;
    Telliste : TStringList;
begin

  Data := Player.getParser;
  Logic := fmMain.GameLogic;

  case Command of
    cmdNOP: ;

    cmdUsername:
      begin
        Player.setName(Data.Strings[1]);
        self.AuthorizePlayer(Player);
      end;

    cmdVER:
      if (Data.Strings[1] = CLT_APP_ID) then
        if (Data.Strings[2] = MAJOR_RELEASE) AND (Data.Strings[3] = PROTO_VER) AND (Data.Strings[4] = PROTO_REV) then
          begin
            LogIt(getSocketIdent(Player.getSocket)+ ' reported version: '+Data.Strings[2]+'.'+Data.Strings[3]+'.'+Data.Strings[4]);
            //SERVERNAME
            Player.getSocket.SendText(Syntax[cmdServerName].Text+#13+fmMain.edServerName.Text+#13);
            //TOGGLESCORE AT START
            Player.getSocket.SendText(Syntax[cmdToggleScore].Text+#13
              +BoolToStr(fmMain.cbScoreboardAvail.Checked)+#13);
            //Put Version into PlayerCOntainer for authorization purpose
            Player.setClientVersion(StrToInt(Data.Strings[2]),StrToInt(Data.Strings[3]),StrToInt(Data.Strings[4]));
          end
        else
          begin
            LogIt(getSocketIdent(Player.getSocket) +' incompatible version ('+ Data.Strings[2]+'.'+Data.Strings[3]+')');
            Player.getSocket.Close;
          end
      else
        begin
          LogIt(getSocketIdent(Player.getSocket)+' is no Quizmaster Client');
          Player.getSocket.Close;
        end;

    cmdAnswer:
      begin
        Logic.registerAnAnswer(Player,Data.Strings[1][1]);
      end;

    cmdRevokeAnswer:
      begin
        Logic.revokeAnswer(Player);
      end;

    cmdReqTelephone:
      begin
        if ClientList.Count - 1 > 0 then
          begin
            TelListe := TStringList.Create;

            for i := 0 to ClientList.Count- 1 do
              if TPlayer(ClientList.Objects[i]) <> Player then  //do not show requesting player in list
                TelListe.Add(TPlayer(ClientList.Objects[i]).getName);

            Player.getSocket.SendText(Syntax[cmdTelList].Text+#13+TelListe.CommaText+#13);
            FreeAndNil(TelListe);
          end
        else  //KEINE HILFE
          Player.getSocket.SendText(Syntax[cmdNoHelp].Text+#13);
      end;


    cmdAskForHelp:
      begin
        Player.decJoker; //Joker dec

        for i := 0 to ClientList.Count - 1 do
          if TPlayer(ClientList.Objects[i]).getName = Data.Strings[1] then
            TPlayer(ClientList.Objects[i]).getSocket.SendText(Syntax[cmdPlsHelp].Text+#13+Player.getName+#13);
      end;

    cmdHelpAnswer:
      begin
        for i := 0 to ClientList.Count - 1 do
          if TPlayer(ClientList.Objects[i]).getName = Data.Strings[1] then
            TPlayer(ClientList.Objects[i]).getSocket.SendText(Syntax[cmdHelpAnswer].Text+#13+Player.getName+#13+Data.Strings[2]+#13);
      end;

    cmdChatToServer:
      begin
        Logic.handleIncomingChartMessage(Player,Data.Strings[1]);
      end;

    cmdReqHero:
      begin
        Logic.requestHero(Player);
      end
  else
    LogIt('Unknown Command from '+ getSocketIdent(Player.getSocket) + ' > '+Data.Strings[0]);
  end;
  for i := 1 to Syntax[Command].ArgCount do
    if Data.Count > 0 then
      Data.Delete(0);
end;

function TServer.Open(pPort : string) : boolean;
begin
  //suppose server cant be opened
  result := false;
  //if it's not already opened
  if not (ServerSocket.Active) then
    begin
      ServerSocket.Port := StrToIntDef(pPort,56000);   //open it
      ServerSocket.Open;
      result := true;      //tell that it was opened
    end;
end;

procedure TServer.Close;
  var
    i : integer;
begin
  if (ServerSocket.Active) then  //if the server is active
    begin
      //Perform a grace shutdown instead of just closing anything
      for I := 0 to ServerSocket.Socket.ActiveConnections - 1 do  //for all connections
        begin
          ServerSocket.Socket.Connections[I].SendText(Syntax[cmdServerShutdown].Text+#13);
          ServerSocket.Socket.Connections[I].Close;  //close client
        end;
      Application.ProcessMessages;  //process any buffers
      sleep(1000);                  //wait a second for any incoming messages
      Application.ProcessMessages;  //process everything
      ServerSocket.Close;           //shutdown the socket
    end;
end;

procedure TServer.KickPlayer(Player : TPlayer);
begin
  Player.getSocket.SendText(Syntax[cmdKickNotify].Text + #13);
  Player.getSocket.Close;
end;

procedure Tserver.SendToAll(pMessage: string; PreAuthStateToo : boolean = false);
  var
    i : integer;
begin
  for I := 0 to AuthList.Count - 1 do
    TPlayer(AuthList.Objects[i]).getSocket.SendText(pMessage);

  if PreAuthStateToo then
    for I := 0 to PreAuthList.Count - 1 do
      TPlayer(PreAuthList.Objects[i]).getSocket.SendText(pMessage);
end;
end.
