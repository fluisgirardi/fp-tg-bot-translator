program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, {$IF FPC_FULLVERSION < 30300}ssockets, sslsockets, {$ELSE}opensslsockets, fpopenssl, {$ENDIF}
  tgsendertypes, tgtypes, CustApp, fpjson, jsonparser, StrUtils, fphttpclient,
  configuration, tgsynapsehttpclientbroker
  ;

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  private
    MsgQueued:Boolean;
    Msgs:UTF8String;
    procedure TgMessage({%H-}ASender: TObject; AMessage: TTelegramMessageObj);
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  function HTMLDecode(const AStr: String): String;
  var
    Sp, Rp, Cp, Tp: PChar;
    S: String;
    I, Code: Integer;
  begin
    SetLength(Result, Length(AStr));
    Sp := PChar(AStr);
    Rp := PChar(Result);
    Cp := Sp;
    try
      while Sp^ <> #0 do
      begin
        case Sp^ of
          '&': begin
                 Cp := Sp;
                 Inc(Sp);
                 case Sp^ of
                   'a': if AnsiStrPos(Sp, 'amp;') = Sp then  { do not localize }
                        begin
                          Inc(Sp, 3);
                          Rp^ := '&';
                        end;
                   'l',
                   'g': if (AnsiStrPos(Sp, 'lt;') = Sp) or (AnsiStrPos(Sp, 'gt;') = Sp) then { do not localize }
                        begin
                          Cp := Sp;
                          Inc(Sp, 2);
                          while (Sp^ <> ';') and (Sp^ <> #0) do
                            Inc(Sp);
                          if Cp^ = 'l' then
                            Rp^ := '<'
                          else
                            Rp^ := '>';
                        end;
                   'n': if AnsiStrPos(Sp, 'nbsp;') = Sp then  { do not localize }
                        begin
                          Inc(Sp, 4);
                          Rp^ := ' ';
                        end;
                   'q': if AnsiStrPos(Sp, 'quot;') = Sp then  { do not localize }
                        begin
                          Inc(Sp,4);
                          Rp^ := '"';
                        end;
                   '#': begin
                          Tp := Sp;
                          Inc(Tp);
                          while (Sp^ <> ';') and (Sp^ <> #0) do
                            Inc(Sp);
                          SetString(S, Tp, Sp - Tp);
                          Val(S, I, Code);
                          Rp^ := Chr((I));
                        end;
                   else
                     Exit;
                 end;
             end
        else
          Rp^ := Sp^;
        end;
        Inc(Rp);
        Inc(Sp);
      end;
    except
    end;
    SetLength(Result, Rp - PChar(Result));
  end;

{ TMyApplication }

procedure TMyApplication.TgMessage(ASender: TObject;
  AMessage: TTelegramMessageObj);
var
  jparser: TJSONParser;
  jObj2, jobj3, jobj4: TJSONData;
  auxStr: UTF8String;
  response: Utf8STring;
begin
  if (AMessage.Chat.ID=Conf.Telegram.ChatID) then begin

    try
      response:=TFPHTTPClient.SimpleGet('https://translation.googleapis.com/language/translate/v2?key='+Conf.Google.APIKey+'&q='+EncodeURLElement(AMessage.Text)+'&target=pt');
      if response<>'' then
        try
          jparser:=TJSONParser.Create(response);
          jObj2:=jparser.Parse;
          jobj3:=jobj2.FindPath('data.translations[0].detectedSourceLanguage');
          jobj4:=jobj2.FindPath('data.translations[0].translatedText');
          if Assigned(jobj3) and (jobj3.AsString<>'pt') and Assigned(jobj4) then begin
            MsgQueued:=true;
            auxStr:=UTF8Encode(jobj4.AsString);
            auxStr:=HTMLDecode(auxStr);
            auxStr:=StringReplace(auxStr,'\','\\',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'_','\_',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'*','\*',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'[','\[',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,']','\]',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'(','\(',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,')','\)',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'{','\{',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'}','\}',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'#','\#',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'`','\`',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'+','\+',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'-','\-',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'.','\.',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'!','\!',[rfReplaceAll]);

            Msgs:=Msgs+'['+UTF8Encode(AMessage.From.First_name)+'](tg://user?id='+UTF8Encode(AMessage.From.ID.ToString)+') [escreveu](https://t.me/'+AMessage.Chat.Username+'/'+UTF8Encode(AMessage.MessageId.ToString)+'): '+auxStr+LineEnding+LineEnding;
          end;
        finally
          FreeAndNil(jparser);
          FreeAndNil(jObj2);
        end;
    finally
    end;

    try
      response:=TFPHTTPClient.SimpleGet('https://translation.googleapis.com/language/translate/v2?key='+Conf.Google.APIKey+'&q='+EncodeURLElement(AMessage.Text)+'&target=en');
      if response<>'' then
        try
          jparser:=TJSONParser.Create(response);
          jObj2:=jparser.Parse;
          jobj3:=jobj2.FindPath('data.translations[0].detectedSourceLanguage');
          jobj4:=jobj2.FindPath('data.translations[0].translatedText');
          if Assigned(jobj3) and (jobj3.AsString<>'en') and Assigned(jobj4) then begin
            MsgQueued:=true;
            auxStr:=jobj4.AsString;
            auxStr:=HTMLDecode(auxStr);
            auxStr:=StringReplace(auxStr,'\','\\',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'_','\_',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'*','\*',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'[','\[',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,']','\]',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'(','\(',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,')','\)',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'{','\{',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'}','\}',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'#','\#',[rfReplaceAll]);
            auxStr:=StringReplace(auxStr,'`','\`',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'+','\+',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'-','\-',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'.','\.',[rfReplaceAll]);
            //auxStr:=StringReplace(auxStr,'!','\!',[rfReplaceAll]);

            Msgs:=Msgs+'['+UTF8Encode(AMessage.From.First_name)+'](tg://user?id='+UTF8Encode(AMessage.From.ID.ToString)+') [wrote](https://t.me/'+AMessage.Chat.Username+'/'+UTF8Encode(AMessage.MessageId.ToString)+'): '+UTF8Encode(auxStr)+LineEnding+LineEnding;
          end;
        finally
          FreeAndNil(jparser);
          FreeAndNil(jObj2);
        end;
    finally

    end;
  end;
end;

procedure TMyApplication.DoRun;
var
  TgBot:TTelegramSender = nil;

procedure SetupBot;
begin
  TgBot:=TTelegramSender.Create(Conf.Telegram.APIToken);
  TgBot.OnReceiveMessage:=@TgMessage;
end;

begin
  if not FileExists(ConfFile) then
  begin
    WriteLn('Please fill in the settings file! '+ConfFile);
    ReadLn;
    SaveToJSON(Conf, ConfFile);
    Terminate;
    Exit;
  end;
  while true do begin
    try
      if not Assigned(TgBot) then SetupBot;
      if TgBot.getUpdatesEx(0,0,[utMessage]) and MsgQueued then begin
        if TgBot.sendMessage(Conf.Telegram.ChatID, Msgs, pmMarkdown, true) then begin
          Msgs:='';
          MsgQueued:=false;
        end else begin
          WriteLn(Msgs);
          writeln(TgBot.LastErrorCode);
          writeln(TgBot.LastErrorDescription);
          WriteLn(TgBot.CurrentUpdate.AsString);
        end;
        if Conf.Telegram.SleepTime>0 then
          Sleep(Conf.Telegram.SleepTime);
      end;
    except
      FreeAndNil(TgBot);
    end;
  end;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='My Application';
  Application.Run;
  Application.Free;
end.

