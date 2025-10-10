# GeoMap Component - Complete Usage Guide

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Loading Maps](#loading-maps)
3. [Working with Markers](#working-with-markers)
4. [Country Operations](#country-operations)
5. [Navigation](#navigation)
6. [Events](#events)
7. [Advanced Features](#advanced-features)
---

## Basic Usage

### Minimal Setup

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
  // Load a map file
  GeoMap1.LoadMapFromFile('world.geojson');
  
  // Add a marker
  GeoMap1.AddMarker(51.5074, -0.1278, 'London');
end;
```

### Component Properties

```pascal
// Visual appearance
GeoMap1.ShowCountryBorders := True;
GeoMap1.BorderColor := clBlack;
GeoMap1.BorderWidth := 1;
GeoMap1.DefaultCountryColor := clSilver;
GeoMap1.HoverColor := clYellow;
GeoMap1.Color := clWhite;  // Background color

// Labels
GeoMap1.ShowMarkerLabels := True;

// Projection
GeoMap1.ProjectionType := mptMercator;  // or mptEquirectangular
```

---

## Loading Maps

### From File

```pascal
procedure TForm1.LoadMapFile;
begin
  try
    GeoMap1.LoadMapFromFile('C:\Maps\world.geojson');
    ShowMessage('Map loaded successfully');
  except
    on E: Exception do
      ShowMessage('Error: ' + E.Message);
  end;
end;
```

### From String (JSON)

```pascal
procedure TForm1.LoadMapFromJSON;
var
  JSON: string;
begin
  JSON := '{"type":"FeatureCollection","features":[...]}';
  GeoMap1.LoadMapFromJSON(JSON);
end;
```

### From Resource

```pascal
// Add to .rc file:
// WORLDMAP RCDATA "world.geojson"

procedure TForm1.LoadMapFromResource;
begin
  GeoMap1.LoadMapFromResource('WORLDMAP');
end;
```

### Check Loaded Countries

```pascal
procedure TForm1.ShowCountriesList;
var
  Country: TGeoCountry;
  List: TStringList;
begin
  List := TStringList.Create;
  try
    for Country in GeoMap1.MapData.Countries do
      List.Add(Format('%s - %s', [Country.Code, Country.Name]));
    
    Memo1.Lines.Assign(List);
  finally
    List.Free;
  end;
end;
```

---

## Working with Markers

### Add Marker by Coordinates

```pascal
procedure TForm1.AddMarkerByCoordinates;
var
  Marker: TGeoMarker;
begin
  Marker := GeoMap1.AddMarker(
    40.7128,    // Latitude
    -74.0060,   // Longitude
    'New York'  // Caption
  );
  
  // Customize marker
  if Assigned(Marker) then
  begin
    Marker.Color := clRed;
    Marker.Size := 12;
    Marker.TextColor := clBlack;
    Marker.Hint := 'Click for details';
    Marker.Tag := 1;
  end;
end;
```

### Batch Add Markers

```pascal
procedure TForm1.AddMultipleMarkers;
type
  TCityInfo = record
    Name: string;
    Lat, Lon: Double;
    Color: TColor;
  end;
var
  Cities: array[0..4] of TCityInfo;
  I: Integer;
  Marker: TGeoMarker;
begin
  Cities[0] := (Name: 'New York'; Lat: 40.7128; Lon: -74.0060; Color: clRed);
  Cities[1] := (Name: 'London'; Lat: 51.5074; Lon: -0.1278; Color: clGreen);
  Cities[2] := (Name: 'Tokyo'; Lat: 35.6762; Lon: 139.6503; Color: clBlue);
  Cities[3] := (Name: 'Sydney'; Lat: -33.8688; Lon: 151.2093; Color: clYellow);
  Cities[4] := (Name: 'Dubai'; Lat: 25.2048; Lon: 55.2708; Color: clPurple);
  
  for I := Low(Cities) to High(Cities) do
  begin
    Marker := GeoMap1.AddMarker(Cities[I].Lat, Cities[I].Lon, Cities[I].Name);
    if Assigned(Marker) then
      Marker.Color := Cities[I].Color;
  end;
end;
```

### Custom Marker Data

```pascal
type
  TLocationData = class
    Population: Integer;
    Temperature: Double;
    Description: string;
  end;

procedure TForm1.AddMarkerWithData;
var
  Marker: TGeoMarker;
  Data: TLocationData;
begin
  Data := TLocationData.Create;
  Data.Population := 8000000;
  Data.Temperature := 15.5;
  Data.Description := 'Major city';
  
  Marker := GeoMap1.AddMarker(40.7128, -74.0060, 'New York');
  Marker.Data := Data;  // Store custom data
  Marker.Tag := 100;    // Or use integer tag
end;

// Access in event handler:
procedure TForm1.GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
var
  Data: TLocationData;
begin
  if Assigned(Marker.Data) then
  begin
    Data := TLocationData(Marker.Data);
    ShowMessage(Format('Population: %d', [Data.Population]));
  end;
end;
```

### Find and Modify Markers

```pascal
procedure TForm1.ChangeMarkerColor;
var
  I: Integer;
begin
  for I := 0 to GeoMap1.Markers.Count - 1 do
  begin
    if GeoMap1.Markers[I].Caption = 'New York' then
    begin
      GeoMap1.Markers[I].Color := clGreen;
      GeoMap1.Markers[I].Size := 20;
      Break;
    end;
  end;
  
  GeoMap1.Invalidate;  // Redraw
end;
```

### Clear Markers

```pascal
// Remove all markers
procedure TForm1.ClearAll;
begin
  GeoMap1.ClearMarkers;
end;

// Remove specific marker
procedure TForm1.RemoveMarker(Marker: TGeoMarker);
begin
  GeoMap1.Markers.Remove(Marker);
  GeoMap1.Invalidate;
end;
```

---

## Country Operations

### Highlight Countries

```pascal
procedure TForm1.HighlightCountries;
begin
  // Single color
  GeoMap1.SetCountryColor('usa', clRed);
  GeoMap1.SetCountryColor('can', clBlue);
  GeoMap1.SetCountryColor('mex', clGreen);
  
  // RGB colors
  GeoMap1.SetCountryColor('bra', RGB(255, 200, 100));
end;
```

### Color by Data Values

```pascal
procedure TForm1.ColorCountriesByPopulation;
var
  Country: TGeoCountry;
  Population: Double;
  ColorValue: Byte;
begin
  for Country in GeoMap1.MapData.Countries do
  begin
    Population := GetPopulation(Country.Code);  // Your function
    
    // Simple heat map: higher population = darker red
    ColorValue := Trunc(255 - (Population / 1000000) * 10);
    if ColorValue < 50 then ColorValue := 50;
    
    Country.Color := RGB(255, ColorValue, ColorValue);
  end;
  
  GeoMap1.Invalidate;
end;
```

### Get Country Info

```pascal
procedure TForm1.GetCountryInfo;
var
  Country: TGeoCountry;
begin
  Country := GeoMap1.GetCountryByCode('usa');
  
  if Assigned(Country) then
  begin
    ShowMessage(Format(
      'Code: %s'#13#10 +
      'Name: %s'#13#10 +
      'Polygons: %d'#13#10 +
      'Visible: %s',
      [Country.Code, 
       Country.Name, 
       Country.Polygons.Count,
       BoolToStr(Country.Visible, True)]
    ));
  end;
end;
```

### Hide/Show Countries

```pascal
procedure TForm1.ToggleCountryVisibility;
var
  Country: TGeoCountry;
begin
  Country := GeoMap1.GetCountryByCode('usa');
  if Assigned(Country) then
  begin
    Country.Visible := not Country.Visible;
    GeoMap1.Invalidate;
  end;
end;
```

### Find Country at Location

```pascal
procedure TForm1.FindCountryAtPoint(X, Y: Integer);
var
  Country: TGeoCountry;
begin
  Country := GeoMap1.FindCountryAt(X, Y);
  
  if Assigned(Country) then
    ShowMessage('Found: ' + Country.Name)
  else
    ShowMessage('No country at this location');
end;
```

---

## Navigation

### Zoom

```pascal
// Programmatic zoom
procedure TForm1.ZoomControls;
begin
  GeoMap1.ZoomIn;   // Zoom in by 20%
  GeoMap1.ZoomOut;  // Zoom out by 20%
  
  // Set specific zoom level (0.5 to 10.0)
  GeoMap1.ZoomLevel := 2.5;
end;
```

### Center on Location

```pascal
procedure TForm1.CenterOnCity;
begin
  // By coordinates
  GeoMap1.CenterOn(51.5074, -0.1278);  // London
  
  // By country
  GeoMap1.CenterOnCountry('gbr');
end;
```

### Reset View

```pascal
procedure TForm1.ResetMapView;
begin
  GeoMap1.ResetView;  // Reset zoom and pan
end;
```

### Combined Navigation

```pascal
procedure TForm1.FocusOnCountry(const ACountryCode: string);
begin
  GeoMap1.ResetView;
  GeoMap1.CenterOnCountry(ACountryCode);
  GeoMap1.ZoomLevel := 3.0;
  GeoMap1.SetCountryColor(ACountryCode, clYellow);
end;
```

---

## Events

### Country Click

```pascal
procedure TForm1.GeoMap1CountryClick(Sender: TObject; Country: TGeoCountry);
begin
  ShowMessage(Format('Clicked: %s (%s)', [Country.Name, Country.Code]));
  
  // Highlight clicked country
  Country.Color := clYellow;
  GeoMap1.Invalidate;
end;
```

### Country Hover

```pascal
procedure TForm1.GeoMap1CountryHover(Sender: TObject; Country: TGeoCountry);
begin
  if Assigned(Country) then
  begin
    StatusBar1.SimpleText := Country.Name;
    // Show tooltip or update info panel
  end
  else
    StatusBar1.SimpleText := '';
end;
```

### Marker Click

```pascal
procedure TForm1.GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
begin
  ShowMessage(Format(
    'Marker: %s'#13#10 +
    'Location: %s'#13#10 +
    'Tag: %d',
    [Marker.Caption, Marker.Location.ToString, Marker.Tag]
  ));
  
  // Zoom to marker
  GeoMap1.CenterOn(Marker.Location.Latitude, Marker.Location.Longitude);
  GeoMap1.ZoomLevel := 4.0;
end;
```

---

## Advanced Features

### Coordinate Conversion

```pascal
procedure TForm1.ConvertCoordinates;
var
  GeoPoint: TGeoPoint;
  ScreenPoint: TPointF;
begin
  // Geographic to Screen
  GeoPoint := TGeoPoint.Create(-74.0060, 40.7128);
  ScreenPoint := GeoMap1.LatLonToScreen(GeoPoint);
  ShowMessage(Format('Screen: %.0f, %.0f', [ScreenPoint.X, ScreenPoint.Y]));
  
  // Screen to Geographic
  ScreenPoint := PointF(400, 300);
  GeoPoint := GeoMap1.ScreenToLatLon(ScreenPoint);
  ShowMessage(Format('Geo: %s', [GeoPoint.ToString]));
end;
```

### Track Mouse Position

```pascal
procedure TForm1.GeoMap1MouseMove(Sender: TObject; Shift: TShiftState; 
  X, Y: Integer);
var
  GeoPoint: TGeoPoint;
begin
  GeoPoint := GeoMap1.ScreenToLatLon(PointF(X, Y));
  StatusBar1.SimpleText := Format('Lat: %.4f°, Lon: %.4f°', 
    [GeoPoint.Latitude, GeoPoint.Longitude]);
end;
```

### Change Projection

```pascal
procedure TForm1.SwitchProjection;
begin
  if GeoMap1.ProjectionType = mptMercator then
    GeoMap1.ProjectionType := mptEquirectangular
  else
    GeoMap1.ProjectionType := mptMercator;
end;
```

### Export View as Image

```pascal
procedure TForm1.SaveMapAsImage;
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(GeoMap1.Width, GeoMap1.Height);
    GeoMap1.PaintTo(Bitmap.Canvas, 0, 0);
    Bitmap.SaveToFile('map.bmp');
  finally
    Bitmap.Free;
  end;
end;
```
## Complete Example

```pascal
unit MapForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls,
  GeoMap.VCL, GeoMap.Types, GeoMap.Markers;

type
  TFormMap = class(TForm)
    GeoMap1: TGeoMapVCL;
    procedure FormCreate(Sender: TObject);
    procedure GeoMap1CountryClick(Sender: TObject; Country: TGeoCountry);
    procedure GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
  private
    procedure SetupMap;
    procedure AddCityMarkers;
    procedure HighlightRegions;
  end;

var
  FormMap: TFormMap;

implementation

{$R *.dfm}

procedure TFormMap.FormCreate(Sender: TObject);
begin
  SetupMap;
  AddCityMarkers;
  HighlightRegions;
end;

procedure TFormMap.SetupMap;
begin
  // Configure appearance
  GeoMap1.ProjectionType := mptMercator;
  GeoMap1.ShowCountryBorders := True;
  GeoMap1.BorderColor := clGray;
  GeoMap1.DefaultCountryColor := RGB(240, 240, 240);
  GeoMap1.HoverColor := RGB(255, 255, 200);
  
  // Load map
  GeoMap1.LoadMapFromFile('world.geojson');
end;

procedure TFormMap.AddCityMarkers;
begin
  // Add major cities
  GeoMap1.AddMarker(40.7128, -74.0060, 'New York').Color := clRed;
  GeoMap1.AddMarker(51.5074, -0.1278, 'London').Color := clBlue;
  GeoMap1.AddMarker(35.6762, 139.6503, 'Tokyo').Color := clGreen;
  GeoMap1.AddMarker(48.8566, 2.3522, 'Paris').Color := clPurple;
end;

procedure TFormMap.HighlightRegions;
begin
  // Highlight countries
  GeoMap1.SetCountryColor('usa', RGB(200, 220, 255));
  GeoMap1.SetCountryColor('gbr', RGB(255, 200, 200));
  GeoMap1.SetCountryColor('jpn', RGB(200, 255, 200));
  GeoMap1.SetCountryColor('fra', RGB(255, 220, 200));
end;

procedure TFormMap.GeoMap1CountryClick(Sender: TObject; Country: TGeoCountry);
begin
  Caption := Format('Selected: %s (%s)', [Country.Name, Country.Code]);
end;

procedure TFormMap.GeoMap1MarkerClick(Sender: TObject; Marker: TGeoMarker);
begin
  ShowMessage(Marker.Caption);
end;

end.
```

---

## Troubleshooting

### Map doesn't render
- Check if GeoJSON file is valid
- Verify file path is correct
- Ensure map has features with coordinates

### Markers not visible
- Check if coordinates are valid (-90 to 90, -180 to 180)
- Verify ShowMarkerLabels is True if you want captions
- Check marker Size property (default is 10)

### Performance issues
- Reduce number of polygons in GeoJSON
- Use simpler map for lower detail levels
- Limit number of markers

---

For more examples, see the `Samples/BasicMapDemo` project.

