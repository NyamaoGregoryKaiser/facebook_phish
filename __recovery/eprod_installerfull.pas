unit eprod_installerfull;

interface
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ComCtrls,System.IOUtils, System.UITypes,Vcl.Dialogs, System.Zip,
  ShellAPI, Windows,uInstaller,Vcl.FileCtrl;

type
  TForm1 = class(TForm)
    // Form components
    ButtonDownload: TButton;
    ProgressBar: TProgressBar;
    MemoLog: TMemo;
    sbFiles: TScrollBox;
    procedure ButtonDownloadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FDownloadedCount: Integer;
    FCheckBoxes: TArray<TCheckBox>;
    FInstller: TInstaller;
    FDownloadFolder: string;
    procedure IncrementProgressBar;
    procedure CreateCheckBoxes;
    procedure SelectDownloadFolder;

  public
    LicenseID: string;
    FFileItems: TArray<TFileItem>;
    Procedure AfterConstruction; override;
  end;

var
  Form1: TForm1;
  FileStream: TFileStream;
  StringList: TStringList;
implementation
{$R *.dfm}
const
  ConfigFilePath = 'update.txt';
  DownloadFolder = '';
  clicenseFile = 'e-prod.lic';

  // URL for POST Request
  ServerURL =
    'https://test-dev.api-eprod-solutions.com:9696/version/getdownloadlocation';
  VersionURL = 'https://test-dev.api-eprod-solutions.com:9696/version/check/';

procedure TForm1.AfterConstruction;
begin
  inherited;
end;
procedure TForm1.SelectDownloadFolder;  //Added function for selecting folder to download to
var
  Dialog: TFileOpenDialog;
const
  DownloadFolder = '';
begin
  Dialog := TFileOpenDialog.Create(nil);
  try
    Dialog.Options := [fdoPickFolders];
    Dialog.DefaultFolder := DownloadFolder; // default folder is set
    if Dialog.Execute then
      FDownloadFolder := Dialog.FileName
    else
      FDownloadFolder := DownloadFolder; // Use default folder if no selection is made
  finally
    Dialog.Free;
  end;
end;
procedure TForm1.ButtonDownloadClick(Sender: TObject);
var
  I: Integer;
  FolderOpen: Integer;
  DownloadPath: string;
begin
  FDownloadedCount := 0;
  ProgressBar.Position := 0;
  ProgressBar.Max := Length(FCheckBoxes); // Set the maximum value to the number of checkboxes (files)
   SelectDownloadFolder;
  for I := 0 to High(FCheckBoxes) do
  begin
    if FCheckBoxes[I].Checked then
    begin
      DownloadPath := TPath.Combine(FDownloadFolder, FFileItems[I].LocalVersion);
      FInstller.DownloadFile(FFileItems[I].URL, DownloadPath);
      MemoLog.Lines.Add(Format('Downloaded: %s', [DownloadPath]));
      IncrementProgressBar;  // Increment progress after each file download
    end;
  end;

  // Ensure the progress bar reaches max at the end
  ProgressBar.Position := ProgressBar.Max;

  if FileExists(ConfigFilePath) then
  begin
    if DeleteFile(ConfigFilePath) then
    begin
      MemoLog.Lines.Add('Update file deleted successfully.');
      FolderOpen := MessageDlg('Successfully Downloaded' + #13#10 + 'Do you want to open the folder?', mtConfirmation, [mbYes, mbNo], 0);
      if FolderOpen = mrYes then
      begin
         ShellExecute(Application.Handle, 'open', PChar(FDownloadFolder), nil, nil, SW_SHOWNORMAL);
        Application.Terminate;
      end
      else if FolderOpen = mrNo then
      begin
       Application.Terminate;
      end;
    end
    else
      MemoLog.Lines.Add('Failed to delete the update file.');
  end;
end;

procedure TForm1.IncrementProgressBar;
begin
  Inc(FDownloadedCount);
  ProgressBar.Position := FDownloadedCount;
end;


procedure TForm1.FormCreate(Sender: TObject);
// program starts from here on loading
begin

 FInstller := TInstaller.Create;
 FInstller.InitializeLogger;

  if FInstller.FetchUpdateFile then // if True
  begin
    FInstller.LoadFileItems(ConfigFilePath,FFileItems); // calls LoadFileItems function
    CreateCheckBoxes; // then the next function call
  end
  else
    MemoLog.Lines.Add('Failed to fetch the update file.');
end;

procedure TForm1.CreateCheckBoxes;
var
  I: Integer;
  CheckBox: TCheckBox;
begin
  for I := 0 to High(FFileItems) do
  begin
    CheckBox := TCheckBox.Create(Self);
    CheckBox.Parent := sbFiles;
    CheckBox.Caption := FFileItems[I].Descr;
    CheckBox.Top := I * 25;
    CheckBox.Left := 10;
    CheckBox.Width := sbFiles.Width - 20;
    if FFileItems[I].Mandatory then
    begin
      CheckBox.Checked := True;
      CheckBox.Enabled := False;
    end
    else
    begin
      CheckBox.Checked := True; // Checked by default
      CheckBox.Enabled := True;
    end;
    SetLength(FCheckBoxes, Length(FCheckBoxes) + 1);
    FCheckBoxes[High(FCheckBoxes)] := CheckBox;
  end;
end;



end. // end for main peogram

