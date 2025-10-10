object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'GeoMap Component - Basic Demo'
  ClientHeight = 661
  ClientWidth = 1084
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object GeoMap1: TGeoMapVCL
    Left = 193
    Top = 0
    Width = 891
    Height = 642
    ZoomLevel = 1.100000023841858000
    OnMarkerClick = GeoMap1MarkerClick
    OnCountryClick = GeoMap1CountryClick
    OnCountryHover = GeoMap1CountryHover
    Align = alClient
    ParentColor = False
    TabOrder = 0
  end
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 193
    Height = 642
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 56
      Width = 52
      Height = 13
      Caption = 'Projection:'
    end
    object Label2: TLabel
      Left = 16
      Top = 168
      Width = 43
      Height = 13
      Caption = 'Latitude:'
    end
    object Label3: TLabel
      Left = 16
      Top = 192
      Width = 51
      Height = 13
      Caption = 'Longitude:'
    end
    object Label4: TLabel
      Left = 16
      Top = 216
      Width = 41
      Height = 13
      Caption = 'Caption:'
    end
    object Label5: TLabel
      Left = 16
      Top = 304
      Width = 71
      Height = 13
      Caption = 'Country Code:'
    end
    object ButtonLoadMap: TButton
      Left = 16
      Top = 16
      Width = 161
      Height = 25
      Caption = 'Load Map...'
      TabOrder = 0
      OnClick = ButtonLoadMapClick
    end
    object ButtonAddMarker: TButton
      Left = 16
      Top = 240
      Width = 161
      Height = 25
      Caption = 'Add Marker by Coordinates'
      TabOrder = 1
      OnClick = ButtonAddMarkerClick
    end
    object ButtonZoomIn: TButton
      Left = 16
      Top = 480
      Width = 75
      Height = 25
      Caption = 'Zoom In'
      TabOrder = 2
      OnClick = ButtonZoomInClick
    end
    object ButtonZoomOut: TButton
      Left = 102
      Top = 480
      Width = 75
      Height = 25
      Caption = 'Zoom Out'
      TabOrder = 3
      OnClick = ButtonZoomOutClick
    end
    object ButtonReset: TButton
      Left = 16
      Top = 512
      Width = 161
      Height = 25
      Caption = 'Reset View'
      TabOrder = 4
      OnClick = ButtonResetClick
    end
    object ComboProjection: TComboBox
      Left = 16
      Top = 80
      Width = 161
      Height = 21
      Style = csDropDownList
      TabOrder = 5
      OnChange = ComboProjectionChange
    end
    object CheckBorders: TCheckBox
      Left = 16
      Top = 112
      Width = 161
      Height = 17
      Caption = 'Show Country Borders'
      Checked = True
      State = cbChecked
      TabOrder = 6
      OnClick = CheckBordersClick
    end
    object CheckLabels: TCheckBox
      Left = 16
      Top = 136
      Width = 161
      Height = 17
      Caption = 'Show Marker Labels'
      Checked = True
      State = cbChecked
      TabOrder = 7
      OnClick = CheckLabelsClick
    end
    object EditLat: TEdit
      Left = 88
      Top = 165
      Width = 89
      Height = 21
      TabOrder = 8
      Text = '40.7128'
    end
    object EditLon: TEdit
      Left = 88
      Top = 189
      Width = 89
      Height = 21
      TabOrder = 9
      Text = '-74.0060'
    end
    object EditCaption: TEdit
      Left = 88
      Top = 213
      Width = 89
      Height = 21
      TabOrder = 10
      Text = 'New York'
    end
    object EditCountryCode: TEdit
      Left = 16
      Top = 323
      Width = 161
      Height = 21
      TabOrder = 11
      Text = 'usa'
    end
    object ButtonHighlight: TButton
      Left = 16
      Top = 352
      Width = 161
      Height = 25
      Caption = 'Highlight Country...'
      TabOrder = 12
      OnClick = ButtonHighlightClick
    end
    object ButtonClearMarkers: TButton
      Left = 16
      Top = 384
      Width = 161
      Height = 25
      Caption = 'Clear All Markers'
      TabOrder = 13
      OnClick = ButtonClearMarkersClick
    end
    object ButtonClearHighlights: TButton
      Left = 16
      Top = 416
      Width = 161
      Height = 25
      Caption = 'Clear Country Highlights'
      TabOrder = 14
      OnClick = ButtonClearHighlightsClick
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 642
    Width = 1084
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Panel1: TPanel
    Left = 16
    Top = 272
    Width = 161
    Height = 17
    BevelOuter = bvNone
    Caption = 'Country Operations'
    Color = clActiveCaption
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 3
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'geojson'
    Filter = 
      'GeoJSON Files (*.geojson;*.json)|*.geojson;*.json|All Files (*.*' +
      ')|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 232
    Top = 24
  end
  object ColorDialog1: TColorDialog
    Left = 304
    Top = 24
  end
end
