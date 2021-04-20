// TParserStringList - Protokollparser für das Terminatorzeichen-Protokoll
// ---------------------------------------------------------------------------
// (C) 2006 Narses
//
//   Version 1.00 vom 17.01.2006
//     - erste öffentliche Version
//   Version 1.01 vom 02.10.2006
//     - Clear aus den ParseText-Methoden entfernt, um Warteschlangen zu
//       ermöglichen

unit ParserStrList;

interface

uses
  Classes;

const
  PARSER_DEFAULT_TERMCHAR = #13;

type
  TParserStringList = class(TStringList)
  protected
    function GetTermText: AnsiString; virtual;
  public
    TermChar: Char;
    constructor Create;
    procedure ParseText(var Buffer: AnsiString); overload;
    procedure ParseText(Buffer: TStrings; const Index: Integer); overload;
    property TermText: AnsiString read GetTermText;
  end;

implementation

// TermChar auf Default-Wert setzen
constructor TParserStringList.Create;
begin
  inherited;
  TermChar := PARSER_DEFAULT_TERMCHAR;
end;

// durch TermChar abgeschlossene Zeichenfolgen vorne aus dem Puffer abtrennen
// und in die Liste tun; reagiert nur auf TermChar (also auch ausdrücklich
// NICHT auf #0!), ist damit also auch binärfähig
procedure TParserStringList.ParseText(var Buffer: AnsiString);
  var
    S: AnsiString;
    i,j,len: Integer;
begin
  BeginUpdate;
  try
    len := Length(Buffer);
    if (len > 0) then begin
      j := 1;
      for i := 1 to len do
        if (Buffer[i] = TermChar) then begin
          SetString(S,PAnsiChar(@Buffer[j]), i -j);
          Add(S);
          j := i +1;
        end;
      if (Buffer[len] = TermChar) then
        Buffer := ''
      else
        if (j > 1) then begin
          SetString(S,PAnsiChar(@Buffer[j]),len -j +1);
          Buffer := S;
        end;
    end;
  finally
    EndUpdate;
  end;
end;

// Variante für TStrings mit Index
procedure TParserStringList.ParseText(Buffer: TStrings; const Index: Integer);
  var
    S: AnsiString;
    i,j,len: Integer;
begin
  BeginUpdate;
  try
    if ( (Buffer <> NIL) and (Index < Buffer.Count) ) then begin
      len := Length(Buffer.Strings[Index]);
      if (len > 0) then begin
        j := 1;
        for i := 1 to len do
          if (Buffer.Strings[Index][i] = TermChar) then begin
            SetString(S,PAnsiChar(@Buffer.Strings[Index][j]), i -j);
            Add(S);
            j := i +1;
          end;
        if (Buffer.Strings[Index][len] = TermChar) then
          Buffer.Strings[Index] := ''
        else
          if (j > 1) then begin
            SetString(S,PAnsiChar(@Buffer.Strings[Index][j]),len -j +1);
            Buffer.Strings[Index] := S;
          end;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

// Strings mit TermChar verkettet abliefern
function TParserStringList.GetTermText: AnsiString;
  var
    i, L, Size, Count: Integer;
    P: PAnsiChar;
    S: AnsiString;
begin
  Count := GetCount;
  Size := 0;
  for i := 0 to Count-1 do
    Inc(Size, Length(Get(i)) +1);
  SetString(Result, NIL, Size);
  P := Pointer(Result);
  for i := 0 to Count-1 do begin
    S := Get(i);
    L := Length(S);
    if (L <> 0) then begin
      System.Move(Pointer(S)^, P^, L);
      Inc(P, L);
    end;
    P^ := TermChar;
    Inc(P);
  end;
end;

end.
