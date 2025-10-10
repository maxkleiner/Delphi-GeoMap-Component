unit GeoMap.Data;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  System.JSON, System.IOUtils, GeoMap.Types;

type
  TGeoMapData = class
  private
    FCountries: TObjectList<TGeoCountry>;
    function FindCountryIndex(const ACode: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadFromJSON(const AJSON: string);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromResource(const AResourceName: string);
    
    function FindCountry(const ACode: string): TGeoCountry;
    function GetCountryAt(const APoint: TGeoPoint): TGeoCountry;
    
    property Countries: TObjectList<TGeoCountry> read FCountries;
    
    procedure Clear;
  end;

implementation

{ TGeoMapData }

constructor TGeoMapData.Create;
begin
  FCountries := TObjectList<TGeoCountry>.Create(True);
end;

destructor TGeoMapData.Destroy;
begin
  FCountries.Free;
  inherited;
end;

procedure TGeoMapData.Clear;
begin
  FCountries.Clear;
end;

function TGeoMapData.FindCountryIndex(const ACode: string): Integer;
var
  I: Integer;
  SearchCode: string;
begin
  Result := -1;
  SearchCode := LowerCase(ACode);
  
  for I := 0 to FCountries.Count - 1 do
  begin
    if FCountries[I].Code = SearchCode then
      Exit(I);
  end;
end;

function TGeoMapData.FindCountry(const ACode: string): TGeoCountry;
var
  Idx: Integer;
begin
  Idx := FindCountryIndex(ACode);
  if Idx >= 0 then
    Result := FCountries[Idx]
  else
    Result := nil;
end;

procedure TGeoMapData.LoadFromFile(const AFileName: string);
var
  JSONText: string;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Map file not found: %s', [AFileName]);
    
  JSONText := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  LoadFromJSON(JSONText);
end;

procedure TGeoMapData.LoadFromStream(AStream: TStream);
var
  StringStream: TStringStream;
begin
  StringStream := TStringStream.Create('', TEncoding.UTF8);
  try
    StringStream.LoadFromStream(AStream);
    LoadFromJSON(StringStream.DataString);
  finally
    StringStream.Free;
  end;
end;

procedure TGeoMapData.LoadFromResource(const AResourceName: string);
var
  ResStream: TResourceStream;
begin
  ResStream := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
  try
    LoadFromStream(ResStream);
  finally
    ResStream.Free;
  end;
end;

procedure TGeoMapData.LoadFromJSON(const AJSON: string);
var
  JSONValue: TJSONValue;
  JSONArray: TJSONArray;
  Feature: TJSONObject;
  Properties: TJSONObject;
  Geometry: TJSONObject;
  Coordinates: TJSONArray;
  I, J, K, L: Integer;
  Country: TGeoCountry;
  Polygon: TGeoPolygon;
  Points: TArray<TGeoPoint>;
  MultiPoly, PolyRing, CoordPair: TJSONArray;
  ShortName, Name: string;
begin
  Clear;
  
  if AJSON = '' then
    raise Exception.Create('Empty JSON data');
  
  JSONValue := TJSONObject.ParseJSONValue(AJSON);
  if not Assigned(JSONValue) then
    raise Exception.Create('Invalid JSON format');
    
  try
    if not (JSONValue is TJSONObject) then 
      raise Exception.Create('JSON root must be an object');
    
    // Parse GeoJSON FeatureCollection
    JSONArray := TJSONObject(JSONValue).GetValue<TJSONArray>('features');
    if not Assigned(JSONArray) then 
      raise Exception.Create('No "features" array found in GeoJSON');
    
    for I := 0 to JSONArray.Count - 1 do
    begin
      if not (JSONArray.Items[I] is TJSONObject) then Continue;
      
      Feature := JSONArray.Items[I] as TJSONObject;
      
      // Get properties
      ShortName := '';
      Name := '';
      
      Properties := Feature.GetValue<TJSONObject>('properties');
      if Assigned(Properties) then
      begin
        ShortName := Properties.GetValue<string>('shortName', '');
        Name := Properties.GetValue<string>('name', '');
      end;
      
      // Use generated name if not provided
      if ShortName = '' then
        ShortName := Format('country_%d', [I]);
      if Name = '' then
        Name := ShortName;
      
      // Create country
      Country := TGeoCountry.Create(ShortName, Name);
      
      // Get geometry
      Geometry := Feature.GetValue<TJSONObject>('geometry');
      if Assigned(Geometry) then
      begin
        Coordinates := Geometry.GetValue<TJSONArray>('coordinates');
        if Assigned(Coordinates) then
        begin
          // Parse MultiPolygon coordinates
          // Structure: [[[[lon, lat], ...]]]
          for J := 0 to Coordinates.Count - 1 do
          begin
            if not (Coordinates.Items[J] is TJSONArray) then Continue;
            MultiPoly := Coordinates.Items[J] as TJSONArray;
            
            for K := 0 to MultiPoly.Count - 1 do
            begin
              if not (MultiPoly.Items[K] is TJSONArray) then Continue;
              PolyRing := MultiPoly.Items[K] as TJSONArray;
              
              SetLength(Points, PolyRing.Count);
              
              for L := 0 to PolyRing.Count - 1 do
              begin
                if not (PolyRing.Items[L] is TJSONArray) then Continue;
                CoordPair := PolyRing.Items[L] as TJSONArray;
                
                if CoordPair.Count >= 2 then
                begin
                  Points[L] := TGeoPoint.Create(
                    CoordPair.Items[0].AsType<Double>,
                    CoordPair.Items[1].AsType<Double>
                  );
                end;
              end;
              
              if Length(Points) >= 3 then  // Need at least 3 points for a polygon
              begin
                Polygon := TGeoPolygon.Create(Points);
                Country.AddPolygon(Polygon);
              end;
            end;
          end;
        end;
      end;
      
      // Only add country if it has at least one polygon
      if Country.Polygons.Count > 0 then
        FCountries.Add(Country)
      else
        Country.Free;
    end;
  finally
    JSONValue.Free;
  end;
end;

function TGeoMapData.GetCountryAt(const APoint: TGeoPoint): TGeoCountry;
var
  I, J, K: Integer;
  Country: TGeoCountry;
  Polygon: TGeoPolygon;
  Inside: Boolean;
  X, Y: Double;
  X1, Y1, X2, Y2: Double;
begin
  Result := nil;
  X := APoint.Longitude;
  Y := APoint.Latitude;
  
  // Check each country
  for I := 0 to FCountries.Count - 1 do
  begin
    Country := FCountries[I];
    
    if not Country.Visible then Continue;
    
    // Quick bounds check
    if not Country.Bounds.Contains(PointF(X, Y)) then Continue;
    
    // Point-in-polygon test for each polygon
    for J := 0 to Country.Polygons.Count - 1 do
    begin
      Polygon := Country.Polygons[J];
      
      if Length(Polygon.Points) < 3 then Continue;
      
      Inside := False;
      
      // Ray casting algorithm
      for K := 0 to High(Polygon.Points) do
      begin
        X1 := Polygon.Points[K].Longitude;
        Y1 := Polygon.Points[K].Latitude;
        
        if K < High(Polygon.Points) then
        begin
          X2 := Polygon.Points[K + 1].Longitude;
          Y2 := Polygon.Points[K + 1].Latitude;
        end
        else
        begin
          X2 := Polygon.Points[0].Longitude;
          Y2 := Polygon.Points[0].Latitude;
        end;
        
        if ((Y1 > Y) <> (Y2 > Y)) and 
           (X < (X2 - X1) * (Y - Y1) / (Y2 - Y1) + X1) then
          Inside := not Inside;
      end;
      
      if Inside then
        Exit(Country);
    end;
  end;
end;

end.

