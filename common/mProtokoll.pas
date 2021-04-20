unit mProtokoll;

interface

const

MAJOR_RELEASE = '2';
CLT_APP_ID = 'Quizmaster_Client'; // Client-ID-String
SRV_APP_ID = 'Quizmaster_Server'; // Server-ID-String
PROTO_VER = '5'; // Protokoll-Version
PROTO_REV = '21'; // Protokoll-Revision


const HERO_JOKER_COSTS : integer = 2;

type
  TCmdSyntax = record
    Text: ShortString;
    ArgCount: shortint;
  end;

  TCmdToken = (
    cmdNOP = 0,          
    cmdServerName,
    cmdUsername,
    cmdVER,
    cmdKickNotify,
    cmdLogNotify,
    cmdAnswer,
    cmdLockButtons,
    cmdUnlockButtons,
    cmdUnlockAnswerButtons,
    cmdNewRound,
    cmdRIGHT,
    cmdWRONG,
    cmdUpdateScore,
    cmdToggleScore,
    cmdYourJokers,
    cmdYourJokerAnswer,
    cmdReqTelephone,
    cmdTelList,
    cmdAskForHelp,
    cmdHelpAnswer,
    cmdPlsHelp,
    cmdNoHelp,
    cmdReqHero,
    cmdStatusNotify,
    cmdStatusNotifyHigh,
    cmdWindowList,
    cmdMajorityAnswers,
    cmdChatToServer,
    cmdChatMessage,
    cmdGrantFlipchart,
    cmdRevokeAnswer,
    cmdCloseRound,
    cmdClearChat,
    cmdServerShutdown,
    cmdERROR
  );

const
  Syntax: Array[TCmdToken] of TCmdSyntax = (
    (Text: ''; ArgCount: 1),
    (Text: 'SERVERNAME'; ArgCount: 2),
    (Text: 'USERNAME'; ArgCount: 2),
    (Text: 'VER'; ArgCount: 5),
    (Text: 'KICKNOTIFY'; ArgCount: 1),
    (Text: 'LOGNOTIFY'; ArgCount:2),
    (Text: 'ANSWER'; ArgCount:2),
    (Text: 'LOCKBTNS'; ArgCount:1),
    (Text: 'ULOCKBTNS'; ArgCount:1),
    (Text: 'ULOCKANSBTNS'; ArgCount:1),
    (Text: 'NEWROUND'; ArgCount:1),
    (Text: 'RIGHT'; ArgCount:2),
    (Text: 'WRONG'; ArgCount:2),
    (Text: 'UPDATESCORE'; ArgCount:2),
    (Text: 'TOGGLESCORE'; ArgCount:2),
    (Text: 'YOURJOKERS'; ArgCount:2),
    (Text: 'YJAnswer'; ArgCount:2),
    (Text: 'ReqTele'; ArgCount:1),
    (Text: 'TELLIST'; ArgCount:2),
    (Text: 'Askforhelp'; ArgCount:2),
    (Text: 'HelpAnswer'; ArgCount:3),
    (Text: 'PLSHELP'; ArgCount:2),
    (Text: 'NOHELP'; ArgCount:1),
    (Text: 'WANNABE'; ArgCount:1),
    (Text: 'STATNotify'; ArgCount:2),
    (Text: 'STATNotifyHIGH'; ArgCount:2),
    (Text: 'WINDOWS'; ArgCount:2),
    (Text: 'MAJORITYANSWERS'; ArgCount:5),
    (Text: 'ChatToServer'; ArgCount: 2),
    (Text: 'ChatToClient'; ArgCount: 2),
    (Text: 'GrantFlipChart'; ArgCount:1),
    (Text: 'RevokeAnswer'; ArgCount:1),
    (Text: 'CloseRound'; ArgCount:1),
    (Text: 'ClearChat'; ArgCount:1),
    (Text: 'ServerShutdown'; ArgCount:1),
    (Text: ''; ArgCount: 1)
  );
implementation

end.
