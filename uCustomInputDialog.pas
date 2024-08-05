unit uCustomInputDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.RegularExpressions;

type
  TForm4 = class(TForm)
    Edit1: TEdit;
    Button1: TButton; // OK Button
    Button2: TButton; // Cancel Button
    Label1: TLabel;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);// Handle input change event
    procedure Edit1Change(Sender: TObject); // Form create event
  private
    function IsInputValid: Boolean; // Validation function
  public
    class function Execute(const ATitle, APrompt: string; out AValue: string): Boolean;
  end;

implementation

{$R *.dfm}

class function TForm4.Execute(const ATitle, APrompt: string; out AValue: string): Boolean;
var
  Form: TForm4; // Local instance of TForm2
begin
  Form := TForm4.Create(nil); // Create the form instance dynamically
  try
    Form.Caption := ATitle;
    Form.Label1.Caption := APrompt;
    Form.Edit1.Text := ''; // Clear previous input
    Form.Button1.Enabled := False; // Disable the OK button by default

    Result := Form.ShowModal = mrOk;
    if Result then
      AValue := Form.Edit1.Text;
  finally
    Form.Free; // Free the form instance after use
  end;
end;

// Function to validate the input
function TForm4.IsInputValid: Boolean;
begin
  // Ensure the input is exactly 3 numeric characters
  Result := (Length(Edit1.Text) = 3) and TRegEx.IsMatch(Edit1.Text, '^\d+$');
end;


procedure TForm4.Edit1Change(Sender: TObject);
begin
  // Update the label to show the current input


  // Enable/disable the OK button based on the validity of the input
  Button1.Enabled := IsInputValid;
end;

 procedure TForm4.FormCreate(Sender: TObject);
begin
  Button1.Enabled := False;

end;



procedure TForm4.Button1Click(Sender: TObject);
begin

  if IsInputValid then
  begin
    ModalResult := mrOk;
  end
  else
  begin
    ShowMessage('Please enter exactly 3 numeric characters.');
  end;
end;


procedure TForm4.Button2Click(Sender: TObject);
begin
//Label2.Caption := 'Current input: ';
  ModalResult := mrCancel; // Cancel button action
  Exit
end;


end.
