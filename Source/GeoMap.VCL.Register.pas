unit GeoMap.VCL.Register;

interface

procedure Register;

implementation

uses
  System.Classes, GeoMap.VCL;

procedure Register;
begin
  RegisterComponents('GeoMap', [TGeoMapVCL]);
end;

end.

