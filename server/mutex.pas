unit mutex;

interface 

implementation 

uses 
  Windows,Dialogs,Messages;

var 
  mHandle: THandle;
  wHandle: HWND;

initialization 
  mHandle := CreateMutex(nil, True, PAnsiChar('bb305c6d-d373-4852-9b11-7c10616dbb25'));

  if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      MessageDlg('Process is already running!',mtError,[mbOK],0);
      wHandle := FindWindow(PAnsiChar('TfmMain'),nil);
      if wHandle <> 0 then
        SetForegroundWindow(wHandle);
      Halt;
    end;

finalization 
  if mHandle <> 0 then 
    CloseHandle(mHandle); 
end.