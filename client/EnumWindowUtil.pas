unit EnumWindowUtil;

{
Wrapper-Class for EnumWindows, EnumChildWindows, EnumDesktopWindows
29.07.2004 Andreas Schmidt
}


interface

uses Classes, Windows, Messages;

type

TWindowList = class(TStringList)
private
   FUseCaption : Boolean;
   FShowUnvisibleWindows: Boolean;
   FAddClassname: Boolean;
   function GetHandles(idx: Integer): HWND;
   function GetClassNames(idx: Integer): string;
   procedure KillProcess(hWindowHandle: HWND);
public
   procedure EnumTopLevelWindows;
   procedure EnumDesktopWindows(handle:HWND);
   procedure EnumChildWindows(handle:HWND);
   procedure EnumThreadWindows(ThreadId:Cardinal);
   procedure EnumWindowStations;
   procedure Kill(i : integer);

   property ShowUnvisibleWindows:Boolean read FShowUnvisibleWindows write FShowUnvisibleWindows;
   property AddClassname:Boolean read FAddClassname write FAddClassname;
   property Handles[idx:Integer]:HWND read GetHandles;
   property ClassNames[idx:Integer]:string read GetClassNames;

end;



implementation

uses SysUtils;

{ TWindowList }

function GetWindowClassName(hwnd:HWND):string;
begin
   SetLength(Result, 1024);
   GetClassName(hwnd, PChar(Result), Length(Result));
   Result := PChar(Result);
end;


procedure EnumWindowCallback(hwnd:HWND; lParam:TWindowList); stdcall;
var
   caption : string;
begin
   if (not lParam.ShowUnvisibleWindows) and (not IsWindowVisible(hwnd)) then
      Exit;

   if lParam.FUseCaption then
   begin
      SetLength(caption, GetWindowTextLength(hwnd));
      GetWindowText(hwnd, PChar(caption), Length(caption)+1);
   end
   else
   begin
      caption := Format('%6.6x', [hwnd]);
   end;
   if lParam.AddClassname then
      caption := caption + ':' +GetWindowClassName(hwnd);


   lParam.AddObject(caption, TObject(hwnd));
end;

procedure EnumWindowStationCallback(station:PChar;lParam:TWindowList); stdcall;
begin
   lParam.Add(station);
end;



procedure TWindowList.EnumChildWindows(handle: HWND);
begin
   Clear;
   FUseCaption := False;
   if Windows.EnumChildWindows(handle, @EnumWindowCallback, Integer(Self)) then
      ;
//      RaiseLastOSError;
end;

procedure TWindowList.EnumDesktopWindows(handle: HWND);
begin
   Clear;
   if Windows.EnumDesktopWindows(handle, @EnumWindowCallback, Integer(self)) then
      RaiseLastOSError;
end;

procedure TWindowList.EnumThreadWindows(ThreadId:Cardinal);
begin
   if ThreadId = 0 then
      ThreadId := GetCurrentThreadId;
   Clear;
   FUseCaption := True;
   if not windows.EnumThreadWindows(ThreadId,@EnumWindowCallback, Integer(self)) then
      RaiseLastOSError;
end;

procedure TWindowList.EnumTopLevelWindows;
begin
   Clear;
   FUseCaption := True;
   if not EnumWindows(@EnumWindowCallback, Integer(self)) then
      RaiseLastOSError;
end;

procedure TWindowList.EnumWindowStations;
begin
   Clear;
   if not Windows.EnumWindowStations(@EnumWindowStationCallback, Integer(Self)) then
      RaiseLastOSError;
end;

function TWindowList.GetClassNames(idx: Integer): string;
begin
   result := GetWindowClassName(GetHandles(idx));
end;

function TWindowList.GetHandles(idx: Integer): HWND;
begin
   Result := HWND(Objects[idx]);
end;

procedure TWindowList.Kill(i: Integer);
begin
  self.KillProcess(self.Handles[i]);
end;

procedure TWindowList.KillProcess(hWindowHandle: HWND);
var
  hprocessID: INTEGER;
  processHandle: THandle;
  DWResult: DWORD;
begin
  SendMessageTimeout(hWindowHandle, WM_CLOSE, 0, 0,
    SMTO_ABORTIFHUNG or SMTO_NORMAL, 5000, DWResult);

  if isWindow(hWindowHandle) then
  begin
    //PostMessage(hWindowHandle, WM_QUIT, 0, 0);

    { Get the process identifier for the window}
    GetWindowThreadProcessID(hWindowHandle, @hprocessID);
    if hprocessID <> 0 then
    begin
      { Get the process handle }
      processHandle := OpenProcess(PROCESS_TERMINATE or PROCESS_QUERY_INFORMATION,
        False, hprocessID);
      if processHandle <> 0 then
      begin
        { Terminate the process }
        TerminateProcess(processHandle, 0);
        CloseHandle(ProcessHandle);
      end;
    end;
  end;
end;
end.
