{*******************************************************************************}
{                                                                               }
{             модуль vmsHtmlLib                                                 }
{                  v.3.0.0.7                                                    }
{             створено 10/05/2012                                               }
{                                                                               }
{  Модуль містить процедури та функції для роботи з Html-об'єктами              }
{                                                                               }
{*******************************************************************************}

unit vmsHtmlLib;

interface

uses
  //Standart units
  Windows, ActiveX, Classes, Forms, Graphics, MSHTML, RegularExpressions, SHDocVw, SysUtils,
  Variants,

  //vms units
  vmsHtmlConsts;

type
  TvmsHtmlLib = class(TObject)
    class function CodeMessageToHtml(const aCode: string): string;
    {
     Description:
       Заміна символів рядка на xml-(html)-теги
    }
    class function EncodeXMLStr(const aValue: string): string;
    {
     Description:
       конвертує тип TColor в кольорову палітру html
     Parameters:
       aWebBrowser - компонент TWebBrowser
    }
    class function ColorToHtml(aColor: TColor): string;
    {
     Description:
       встановлює текст SQL-запиту у вигляді html-тексту з підствіткою синтаксису
     Parameters:
       aSqlText - текст SQL-запиту
    }
    class function SqlToHtml(const aSqlText: string): string;
    {
     Description:
       Отримує виділений текст у вікні aWebBrowser
     Parameters:
       aWebBrowser - компонент TWebBrowser
    }
    class function GetSelectionText(var aWebBrowser: TWebBrowser): string;
    {
     Description:
       Зберігає текст html-текст в буфер обміну
     Parameters:
       aWebBrowser - компонент TWebBrowser
    }
    class procedure CopyToClipboard(var aWebBrowser: TWebBrowser);
    {
     Description:
       Відображає у вікні aWebBrowser html-текст
     Parameters:
       aWebBrowser - компонент TWebBrowser
       aHtmlText   - html-текст
    }
    class procedure LoadStringToBrowser(var aWebBrowser: TWebBrowser; const aHtmlText: string);
    {
     Description:
       Зберігає текст html-текст в зовнішній файл
     Parameters:
       aWebBrowser - компонент TWebBrowser
    }
    class procedure SaveHTMLSourceToFile(var aWebBrowser: TWebBrowser; const aFileName: string);
    {
     Description:
       Встановлює колір межі компонента TWebBrowser
     Parameters:
       aWebBrowser  - компонент TWebBrowser
       aBorderColor - колір
    }
    class procedure SetBorderColor(var aWebBrowser: TWebBrowser; aBorderColor: TColor);
    {
     Description:
       Встановлює стиль межі компонента TWebBrowser
     Parameters:
       aWebBrowser  - компонент TWebBrowser
       aBorderStyle - стиль: 'none'         No border is drawn
                             'dashed'       Border is a dashed line. (as of IE 5.5)
                             'dotted'       Border is a dotted line. (as of IE 5.5)
                             'double'       Border is a double line
                             'groove'       3-D groove is drawn
                             'inset'        3-D inset is drawn
                             'outset'       3-D outset is drawn
                             'ridge'        3-D ridge is drawn
                             'solid'        Border is a solid line
    }
    class procedure SetBorderStyle(var aWebBrowser: TWebBrowser; aBorderStyle: string);
    {
     Description:
       Повертає заповнений табличний тег <TABLE>
     Parameters:
       aCaptionHead - варіантний масив з заголовками таблиці: VarArrayOf(['Заголовок 1','Заголовок 2'])
    }
   class function GetTableTag(aColumns: Variant; aTableCaption: string = ''): string;
    {
     Description:
       Повертає заповнений рядок таблиці з тегами <TR><TD>
     Parameters:
       aLineText - варіантний масив з даними таблиці: VarArrayOf(['Заголовок 1','Заголовок 2'])
    }
    class function GetTableLineTag(aLineText: Variant): string;
    {
     Description:
       Повертає кольоровий текст
     Parameters:
       aText  - заданий текст
       aColor - колір, заданий текстом: red, green, blue або
                       типу TColor: clRed, clGreen, clBlue
    }
    class function GetColorTag(aText: string; aColor: TColor): string; overload;
    class function GetColorTag(aText: string; aColor: string): string; overload;
    class function GetSpoilerTag(aCaption, aText: string): string;
    class function GetSrcSQLTag(aCaption, aText: string): string;

    class function GetBoldText(aText: string): string;
    class function GetCenterText(aText: string): string;
  end;

implementation

class procedure TvmsHtmlLib.LoadStringToBrowser(var aWebBrowser: TWebBrowser; const aHtmlText: string);
var
  iDocument : IHTMLDocument2;
  vHtmlText : OleVariant;
begin
  if (aWebBrowser.Document = nil) then
    aWebBrowser.Navigate(C_VMS_HTML_BLANK);
  while (aWebBrowser.Document = nil) do
    Application.ProcessMessages;
  iDocument    := aWebBrowser.Document as IHTMLDocument2;
  vHtmlText    := VarArrayCreate([0, 0], varVariant);
  vHtmlText[0] := aHtmlText;
  iDocument.Write(PSafeArray(TVarData(vHtmlText).VArray));
  iDocument.Close;
end;

class procedure TvmsHtmlLib.CopyToClipboard(var aWebBrowser: TWebBrowser);
begin
  if (aWebBrowser.Document <> nil) then
  begin
    aWebBrowser.ExecWB(OLECMDID_SELECTALL,      OLECMDEXECOPT_DONTPROMPTUSER);
    aWebBrowser.ExecWB(OLECMDID_COPY,           OLECMDEXECOPT_DONTPROMPTUSER);
    aWebBrowser.ExecWB(OLECMDID_CLEARSELECTION, OLECMDEXECOPT_DONTPROMPTUSER);
  end;
end;

class function TvmsHtmlLib.GetColorTag(aText: string; aColor: TColor): string;
begin
  Result := GetColorTag(aText, ColorToHtml(aColor));
end;

class function TvmsHtmlLib.GetBoldText(aText: string): string;
begin
  Result := Concat('<b>', aText, '</b>');
end;

class function TvmsHtmlLib.GetCenterText(aText: string): string;
begin
  Result := Concat('<center>', aText, '</center>');
end;

class function TvmsHtmlLib.GetColorTag(aText, aColor: string): string;
begin
  Result := Concat('<font color="', aColor, '">', aText, '</font>');
end;

class function TvmsHtmlLib.GetSelectionText(var aWebBrowser: TWebBrowser): string;
var
  vDocument: Variant;
begin
  if (aWebBrowser.Document <> nil) then
  begin
    vDocument := aWebBrowser.Document;
    try
      Result := vDocument.Selection.CreateRange.Text
    finally
      vDocument := Unassigned;
    end;
  end
  else
    Result := '';
end;

class function TvmsHtmlLib.CodeMessageToHtml(const aCode: string): string;
begin
  if (aCode <> '') then
    //Result := vmsFrameText(aCode, '<br><font color="navy" size="2">[', ']</font>')
    Result := '<br><a href="' + aCode + '"><font color="navy" size="2">[' + aCode + ']</font></a>'
  else
    Result := aCode;
end;

class function TvmsHtmlLib.EncodeXMLStr(const aValue: string): string;
const
  HSym : array[0..3] of string = ('&amp;','&lt;','&gt;','&quot;');
  TSym : array[0..3] of string = ('&'    ,'<'   ,'>'   ,'"'     );
var
  i    : integer;
  sTmp : string;
begin
  for i := 1 to Length(aValue) do
    if (Ord(aValue[i]) in [32, 40..58]) or (Ord(aValue[i]) >= 65)then
      sTmp := Concat(sTmp, aValue[i])
    else if (Ord(aValue[i]) in [10]) then
      sTmp := Concat(sTmp, '<br>')
    else
    begin
      case aValue[i] of
       //' '  : sTmp := Concat(sTmp, '&nbsp;');        // space
       '<'  : sTmp := Concat(sTmp, '&lt;');     // <
       '>'  : sTmp := Concat(sTmp, '&gt;');     // >
       '&'  : sTmp := Concat(sTmp, '&amp;');    // &
       '"'  : sTmp := Concat(sTmp, '&quot;');   // "
       '''' : sTmp := Concat(sTmp, '&apos;');   // '
      else
        sTmp := Concat(sTmp, '&#' + IntToStr(Ord(aValue[i])) + ';');
    end;
  end;
  Result := sTmp;
end;

class function TvmsHtmlLib.ColorToHtml(aColor: TColor): string;
var
  nRGB: TColorRef;
begin
  nRGB   := ColorToRGB(aColor);
  Result := Format('#%.2x%.2x%.2x', [GetRValue(nRGB), GetGValue(nRGB), GetBValue(nRGB)]);
end;

class procedure TvmsHtmlLib.SetBorderStyle(var aWebBrowser: TWebBrowser; aBorderStyle: string);
var
  iDocument : IHTMLDocument2;
  iElement  : IHTMLElement;
begin
  iDocument := aWebBrowser.Document as IHTMLDocument2;
  if Assigned(iDocument) then
  begin
    iElement := iDocument.Body;
    if (iElement <> nil) then
      iElement.Style.BorderStyle := aBorderStyle;
  end;
end;

class procedure TvmsHtmlLib.SaveHTMLSourceToFile(var aWebBrowser: TWebBrowser; const aFileName: string);
var
  iPersistStream : IPersistStreamInit;
  iStreamAdapter : IStream;
  loFileStream   : TFileStream;
begin
  iPersistStream := aWebBrowser.Document as IPersistStreamInit;
  loFileStream   := TFileStream.Create(aFileName, fmCreate);
  try
    iStreamAdapter := TStreamAdapter.Create(loFileStream, soReference) as IStream;
    iPersistStream.Save(iStreamAdapter, True);
  finally
    loFileStream.Free;
  end;
end;

class procedure TvmsHtmlLib.SetBorderColor(var aWebBrowser: TWebBrowser; aBorderColor: TColor);
var
  iDocument : IHTMLDocument2;
  iElement  : IHTMLElement;
begin
  iDocument := aWebBrowser.Document as IHTMLDocument2;
  if Assigned(iDocument) then
  begin
    iElement := iDocument.Body;
    if (iElement <> nil) then
      iElement.Style.BorderColor := ColorToHtml(aBorderColor);
  end;
end;

class function TvmsHtmlLib.SqlToHtml(const aSqlText: string): string;
const
  C_COMMENTS_PATTERN = '(?is)((/\*.*?\*/)|(--.*?\n))';
  C_LEXEM_PATTERN = '(?i)(' +
    '\bAGGREGATE\b|\bALL\b|\bALTER\b|\bAND\b|\bANY\b|\bAS\b|\bASC\b|\bAVG\b|\bBEFORE\b|\bBEGIN\b|' +
    '\bBETWEEN\b|\bBULK\b|\bBY\b|\bCASE\b|\bCAST\b|\bCHAR\b|\bCHECK\b|\bCOLLECT\b|\bCOMMENT\b|' +
    '\bCOMMIT\b|\bCOUNT\b|\bCURRENT\b|\bCURRENT_USER\b|\bCURSOR\b|\bDATE\b\bDAY\b|\bDEC\b|' +
    '\bDECIMAL\b|\bDECLARE\b|\bDEFAULT\b|\bDELETE\b|\bDESC\b|\bDISTINCT\b|\bEACH\b|\bELSE\b|' +
    '\bELSIF\b|\bEND\b|\bEXCEPTION\b|\bEXECUTE\b|\bEXISTS\b|\bFALSE\b|\bFETCH\b|\bFIRST\b|' +
    '\bFOR\b|\bFORALL\b|\bFOUND\b|\bFROM\b|\bFULL\b|\bFUNCTION\b|\bGROUPING\b|\bHAVING\b|\bIF\b|' +
    '\bIN\b|\bINNER\b|\bINSERT\b|\bINTEGER\b|\bINTERSECT\b|\bINTERVAL\b|\bINTO\b|\bIS\b|\bJOIN\b|' +
    '\bLAST\b|\bLEFT\b|\bLEVEL\b|\bLIKE\b|\bLOOP\b|\bMAX\b|\bMIN\b|\bMONTH\b|\bNEXT\b|\bNEXTVAL\b|' +
    '\bNOT\b|\bNOTFOUND\b|\bNOWAIT\b|\bNULL\b|\bNULLS\b|\bNUMBER\b|\bNUMERIC\b|\bOF\b|\bOLD\b|' +
    '\bON\b|\bOR\b|\bORDER\b|\bOUT\b|\bOUTER\b|\bPLS_INTEGER\b|\bPOSITIVE\b|\bPRIOR\b|\bPROCEDURE\b|' +
    '\bRAISE\b|\bRANGE\b|\bRAW\b|\bREPLACE\b|\bRESULT\b|\bRETURN\b|\bRIGHT\b|\bROLLBACK\b|\bROW\b| ' +
    '\bROWCOUNT\b|\bROWID\b|\bROWTYPE\b|\bSELECT\b|\bSELF\b|\bSET\b|\bSETS\b|\bSTRING\b|\bSUBTYPE\b|' +
    '\bSUM\b|\bSYSDATE\b|\bTABLE\b|\bTHEN\b|\bTIME\b|\bTIMESTAMP\b|\bTO\b|\bTRANSACTION\b|' +
    '\bTRIGGER\b|\bTRIM\b|\bTRUE\b|\bTYPE\b|\bUNDER\b|\bUNION\b|\bUNIQUE\b|\bUPDATE\b|\bUROWID\b|' +
    '\bUSE\b|\bUSER\b|\bUSING\b|\bVALUE\b|\bVALUES\b|\bVARCHAR\b|\bVARCHAR2\b|\bVARIABLE\b|\bWHEN\b|' +
    '\bWHERE\b|\bWHILE\b|\bWITH\b|\bXOR\b|\bYEAR\b)';
begin
   Result := aSqlText.Replace(sLineBreak, C_VMS_HTML_BREAK);
   Result := TRegEx.Replace(Result, C_LEXEM_PATTERN, '<b>$1</b>');
   Result := TRegEx.Replace(Result, C_COMMENTS_PATTERN, '<font color="DarkCyan">$1</font>');
end;

class function TvmsHtmlLib.GetTableTag(aColumns: Variant; aTableCaption: string = ''): string;
const
  C_TABLE_TAG = '<TABLE width="100&#37;" border="1" bordercolor="gray" cols="%d" cellspacing="0" cellpadding="2">';
var
  i           : Integer;
  nArrayBound : Byte;
  sTableTag   : string;
  sTrTag      : string;
begin
  if VarIsArray(aColumns) then
  begin
    nArrayBound := VarArrayHighBound(aColumns, 1);
    sTableTag   := Format(C_TABLE_TAG, [nArrayBound]);
    if (aTableCaption <> '') then
      sTableTag := Concat(sTableTag, '<CAPTION>', aTableCaption, '</CAPTION>');
    sTrTag := '<THEAD><TR bgcolor="#85ACE3">';
    for i := VarArrayLowBound(aColumns, 1) to nArrayBound do
      sTrTag := Concat(sTrTag, '<TH>', VarToStr(aColumns[i]), '</TH>');
    sTrTag := Concat(sTrTag,  '</TR></THEAD>');
  end
  else
  begin
    sTableTag := Format(C_TABLE_TAG, [1]);
    if (aTableCaption <> '') then
      sTableTag := Concat(sTableTag, '<CAPTION>', aTableCaption, '</CAPTION>');
    sTrTag    := Concat('<THEAD><TR bgcolor="#85ACE3"><TH>', VarToStr(aColumns), '</TH></TR></THEAD>')
  end;
  Result := Concat(sTableTag, sTrTag);
end;

class function TvmsHtmlLib.GetSpoilerTag(aCaption, aText: string): string;
begin
  if (Trim(aText) <> '') then
    Result := Concat(
                   '<td class="msgBody">',
                     '<table width="96%" border="0" bgcolor="#c0c0c0" cellspacing="0" cellpadding="4" style="border:solid 1px #888888;margin:10px">',
                       '<tr>',
                         '<td>',
                           '<span style="font-family:monospace;padding:1px;cursor:pointer;background-color:#E8E8E8;border:1px solid #888888;txt-align:center;" ', 'onclick="var el=this.parentNode.parentNode.parentNode.rows[1]; el.style.display=el.style.display==''none''?'''':''none'';this.innerHTML=this.innerHTML==''+''?''-'':''+'';">+</span> ',
                           aCaption,
                         '</td>',
                       '</tr>',
                       '<tr style="display:none">',
                         '<td bgcolor="#E8E8E8">',
                           aText,
                         '</td>',
                      '</tr>',
                    '</table>',
                   '</td>');
end;

class function TvmsHtmlLib.GetSrcSQLTag(aCaption, aText: string): string;
begin
  if (Trim(aText) <> '') then
    Result := Concat(
                     '<table width="96%" border="0" bgcolor="#c0c0c0" cellspacing="0" cellpadding="4" style="border:solid 1px #888888; margin :10px">',
                       '<tr height="1">',
                         '<td>',
                           aCaption,
                         '</td>',
                       '</tr>',
                       '<tr>',
                         '<td bgcolor="#E8E8E8"><pre>',
                           SqlToHtml(aText),
                         '</pre></td>',
                      '</tr>',
                    '</table>');
end;

class function TvmsHtmlLib.GetTableLineTag(aLineText: Variant): string;
var
  i      : Integer;
  sTrTag : string;
begin
  if VarIsArray(aLineText) then
  begin
    sTrTag := '<TR>';
    for i := VarArrayLowBound(aLineText, 1) to VarArrayHighBound(aLineText, 1) do
      sTrTag := Concat(sTrTag, '<TD>', VarToStr(aLineText[i]), '</TD>');
    sTrTag := Concat(sTrTag, '</TR>');
  end
  else
    sTrTag := Concat('<TR><TD>', VarToStr(aLineText), '</TD></TR>');
  Result := sTrTag;
end;

end.
