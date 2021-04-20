unit mPlayer;

interface

uses

  ScktComp, ParserStrList, mPlayerObserver, Classes, mProtokoll, SysUtils;

type
  TPlayer = class(TSubject)
  private
    FPlayerName : string;
    FScoreCount : integer;
    FJokerMoney : integer;
    FReceiveBuffer: ansistring;
    FMyParser : TParserStringList;
    FMySocket : TCustomWinSocket;
    FMyClientMajorVersion : integer;
    FMyClientProtocolVersion : integer;
    FMyClientProtocolRevision : integer;
    FMyAnswer : Char;
    lastround : integer;
    procedure setBuffer(Buffer : ansistring);
  public
    parsing : boolean;

    constructor Create;
    destructor  Destroy;   override;

    procedure AddReceiveText(pString : ansistring);
    function  getReceiveTextLength : integer;
    property  Buffer : ansistring read FReceiveBuffer write setBuffer;

    function getSocket : TCustomWinSocket;
    procedure setSocket(Socket : TCustomWinSocket);

    function getParser : TParserStringList;

    function  getName : string;
    procedure setName(pName : string);

    procedure setClientVersion(Major,Prot,Rev : integer);

    procedure addPoints(NumPointsToAdd : integer = 1);
    function getPoints : integer;
    function getPercentage : integer;

    procedure addJoker(count : integer = 1);
    procedure decJoker(count : integer = 1);
    function getJokerMoney : integer;

    procedure setAnswer(Answer: Char = #0);
    function  getAnswer() : Char;
  end;

implementation

uses
  mMain;

procedure TPlayer.AddReceiveText(pString: ansistring);
begin
  self.FReceiveBuffer := pString;
end;

function TPlayer.getReceiveTextLength;
begin
  result := Length(FReceiveBuffer);
end;

constructor TPlayer.Create;
begin
  inherited Create; //important for creating observerlist through superclass

  //Joker set to zero Money
  FJokerMoney := 0;

  //init empty ReceiveBuffer
  FReceiveBuffer := '';

  //init empty Name
  FPlayerName := '';

  //init my parserlist
  FMyParser := TParserStringList.Create;

  //not parsing at the moment
  parsing := false;
end;

destructor TPlayer.Destroy;
begin
  //Destroy Parser
  FMyParser.Clear;
  FMyParser.Destroy;
  inherited Destroy;
end;

function TPlayer.getSocket;
begin
  result := FMySocket;
end;

procedure TPlayer.setSocket(Socket: TCustomWinSocket);
begin
  FMySocket := Socket;
end;

function TPlayer.getName;
begin
  result := FPlayerName;
end;

procedure TPlayer.setName(pName: ansistring);
begin
  FPlayerName := pName;
  self.callObservers;
end;

function TPlayer.getParser;
begin
  result := FMyParser;
end;

procedure TPlayer.setBuffer(Buffer: ansistring);
begin
  FReceiveBuffer := Buffer;
end;

procedure TPLayer.setClientVersion(Major: Integer; Prot: Integer; Rev: Integer);
begin
  FMyClientMajorVersion := Major;
  FMyClientProtocolVersion := Prot;
  FMyClientProtocolRevision := Rev;
end;

procedure TPlayer.addPoints(NumPointsToAdd : integer = 1);
begin
  FScoreCount := FScoreCount + NumPointsToAdd;
  self.callObservers;
end;

function TPlayer.getPoints;
begin
  result := FScoreCount;
end;

function TPlayer.getPercentage;   
  function prozent(antworten: integer; runden : integer) : integer;
      var
        i : integer;
    begin
    if (runden > 0) then
      begin
        i := trunc((antworten / runden)*100);
        if i > 0 then
          result := i
        else
          result := 0;
      end;
    end;
begin
  if lastround <> fmMain.GameLogic.rounds then
    begin
      lastround := fmMain.GameLogic.rounds;
      result := prozent(self.getPoints,fmMain.GameLogic.rounds);
    end
  else
    result := prozent(self.getPoints,fmMain.GameLogic.rounds  + 1);
end;

procedure TPlayer.addJoker(count : integer = 1);
begin
  inc(FJokerMoney, count);
  getSocket.SendText(Syntax[cmdYourJokers].Text+#13+IntToStr(getJokerMoney)+#13);
end;

procedure TPlayer.decJoker(count : integer = 1);
begin
  dec(FJokerMoney, count);
  getSocket.SendText(Syntax[cmdYourJokers].Text+#13+IntToStr(getJokerMoney)+#13);
end;

function TPlayer.getJokerMoney;
begin
  result := FJokerMoney;
end;

procedure TPlayer.setAnswer(Answer: Char = #0);
begin   
  FMyAnswer := Answer;
  self.callObservers;
end;

function TPlayer.getAnswer() : Char;
begin
  result := FMyAnswer;
end;

end.
