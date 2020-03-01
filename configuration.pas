unit configuration;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TTelegramConfig }

  TTelegramConfig = class
  private
    FAPIToken: String;
    FChatId: Int64;
    FSleepTime: Integer;
  published
    property ChatID: Int64 read FChatId write FChatID;
    property APIToken: String read FAPIToken write FAPIToken;
    property SleepTime: Integer read FSleepTime write FSleepTime;
  end;

  { TGoogleConfig }

  TGoogleConfig = class
  private
    FAPIKey: String;
  published
    property APIKey: String read FAPIKey write FAPIKey;
  end;

  { TConfig }

  TConfig = class
  private
    FGoogleConfig: TGoogleConfig;
    FTelegramConfig: TTelegramConfig;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Telegram: TTelegramConfig read FTelegramConfig write FTelegramConfig;
    property Google: TGoogleConfig read FGoogleConfig write FGoogleConfig;
  end;

var
  Conf: TConfig;
  ConfFile: String;

procedure SaveToJSON(AObject: TObject; const AFileName: String);

implementation

uses
  fpjson, fpjsonrtti
  ;

procedure LoadFromJSON(AObject: TObject; const AFileName: String);
var
  ADeStreamer: TJSONDeStreamer;
  AJSON: TStringList;
begin
  ADeStreamer:=TJSONDeStreamer.Create(nil);
  AJSON:=TStringList.Create;
  try
    try
      AJSON.LoadFromFile(AFileName);
      ADeStreamer.JSONToObject(AJSON.Text, AObject);
    except
    end;
  finally
    AJSON.Free;
    ADeStreamer.Free;
  end;
end;

procedure SaveToJSON(AObject: TObject; const AFileName: String);
var
  AStreamer: TJSONStreamer;
  AJSON: TStringList;
  AJSONObject: TJSONObject;
begin
  AStreamer:=TJSONStreamer.Create(nil);
  AJSON:=TStringList.Create;
  AJSONObject:=AStreamer.ObjectToJSON(AObject);
  try
    try
      AJSON.Text:=AJSONObject.FormatJSON();
    except
    end;
    AJSON.SaveToFile(AFileName);
  finally
    AJSONObject.Free;
    AJSON.Free;
    AStreamer.Free;
  end;
end;

{ TConfig }

constructor TConfig.Create;
begin
  FTelegramConfig:=TTelegramConfig.Create;
  FGoogleConfig:=TGoogleConfig.Create;
end;

destructor TConfig.Destroy;
begin
  FGoogleConfig.Free;
  FTelegramConfig.Free;
  inherited Destroy;
end;

initialization
  ConfFile:=ChangeFileExt(ParamStr(0), '.json'); // full path and name can be other
  Conf:=TConfig.Create;
  LoadFromJSON(Conf, ConfFile);

finalization
  Conf.Free;

end.

