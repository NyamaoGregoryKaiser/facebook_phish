object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'eprod-instalation'
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object sbFiles: TScrollBox
    Left = 0
    Top = 0
    Width = 273
    Height = 400
    Align = alLeft
    Color = clGradientActiveCaption
    ParentColor = False
    TabOrder = 0
    ExplicitHeight = 399
  end
  object MemoLog: TMemo
    Left = 402
    Top = 0
    Width = 226
    Height = 400
    Align = alRight
    Color = clGradientInactiveCaption
    Lines.Strings = (
      '')
    TabOrder = 1
    ExplicitLeft = 398
    ExplicitHeight = 399
  end
  object ProgressBar: TProgressBar
    Left = 0
    Top = 400
    Width = 628
    Height = 42
    Align = alBottom
    BarColor = clFuchsia
    BackgroundColor = clYellow
    TabOrder = 2
    ExplicitTop = 399
    ExplicitWidth = 624
  end
  object ButtonDownload: TButton
    Left = 279
    Top = 160
    Width = 104
    Height = 73
    Caption = 'Download'
    TabOrder = 3
    OnClick = ButtonDownloadClick
  end
end
