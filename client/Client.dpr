program Client;

{$DEFINE release}

uses
 {$IFDEF release}mutex in 'mutex.pas',{$ENDIF}
  Forms,
  windows,
  Dialogs,
  Unit1 in 'Unit1.pas' {fmClient},
  mProtokoll in '..\common\mProtokoll.pas',
  ParserStrList in '..\common\ParserStrList.pas',
  Unit2 in 'Unit2.pas' {fmAskForm},
  Unit3 in 'Unit3.pas' {fmAnswerHelp},
  EnumWindowUtil in 'EnumWindowUtil.pas';

{$IFDEF release}
var
  OldDesk      : HDESK;
  NewDesk      : HDESK;
  sti:_STARTUPINFO;
  pri:_PROCESS_INFORMATION;
{$ENDIF}

{$R *.res}

  procedure StartApp;
  begin
    Application.Initialize;
    Application.Title := 'Quizmaster² - Client';
    Application.CreateForm(TfmClient, fmClient);
    Application.CreateForm(TfmAskForm, fmAskForm);
    Application.CreateForm(TfmAnswerHelp, fmAnswerHelp);
    Application.Run;
  end;

begin

  {$IFDEF test}
    StartApp;
  {$ENDIF}
  {$IFDEF release}
  if(CmdLine = 'game')then
  begin
    StartApp;
  end else
  begin
    if (MessageDlgPos('Attention:' +#10#13
                      + 'Quizmaster will be run on a separated Desktop. ' +#10#13
                      + #10#13
                      + 'You will not be able to work with currently opened applications.' +#10#13
                      + 'To be sure, please save your work!' +#10#13
                      + #10#13
                      + 'Do you accept this?',
                      mtInformation,
                      [mbYes,mbNo],
                      0,
                      Screen.Width div 2 - 200,
                      Screen.Height div 2 - 80,
                      mbNo) = 6)
    then
      begin
        OldDesk := GetThreadDesktop(GetCurrentThreadID);
        NewDesk := CreateDesktop(
                              PAnsiChar('QuizWindow'),
                              nil,
                              nil,
                              0,
                              (
                                DESKTOP_CREATEWINDOW or
                                DESKTOP_SWITCHDESKTOP or
                                DESKTOP_CREATEMENU
                              ),
                              nil);

        if (NewDesk <> 0) AND (NewDesk <> OldDesk) then
        begin
          SetThreadDesktop(NewDesk);
          Windows.SwitchDesktop(NewDesk);
          sti.lpDesktop:= PAnsiChar('QuizWindow');

          CreateProcess(  PAnsiChar(ParamStr(0)),
                          PAnsiChar('game'),
                          nil,
                          nil,
                          true,
                          0,
                          nil,
                          nil,
                          sti,
                          pri);

          // Wait until child process exits.
          WaitForSingleObject( pri.hProcess, INFINITE );

          // Close process and thread handles.
          CloseHandle( pri.hProcess );
          CloseHandle( pri.hThread );

          Windows.SwitchDesktop(OldDesk);
          SetThreadDesktop(OldDesk);
          CloseDesktop(NewDesk);
        end;
      end
      else
        Halt(0);
  end;
  {$ENDIF}
end.
