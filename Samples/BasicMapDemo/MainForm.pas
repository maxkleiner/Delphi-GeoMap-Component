unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  GeoMap.VCL, GeoMap.Types, GeoMap.Markers;

type
  TFormMain = class(TForm)
    GeoMap1: TGeoMapVCL;
    PanelTop: TPanel;
    ButtonLoadMap: TButton;
    ButtonAddMarker: TButton;
    ButtonZoomIn: TButton;
    ButtonZoomOut: TButton;
    ButtonReset: TButton;
    ComboProjection: TComboBox;
    Label1: TLabel;
    CheckBorders: TCheckBox;
    CheckLabels: TCheckBox;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Label2: TLabel;
    EditLat: TEdit;
    Label3: TLabel;
    EditLon: TEdit;
    EditCaption: TEdit;
    Label4: TLabel;
    EditCountryCode: TEdit;
    Label5: TLabel;
    ButtonHighlight: TButton;
    ButtonClearMarkers: TButton;
    ButtonClearHighlights: TButton;
    ColorDialog1: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure ButtonLoadMapClick(Sender: TObject);
    procedure ButtonAddMarkerClick(Sender: TObject);
    procedure ButtonZoomInClick(Sender: TObject);
    procedure ButtonZoomOutClick(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure ComboProjectionChange(Sender: TObject);
    procedure CheckBordersClick(Sender: TObject);
    procedure CheckLabelsClick(Sender: TObject);
    procedure GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
    procedure GeoMap1CountryClick(Sender: TObject; Country: TGeoCountry);
    procedure GeoMap1CountryHover(Sender: TObject; Country: TGeoCountry);
    procedure ButtonHighlightClick(Sender: TObject);
    procedure ButtonClearMarkersClick(Sender: TObject);
    procedure ButtonClearHighlightsClick(Sender: TObject);
  private
    procedure UpdateStatus(const AMessage: string);
    procedure LoadSampleMap;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // Initialize projection combo
  ComboProjection.Items.Clear;
  ComboProjection.Items.Add('Equirectangular');
  ComboProjection.Items.Add('Mercator');
  ComboProjection.ItemIndex := 1;  // Mercator default
  
  // Set defaults
  CheckBorders.Checked := GeoMap1.ShowCountryBorders;
  CheckLabels.Checked := GeoMap1.ShowMarkerLabels;
  
  // Sample coordinates
  EditLat.Text := '40.7128';
  EditLon.Text := '-74.0060';
  EditCaption.Text := 'New York';
  EditCountryCode.Text := 'usa';
  
  UpdateStatus('Ready. Click "Load Map" to begin.');
end;

procedure TFormMain.LoadSampleMap;
var
  MapFile: string;
begin
  // Try to load world.geojson from various locations
  MapFile := ExtractFilePath(Application.ExeName) + 'world.geojson';
  if not FileExists(MapFile) then
    MapFile := ExtractFilePath(Application.ExeName) + '..\..\Resources\world.geojson';
  if not FileExists(MapFile) then
    MapFile := ExtractFilePath(Application.ExeName) + '..\..\..\Resources\world.geojson';
  
  if FileExists(MapFile) then
  begin
    GeoMap1.LoadMapFromFile(MapFile);
    UpdateStatus(Format('Loaded map with %d countries', [GeoMap1.MapData.Countries.Count]));
    
    // Add some sample markers
    GeoMap1.AddMarker(40.7128, -74.0060, 'New York');
    GeoMap1.AddMarker(51.5074, -0.1278, 'London');
    GeoMap1.AddMarker(35.6762, 139.6503, 'Tokyo');
    GeoMap1.AddMarker(-33.8688, 151.2093, 'Sydney');
    
    // Highlight some countries
    GeoMap1.SetCountryColor('usa', RGB(200, 220, 255));
    GeoMap1.SetCountryColor('gbr', RGB(255, 200, 200));
    GeoMap1.SetCountryColor('jpn', RGB(200, 255, 200));
    GeoMap1.SetCountryColor('aus', RGB(255, 255, 200));
  end
  else
    UpdateStatus('Map file not found. Please select a GeoJSON file.');
end;

procedure TFormMain.ButtonLoadMapClick(Sender: TObject);
begin
  OpenDialog1.Filter := 'GeoJSON Files (*.geojson;*.json)|*.geojson;*.json|All Files (*.*)|*.*';
  OpenDialog1.DefaultExt := 'geojson';
  
  if OpenDialog1.Execute then
  begin
    try
      GeoMap1.LoadMapFromFile(OpenDialog1.FileName);
      UpdateStatus(Format('Loaded: %s (%d countries)', 
        [ExtractFileName(OpenDialog1.FileName), GeoMap1.MapData.Countries.Count]));
    except
      on E: Exception do
      begin
        ShowMessage('Error loading map: ' + E.Message);
        UpdateStatus('Error loading map');
      end;
    end;
  end;
end;

procedure TFormMain.ButtonAddMarkerClick(Sender: TObject);
var
  Lat, Lon: Double;
  Marker: TGeoMarker;
begin
  try
    Lat := StrToFloat(EditLat.Text);
    Lon := StrToFloat(EditLon.Text);
    
    Marker := GeoMap1.AddMarker(Lat, Lon, EditCaption.Text);
    if Assigned(Marker) then
    begin
      Marker.Color := clRed;
      UpdateStatus(Format('Added marker: %s at %.4f, %.4f', 
        [EditCaption.Text, Lat, Lon]));
    end;
  except
    on E: Exception do
      ShowMessage('Invalid coordinates: ' + E.Message);
  end;
end;

procedure TFormMain.ButtonHighlightClick(Sender: TObject);
begin
  if ColorDialog1.Execute then
  begin
    GeoMap1.SetCountryColor(EditCountryCode.Text, ColorDialog1.Color);
    UpdateStatus(Format('Highlighted country: %s', [EditCountryCode.Text]));
  end;
end;

procedure TFormMain.ButtonClearMarkersClick(Sender: TObject);
begin
  GeoMap1.ClearMarkers;
  UpdateStatus('Markers cleared');
end;

procedure TFormMain.ButtonClearHighlightsClick(Sender: TObject);
begin
  GeoMap1.ClearCountryHighlights;
  UpdateStatus('Country highlights cleared');
end;

procedure TFormMain.ButtonZoomInClick(Sender: TObject);
begin
  GeoMap1.ZoomIn;
  UpdateStatus(Format('Zoom: %.2fx', [GeoMap1.ZoomLevel]));
end;

procedure TFormMain.ButtonZoomOutClick(Sender: TObject);
begin
  GeoMap1.ZoomOut;
  UpdateStatus(Format('Zoom: %.2fx', [GeoMap1.ZoomLevel]));
end;

procedure TFormMain.ButtonResetClick(Sender: TObject);
begin
  GeoMap1.ResetView;
  UpdateStatus('View reset');
end;

procedure TFormMain.ComboProjectionChange(Sender: TObject);
begin
  case ComboProjection.ItemIndex of
    0: GeoMap1.ProjectionType := mptEquirectangular;
    1: GeoMap1.ProjectionType := mptMercator;
  end;
  UpdateStatus('Projection changed');
end;

procedure TFormMain.CheckBordersClick(Sender: TObject);
begin
  GeoMap1.ShowCountryBorders := CheckBorders.Checked;
end;

procedure TFormMain.CheckLabelsClick(Sender: TObject);
begin
  GeoMap1.ShowMarkerLabels := CheckLabels.Checked;
end;

procedure TFormMain.GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
begin
  UpdateStatus(Format('Marker clicked: %s (%s)', 
    [Marker.Caption, Marker.Location.ToString]));
  ShowMessage(Format('Marker: %s'#13#10'Location: %s', 
    [Marker.Caption, Marker.Location.ToString]));
end;

procedure TFormMain.GeoMap1CountryClick(Sender: TObject; Country: TGeoCountry);
begin
  UpdateStatus(Format('Country clicked: %s (%s)', [Country.Name, Country.Code]));
  EditCountryCode.Text := Country.Code;
end;

procedure TFormMain.GeoMap1CountryHover(Sender: TObject; Country: TGeoCountry);
begin
  if Assigned(Country) then
    UpdateStatus(Format('Hovering: %s (%s)', [Country.Name, Country.Code]))
  else
    UpdateStatus('');
end;

procedure TFormMain.UpdateStatus(const AMessage: string);
begin
  StatusBar1.SimpleText := AMessage;
end;

end.

