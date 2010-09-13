object frmPropSettings: TfrmPropSettings
  Left = 357
  Top = 177
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'Settings'
  ClientHeight = 320
  ClientWidth = 416
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TabControl1: TTabControl
    Left = 8
    Top = 8
    Width = 401
    Height = 305
    TabOrder = 0
    object GroupBox1: TGroupBox
      Left = 16
      Top = 76
      Width = 369
      Height = 49
      Caption = ' Metatag '
      TabOrder = 0
      object Label8: TLabel
        Left = 16
        Top = 20
        Width = 337
        Height = 13
        AutoSize = False
        ParentShowHint = False
        PopupMenu = PopupMenu2
        ShowAccelChar = False
        ShowHint = True
      end
    end
    object GroupBox2: TGroupBox
      Left = 16
      Top = 200
      Width = 369
      Height = 89
      Caption = ' Export Stream '
      Enabled = False
      TabOrder = 1
      object Label3: TLabel
        Left = 16
        Top = 60
        Width = 337
        Height = 13
        AutoSize = False
        ParentShowHint = False
        ShowAccelChar = False
        ShowHint = True
      end
      object Button2: TButton
        Left = 16
        Top = 24
        Width = 89
        Height = 25
        Caption = 'Start writing'
        Enabled = False
        TabOrder = 0
        OnClick = Button2Click
      end
      object Button3: TButton
        Left = 120
        Top = 24
        Width = 89
        Height = 25
        Caption = 'Stop writing'
        Enabled = False
        TabOrder = 1
        OnClick = Button3Click
      end
      object CheckBox1: TCheckBox
        Left = 222
        Top = 28
        Width = 137
        Height = 17
        Caption = 'Split Stream on new Tag'
        Enabled = False
        TabOrder = 2
        OnClick = CheckBox1Click
      end
    end
    object GroupBox3: TGroupBox
      Left = 16
      Top = 16
      Width = 369
      Height = 49
      Caption = ' Stream '
      TabOrder = 2
      object Label1: TLabel
        Left = 16
        Top = 20
        Width = 337
        Height = 13
        AutoSize = False
        ParentShowHint = False
        PopupMenu = PopupMenu1
        ShowAccelChar = False
        ShowHint = True
      end
    end
    object GroupBox4: TGroupBox
      Left = 16
      Top = 136
      Width = 369
      Height = 53
      Caption = ' Shoutcast Buffer '
      TabOrder = 3
      object Label4: TLabel
        Left = 16
        Top = 24
        Width = 49
        Height = 13
        Caption = 'Prebuffer '
      end
      object Label5: TLabel
        Left = 136
        Top = 24
        Width = 13
        Height = 13
        Caption = 'ms'
      end
      object Label6: TLabel
        Left = 160
        Top = 24
        Width = 48
        Height = 13
        Caption = 'Buffersize'
      end
      object Label7: TLabel
        Left = 280
        Top = 24
        Width = 13
        Height = 13
        Caption = 'ms'
      end
      object SpinEdit1: TSpinEdit
        Left = 72
        Top = 19
        Width = 57
        Height = 22
        MaxValue = 5000
        MinValue = 100
        TabOrder = 0
        Value = 100
        OnChange = SpinEdit1Change
      end
      object SpinEdit2: TSpinEdit
        Left = 216
        Top = 19
        Width = 57
        Height = 22
        MaxValue = 5000
        MinValue = 100
        TabOrder = 1
        Value = 100
        OnChange = SpinEdit2Change
      end
      object Button1: TButton
        Left = 306
        Top = 19
        Width = 49
        Height = 22
        Caption = 'Default'
        TabOrder = 2
        OnClick = Button1Click
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 376
    Top = 184
  end
  object PopupMenu1: TPopupMenu
    Left = 368
    Top = 40
    object CopytoClipboard1: TMenuItem
      Caption = 'Copy to Clipboard'
      OnClick = CopytoClipboard1Click
    end
  end
  object PopupMenu2: TPopupMenu
    Left = 368
    Top = 96
    object MenuItem1: TMenuItem
      Caption = 'Copy to Clipboard'
      OnClick = MenuItem1Click
    end
  end
end
