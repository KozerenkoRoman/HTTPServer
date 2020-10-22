object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'HTTP-server'
  ClientHeight = 466
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 635
    Height = 73
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 24
      Height = 13
      Caption = 'Port:'
    end
    object lblIpAddress: TLabel
      Left = 136
      Top = 8
      Width = 3
      Height = 13
    end
    object btnStart: TButton
      Left = 8
      Top = 40
      Width = 105
      Height = 25
      Caption = 'Start / Stop'
      TabOrder = 0
      OnClick = btnStartClick
    end
    object edPort: TSpinEdit
      Left = 38
      Top = 5
      Width = 75
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 1
      Value = 8080
    end
  end
  object lbLog: TListBox
    Left = 0
    Top = 73
    Width = 635
    Height = 393
    Align = alClient
    ItemHeight = 13
    TabOrder = 1
  end
end
