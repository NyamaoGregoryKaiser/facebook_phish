unit uInstaller;

interface

uses
System.SysUtils, System.Classes, System.Net.HttpClientComponent,
System.Net.HttpClient, System.JSON, System.NetEncoding,Vcl.Forms,
Vcl.StdCtrls,System.IOUtils,Vcl.Dialogs,  System.UITypes,Vcl.Graphics,
Data.DB, Data.Win.ADODB, Grijjy.CloudLogging;

type
  TFileItem = record
    URL: string;
    LocalVersion: string;
    Descr: string;
    Mandatory: Boolean;
  end;

  TInstaller = class(TObject)

  public

    procedure DownloadFile(const URL, SavePath: string);
    procedure LoadFileItems(const FilePath: string;
    var aFileItems: TArray<TFileItem>);
    procedure LicenseDownload(const LicenseID: string);
    procedure InitializeLogger ;//For logging errors
    function FetchUpdateFile: Boolean;
    function FetchVersionNo: String;

  end;

implementation

{ TInstaller }

const
  ConfigFilePath = 'update.txt';
  DownloadFolder = '';
  clicenseFile = 'e-prod.lic';
  // URL for POST Request
  ServerURL =
    'https://test-dev.api-eprod-solutions.com:9696/version/getdownloadlocation';
  VersionURL = 'https://test-dev.api-eprod-solutions.com:9696/version/check/';

  // Credentials for Basic Authorization
  Username = 'admin';
  Password = 'eprod';


procedure TInstaller.InitializeLogger;  //Logging function
const
  ServerAddress = 'tcp://localhost:7337';
  AppID = 'mantra';
begin
  try
    GrijjyLog.Connect(ServerAddress, AppID);
    GrijjyLog.Send('Logger initialized successfully');


  except
    on E: Exception do
      ShowMessage('Failed to initialize logger: ' + E.Message);
  end;
end;

procedure TInstaller.DownloadFile(const URL, SavePath: string);
var
  HttpClient: TNetHTTPClient;
  HttpResponse: IHTTPResponse;
  FileStream: TFileStream;
begin
  GrijjyLog.Send('Download has started Hurray !!!!!!');
  HttpClient := TNetHTTPClient.Create(nil);
  try
    HttpResponse := HttpClient.Get(URL);
    if HttpResponse.StatusCode = 200 then
    begin
      FileStream := TFileStream.Create(SavePath, fmCreate);
      try
        FileStream.CopyFrom(HttpResponse.ContentStream, 0);
        // MemoLog.Lines.Add(Format('Downloaded: %s',[ SavePath]));


      finally
        FileStream.Free;
      end;

    end
    else
      // MemoLog.Lines.Add('Failed to download: ' + URL);
    finally
      HttpClient.Free;
    end;


  end;

function TInstaller.FetchUpdateFile: Boolean;
  var
    HttpClient: TNetHTTPClient;
    HttpRequest: TNetHTTPRequest;
    HttpResponse: IHTTPResponse;
    JsonToSend, ResponseContent: string;
    JsonValue: TJSONObject;
    DownloadLocation: string;
    FileStream: TFileStream;

    VersionNo: string;
  begin
    Result := False;

    // Fetch version number
    VersionNo := FetchVersionNo;

    if VersionNo = '' then
    begin
      ShowMessage('Failed to fetch version number.');
      GrijjyLog.Send('Failed to fetch version number', TgoLogLevel.Error);
      Exit;
    end;

    // Continue with fetching update file if version no is sent back
    HttpClient := TNetHTTPClient.Create(nil);
    HttpRequest := TNetHTTPRequest.Create(nil);
    try
      HttpRequest.Client := HttpClient;
      HttpRequest.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64.Encode(Username + ':' + Password);
      HttpRequest.CustomHeaders['Content-Type'] := 'application/json';

      JsonToSend := '{"versionno":"' + VersionNo +'","application":"eProd Desktop"}';
      HttpResponse := HttpRequest.Post(ServerURL,
      TStringStream.Create(JsonToSend));

      if HttpResponse.StatusCode = 200 then
      begin
        ResponseContent := HttpResponse.ContentAsString();
        JsonValue := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject;
        try
          if JsonValue.GetValue<string>('result') = 'OK' then
          begin
            DownloadLocation := JsonValue.GetValue<string>('downloadlocation');

            HttpResponse := HttpClient.Get(DownloadLocation);
            if HttpResponse.StatusCode = 200 then
            begin
              FileStream := TFileStream.Create(ConfigFilePath, fmCreate);
              try
                FileStream.CopyFrom(HttpResponse.ContentStream, 0);
                Result := True;
              finally
                FileStream.Free;
              end;
            end
            else
               ShowMessage('Failed to download update file');
          end
          else
            JsonValue.GetValue<string>('result');
        finally
          JsonValue.Free;
        end;
      end
       else
        ShowMessage('Failed to get update file location.');
        GrijjyLog.Send('Failed to get update file location.', TgoLogLevel.Error);
    finally
      HttpRequest.Free;
      HttpClient.Free;
    end;
  end;

function TInstaller.FetchVersionNo: String;

  var
    HttpClient: TNetHTTPClient;
    HttpRequest: TNetHTTPRequest;
    HttpResponse: IHTTPResponse;
    JsonToSend, ResponseContent: string;
    JsonValue: TJSONObject;
    LicenseID: String;

    Error: String;
    DisplayError: String;

  begin
    Result := '';
    Error := '';

    // Prompt the user to input the license ID

    if not InputQuery('Enter License ID', 'License ID:', LicenseID) then
    begin
      ShowMessage('License ID input cancelled.');
      Application.Terminate;//closes the application
    end;

    HttpClient := TNetHTTPClient.Create(nil);
    HttpRequest := TNetHTTPRequest.Create(nil);
    try
      HttpRequest.Client := HttpClient;
      HttpRequest.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64.Encode(Username + ':' + Password);
      HttpRequest.CustomHeaders['Content-Type'] := 'application/json';


      JsonToSend :=' {"application": "eProd App 32bit","userdb": "user_db","device":"testlaptop","user":"user1", "versionno": "20200101","licenseid": "'+ LicenseID + '"}';
      HttpResponse := HttpRequest.Post(VersionURL,
      TStringStream.Create(JsonToSend));

      if HttpResponse.StatusCode = 200 then
      begin
        ResponseContent := HttpResponse.ContentAsString();
        JsonValue := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject;

        Error := JsonValue.GetValue<string>('result');
        if Error = 'NOK' then
        begin
          DisplayError := JsonValue.GetValue<string>('error');
          ShowMessage(DisplayError);
          Application.Terminate; // ends the program

        end
        else

          try
            Result := JsonValue.GetValue<string>('version');
            LicenseDownload(LicenseID);
          finally
            JsonValue.Free;
          end;
      end
      else
        ShowMessage('Failed to fetch version number.');
        GrijjyLog.Send('Failed to fetch version no.', TgoLogLevel.Error);

    finally
      HttpRequest.Free;
      HttpClient.Free;
    end;
  end;

procedure TInstaller.LicenseDownload(const LicenseID: string); //function to get licence value and store in txt

  var
    FileStream: TFileStream;
    LicValue: string;
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;

  begin
    ADOConnection1 := TADOConnection.Create(nil);
    ADOQuery1 := TADOQuery.Create(nil);
    ADOConnection1.ConnectionString :='Provider=MSDASQL.1;Persist Security Info=False;Data Source=eprod;Initial Catalog=eprod_release3';
    ADOConnection1.LoginPrompt := False;

    try
      // Connects to the database
      ADOConnection1.Connected := True;

      // Set up and execute the query
      ADOQuery1.Connection := ADOConnection1;
      ADOQuery1.SQL.Text := 'SELECT lic_value FROM license WHERE lic_id = ' +LicenseID;
      ADOQuery1.Open;

      // lic_value is retrived from the query result
      if not ADOQuery1.Eof then
      begin
        LicValue := ADOQuery1.FieldByName('lic_value').AsString;

        // Creation of a file stream to save the result
        FileStream := TFileStream.Create(clicenseFile, fmCreate);
        try
          FileStream.WriteBuffer(Pointer(LicValue)^, Length(LicValue));
        finally
          FileStream.Free;
        end;
      end
      else
      begin
        ShowMessage('No license found for the specified ID.');
        GrijjyLog.Send('No license found for the specified ID.', TgoLogLevel.Error);
      end;

    except
      on E: Exception do
      begin
        ShowMessage('An error occurred: ' + E.Message);
      end;
    end;

    // Close the connection
    ADOConnection1.Connected := False;
  end;

  Procedure TInstaller.LoadFileItems(const FilePath: string;
 var aFileItems: TArray<TFileItem>);

  var
    Lines: TStringList;
    Line: string;
    CurrentItem: TFileItem;
    I: Integer;

  begin
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FilePath);

      SetLength(aFileItems, 0);

      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        if Line.StartsWith('[file') then
        begin
          if CurrentItem.URL <> '' then
          begin
            SetLength(aFileItems, Length(aFileItems) + 1);
            aFileItems[High(aFileItems)] := CurrentItem;
          end;
          CurrentItem := Default (TFileItem);
        end
        else if Line.StartsWith('url=') then
          CurrentItem.URL := Copy(Line, 5, MaxInt)
        else if Line.StartsWith('localversion=') then
          CurrentItem.LocalVersion := Copy(Line, 14, MaxInt);
        if CurrentItem.LocalVersion = 'epprodsys.exe' then
        begin
          CurrentItem.LocalVersion := 'epprodsys.cab';
        end

        else if Line.StartsWith('descr=') then
          CurrentItem.Descr := Copy(Line, 7, MaxInt)
        else if Line.StartsWith('mandatory=') then
          CurrentItem.Mandatory := Copy(Line, 11, MaxInt) = '1';
      end;

      if CurrentItem.URL <> '' then
      begin
        SetLength(aFileItems, Length(aFileItems) + 1);
        aFileItems[High(aFileItems)] := CurrentItem;
      end;

    finally
      Lines.Free;
    end;
  end;

end.
