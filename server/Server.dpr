program Server;

uses
  Forms,
  mProtokoll in '..\common\mProtokoll.pas',
  ParserStrList in '..\common\ParserStrList.pas',
  mPlayer in 'mPlayer.pas',
  mPlayerObserver in 'mPlayerObserver.pas',
  mPrintUtils in 'mPrintUtils.pas',
  mServer in 'mServer.pas',
  mutex in 'mutex.pas',
  mGameLogic in 'mGameLogic.pas',
  mMain in 'mMain.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Quizmaster² - Server';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
