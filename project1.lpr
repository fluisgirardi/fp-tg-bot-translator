program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, openssl, opensslsockets, fpopenssl, tgsendertypes, tgtypes,
  CustApp, fpjson, jsonparser, StrUtils, fphttpclient
  { you can add units after this };

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  private
    MsgQueued:Boolean;
    Msgs:UTF8String;
    procedure TgMessage(ASender: TObject; AMessage: TTelegramMessageObj);
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
const 
  gtranslatorAPI_key = 'Your Google translator API Key goes here!';
begin
  if (AMessage.Chat.ID=-1001271631027) then begin

    try
      response:=TFPHTTPClient.SimpleGet('https://translation.googleapis.com/language/translate/v2?key='+gtranslatorAPI_key+'&q='+EncodeURLElement(AMessage.Text)+'&target=pt');
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

            Msgs:=Msgs+'['+UTF8Encode(AMessage.From.First_name)+'](tg://user?id='+UTF8Encode(AMessage.From.ID.ToString)+') [escreveu](https://t.me/pascalscada/'+UTF8Encode(AMessage.MessageId.ToString)+'): '+auxStr+LineEnding+LineEnding;
          end;
        finally
          FreeAndNil(jparser);
          FreeAndNil(jObj2);
        end;
    finally
    end;

    try
      response:=TFPHTTPClient.SimpleGet('https://translation.googleapis.com/language/translate/v2?key=AIzaSyBGD_JOdlWhwHlGmi7V--WJi1BV5RlWXOk&q='+EncodeURLElement(AMessage.Text)+'&target=en');
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

            Msgs:=Msgs+'['+UTF8Encode(AMessage.From.First_name)+'](tg://user?id='+UTF8Encode(AMessage.From.ID.ToString)+') [wrote](https://t.me/pascalscada/'+UTF8Encode(AMessage.MessageId.ToString)+'): '+UTF8Encode(auxStr)+LineEnding+LineEnding;
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
const
  tbbotapi = 'your Telegram Bot API key goes here';
  tgchartID = -1001271631027; //ID of the group/person where translated messages will be sent.

procedure SetupBot;
begin
  TgBot:=TTelegramSender.Create(tbbotapi);
  TgBot.OnReceiveMessage:=@TgMessage;
end;

begin
  while true do begin
    try
      if not Assigned(TgBot) then SetupBot;
      if TgBot.getUpdatesEx(0,0,[utMessage]) and MsgQueued then begin
        if TgBot.sendMessage(tgchartID, Msgs, pmMarkdown, true) then begin
          Msgs:='';
          MsgQueued:=false;
        end else begin
          WriteLn(Msgs);
          writeln(TgBot.LastErrorCode);
          writeln(TgBot.LastErrorDescription);
          WriteLn(TgBot.CurrentUpdate.AsString);
        end;
        Sleep(3000);
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

