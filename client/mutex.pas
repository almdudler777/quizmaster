unit mutex;

interface 

implementation 

uses 
  Windows,Dialogs;

var 
  mHandle: THandle;
  wHandle: HWND;

initialization
  if CmdLine <> 'game' then
  begin
    mHandle := CreateMutex(nil, True, PAnsiChar('bb305c6d-d373-4852-9b11-7c10616dbb26'));

    if GetLastError = ERROR_ALREADY_EXISTS then
      begin
        MessageDlg('Process is already running!',mtError,[mbOK],0);
        wHandle := FindWindow(PAnsiChar('TfmClient'),nil);
        if wHandle <> 0 then
          SetForegroundWindow(wHandle);
        Halt;
      end;
  end;

finalization
if CmdLine <> 'game' then 
  if mHandle <> 0 then
    CloseHandle(mHandle);
end.
