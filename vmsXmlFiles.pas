{****************************************************************************************}
{                                                                                        }
{������� xml-����� � UsedAttribute = [uaTimeChange, uaValue]:                            }
{<?xml version="1.0" encoding="windows-1251" ?>                                          }
{<Root>                                                                                  }
{  <Cash_register>                                                                       }
{    <CashRegister        Value="0"     TimeChange = "2008-04-16 16:33:21" />            }
{    <ModelCashRegister   Value=""      TimeChange = "2008-04-16 16:33:21" />            }
{    <PortingCashRegister Value="COM1"  TimeChange = "2008-04-16 16:33:21" />            }
{    <BaudsCashRegister   Value="19200" TimeChange = "2008-04-16 16:33:21" />            }
{    <RegisterCashier     Value="1"     TimeChange = "2008-04-16 16:33:21" />            }
{  </Cash_register>                                                                      }
{</Root>                                                                                 }
{                                                                                        }
{������� xml-����� � UsedAttribute = []:                                                 }
{<?xml version="1.0" encoding="windows-1251"?>                                           }
{<Root>                                                                                  }
{  <Cash_register>                                                                       }
{    <CashRegister>0</CashRegister>                                                      }
{    <ModelCashRegister/>                                                                }
{    <PortingCashRegister>COM1</PortingCashRegister>                                     }
{    <BaudsCashRegister>19200</BaudsCashRegister>                                        }
{    <RegisterCashier>1</RegisterCashier>                                                }
{  </Cash_register>                                                                      }
{</Root>                                                                                 }
{                                                                                        }
{ ������ � ��������� ����������                                                         }
{   //���������� �������� � �� ��������                                                  }
{   xmlFile.Attributes.Node := xmlFile.GetNode(xmlFile.GetXPath('SECTION', 'Key'));      }
{   ��� ��� CurrentSection <> ''                                                         }
{   xmlFiles.Attributes.AddNode;                                                         }
{   xmlFile.Attributes.SetAttributeValue('CurrentDate', date);                           }
{   xmlFile.Attributes.SetAttributeValue('CurrentTime', time);                           }
{   //�������� ����������� �������� � ����                                               }
{   xmlFile.WriteAttributes;                                                             }
{                                                                                        }
{                                                                                        }
{   //������� �������� � �����                                                           }
{   if xmlFile.ReadAttributes('SomeSection', 'SomeKey') then                             }
{   begin                                                                                }
{     //������� �������� � �������� �����                                             }
{     var1 := xmlFile.Attributes.GetAttributeValue('CurrentDateTime', now);              }
{     var2 := xmlFile.Attributes.GetAttributeValue('CurrentDate',     date);             }
{     var3 := xmlFile.Attributes.GetAttributeValue('CurrentTime',     time);             }
{   end;                                                                                 }
{                                                                                        }
{  //������� �������� � ������, � ��� �� ����� �������� �� ���������                  }
{  //� ���������� C_KEY                                                                }
{   xmlFile.CurrentSection := 'SomeSection';                                             }
{   while not xmlFile.IsLastKey do                                                       }
{   begin                                                                                }
{     if xmlFile.ReadAttributes then                                                     }
{     begin                                                                              }
{       var1 := xmlFile.Attributes.GetAttributeValue('CurrentDateTime', now);            }
{       var2 := xmlFile.Attributes.GetAttributeValue('CurrentDate',     date);           }
{       var3 := xmlFile.Attributes.GetAttributeValue('CurrentTime',     time);           }
{     end;                                                                               }
{     xmlFile.NextKey;                                                                   }
{   end;                                                                                 }
{   xmlFile.CurrentSection := '';                                                        }
{                                                                                        }
{****************************************************************************************}

unit vmsXmlFiles;

interface

uses
  // Standart units
  Winapi.Windows, System.Classes, Vcl.Forms, System.IniFiles,
  System.SysUtils, System.Variants, System.Win.ComObj, Xml.XMLDoc, Xml.XMLIntf,
  Xml.Xmldom, Winapi.msxml, Soap.EncdDecd, System.WideStrUtils, System.NetEncoding;

const
  varTime     = $0060;
  varDateTime = $0061;
  varBase64   = $0064;

  C_ATTR_CODE_TYPE   = 'CodeType';
  C_ATTR_COMMENT     = 'Comment';
  C_ATTR_ENABLED     = 'Enabled';
  C_ATTR_TIME_CHANGE = 'TimeChange';
  C_ATTR_VALUE       = 'Value';
  C_ATTR_VERSION     = 'version';
  C_VMS_XPATH_SEPARATOR  : Char = '/';

type
  TXMLUsedAttribute = (uaCodeType, uaComment, uaTimeChange, uaValue);
  TXMLUsedAttributes = set of TXMLUsedAttribute;

  TXMLAttributes = class
  private
    FNode           : IXMLDOMNode;
    FXMLDOMDocument : IXMLDOMDocument;
    function GetCount: Integer;
  public
    constructor Create(aXMLDOMDocument: IXMLDOMDocument);
    function GetAttributeValue(aAttributeIndex: Integer; aDefault: OleVariant): OleVariant; overload;
    function GetAttributeValue(aAttributeName: string; aDefault: OleVariant): OleVariant; overload;
    function IsExist(aAttributeName: string): Boolean;
    procedure SetAttributeValue(aAttributeName: string; aValue: OleVariant);

    procedure AddNode;
    procedure InitNode(aXPath: string); overload;
    procedure InitNode(aSection, aKey: string); overload;

    property Count : Integer     read GetCount;
    property Node  : IXMLDOMNode read FNode write FNode;
  end;

  TXMLFile = class
  const
    C_CRYPT_KEY    = '1D52E82CD94C4A03B458875597AD9253';
    C_KEY          = 'Item';
    C_ROOT         = 'Root';
    C_XML_ENCODING = 'UTF-8';//'windows-1251';
    C_XML_VERSION  = '1.0';
    C_XML_SIGN     = '<?xml ' + C_ATTR_VERSION + '="' + C_XML_VERSION + '" encoding="' + C_XML_ENCODING + '"?>';
    C_PREFIX_NODE  = 'cf_';
    C_VERSION_FILE = 1;
  private
    FActive             : Boolean;
    FAttributes         : TXMLAttributes;     // ������ ��������, �� ������ ����������� ����������������� � ��������� �������
    FBackup             : Boolean;
    FCurrentNode        : IXMLDOMNode;
    FCurrentSection     : IXMLDOMNode;
    FEncodeStream       : Boolean;
    FFileName           : string;
    FItemNode           : string;
    FModified           : Boolean;
    FNameCurrentSection : string;
    FRootNode           : string;
    FUsedAttributes     : TXMLUsedAttributes;
    FXMLDoc             : IXMLDOMDocument;
    function GetActive: Boolean;
    function GetNodeKey(aSection, aKey: string; bCreate: Boolean = True): IXMLDOMNode;
    function GetXML: TStrings;
    function IsAccessToFile(const aFileName: TFileName): Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetCurrentSection(const Value: string);
    procedure SetXML(const aValue: TStrings);
    procedure SetXMLText(const Value: string);
    procedure Write(const aXPath: string; aValue: OleVariant; aCodeType: Word; aComment: string);
    function GetItemNode: string;
  public
    procedure Open;
    procedure Clear;
    procedure Save;
    procedure SaveToFile(const aFileName: TFileName);
    procedure UpdateFile;
    procedure LoadFromFile(const aFileName: TFileName);

    function IsLastKey: Boolean;                                                                   // �����, �� �������� ���� �������� � �������� ������
    procedure NextKey;                                                                             // ���������� �� ���������� ����� � �������� ������

    function GetXPath(aSection, aKey: string): string; overload;
    function GetXPath(aSection: string): string; overload;
    function GetNode(aXPath: string; bCreate: Boolean = True): IXMLDOMNode;

    function ReadAttributes(const aSection, aKey: string): Boolean; overload;
    function ReadAttributes(const aXPath: string): Boolean; overload;
    function ReadAttributes: Boolean; overload;
    procedure WriteAttributes;

    function SectionExists(const aSection: string): Boolean;
    function ValueExists(aSection, aKey: string): Boolean;

    function IsValidXML(const aXmlStr: string): Boolean;
    function IsValidXMLFile(const aXmlFile: TFileName): Boolean;
    function GetRootTag: string;
    function GetXMLText: string;
    function GetXMLDeclaration: string;
    function GetCorrectEncoding(const aValue: string): string;

    function ReadBool(const aSection, aKey: string; aDefault: Boolean): Boolean;
    function ReadDate(const aSection, aKey: string; aDefault: TDate): TDate;
    function ReadDateTime(const aSection, aKey: string; aDefault: TDateTime): TDateTime;
    function ReadFloat(const aSection, aKey: string; aDefault: Double): Double;
    function ReadInteger(const aSection, aKey: string; aDefault: Integer): Integer;
    function ReadString(const aSection, aKey, aDefault: string): string;
    function ReadTime(const aSection, aKey: string; aDefault: TTime): TTime;
    function ReadValue(const aSection, aKey: string; aDefault: OleVariant): OleVariant; overload;
    function ReadValue(const aXPath: string; aDefault: OleVariant): OleVariant; overload;
    procedure ReadToFile(const aSection, aKey, aFileName: string);                                 // ������ �������� xml-����� � ��������� ����

    procedure WriteBool(const aSection, aKey: string; aValue: Boolean; aComment: string = '');
    procedure WriteDate(const aSection, aKey: string; aValue: TDate; aComment: string = '');
    procedure WriteDateTime(const aSection, aKey: string; aValue: TDateTime; aComment: string = '');
    procedure WriteFloat(const aSection, aKey: string; aValue: Double; aComment: string = '');
    procedure WriteInteger(const aSection, aKey: string; aValue: Longint; aComment: string = '');
    procedure WriteString(const aSection, aKey, aValue: string; aComment: string = '');
    procedure WriteTime(const aSection, aKey: string; aValue: TTime; aComment: string = '');
    procedure WriteValue(const aSection, aKey: string; aValue: OleVariant; aComment: string = ''); overload;
    procedure WriteValue(const aXPath: string; aValue: OleVariant); overload;

    procedure DeleteKey(const aSection, aKey: string); overload;
    procedure DeleteKey(const aXPath: string); overload;
    procedure EraseSection(const aSection: string);

    procedure ReadSection(const aSection: string; aStrings: TStrings); overload;
    procedure ReadSection(const aSection: string; aStrings: TStrings; const aSortAttr: OleVariant); overload;
    procedure ReadSections(aStrings: TStrings);
    procedure ReadSectionValues(const aSection: string; aStrings: TStrings);

    constructor Create(const aFileName: TFileName); overload;
    constructor Create; overload;
    destructor Destroy; override;

    class function GetCorrectNodeName(const aNodeName: string): string;
    class function GetReturnedNodeName(const aNodeName: string): string;
    class function ConvertIni2Xml(aIniFileName: TFileName): Boolean;

    property Active         : Boolean            read GetActive           write SetActive;
    property Attributes     : TXMLAttributes     read FAttributes         write FAttributes;
    property Backup         : Boolean            read FBackup             write FBackup;           // ������, �� ������� ���������� ��������� ���� ����� ����� �������
    property CurrentSection : string             read FNameCurrentSection write SetCurrentSection; // ������� ������� ������
    property EncodeStream   : Boolean            read FEncodeStream       write FEncodeStream;     // ������, �� ������� ��������/������������� ����� �����/���� ������ �� ����� � ������ Base64
    property RootNode       : string             read FRootNode           write FRootNode;
    property ItemNode       : string             read GetItemNode         write FItemNode;
    property CurrentNode    : IXMLDOMNode        read FCurrentNode        write FCurrentNode;
    property SectionNode    : IXMLDOMNode        read FCurrentSection     write FCurrentSection;
    property UsedAttributes : TXMLUsedAttributes read FUsedAttributes     write FUsedAttributes;
    property Xml            : TStrings           read GetXML              write SetXML;
    property XMLDomDocument : IXMLDOMDocument    read FXMLDoc;
    property XMLText        : string             read GetXMLText          write SetXMLText;
  end;

implementation

resourcestring
  C_ERROR_MSG = 'Error Code : %d  Msg : %s line : %d Character  Position : %d Pos in file : %d';

{ TXMLFile }

constructor TXMLFile.Create(const aFileName: TFileName);
begin
  inherited Create;
  FFileName           := aFileName;
  FRootNode           := C_ROOT;
  FCurrentSection     := nil;
  FCurrentNode        := nil;
  FNameCurrentSection := '';
  FUsedAttributes     := [uaValue];
  FEncodeStream       := True;

  FXMLDoc := CreateOleObject('Microsoft.XMLDOM') as IXMLDOMDocument;
  FXMLDoc.async           := False;
  FXMLDoc.validateOnParse := False;
  FXMLDoc.createProcessingInstruction('xml', 'version="' + C_XML_VERSION + '" encoding="' + C_XML_ENCODING + '"');

  if (aFileName <> '') and not IsValidXMLFile(aFileName) then
    FXMLDoc.LoadXML(GetXMLDeclaration);

  Attributes := TXMLAttributes.Create(FXMLDoc);
end;

constructor TXMLFile.Create;
begin
  Self.Create('');
end;

destructor TXMLFile.Destroy;
begin
  FCurrentSection := nil;
  FCurrentNode    := nil;
  FreeAndNil(FAttributes);
  if Assigned(FXMLDoc) then
    try
      Save;
    finally
      FXMLDoc := nil;
    end;
  inherited;
end;

procedure TXMLFile.Open;
var
  iAttrib : IXMLDOMAttribute;
  iNode   : IXMLDOMNode;
begin
  FActive := True;
  if not Assigned(FXMLDoc.documentElement) then
  begin
    iNode := FXMLDoc.createNode(1, FRootNode, '');
    iAttrib := FXMLDoc.createAttribute(C_ATTR_VERSION);
    iAttrib.Value := C_VERSION_FILE;
    iNode.Attributes.setNamedItem(iAttrib);
    FXMLDoc.appendChild(iNode);
  end;
end;

procedure TXMLFile.SetActive(const Value: Boolean);
begin
  if Value then
    Open;
  FActive := Value;
end;

function TXMLFile.GetActive: Boolean;
begin
  Result := FActive;
end;


procedure TXMLFile.Clear;
begin
  FXMLDoc.LoadXML(GetXMLDeclaration);
  FRootNode := FXMLDoc.documentElement.nodeName;
  FModified := True;
  FActive   := True;
  Save;
end;

function TXMLFile.GetXML: TStrings;
begin
  Result := TStringList.Create;
  if (FXMLDoc.Xml <> '') then
    Result.Text := GetCorrectEncoding(FormatXMLData(FXMLDoc.Xml))
  else
  begin
    FXMLDoc.LoadXML(GetXMLDeclaration);
    Result.Text := FXMLDoc.Xml;
  end;
end;

function TXMLFile.GetXMLDeclaration: string;
begin
  Result := Concat(C_XML_SIGN, GetRootTag);
end;

function TXMLFile.GetXMLText: string;
begin
  Result := FormatXMLData(FXMLDoc.Xml);
end;

function TXMLFile.GetXPath(aSection, aKey: string): string;
begin
  Result := Concat(C_VMS_XPATH_SEPARATOR, FRootNode, C_VMS_XPATH_SEPARATOR, GetCorrectNodeName(aSection), C_VMS_XPATH_SEPARATOR, GetCorrectNodeName(aKey));
end;

function TXMLFile.GetXPath(aSection: string): string;
begin
  Result := Concat(C_VMS_XPATH_SEPARATOR, FRootNode, C_VMS_XPATH_SEPARATOR, GetCorrectNodeName(aSection));
end;

procedure TXMLFile.SetXML(const aValue: TStrings);
begin
  if Assigned(aValue) then
  begin
    if (aValue.Count > 0) and (pos('<?xml', aValue.Text) > 0) and
      not IsValidXML(GetCorrectEncoding(aValue.Text)) then
    begin
      FXMLDoc.LoadXML(GetXMLDeclaration);
      Open;
      FRootNode := FXMLDoc.documentElement.nodeName;
    end;
  end
  else
    FActive := False;
end;

procedure TXMLFile.SetXMLText(const Value: string);
begin
  if not IsValidXML(Value) then
  begin
    FXMLDoc.LoadXML(GetXMLDeclaration);
    Open;
    FRootNode := FXMLDoc.documentElement.nodeName;
  end;
end;

function TXMLFile.IsAccessToFile(const aFileName: TFileName): Boolean;
var
  nHandle: DWORD;
begin
  Result  := False;
  if (aFileName <> '') then
  begin
    nHandle := CreateFile(PChar(aFileName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if (nHandle <> INVALID_HANDLE_VALUE) then
    begin
      CloseHandle(nHandle);
      Result := True;
    end;
  end;
end;

function TXMLFile.IsValidXML(const aXmlStr: string): Boolean;
var
  sErrorMsg: string;
begin
  if aXmlStr.Trim.IsEmpty then
  begin
    Result := False;
  end
  else
  begin
    Result := (FXMLDoc.LoadXML(aXmlStr)) and (FXMLDoc.parseError.errorCode = 0);
    if not Result then
    begin
      sErrorMsg := Format(C_ERROR_MSG, [FXMLDoc.parseError.errorCode,
                                        FXMLDoc.parseError.Reason,
                                        FXMLDoc.parseError.Line,
                                        FXMLDoc.parseError.linepos,
                                        FXMLDoc.parseError.filepos]);
    end;
  end;
  FActive := Result;
end;

function TXMLFile.IsValidXMLFile(const aXmlFile: TFileName): Boolean;
var
  sErrorMsg: string;
begin
  Result := False;
  if FileExists(aXmlFile) then
  begin
    Result := IsAccessToFile(aXmlFile) and (FXMLDoc.Load(aXmlFile)) and (FXMLDoc.parseError.errorCode = 0);
    if not Result then
    begin
      sErrorMsg := Format(C_ERROR_MSG, [FXMLDoc.parseError.errorCode,
                                        FXMLDoc.parseError.Reason,
                                        FXMLDoc.parseError.Line,
                                        FXMLDoc.parseError.linepos,
                                        FXMLDoc.parseError.filepos]);
    end;
  end;
  FActive := Result;
end;

procedure TXMLFile.SetCurrentSection(const Value: string);
begin
  if not Assigned(FXMLDoc.documentElement) then
    Open;

  FNameCurrentSection := Value;
  FCurrentSection     := nil;
  FCurrentNode        := nil;
  if not FNameCurrentSection.IsEmpty then
  begin
    if not Assigned(FCurrentSection) then
    begin
      if FNameCurrentSection.Contains(C_VMS_XPATH_SEPARATOR) then
        FCurrentSection := GetNode(FNameCurrentSection)
      else if (Value = RootNode) then
        FCurrentSection := GetNode(FRootNode)
      else
        FCurrentSection := GetNode(Self.GetXPath(FNameCurrentSection));
    end;
    FCurrentNode := FCurrentSection.firstChild;
  end;
end;

function TXMLFile.IsLastKey: Boolean;
begin
  if Assigned(FCurrentSection) and FCurrentSection.hasChildNodes and Assigned(FCurrentNode)
  then
    Result := (FCurrentSection.lastChild = FCurrentNode)
  else
    Result := True;
end;

procedure TXMLFile.NextKey;
begin
  if Assigned(FCurrentSection) and FCurrentSection.hasChildNodes and Assigned(FCurrentNode) then
  begin
    if (FCurrentSection.lastChild <> FCurrentNode) then
      FCurrentNode := FCurrentNode.nextSibling;
  end;
end;

function TXMLFile.ReadAttributes(const aXPath: string): Boolean;
var
  iNode: IXMLDOMNode;
begin
  if Assigned(FCurrentSection) and FCurrentSection.hasChildNodes and Assigned(FCurrentNode) then
    iNode := FCurrentNode
  else
    iNode := FXMLDoc.SelectSingleNode(aXPath);

  if Assigned(iNode) then
  begin
    Attributes.Node := iNode;
    Result          := True;
  end
  else
    Result := False;
end;

function TXMLFile.ReadAttributes(const aSection, aKey: string): Boolean;
begin
  Result := ReadAttributes(GetXPath(aSection, aKey));
end;

function TXMLFile.ReadAttributes: Boolean;
begin
  Result := ReadAttributes(GetXPath(FCurrentSection.nodeName, ItemNode));
end;

function TXMLFile.ReadValue(const aXPath: string; aDefault: OleVariant): OleVariant;
var
  iNode           : IXMLDOMNode;
  vResult         : OleVariant;
begin
  Result := aDefault;
  if aXPath.Contains(C_VMS_XPATH_SEPARATOR) then
    iNode := FXMLDoc.SelectSingleNode(aXPath);

  if not Assigned(iNode) then
    vResult := aDefault
  else
  begin
    if (uaValue in FUsedAttributes) then
    begin
      if Assigned(iNode.Attributes.getNamedItem(C_ATTR_VALUE)) then
        vResult := iNode.Attributes.getNamedItem(C_ATTR_VALUE).nodeValue;
    end
    else
      vResult := iNode.nodeValue;

    if VarIsNull(vResult) or VarIsEmpty(vResult) or (vResult = '') then
      vResult := aDefault;
    Result := vResult;
  end;
end;

function TXMLFile.ReadBool(const aSection, aKey: string; aDefault: Boolean): Boolean;
begin
  Result := Boolean(ReadValue(GetXPath(aSection, aKey), aDefault));
end;

function TXMLFile.ReadDate(const aSection, aKey: string; aDefault: TDate): TDate;
begin
  Result := ReadInteger(aSection, aKey, Trunc(aDefault));
end;

function TXMLFile.ReadDateTime(const aSection, aKey: string; aDefault: TDateTime): TDateTime;
begin
  Result := StrToDateTime(ReadValue(GetXPath(aSection, aKey), DateTimeToStr(aDefault)));
end;

function TXMLFile.ReadFloat(const aSection, aKey: string; aDefault: Double): Double;
begin
  Result := StrToFloat(ReadValue(GetXPath(aSection, aKey), FloatToStr(aDefault)));
end;

function TXMLFile.ReadInteger(const aSection, aKey: string; aDefault: Integer): Integer;
begin
  Result := StrToIntDef(ReadValue(GetXPath(aSection, aKey), IntToStr(aDefault)), aDefault);
end;

function TXMLFile.ReadString(const aSection, aKey, aDefault: string): string;
begin
  Result := ReadValue(GetXPath(aSection, aKey), aDefault);
end;

function TXMLFile.ReadTime(const aSection, aKey: string; aDefault: TTime): TTime;
begin
  Result := ReadFloat(aSection, aKey, Frac(aDefault));
end;

function TXMLFile.ReadValue(const aSection, aKey: string; aDefault: OleVariant): OleVariant;
begin
  Result := ReadValue(GetXPath(aSection, aKey), aDefault);
end;

procedure TXMLFile.ReadToFile(const aSection, aKey, aFileName: string);
var
  iNode        : IXMLDOMNode;
  loFileStream : TFileStream;
  sValue       : string;
begin
  try
    iNode := GetNode(GetXPath(aSection, aKey), False);
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aSection + '\' + aKey);
  end;

  if Assigned(iNode) then
  begin
    sValue := ReadString(aSection, aKey, '');
    if (sValue <> '') then
    begin
      if EncodeStream or
        (Assigned(iNode.Attributes.getNamedItem(C_ATTR_CODE_TYPE)) and (iNode.Attributes.getNamedItem(C_ATTR_CODE_TYPE).nodeValue = varBase64)) then
        sValue := Soap.EncdDecd.DecodeString(sValue);
    end;

    if FileExists(aFileName) then
      loFileStream := TFileStream.Create(aFileName, fmOpenWrite + fmShareDenyNone)
    else
      loFileStream := TFileStream.Create(aFileName, fmCreate);

    try
      loFileStream.Write(Pointer(sValue)^, Length(sValue));
    finally
      FreeAndNil(loFileStream);
    end;
  end;
end;

procedure TXMLFile.ReadSection(const aSection: string; aStrings: TStrings);
var
  i     : Integer;
  iNode : IXMLDOMNode;
begin
  try
    if aSection.Contains(C_VMS_XPATH_SEPARATOR) then
      iNode := GetNode(aSection, False)
    else
      iNode := GetNode(GetXPath(aSection), False)
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aSection);
  end;

  if Assigned(iNode) then
    for i := 0 to iNode.childNodes.Length - 1 do
      aStrings.Add(GetReturnedNodeName(iNode.childNodes.item[i].nodeName));
end;

procedure TXMLFile.ReadSection(const aSection: string; aStrings: TStrings; const aSortAttr: OleVariant);
const
  C_COUNT_SYMB = 25;
var
  i         : Integer;
  j         : Integer;
  iNode     : IXMLDOMNode;
  iNodeKey  : IXMLDOMNode;
  sSortKey  : string;
  stKeyList : TStringList;
begin
  try
    if aSection.Contains(C_VMS_XPATH_SEPARATOR) then
      iNode := GetNode(aSection, False)
    else
      iNode := GetNode(GetXPath(aSection), False)
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aSection);
  end;

  if not Assigned(iNode) then
    Exit;

  if VarIsNull(aSortAttr) or VarIsEmpty(aSortAttr) then
    ReadSection(aSection, aStrings)
  else
  begin
    stKeyList := TStringList.Create;
    stKeyList.Sorted := False;
    try
      for i := 0 to iNode.childNodes.Length - 1 do
      begin
        iNodeKey := iNode.childNodes.item[i];
        sSortKey := '';

        if aSection.Contains(C_VMS_XPATH_SEPARATOR) then
          ReadAttributes(aSection + C_VMS_XPATH_SEPARATOR + iNodeKey.nodeName)
        else
          ReadAttributes(aSection, iNodeKey.nodeName);

        if VarIsArray(aSortAttr) then
          for j := VarArrayLowBound(aSortAttr, 1) to VarArrayHighBound(aSortAttr, 1) do
            sSortKey := sSortKey + VarToStr(Attributes.GetAttributeValue(VarToStr(aSortAttr[j]), '')).PadLeft(C_COUNT_SYMB, '0')
        else
          sSortKey := VarToStr(Attributes.GetAttributeValue(VarToStr(aSortAttr), '')).PadLeft(C_COUNT_SYMB, '0');
        stKeyList.Add(sSortKey + iNodeKey.nodeName);
      end;

      stKeyList.Sorted := True;
      for i := 0 to stKeyList.Count - 1 do
      begin
        sSortKey := stKeyList[i];
        if VarIsArray(aSortAttr) then
          Delete(sSortKey, 1, (VarArrayHighBound(aSortAttr, 1) + 1) * C_COUNT_SYMB)
        else
          Delete(sSortKey, 1, C_COUNT_SYMB);
        aStrings.Add(sSortKey);
      end;
    finally
      FreeAndNil(stKeyList);
    end;
  end;
end;

procedure TXMLFile.ReadSections(aStrings: TStrings);
begin
  ReadSection(FXMLDoc.documentElement.nodeName, aStrings);
end;

procedure TXMLFile.ReadSectionValues(const aSection: string; aStrings: TStrings);
var
  i         : Integer;
  loKeyList : TStringList;
begin
  loKeyList := TStringList.Create;
  try
    ReadSection(aSection, loKeyList);
    aStrings.BeginUpdate;
    try
      aStrings.Clear;
      for i := 0 to loKeyList.Count - 1 do
        aStrings.Add(loKeyList[i] + '=' + ReadString(aSection, loKeyList[i], ''))
    finally
      aStrings.EndUpdate;
    end;
  finally
    loKeyList.Free;
  end;
end;

procedure TXMLFile.WriteAttributes;
var
  iAttrib : IXMLDOMAttribute;
begin
  if Assigned(Attributes.Node) then
  begin
    if not Assigned(Attributes.Node.parentNode) then
      if Assigned(FCurrentSection) then
        FCurrentSection.appendChild(Attributes.Node)
      else
        FXMLDoc.documentElement.appendChild(Attributes.Node);

    if (uaTimeChange in FUsedAttributes) then
    begin
      iAttrib := FXMLDoc.createAttribute(ItemNode);
      iAttrib.Value := Now;
      Attributes.Node.Attributes.setNamedItem(iAttrib);
    end;
    FModified := True;
  end;
end;

procedure TXMLFile.Write(const aXPath: string; aValue: OleVariant; aCodeType: Word; aComment: string);
var
  iAttrib : IXMLDOMAttribute;
  iNode   : IXMLDOMNode;
begin
  if (FNameCurrentSection <> '') and Assigned(FCurrentSection) then
  begin
    iNode := FXMLDoc.createNode(varNull, ItemNode, '');
    //iNode.nodeValue := aValue;
    FCurrentSection.appendChild(iNode);
  end
  else
  try
    iNode := GetNode(aXPath, True);
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aXPath);
  end;

  if (uaCodeType in FUsedAttributes) or (aCodeType = varBase64) then
  begin
    iAttrib := FXMLDoc.createAttribute(C_ATTR_CODE_TYPE);
    iAttrib.Value := aCodeType;
    iNode.Attributes.setNamedItem(iAttrib);
  end;
  if (uaTimeChange in FUsedAttributes) then
  begin
    iAttrib := FXMLDoc.createAttribute(C_ATTR_TIME_CHANGE);
    iAttrib.Value := DateTimeToStr(Now);
    iNode.Attributes.setNamedItem(iAttrib);
  end;
  if (uaComment in FUsedAttributes) then
  begin
    iAttrib := FXMLDoc.createAttribute(C_ATTR_COMMENT);
    iAttrib.Value := VarToStr(aComment);
    iNode.Attributes.setNamedItem(iAttrib);
  end;

  if (uaValue in FUsedAttributes) then
  begin
    iAttrib := FXMLDoc.createAttribute(C_ATTR_VALUE);
    iAttrib.Value := VarToStr(aValue);
    iNode.Attributes.setNamedItem(iAttrib);
  end
  else
    iNode.nodeValue := aValue;

  FModified := True;
end;

procedure TXMLFile.WriteValue(const aXPath: string; aValue: OleVariant);
begin
  Write(aXPath, aValue, VarType(aValue), '');
end;

procedure TXMLFile.WriteValue(const aSection, aKey: string; aValue: OleVariant; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, VarType(aValue), aComment);
end;

procedure TXMLFile.WriteBool(const aSection, aKey: string; aValue: Boolean; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, varBoolean, aComment);
end;

procedure TXMLFile.WriteDate(const aSection, aKey: string; aValue: TDate; aComment: string);
begin
  Write(GetXPath(aSection, aKey), Trunc(aValue), varDate, aComment);
end;

procedure TXMLFile.WriteDateTime(const aSection, aKey: string; aValue: TDateTime; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, varDateTime, aComment);
end;

procedure TXMLFile.WriteFloat(const aSection, aKey: string; aValue: Double; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, varDouble, aComment);
end;

procedure TXMLFile.WriteInteger(const aSection, aKey: string; aValue: Integer; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, varInteger, aComment);
end;

procedure TXMLFile.WriteString(const aSection, aKey, aValue: string; aComment: string);
begin
  Write(GetXPath(aSection, aKey), aValue, varOleStr, aComment);
end;

procedure TXMLFile.WriteTime(const aSection, aKey: string; aValue: TTime; aComment: string);
begin
  Write(GetXPath(aSection, aKey), Frac(aValue), varTime, aComment);
end;

function TXMLFile.GetCorrectEncoding(const aValue: string): string;
var
  nPosEnd      : Integer;
  nPosStart    : Integer;
  sDeclaration : string;
begin
  Result := aValue;
  nPosStart := pos('<?xml', aValue);
  nPosEnd := pos('?>', aValue);
  if (nPosStart >= 0) and (nPosEnd > 0) then
  begin
    sDeclaration := Copy(aValue, nPosStart, nPosEnd - nPosStart + 1);
    if not sDeclaration.Contains('encoding') then
      Result := Concat(C_XML_SIGN, Copy(aValue, nPosEnd + 2, aValue.Length));
  end;
end;

class function TXMLFile.GetCorrectNodeName(const aNodeName: string): string;
var
  i : Integer;
begin
  for i := 1 to aNodeName.Length do
    if CharInSet(aNodeName[i], ['_', '.', 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '�' .. '�', '�' .. '�']) then
      Result := Concat(Result, aNodeName[i])
    else
      Result := Concat(Result, FormatFloat('-0000', Ord(aNodeName[i])));

  if ((Length(Result) > 0) and CharInSet(Result[1], ['-', '.', '_', '0' .. '9'])) or (aNodeName = '') then
    Result := Concat(C_PREFIX_NODE, Result);
end;

function TXMLFile.GetItemNode: string;
begin
  if FItemNode.IsEmpty then
    Result := C_KEY
  else
    Result := FItemNode;
end;

function TXMLFile.GetNodeKey(aSection, aKey: string; bCreate: Boolean): IXMLDOMNode;
begin
  if (FNameCurrentSection <> '') then
    aKey := ItemNode;
  Result := GetNode(GetXPath(aSection, aKey), bCreate);
end;

function TXMLFile.GetNode(aXPath: string; bCreate: Boolean = True): IXMLDOMNode;
var
  loStList     : TStringList;
  i            : Integer;
  iNode        : IXMLDOMNode;
  iNodeParent  : IXMLDOMNode;
  sNodeName    : string;
begin
  if aXPath.Contains(C_VMS_XPATH_SEPARATOR) then
    try
      iNode := FXMLDoc.SelectSingleNode(aXPath);
    except
      raise Exception.Create('Wrong IXMLDOMNode - ' + aXPath);
  end;

  if not Assigned(iNode) and bCreate then
  begin
    loStList := TStringList.Create;
    try
      loStList.Delimiter     := C_VMS_XPATH_SEPARATOR;
      loStList.DelimitedText := aXPath;
      iNodeParent            := FXMLDoc.documentElement;
      for i := 0 to loStList.Count - 1 do
        if (loStList[i] <> '') then
        begin
           sNodeName := Concat(sNodeName, C_VMS_XPATH_SEPARATOR, loStList[i]);
           iNode := FXMLDoc.selectSingleNode(sNodeName);
           if not Assigned(iNode) then
           begin
             if (loStList[i].ToUpper = FRootNode.ToUpper) then
             begin
               iNode := FXMLDoc.createNode(varNull, FRootNode, '');
               FXMLDoc.appendChild(iNode);
               iNodeParent := iNode;
             end
             else
             begin
               iNode := FXMLDoc.createNode(varNull, loStList[i], '');
               iNodeParent.appendChild(iNode);
               iNodeParent := iNode;
             end;
           end
           else
             iNodeParent := iNode;
        end;
    finally
      FreeAndNil(loStList);
    end;
  end;
  Result := iNode;
end;

procedure TXMLFile.Save;
begin
  if FModified and (FFileName <> '') then
  begin
    FModified := False;
    if Backup then
      CopyFile(PChar(FFileName), PChar(FFileName + '.bak'), False);
    try
      FXMLDoc.Save(FFileName);
    except
      on E: Exception do
      begin
      end;
    end;
  end;
end;

procedure TXMLFile.SaveToFile(const aFileName: TFileName);
begin
  if (aFileName <> '') then
  begin
    try
      FXMLDoc.Save(aFileName);
    except
      on E: Exception do
      begin

      end;
    end;
  end;
end;

procedure TXMLFile.UpdateFile;
begin
  CurrentSection := '';
//  Save;
end;

procedure TXMLFile.LoadFromFile(const aFileName: TFileName);
begin
  if IsValidXMLFile(aFileName) then
    FFileName := aFileName
  else
    FActive := False;
end;

function TXMLFile.SectionExists(const aSection: string): Boolean;
var
  iNode: IXMLDOMNode;
begin
  iNode := GetNode(aSection, False);
  if not Assigned(iNode) then
  try
    iNode := GetNode(GetXPath(aSection), False);
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aSection);
  end;

  try
    Result := Assigned(iNode);
  finally
    iNode := nil;
  end;
end;

function TXMLFile.ValueExists(aSection, aKey: string): Boolean;
var
  iNode: IXMLDOMNode;
begin
  iNode := GetNodeKey(aSection, aKey, False);
  try
    Result := Assigned(iNode);
  finally
    iNode := nil;
  end;
end;

procedure TXMLFile.DeleteKey(const aSection, aKey: string);
var
  iNode: IXMLDOMNode;
begin
  iNode := GetNodeKey(aSection, aKey, False);
  if Assigned(iNode) then
  begin
    iNode.parentNode.removeChild(iNode);
    FModified := True;
  end;
end;

procedure TXMLFile.DeleteKey(const aXPath: string);
var
  iNode: IXMLDOMNode;
begin
  try
    iNode := GetNode(GetXPath(aXPath), False);
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aXPath);
  end;

  if Assigned(iNode) then
  begin
    iNode.parentNode.removeChild(iNode);
    FModified := True;
  end;
end;

procedure TXMLFile.EraseSection(const aSection: string);
var
  iNode: IXMLDOMNode;
begin
  iNode := GetNode(aSection, False);
  if not Assigned(iNode) then
  try
    iNode := GetNode(GetXPath(aSection), False);
  except
    raise Exception.Create('Wrong IXMLDOMNode - ' + aSection);
  end;

  if Assigned(iNode) and iNode.hasChildNodes then
  begin
    (iNode.selectNodes('*') as IXMLDOMSelection).removeAll;
    FModified := True;
  end;
end;

class function TXMLFile.GetReturnedNodeName(const aNodeName: string): string;
var
  nCode     : Integer;
  nLength   : Integer;
  sCode     : string;
  sNodeName : string;
  sTmp      : string;
begin
  sNodeName := aNodeName;
  sTmp      := '';

  if (Pos('cf_', sNodeName) = 1) then
  begin
    nLength := Length(sNodeName);
    if ((nLength > 3) and CharInSet(sNodeName[4], ['-', '.', '_', '0' .. '9'])) then
      sNodeName := Copy(sNodeName, 4, nLength - 3)
    else
      sNodeName := '';
  end;

  nLength := Length(sNodeName);

  if (nLength = 0) then
    Exit('');

  repeat
    if (sNodeName[1] = '-') then
    begin
      sCode := copy(sNodeName, 2, 4);
      nCode := StrToIntDef(sCode, 0);
      sTmp  := sTmp + Chr(nCode);

      if (nLength = 5) then
        sNodeName := ''
      else
        sNodeName := Copy(sNodeName, 6, nLength - 5);
    end
    else
    begin
      sTmp := sTmp + sNodeName[1];
      if (nLength = 1) then
        sNodeName := ''
      else
        sNodeName := Copy(sNodeName, 2, nLength - 1);
    end;
    nLength := Length(sNodeName);
  until not(nLength > 0);

  Result := sTmp;
end;

function TXMLFile.GetRootTag: string;
begin
  Result := Concat('<', FRootNode, ' ', C_ATTR_VERSION, '="', IntToStr(C_VERSION_FILE), '"/>');
end;

class function TXMLFile.ConvertIni2Xml(aIniFileName: TFileName): Boolean;
var
  aIniFile    : TIniFile;
  aItems      : TStringList;
  aSections   : TStringList;
  aXMLDoc     : TXMLDocument;
  i, j        : Integer;
  NodeKey     : IXMLNode;
  NodeRoot    : IXMLNode;
  NodeSection : IXMLNode;
begin
  //��������, �� ���� ��� �� �������������
  aItems := nil;
  aIniFile := nil;
  if not FileExists(aIniFileName) then
    Exit(False)
  else
  begin
    aSections := TStringList.Create;
    try
      aSections.LoadFromFile(aIniFileName);
      if (aSections.Count = 0) or
        (pos('<?xml', aSections[0]) > 0) then
        Exit(False);
    except
      aSections.Free;
      Exit(False);
    end;
  end;

  aSections.Clear;
  if not CopyFile(PChar(aIniFileName), PChar(aIniFileName + '.bak'), False) then
    Exit(False);
  try
    aIniFile := TIniFile.Create(aIniFileName + '.bak');
    aItems   := TStringList.Create;
    aIniFile.ReadSections(aSections);
    try
      aXMLDoc          := TXMLDocument.Create(Application);
      aXMLDoc.Active   := True;
      aXMLDoc.Encoding := C_XML_ENCODING;
      aXMLDoc.FileName := aIniFileName;
      aXMLDoc.Options  := [doNodeAutoIndent];

      NodeRoot := aXMLDoc.AddChild(C_ROOT);
      for i := 0 to Pred(aSections.Count) do
      begin
        aItems.Clear;
        aIniFile.ReadSection(aSections[i], aItems);
        NodeSection := NodeRoot.AddChild(GetCorrectNodeName(aSections[i]));
        for j := 0 to Pred(aItems.Count) do
        begin
          NodeKey := NodeSection.AddChild(GetCorrectNodeName(aItems[j]));
          NodeKey.NodeValue := aIniFile.ReadString(aSections[i], aItems[j], '');
//          NodeKey.Attributes[C_ATTR_CODE_TYPE]   := VarType(aIniFile.ReadString(aSections[i], aItems[j], ''));
//          NodeKey.Attributes[C_ATTR_VALUE]       := aIniFile.ReadString(aSections[i], aItems[j], '');
//          NodeKey.Attributes[C_ATTR_TIME_CHANGE] := DateTimeToStr(now);
        end;
      end;

      aXMLDoc.SaveToFile(aIniFileName);
      Result := True;
    finally
      NodeRoot    := nil;
      NodeSection := nil;
      NodeKey     := nil;
      FreeAndNil(aXMLDoc);
    end;

  finally
    aSections.Free;
    aIniFile.Free;
    aItems.Free;
  end;
end;

{ TXMLAttributes }

procedure TXMLAttributes.SetAttributeValue(aAttributeName: string; aValue: OleVariant);
var
  iAttrib: IXMLDOMAttribute;
begin
  if Assigned(FNode) then
  begin
    iAttrib := FXMLDOMDocument.createAttribute(aAttributeName);
    iAttrib.Value := aValue;
    FNode.Attributes.setNamedItem(iAttrib);
  end;
end;

constructor TXMLAttributes.Create(aXMLDOMDocument: IXMLDOMDocument);
begin
  FXMLDOMDocument := aXMLDOMDocument;
end;

function TXMLAttributes.GetAttributeValue(aAttributeName: string; aDefault: OleVariant): OleVariant;
var
  iNode: IXMLDOMNode;
begin
  Result := aDefault;
  if Assigned(FNode) then
  begin
    iNode := FNode.Attributes.getNamedItem(aAttributeName);
    if Assigned(iNode) and not(VarIsNull(iNode.nodeValue) or VarIsEmpty(iNode.nodeValue) or (VarToStr(iNode.nodeValue) = '')) then
      Result := iNode.nodeValue;
  end;
end;

function TXMLAttributes.GetAttributeValue(aAttributeIndex: Integer; aDefault: OleVariant): OleVariant;
var
  iNode: IXMLDOMNode;
begin
  Result := aDefault;
  if Assigned(FNode) then
  begin
    iNode := FNode.Attributes.item[aAttributeIndex];
    if Assigned(iNode) and not(VarIsNull(iNode.nodeValue) or VarIsEmpty(iNode.nodeValue) or (VarToStr(iNode.nodeValue) = '')) then
      Result := iNode.nodeValue;
  end;
end;

function TXMLAttributes.GetCount: Integer;
begin
  Result := 0;
  if Assigned(FNode) then
    FNode.Attributes.Length;
end;

procedure TXMLAttributes.AddNode;
begin
  if Assigned(FXMLDOMDocument) then
    FNode := FXMLDOMDocument.createNode(varNull, TXMLFile.C_KEY, '');
end;

procedure TXMLAttributes.InitNode(aXPath: string);
begin
  if Assigned(FXMLDOMDocument) then
    FNode := FXMLDOMDocument.selectSingleNode(aXPath);
end;

procedure TXMLAttributes.InitNode(aSection, aKey: string);
begin
  if Assigned(FXMLDOMDocument) and Assigned(FXMLDOMDocument.documentElement) then
    FNode := FXMLDOMDocument.selectSingleNode(C_VMS_XPATH_SEPARATOR + FXMLDOMDocument.documentElement.nodeName + C_VMS_XPATH_SEPARATOR + aSection + C_VMS_XPATH_SEPARATOR + aKey);
end;

function TXMLAttributes.IsExist(aAttributeName: string): Boolean;
begin
  Result := Assigned(FNode) and Assigned(FNode.Attributes.getNamedItem(aAttributeName));
end;

end.