{ FILEINFO.PAS v. 1.2
  Copyright (c) 2002 by Ted Vinke
  email: teddy@jouwfeestje.com
  Web:  jouwfeestje.com/go/fileinfo
  1.0 - date: 1 feb 2002
  1.1 - date: 29 feb 2002
  1.2 - date: 30 jun 2002

  Create an FileInfo object with as parameter the file
  you want info about. Then use the various functions of
  that object to retrieve the info.

  E.g.
  fiMyFile := TFileInfo.Create("winword.exe");
  ShowMessage(IntToStr(fiMyFile.GetFileSize));

  This software is provided as it is, without any kind of warranty 
  given. The author can not be held responsible for any kind of
  damage, problems etc. arised from using this product.
}

{Compiler version definitions}
{============================}

{$IFNDEF VER80}  //If not D1
  {$DEFINE D2_OR_HIGHER}
  {$IFNDEF VER90}  //If not D2
    {$DEFINE BCB1_OR_HIGHER}
    {$IFNDEF VER93}  //If not BCB 1
      {$DEFINE D3_OR_HIGHER}
      {$IFNDEF VER100}  //If not D3
        {$DEFINE BCB3_OR_HIGHER}
        {$IFNDEF VER110}  //IF not BCB 3
          {$DEFINE D4_OR_HIGHER}
          {$IFNDEF VER120}  //If not D4
            {$DEFINE BCB4_OR_HIGHER}
            {$IFNDEF VER125}  //If not BCB 4
              {$DEFINE D5_OR_HIGHER}
              {$IFNDEF VER130}  //If not D5
                {$DEFINE D6_OR_HIGHER}
              {$ENDIF}
            {$ENDIF}
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{-----------------------------------------------------------------------------}

unit FileInfo;

interface

{$IFDEF D6_OR_HIGHER}   //870
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARN UNIT_PLATFORM OFF}
{$ENDIF}

uses
  Forms, Dialogs, Windows, StdCtrls, Comctrls, SysUtils, Classes,
  ShellApi, ShlObj, ImageHlp, Ole2, Oleauto;

const
  VERSION = 1.3;

  // FileGetIcon
  ATTR_DEFAULT = SHGFI_DISPLAYNAME or SHGFI_EXETYPE or SHGFI_TYPENAME;
  ATTR_ALL     = SHGFI_ATTRIBUTES or ATTR_DEFAULT;
  ATTR_ICON    = SHGFI_ICON or ATTR_DEFAULT;
  // FileShellOp
  fofAllowUndo      = FOF_ALLOWUNDO;
  fofFilesOnly      = FOF_FILESONLY;
  fofNoConfirm      = FOF_NOCONFIRMATION;
  fofNoConfirmDir   = FOF_NOCONFIRMMKDIR;
  fofRenameOnColl   = FOF_RENAMEONCOLLISION;
  fofSilent         = FOF_SILENT;
  fofSimpleProgress = FOF_SIMPLEPROGRESS;
  // GetWordInfo
  PID_TITLE = $00000002;
  PID_SUBJECT = $00000003;
  PID_AUTHOR = $00000004;
  PID_KEYWORDS = $00000005;
  PID_COMMENTS = $00000006;
  PID_TEMPLATE = $00000007;
  PID_LASTAUTHOR = $00000008;
  PID_REVNUMBER = $00000009;
  PID_EDITTIME = $0000000A;
  PID_LASTPRINTED = $0000000B;
  PID_CRAETE_DTM = $0000000C;
  PID_LASTSAVE_DTM = $0000000D;
  PID_PAGECOUNT = $0000000E;
  PID_WORDCOUNT = $0000000F;
  PID_CHARCOUNT = $00000010;
  PID_THUMBAIL = $00000011;
  PID_APPNAME = $00000012;
  PID_SECURITY = $00000013;
  // GetMP3
  TAGLEN = 127;
  // GetMP3ExInfo
  { MPEG version indexes }
  MPEG_VERSION_UNKNOWN = 0; { Unknown     }
  MPEG_VERSION_1 = 1;       { Version 1   }
  MPEG_VERSION_2 = 2;       { Version 2   }
  MPEG_VERSION_25 = 3;      { Version 2.5 }

  { Description of MPEG version index }
  MPEG_VERSIONS : array[0..3] of string = ('Unknown', '1.0', '2.0', '2.5');

  { Channel mode (number of channels) in MPEG file }
  MPEG_MD_STEREO = 0;            { Stereo }
  MPEG_MD_JOINT_STEREO = 1;      { Stereo }
  MPEG_MD_DUAL_CHANNEL = 2;      { Stereo }
  MPEG_MD_MONO = 3;              { Mono   }

  { Description of number of channels }
  MPEG_MODES : array[0..3] of string = ('Stereo', 'Joint-Stereo',
                                        'Dual-Channel', 'Single-Channel');

  { Description of layer value }
  MPEG_LAYERS : array[0..3] of string = ('Unknown', 'I', 'II', 'III');

  {
    Sampling rates table.
    You can read mpeg sampling frequency as
    MPEG_SAMPLE_RATES[mpeg_version_index][samplerate_index]
  }
  MPEG_SAMPLE_RATES : array[1..3] of array[0..3] of word =
     { Version 1   }
    ((44100, 48000, 32000, 0),
     { Version 2   }
     (22050, 24000, 16000, 0),
     { Version 2.5 }
     (11025, 12000, 8000, 0));

  {
    Predefined bitrate table.
    Right bitrate is MPEG_BIT_RATES[mpeg_version_index][layer][bitrate_index]
  }
  MPEG_BIT_RATES : array[1..3] of array[1..3] of array[0..15] of word =
       { Version 1, Layer I     }
     (((0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,0),
       { Version 1, Layer II    }
       (0,32,48,56, 64, 80, 96,112,128,160,192,224,256,320,384,0),
       { Version 1, Layer III   }
       (0,32,40,48, 56, 64, 80, 96,112,128,160,192,224,256,320,0)),
       { Version 2, Layer I     }
      ((0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,0),
       { Version 2, Layer II    }
       (0,32,48,56, 64, 80, 96,112,128,160,192,224,256,320,384,0),
       { Version 2, Layer III   }
       (0, 8,16,24, 32, 64, 80, 56, 64,128,160,112,128,256,320,0)),
       { Version 2.5, Layer I   }
      ((0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,0),
       { Version 2.5, Layer II  }
       (0,32,48,56, 64, 80, 96,112,128,160,192,224,256,320,384,0),
       { Version 2.5, Layer III }
       (0, 8,16,24, 32, 64, 80, 56, 64,128,160,112,128,256,320,0)));

  { Types of MPEG AUDIO DATAFILE }
  MPEG_DF_CUSTOM = 0;
  MPEG_DF_CATALOGUE = 1;
  MPEG_DF_ORDER_FORM = 2;

  { Description of MPEG AUDIO DATAFILE type }
  MPEG_DATAFILE_TYPES : array[0..2] of string = ('Custom','Catalogue',
                                                 'Order form');

  { Sign for MPEG Audio Datafile. This is used in MPEG Audio Datafile
    header to identify file as such. First eight bytes (i.e #9'MP3DATA')
    are file id, and rest two bytes are version and subversion numbers.
    Do not change it. }
  MPEG_DATAFILE_SIGN : string[9] = 'MP3DATA'+#01+#02;

  { File types that unit can recognize and read }
  FT_UNKNOWN = 0;                { Unknown }
  FT_WINAMP_PLAYLIST = 1;        { WinAmp playlist (*.m3u) }
  FT_MPEG_DATAFILE = 2;          { MPEG Audio Datafile (*.m3d) }
  FT_MPEG_AUDIO = 3;             { MPEG Audio }

type
  TIconSize = (isSmall, isLarge, isOpen);
  TObjAttr  = (oaCanCopy, oaCanDelete, oaCanLink, oaCanMove,
    oaCanRename, oaDropTarget, oaHasPropSheet,
    oaIsLink, oaIsReadOnly, oaIsShare, oaHasSubFolder,
    oaFileSys, oaFileSysAnc, oaIsFolder, oaRemovable);
  TTypeExe  = (teWin32, teDOS, teWin16, tePIF, tePOSIX, teOS2, teUnknown, teError);
  TSubType  = (stUnknown, stApp, stDLL, stSLL,
    stDrvUnknown, stDrvComm, stDrvPrint, stDrvKeyb,
    stDrvLang, stDrvDisplay,
    stDrvMouse, stDrvNetwork, stDrvSystem, stDrvInstall, stDrvSound,
    stFntUnknown, stFntRaster, stFntVector, stFntTrueType, stVXD);
  TOpFunc   = (foCopy, foDelete, foMove, foRename);

type
  TFileVersionInfo = record
    FileType,
    CompanyName,
    FileDescription,
    FileVersion,
    InternalName,
    LegalCopyRight,
    LegalTradeMarks,
    OriginalFileName,
    ProductName,
    ProductVersion,
    Comments,
    SpecialBuildStr,
    PrivateBuildStr: string;
    FileFunction: TSubType;
    DebugBuild,
    PreRelease,
    SpecialBuild,
    PrivateBuild,
    Patched,
    InfoInferred: Boolean;
  end;

type
  TDocInfo = record
    Title,
    Subject,
    Author,
    Keywords,
    Comments,
    Template,
    LastAuthor,
    RevNumber: string;
    EditTime: integer;
    LastPrintedDate,
    CreateDate,
    LastSaveDate: TDateTime;
    PageCount,
    WordCount,
    CharCount,
    Error: integer;
  end;

type
  TMP3Info = record
    Tag,
    Artist,
    Title,
    Album,
    Comment,
    Year,
    Genre: string;
    Genres: TStrings;
    GenreID: Byte;
    Valid: boolean;
    Error: integer;
  end;

type
  TMP3ExInfo = packed record
    Duration : word;         { Song duration }
    FileLength : LongInt;    { File length in bytes}
    Version : byte;          { MPEG audio version index (1 - Version 1,
                               2 - Version 2,  3 - Version 2.5,
                               0 - unknown }
    Layer : byte;            { Layer (1, 2, 3, 0 - unknown) }
    SampleRate : LongInt;    { Sampling rate in Hz}
    BitRate : LongInt;       { Bit Rate }
    Mode : byte;             { Number of channels (0 - Stereo,
                               1 - Joint-Stereo, 2 - Dual-channel,
                               3 - Single-Channel) }
    Copyright : Boolean;     { Copyrighted? }
    Original : Boolean;      { Original? }
    ErrorProt : boolean; { Error protected? }
    Padding : Boolean;       { If frame is padded }
    FrameLength : Word;      { total frame size including CRC }
    Error: integer;
  end;

type
  TUpdateFunction = procedure(Pos, MaxPos: Longint; RemainSecs: Integer);

type
  PPropertySetHeader = ^TPropertySetHeader;
  TPropertySetHeader = record
    wByteOrder: Word;   // Always 0xFFFE
    wFormat: Word ;     // Always 0
    dwOSVer: DWORD;     // System version
    clsid: TCLSID;      // Application CLSID
    dwReserved: DWORD;  // Should be 1
  end;

  TFMTID = TCLSID;

  PFormatIDOffset = ^TFormatIDOffset;
  TFormatIDOffset = record
    fmtid: TFMTID;      // Semantic name of a section
    dwOffset: DWORD;    // Offset from start of whole property set
                        // stream to the section
  end;

  PPropertySectionHeader = ^TPropertySectionHeader;
  TPropertySectionHeader = record
    cbSection: DWORD;    // Size of section
    cProperties: DWORD;  // Count of properties in section
  end;

  PPropertyIDOffset = ^TPropertyIDOffset;
  TPropertyIDOffset = record
    propid: DWORD;      // Name of a property
    dwOffset: DWORD;    // Offset from the start of the section to that
                        // property type/value pair
  end;

  PPropertyIDOffsetList = ^TPropertyIDOffsetList;
  TPropertyIDOffsetList = array[0..255] of TPropertyIDOffset;

  PSerializedPropertyValue = ^TSerializedPropertyValue;
  TSerializedPropertyValue = record
    dwType: DWORD;       // Type tag
    prgb: PBYTE;         // The actual property value
  end;

  PSerializedPropertyValueList = ^TSerializedPropertyValueList;
  TSerializedPropertyValueList = array[0..255] of TSerializedPropertyValue;

  PStringProperty = ^TStringProperty;
  TStringProperty = record
    propid: DWORD;
    Value: AnsiString;
  end;

  PIntegerProperty = ^TIntegerProperty;
  TIntegerProperty = record
    propid: DWORD;
    Value: Integer;
  end;

  PFileTimeProperty = ^TFileTimeProperty;
  TFileTimeProperty = record
    propid: DWORD;
    Value: TFileTime;
  end;


type
  TFileInfo = class(TObject)
  private
    { Private declarations }
    FFileName: string;
    FdwFileAttr, FcbFileInfo, FuFlags: Cardinal;
    {$IFNDEF D4_OR_HIGHER}   // for Delphi 3
    FshFileInfo: TSHFILEINFO;
    {$ENDIF}
    {$IFDEF D4_OR_HIGHER}   // for Delphi 4 or higher
    FshFileInfo: SHFILEINFO;
    {$ENDIF}
    FdiDocInfo: TDocInfo;

    FmiMP3Info: TMP3Info;
    Saved: boolean;
    MP3Genres: TStrings;
    FmiMP3ExInfo: TMP3ExInfo;

    stgOpen: IStorage;
    stm: IStream;
    PropertySetHeader: TPropertySetHeader;
    FormatIDOffset: TFormatIDOffset;
    PropertySectionHeader: TPropertySectionHeader;
    prgPropIDOffset: PPropertyIDOffsetList;
    prgPropertyValue: PSerializedPropertyValueList;
    UpdateProc: procedure (Pos, MaxPos: Longint; RemainSecs: Integer);

    // GetDoc routines
    procedure InternalOpen;
    procedure InternalClose;
    procedure InternalInitPropertyDefs;
    procedure AddProperty(propid: DWORD; Value: Pointer);

    function OpenStorage: HResult;
    function OpenStream: HResult;
    function ReadPropertySetHeader: HResult;
    function ReadFormatIdOffset: HResult;
    function ReadPropertySectionHeader: HResult;
    function ReadPropertyIdOffset: HResult;
    function ReadPropertySet: HResult;
    function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
    function FileTimeToElapsedTime(FileTime: TFileTime): Integer;
    // GetMP3 and SetMP3 routines
    function MP3Open: boolean;
    function MP3RemoveID3: boolean;
    function MP3Save: boolean;
    // GetMP3Ex
    function MPGCalcFrameLength (SampleRate, BitRate : LongInt; Padding : Boolean) : Integer;
    procedure MPGResetData;
    function MPGDecodeHeader (MPGHeader : LongInt) : boolean;
    function MPGFrameHeaderValid: boolean;
    // main API call for some functions
    procedure PerformSHGetFileInfo;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(const FileName: string);
    function GetDateTime(var Created: TDateTime; var Accessed: TDateTime;
      var Modified: TDateTime): Boolean;
    function SetDateTime(const DateTime: TDateTime): Integer;
    function GetFileAttr: Integer;
    function SetFileAttr(Attr: Integer): Integer;
    function GetFileNameDisplay: string;
    function GetFileNameFull: string;
    function GetFileType: string;
    function GetFileTypeExe: TTypeExe;
    function GetFileSize: Longint;
    function GetFileIcon(isSize: TIconSize): hIcon;
    function GetFileIconAmount: Integer;
    function GetFileIconByIndex(Index: Integer): hIcon;
    function GetFileOwner(var Domain, Username: string): Boolean;
    function GetFileApp: string;
    function GetDLLInfo: TStringList;
    function GetDOCInfo: TDocInfo;
    function GetMP3Info: TMP3Info;
    function GetMP3ExInfo: TMP3ExInfo;
    function SetMP3Info(NewMP3Info: TMP3Info; RemoveID3: boolean): TMP3Info;
    function GetFileInfo: TFileVersionInfo;
    function GetObjAttr(oaAttr: TObjAttr): Boolean;
    function AttachStream(MemoryStream: TMemoryStream): Boolean;
    function RetrieveStream(MemoryStream: TMemoryStream): Boolean;
    procedure Execute(Params: string);
    function FileShellOp(const DestinationFile: string; OpFunc: TOpFunc;
      OpFlags: Integer; ProgressTitle: string): Boolean;
    function FileCopySilent(const DestinationFile: string;
      FailIfExists: Boolean): Boolean;
    function FileCopyCustom(const DestinationFile: string;
      Update: TUpdateFunction): Boolean;
    function IsEqualWith(const OtherFile: string): Boolean;
    function IsInUse: Boolean;
    function IsAscii: Boolean;
    procedure DialogOpenWith;
    procedure DialogProperties;
  end;

implementation

{ -- public -- }

// Create
// Initialize the the object with a given filename (e.g. 'c:\winnt\explorer.exe')
// You can use wildcards (e.g. '*.*'), but the fileinfo functions won't work, only
// the FileShellOp for copying and deleting, etc.
constructor TFileInfo.Create(const FileName: string);
begin
  FFileName := FileName;
end;

// GetDateTime: determine the creation, modified and acces time of
// the file
// Returns: creation, modified and acces time in vars Created, Accessed and Modified
function TFileInfo.GetDateTime(var Created: TDateTime;
  var Accessed: TDateTime; var Modified: TDateTime): Boolean;
var
  h: THandle;
  Info1, Info2, Info3: TFileTime;
  {$IFNDEF D4_OR_HIGHER}   // for Delphi 3
    SysTimeStruct: TSYSTEMTIME;
  {$ENDIF}
  {$IFDEF D4_OR_HIGHER}   // for Delphi 4 or higher
    SysTimeStruct: SYSTEMTIME;
  {$ENDIF}
  TimeZoneInfo: TTimeZoneInformation; 
  Bias: Double; 
begin 
  Result := False;
  Bias   := 0;
  h      := FileOpen(FFileName, fmOpenRead or fmShareDenyNone);
  if h > 0 then  
  begin 
    try 
      if GetTimeZoneInformation(TimeZoneInfo) <> $FFFFFFFF then 
        Bias := TimeZoneInfo.Bias / 1440; // 60x24
      GetFileTime(h, @Info1, @Info2, @Info3); 
      if FileTimeToSystemTime(Info1, SysTimeStruct) then 
        Created := SystemTimeToDateTime(SysTimeStruct) - Bias; 
      if FileTimeToSystemTime(Info2, SysTimeStruct) then 
        Accessed := SystemTimeToDateTime(SysTimeStruct) - Bias; 
      if FileTimeToSystemTime(Info3, SysTimeStruct) then 
        Modified := SystemTimeToDateTime(SysTimeStruct) - Bias; 
      Result := True; 
    finally 
      FileClose(h); 
    end; 
  end; 
end;

// SetDateTime: sets the DOS date-time stamp of the file
// Returns: zero if the function was successful. Otherwise the return value is a Windows error code.
function TFileInfo.SetDateTime(const DateTime: TDateTime): Integer;
var
  FileHandle: Integer;
  Succes: Integer;
begin
  FileHandle := FileOpen(FFileName, fmOpenRead);
  Succes     := FileSetDate(FileHandle, DateTimeToFileDate(DateTime));
  FileClose(FileHandle);
  Result := Succes;
end;

// GetFileAttr: retrieves the attributes of the file
// Returns: attributes of the file as a string of bits. A return value of -1 indicates that an error occurred.
// Values to compare result with: faReadOnly, faHidden, faSysFile, faVolumeID, faDirectory, faArchive or faAnyFile
function TFileInfo.GetFileAttr: Integer;
begin
  Result := FileGetAttr(FFileName);
end;

// SetFileAttr: sets the file attributes of the file to the value given by Attr.
// Resturns: zero if the function was successful. Otherwise the return value is a Windows error code.
function TFileInfo.SetFileAttr(Attr: Integer): Integer;
begin
  Result := FileSetAttr(FFileName, Attr);
end;

// GetFileNameDisplay
// Returns: displayname of the file
function TFileInfo.GetFileNameDisplay: string;
begin
  FuFlags := ATTR_ALL;
  PerformSHGetFileInfo;
  Result := string(FshFileInfo.szDisplayName);
end;

// GetFileNameFull
// Returns: fullpathname of the file (copy of the constructor param)
function TFileInfo.GetFileNameFull: string;
begin
  Result := FFileName;
end;

// GetFileType
// Returns: filetype of the file e.g. 'Ms Excel Worksheet'
function TFileInfo.GetFileType: string;
begin
  FuFlags := ATTR_ALL;
  PerformSHGetFileInfo;
  Result := string(FshFileInfo.szTypeName);
end;

// GetFileTypeExe: returns type executable. Win95/98 not supported
// Returns: type executable, these can be:
//  teWin32, teDos, teWin16, tePIF, tePOSIX or teOS2
function TFileInfo.GetFileTypeExe: TTypeExe;
var
  BinaryType: DWORD;
begin
  if GetBinaryType(PChar(FFileName), Binarytype) then 
    case BinaryType of 
      SCS_32BIT_BINARY: Result := teWin32;
      SCS_DOS_BINARY: Result   := teDOS;
      SCS_WOW_BINARY: Result   := teWin16;
      SCS_PIF_BINARY: Result   := tePIF;
      SCS_POSIX_BINARY: Result := tePOSIX;
      SCS_OS216_BINARY: Result := teOS2;
      else
        Result := teUnknown;
    end
  else 
    Result := teError; 
end;

// GetFileSize
// Returns: filesize in bytes, -1 on error
function TFileInfo.GetFileSize: Longint;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(ExpandFileName(FFileName), faAnyFile, SearchRec) = 0 then
  begin
    Result := SearchRec.Size;
    FindClose(SearchRec);
  end
  else
    Result := -1;
end;

// GetFileIcon: gets the file's small or large icon specified by isSize
// Resturns: handle of icon of the file
// e.g. assign it to Application.Icon.Handle
function TFileInfo.GetFileIcon(isSize: TIconSize): hIcon;
begin
  case isSize of
    isSmall: FuFlags := (SHGFI_ICON or SHGFI_SMALLICON);
    isLarge: FuFlags := (SHGFI_ICON or SHGFI_LARGEICON);
    isOpen: FuFlags  := (SHGFI_ICON or SHGFI_OPENICON);
    else
      FuFlags := SHGFI_ICON or SHGFI_SMALLICON;
  end;
  PerformSHGetFileInfo;
  Result := FshFileInfo.hIcon;
end;

// GetFileIconAmount: returns amount of icons the the file
function TFileInfo.GetFileIconAmount: Integer;
begin
  Result := ExtractIcon(Application.Handle, PChar(FFileName), UINT(-1));
end;

// GetFileIconByIndex: returns icon from specified by param Index
function TFileInfo.GetFileIconByIndex(Index: Integer): hIcon;
begin
  Result := ExtractIcon(Application.Handle, PChar(FFileName), Index);
end;

// GetFileOwner
// Retrieve the owner who created the file and the domain
// on which it was created. Works only under Win NT.
// Returns: domain and username
function TFileInfo.GetFileOwner(var Domain, Username: string): Boolean;
var
  SecDescr: PSecurityDescriptor; 
  SizeNeeded, SizeNeeded2: DWORD; 
  OwnerSID: PSID;
  OwnerDefault: BOOL; 
  OwnerName, DomainName: PChar; 
  OwnerType: SID_NAME_USE; 
begin
  GetFileOwner := False;
  GetMem(SecDescr, 1024); 
  GetMem(OwnerSID, SizeOf(PSID));
  GetMem(OwnerName, 1024); 
  GetMem(DomainName, 1024); 
  try 
    if not GetFileSecurity(PChar(FFileName),
      OWNER_SECURITY_INFORMATION, 
      SecDescr, 1024, SizeNeeded) then 
      Exit; 
    if not GetSecurityDescriptorOwner(SecDescr, 
      OwnerSID, OwnerDefault) then 
      Exit; 
    SizeNeeded  := 1024; 
    SizeNeeded2 := 1024; 
    if not LookupAccountSID(nil, OwnerSID, OwnerName, 
      SizeNeeded, DomainName, SizeNeeded2, OwnerType) then
      Exit; 
    Domain   := DomainName; 
    Username := OwnerName; 
  finally 
    FreeMem(SecDescr); 
    FreeMem(OwnerName); 
    FreeMem(DomainName);
  end; 
  GetFileOwner := True; 
end;

// GetFileApp
// Returns: full path to associated application
function TFileInfo.GetFileApp: string;
var
  app: array[1..250] of Char;
  i: Integer;
  DefaultDir: string;
begin
  DefaultDir := GetCurrentDir;
  FillChar(app, SizeOf(app), ' ');
  app[250] := #0;
  i        := FindExecutable(@FFileName[1], @DefaultDir[1], @app[1]);
  if i <= 32 then
    Result := ''
  else
    Result := app;
end;

// GetDLLInfo
// Returns: stringlist with all exported function inside if the file is a DLL
function TFileInfo.GetDLLInfo: TStringList;
type
  chararr = array [0..$FFFFFF] of Char;
var
  FunctionList: TStringList;
  H: THandle;
  I, fc: Integer;
  st, DllName: string;
  arr: Pointer;
  ImageDebugInformation: PImageDebugInformation;
begin
  DllName      := FFileName;
  FunctionList := TStringList.Create();
  FunctionList.Clear;
  DLLName := ExpandFileName(DLLName);
  if FileExists(DLLName) then
  begin
    H := CreateFile(PChar(DLLName), GENERIC_READ, FILE_SHARE_READ or
      FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if H <> INVALID_HANDLE_VALUE then
      try
        ImageDebugInformation := MapDebugInformation(H, PChar(DLLName), nil, 0);
        if ImageDebugInformation <> nil then
          try
            arr := ImageDebugInformation^.ExportedNames;
            fc  := 0;
            for I := 0 to ImageDebugInformation^.ExportedNamesSize - 1 do
              if chararr(arr^)[I] = #0 then
              begin
                st := PChar(@chararr(arr^)[fc]);
                if Length(st) > 0 then
                  FunctionList.Add(st);
                if (I > 0) and (chararr(arr^)[I - 1] = #0) then
                  Break;
                fc := I + 1
              end
            finally
              UnmapDebugInformation(ImageDebugInformation)
          end
        finally
          CloseHandle(H)
      end
  end;
  Result := FunctionList;
end;

// GetDOCInfo: get the summary information from a MS Word file
// Returns: TDocInfo record with all information. The error-field
// of the record contains - 1 on succes, else one of the following
// errorcodes
// Error:       0 = file doesn't exist!
//              1 = OLE-error occured
function TFileInfo.GetDOCInfo: TDocInfo;
begin
  FdiDocInfo.Error := -1;
  stgOpen:=nil;
  stm:=nil;
  prgPropIDOffset:=nil;
  prgPropertyValue:=nil;
  if FileExists(FFileName) then
  begin
    try
      InternalOpen;
      InternalClose;
    except
      FdiDocInfo.Error := 1; // OLE-error occured
    end;
  end
  else
    FdiDocInfo.Error := 0; // File doesn't exist
  Result := FdiDocInfo;
end;

// GetMP3Info
// Returns all taginfo from a MP3 file in a record of type TMP3Info. The error-
// field of the record contains -1 if routine went succesfull, otherwise one of
// the following errorcodes
// Error: 0 = File doesn`t exist !
//        1 = Can´t write ID3 tag information !
//        2 = Can't read ID3 tag information !
//        3 = Wrong fileformat;
//        4 = File is already untagged !
//        5 = Could not open file !
function TFileInfo.GetMP3Info: TMP3Info;
begin
  FmiMP3Info.Error   := -1;
  FmiMP3Info.GenreID := 12;
  FmiMP3Info.Valid := False;
  MP3Genres := TStringList.Create;
  MP3Genres.CommaText :=
   '"Blues","Classic Rock","Country","Dance","Disco","Funk","Grunge","Hip-Hop","Jazz","Metal","New Age","Oldies",'
   +'"Other","Pop","R&B","Rap","Reggae","Rock","Techno","Industrial","Alternative","Ska","Death Metal","Pranks",'
   +'"Soundtrack","Euro-Techno","Ambient","Trip-Hop","Vocal","Jazz+Funk","Fusion","Trance","Classical","Instrumental",'
   +'"Acid","House","Game","Sound Clip","Gospel","Noise","AlternRock","Bass","Soul","Punk","Space","Meditative",'
   +'"Instrumental Pop","Instrumental Rock","Ethnic","Gothic","Darkwave","Techno-Industrial","Electronic","Pop-Folk",'
   +'"Eurodance","Dream","Southern Rock","Comedy","Cult","Gangsta","Top 40","Christian Rap","Pop/Funk","Jungle",'
   +'"Native American","Cabaret","New Wave","Psychedelic","Rave","Showtunes","Trailer","Lo-Fi","Tribal","Acid Punk",'
   +'"Acid Jazz","Polka","Retro","Musical","Rock & Roll","Hard Rock","Folk","Folk/Rock","National Folk","Swing","Bebob",'
   +'"Latin","Revival","Celtic","Bluegrass","Avantgarde","Gothic Rock","Progressive Rock","Psychedelic Rock","Symphonic Rock",'
   +'"Slow Rock","Big Band","Chorus","Easy Listening","Acoustic","Humour","Speech","Chanson","Opera","Chamber Music","Sonata",'
   +'"Symphony","Booty Bass","Primus","Porn Groove","Satire","Slow Jam","Club","Tango","Samba","Folklore"';
  MP3Open;
  FmiMP3Info.Genres := MP3Genres;
  Result := FmiMP3Info;
end;

// GetMP3ExInfo
// Error: 0 : File doesn't exists!
//        1 : Unable to open file or acces denied!
//        2 : Unable to read header
function TFileInfo.GetMP3ExInfo: TMP3ExInfo;
var
  mpfile:file;
  mp3hdrread : array[1..8] of byte;
  mp3hdr : LongInt ABSOLUTE mp3hdrread;
  tempbyte : byte;
  frames,tempLongInt : LongInt;
  FFirstValidFrameHeaderPosition : LongInt;
  FFileDetectionPrecision : Integer;
  buffer:array[1..256] of char;
begin
  FmiMP3ExInfo.Error := -1;
  MPGResetData;
  if fileexists(FFilename) then
   begin
    assignfile(mpfile,FFilename);
    FileMode := 0;
    try
    {$I-}
    Reset (mpfile,1);
    {$I+}
    except
      FmiMP3ExInfo.Error := 1; // unable to open file or acces denied
      Result := FmiMP3ExInfo;
      exit;
    end;
    if (FileSize(mpfile) > 5) then begin
{      Data.FileDateTime := FileAge (fileName);
      Data.FileAttr := FileGetAttr (FileName);}
      FmiMP3ExInfo.FileLength := FileSize (mpfile);

      repeat
        { read MPEG header from file }
        BlockRead (mpfile, mp3hdrread,4);
        tempbyte := mp3hdrread[1];
        mp3hdrread[1] := mp3hdrread[4];
        mp3hdrread[4] := tempbyte;
        tempbyte := mp3hdrread[2];
        mp3hdrread[2] := mp3hdrread[3];
        mp3hdrread[3] := tempbyte;
        FFileDetectionPRecision:=0;
        While (not MPGDecodeHeader (mp3hdr)) and (not Eof (mpfile)) and
              ((FilePos(mpfile) <= FFileDetectionPrecision)
              or (FFileDetectionPRecision = 0))
        do begin
          { if mpeg header is not at the begining of the file, search file
            to find proper frame sync. This block can be speed up by reading
            blocks of bytes instead reading single byte from file }
           mp3hdr := mp3hdr shl 8;
           BlockRead (mpfile, tempbyte,1);
           mp3hdrread[1] := tempbyte;

        end; { while }

        FFirstValidFrameHeaderPosition := FilePos (mpfile)-4;
        tempLongInt := Filesize(mpfile) - fFirstValidFrameHeaderPosition - FmiMP3ExInfo.FrameLength + (2 * Byte(FmiMP3ExInfo.ErrorProt));

        If (not MPGFrameHeaderValid) or (TempLongInt <= 0) then begin
          MPGResetData;
{          Data.FileName := ExpandFileName (tempStr);}
          FmiMP3ExInfo.FileLength := FileSize (mpfile);
        end else begin
          { Ok, one header is found, but that is not good proof that file realy
            is MPEG Audio. But, if we look for the next header which must be
            FrameLength bytes after first one, we may be very sure file is
            valid. }
          Seek (mpfile, fFirstValidFrameHeaderPosition + FmiMP3ExInfo.FrameLength);
          BlockRead (mpfile, mp3hdrread,4);
          tempbyte := mp3hdrread[1];
          mp3hdrread[1] := mp3hdrread[4];
          mp3hdrread[4] := tempbyte;
          tempbyte := mp3hdrread[2];
          mp3hdrread[2] := mp3hdrread[3];
          mp3hdrread[3] := tempbyte;

        end; { if }
      until MPGFrameHeaderValid or Eof (mpfile) or ((FilePos(mpfile) > FFileDetectionPrecision) and (FFileDetectionPrecision > 0));
     if Eof (mpfile) or ((FilePos(mpfile) > FFileDetectionPrecision) and (FFileDetectionPrecision > 0)) then begin
       FmiMP3ExInfo.Error := 2; // unable to read headers
       Result := FmiMP3ExInfo;
       exit;
     end else
      begin
       seek(mpfile,fFirstValidFrameHeaderPosition+36);
       blockread(mpfile,buffer,256);
       if (buffer[1]='X') and (buffer[2]='i') and (buffer[3]='n') and (buffer[4]='g') then
       if buffer[8]=#15 then
        begin
         frames:=ord(buffer[9]);
         frames:=frames*256+ord(buffer[10]);
         frames:=frames*256+ord(buffer[11]);
         frames:=frames*256+ord(buffer[12]);
         FmiMP3ExInfo.framelength:=FmiMP3ExInfo.FileLength div frames;
         FmiMP3ExInfo.bitrate:=trunc(FmiMP3ExInfo.framelength*FmiMP3ExInfo.samplerate / 144000)- Integer (FmiMP3ExInfo.Padding);
         FmiMP3ExInfo.Duration := (FmiMP3ExInfo.FileLength*8) div (longint(FmiMP3ExInfo.Bitrate)*1000);
        end;
       seek(mpfile,fFirstValidFrameHeaderPosition);
       blockread(mpfile,mp3hdrread,8);

      end;
    end; { if }
    closefile(mpfile);
   end {fileexists}
   else begin
     FmiMP3ExInfo.Error := 0; // File doesn't exist
   end;
   Result := FmiMP3ExInfo;
end;

// SetMP3Info - sets new tags according to record TMP3Info when RemoveID3 is false.
// Delete the ID3 tags when DeleteID3 is true.
// Returns: returns the new TMP3Info record with in the error-field -1
// on succes, else the errorcode on failure. See GetMP3Info for errorcodes.
// Always do GetMP3Info first, before calling this routine
function TFileInfo.SetMP3Info(NewMP3Info: TMP3Info; RemoveID3: boolean): TMP3Info;
begin
  FmiMP3Info := NewMP3Info;
  FmiMP3Info.Error   := -1;
  if (RemoveID3) then
    MP3RemoveID3
  else
    MP3Save;
  Result := FmiMP3Info;
end;

// GetFileVersion
// Get the file information
function TFileInfo.GetFileInfo: TFileVersionInfo;
var
  rSHFI: TSHFileInfo;
  iRet: Integer;
  VerSize: Integer;
  VerBuf: PChar;
  VerBufValue: Pointer;
  {$IFNDEF D4_OR_HIGHER}   // for Delphi 3
     VerBufLen: integer;
     VerHandle: integer;
  {$ENDIF}
  {$IFDEF D4_OR_HIGHER}   // for Delphi 4 or higher
     VerBufLen: Cardinal;
     VerHandle: Cardinal;
  {$ENDIF}
  VerKey: string;
  FixedFileInfo: PVSFixedFileInfo;
  sAppNamePath: string;

  // dwFileType, dwFileSubtype 
  function GetFileSubType(FixedFileInfo: PVSFixedFileInfo): TSubType;
  begin
    case FixedFileInfo.dwFileType of 

      VFT_UNKNOWN: Result    := stUnknown;
      VFT_APP: Result        := stApp;
      VFT_DLL: Result        := stDLL;
      VFT_STATIC_LIB: Result := stSLL;

      VFT_DRV:
        case
          FixedFileInfo.dwFileSubtype of
          VFT2_UNKNOWN: Result         := stDrvUnknown;
          VFT2_DRV_COMM: Result        := stDrvComm;
          VFT2_DRV_PRINTER: Result     := stDrvPrint;
          VFT2_DRV_KEYBOARD: Result    := stDrvKeyb;
          VFT2_DRV_LANGUAGE: Result    := stDrvLang;
          VFT2_DRV_DISPLAY: Result     := stDrvDisplay;
          VFT2_DRV_MOUSE: Result       := stDrvMouse;
          VFT2_DRV_NETWORK: Result     := stDrvNetwork;
          VFT2_DRV_SYSTEM: Result      := stDrvSystem;
          VFT2_DRV_INSTALLABLE: Result := stDrvSystem;
          VFT2_DRV_SOUND: Result       := stDrvSound;
        end;
      VFT_FONT:
        case FixedFileInfo.dwFileSubtype of
          VFT2_UNKNOWN: Result       := stFntUnknown;
          VFT2_FONT_RASTER: Result   := stFntRaster;
          VFT2_FONT_VECTOR: Result   := stFntVector;
          VFT2_FONT_TRUETYPE: Result := stFntTrueType;
          else;
        end;
      VFT_VXD: Result := stVXD;
    end;
  end; 


  function HasdwFileFlags(FixedFileInfo: PVSFixedFileInfo; Flag: Word): Boolean; 
  begin 
    Result := (FixedFileInfo.dwFileFlagsMask and
      FixedFileInfo.dwFileFlags and 
      Flag) = Flag; 
  end; 

  function GetFixedFileInfo: PVSFixedFileInfo;
  begin 
    if not VerQueryValue(VerBuf, '', Pointer(Result), VerBufLen) then
      Result := nil 
  end; 

  function GetInfo(const aKey: string): string; 
  begin 
    Result := ''; 
    VerKey := Format('\StringFileInfo\%.4x%.4x\%s', 
      [LoWord(Integer(VerBufValue^)), 
      HiWord(Integer(VerBufValue^)), aKey]); 
    if VerQueryValue(VerBuf, PChar(VerKey), VerBufValue, VerBufLen) then 
      Result := StrPas(VerBufValue); 
  end; 

  function QueryValue(const aValue: string): string;
  begin 
    Result := ''; 
    // obtain version information about the specified file 
    if GetFileVersionInfo(PChar(sAppNamePath), VerHandle, VerSize, VerBuf) and
      // return selected version information 
      VerQueryValue(VerBuf, '\VarFileInfo\Translation', VerBufValue, VerBufLen) then 
      Result := GetInfo(aValue);
  end; 
begin
  sAppNamePath := FFileName;
  // Initialize the Result 
  with Result do 
  begin 
    FileType         := ''; 
    CompanyName      := ''; 
    FileDescription  := ''; 
    FileVersion      := ''; 
    InternalName     := ''; 
    LegalCopyRight   := '';
    LegalTradeMarks  := ''; 
    OriginalFileName := ''; 
    ProductName      := ''; 
    ProductVersion   := ''; 
    Comments         := ''; 
    SpecialBuildStr  := ''; 
    PrivateBuildStr  := '';
    DebugBuild       := False; 
    Patched          := False; 
    PreRelease       := False; 
    SpecialBuild     := False; 
    PrivateBuild     := False; 
    InfoInferred     := False; 
  end; 

  // Get the file type 
  if SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI, SizeOf(rSHFI), 
    SHGFI_TYPENAME) <> 0 then 
  begin 
    Result.FileType := rSHFI.szTypeName;
  end; 

  iRet := SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI, SizeOf(rSHFI), SHGFI_EXETYPE); 
  if iRet <> 0 then 
  begin 
    // determine whether the OS can obtain version information 
    VerSize := GetFileVersionInfoSize(PChar(sAppNamePath), VerHandle);
    if VerSize > 0 then 
    begin 
      VerBuf := AllocMem(VerSize); 
      try 
        with Result do 
        begin 
          CompanyName      := QueryValue('CompanyName'); 
          FileDescription  := QueryValue('FileDescription'); 
          FileVersion      := QueryValue('FileVersion'); 
          InternalName     := QueryValue('InternalName'); 
          LegalCopyRight   := QueryValue('LegalCopyRight'); 
          LegalTradeMarks  := QueryValue('LegalTradeMarks'); 
          OriginalFileName := QueryValue('OriginalFileName'); 
          ProductName      := QueryValue('ProductName');
          ProductVersion   := QueryValue('ProductVersion'); 
          Comments         := QueryValue('Comments'); 
          SpecialBuildStr  := QueryValue('SpecialBuild'); 
          PrivateBuildStr  := QueryValue('PrivateBuild'); 
          // Fill the  VS_FIXEDFILEINFO structure 
          FixedFileInfo := GetFixedFileInfo; 
          DebugBuild    := HasdwFileFlags(FixedFileInfo, VS_FF_DEBUG);
          PreRelease    := HasdwFileFlags(FixedFileInfo, VS_FF_PRERELEASE); 
          PrivateBuild  := HasdwFileFlags(FixedFileInfo, VS_FF_PRIVATEBUILD); 
          SpecialBuild  := HasdwFileFlags(FixedFileInfo, VS_FF_SPECIALBUILD); 
          Patched       := HasdwFileFlags(FixedFileInfo, VS_FF_PATCHED); 
          InfoInferred  := HasdwFileFlags(FixedFileInfo, VS_FF_INFOINFERRED); 
          FileFunction  := GetFileSubType(FixedFileInfo); 
        end; 
      finally 
        FreeMem(VerBuf, VerSize); 
      end 
    end; 
  end 
end;


// GetObjAttr: get systemattributes for the file/object specified by oaAttr
// Returns: true if attribute oaAttr is true, else false
function TFileInfo.GetObjAttr(oaAttr: TObjAttr): Boolean;
var
  sfgao: integer;
begin
  sfgao   := 0;
  FuFlags := ATTR_ALL;
  PerformSHGetFileInfo;
  case oaAttr of
    oaCanCopy: sfgao      := SFGAO_CANCOPY;
    oaCanDelete: sfgao    := SFGAO_CANDELETE;
    oaCanLink: sfgao      := SFGAO_CANLINK;
    oaCanMove: sfgao      := SFGAO_CANMOVE;
    oaCanRename: sfgao    := SFGAO_CANRENAME;
    oaDropTarget: sfgao   := SFGAO_DROPTARGET;
    oaHasPropSheet: sfgao := SFGAO_HASPROPSHEET;
    oaIsLink: sfgao       := SFGAO_LINK;
    oaIsReadOnly: sfgao   := SFGAO_READONLY;
    oaIsShare: sfgao      := SFGAO_SHARE;
    oaHasSubFolder: sfgao := SFGAO_HASSUBFOLDER;
    oaFileSys: sfgao      := SFGAO_FILESYSTEM;
    oaFileSysAnc: sfgao   := SFGAO_FILESYSANCESTOR;
    oaIsFolder: sfgao     := SFGAO_FOLDER;
    oaRemovable: sfgao    := SFGAO_REMOVABLE;
  end;
  Result := ((FshFileInfo.dwAttributes and sfgao) > 0);
end;

// AttachStream: Add a stream to the end of a file e.g.
//   aStream := TMemoryStream.Create;
//   Memo1.Lines.SaveToStream(aStream);
//   fiMyFile.AttachStream(aStream);
// Returns: true on succes
function TFileInfo.AttachStream(MemoryStream: TMemoryStream): Boolean;
var
  aStream: TFileStream;
  iSize: Integer;
begin
  Result := False;
  if not FileExists(FFileName) then
    Exit;
  try
   try
    aStream := TFileStream.Create(FFileName, fmOpenWrite or fmShareDenyWrite);
    MemoryStream.Seek(0, soFromBeginning);
    // seek to end of File
    aStream.Seek(0, soFromEnd);
    // copy data from MemoryStream
    aStream.CopyFrom(MemoryStream, 0);
    // save Stream-Size
    iSize := MemoryStream.Size + SizeOf(Integer);
    aStream.Write(iSize, SizeOf(iSize));
    Result := True;
   except
    Result := False;
   end;
  finally
    aStream.Free;
  end;
end;

// RetrieveStream: retrieve a previously attached stream from the file e.g.
//   aStream := TMemoryStream.Create;
//   fiMyFile.RetrieveStream(aStream);
//   Memo1.Lines.LoadFromStream(aStream);
// Returns: true on succes and the attached stream in var MemoryStream
function TFileInfo.RetrieveStream(MemoryStream: TMemoryStream): Boolean;
var
  aStream: TFileStream;
  iSize: Integer;
begin
  Result := False;
  if not FileExists(FFileName) then
    Exit;
  try
   try
    aStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
    // seek to position where Stream-Size is saved
    aStream.Seek(-SizeOf(Integer), soFromEnd);
    aStream.read(iSize, SizeOf(iSize));
    if iSize > aStream.Size then
    begin
      aStream.Free;
      Exit;
    end;
    // seek to position where data is saved
    aStream.Seek(-iSize, soFromEnd);
    MemoryStream.SetSize(iSize - SizeOf(Integer));
    MemoryStream.CopyFrom(aStream, iSize - SizeOf(iSize));
    MemoryStream.Seek(0, soFromBeginning);
    Result := True;
   except
     Result := False;
   end;
  finally
    aStream.Free;
  end;
end;

// Execute: run the (associated) application
procedure TFileInfo.Execute(Params: string);
var
  c, p: array[0..800] of Char;
begin
  StrPCopy(c, FFileName);
  StrPCopy(p, Params);
  ShellExecute(Application.Handle, 'open', c, p, nil, SW_NORMAL);
end;

// FileShellOp
// Copies, renames, moves or deletes the file via the shell
// Func specifies the function: foCopy, foMove, foDelete or foRename
// Flags that control the file operation. This member can be a combination
// of the following values:

// fofFilesOnly	        Performs the operation only on files if a wildcard filename (*.*) is specified.
// fofNoConfirm	        Responds with "yes to all" for any dialog box that is displayed.
// fofNoConfirmDir	Does not confirm the creation of a new directory if the operation requires one to be created.
// fofRenameOnColl	Gives the file being operated on a new name (such as "Copy #1 of...") in a move, copy, or rename operation if a file of the target name already exists.
// fofSilent	        Does not display a progress dialog box.
// fofSimpleProgress	Displays a progress dialog box, but does not show the filenames.
//
// Returns: TRUE if the user aborted any file operations before they were completed or FALSE otherwise.
function TFileInfo.FileShellOp(const DestinationFile: string;
  OpFunc: TOpFunc; OpFlags: Integer; ProgressTitle: string): Boolean;
var
  shi: TSHFileOpStructA;
  Func: Integer;
begin
  case OpFunc of
    foCopy: Func   := FO_COPY;
    foDelete: Func := FO_DELETE;
    foMove: Func   := FO_MOVE;
    foRename: Func := FO_RENAME;
  end;
  with shi do
  begin
    wnd    := Application.Handle;
    wFunc  := Func;
    fFlags := OpFlags;
    pFrom  := PChar(FFileName);
    pTo    := PChar(DestinationFile);
    lpszProgressTitle := PChar(ProgressTitle);
  end;
  SHFileOperation(shi);
  Result := shi.fAnyOperationsAborted;
end;

// FileCopySilent: copies this file to location DestinationFile. param
// FailIfExist specifies how this operation is to proceed if a file of
// the same name as that specified by DestinationFile already exists. If
// this parameter is True and the new file already exists, the function
// fails. If this parameter is False and the new file already exists,
// the function overwrites the existing file and succeeds.
// Returns: false if copying failed
function TFileInfo.FileCopySilent(const DestinationFile: string;
  FailIfExists: Boolean): Boolean;
begin
  Result := CopyFile(PChar(FFileName), PChar(DestinationFile), FailIfExists);
end;

// FileCopyCustom: copy this file to another location. Every time a block is copied
// the 'callback' function Update will be called. The user can create this himself in
// the form: x(Pos, MaxPos: longint; RemainSecs: integer) and can pass the name x as the
// function to be called with the params Pos (current position in the file, MaxPos
// (filelength) and RemainSecs (estimated remaining seconds to end of copying) 
function TFileInfo.FileCopyCustom(const DestinationFile: string;
  Update: TUpdateFunction): Boolean;
var
  FromF, ToF: file of Byte;
  Buffer: array[0..4096] of Char;
  Position, NumRead: Integer;
  Min, Max, FileLength: Longint;
  t1, t2: DWORD;
  maxi: Integer;
begin
  try
    AssignFile(FromF, FFileName);
    Reset(FromF);
    AssignFile(ToF, DestinationFile);
    Rewrite(ToF);
    FileLength := FileSize(FromF);

    Min  := 0;
    Max  := FileLength;
    t1   := GetTickCount;
    maxi := Max div 4096;
    while FileLength > 0 do
    begin
      BlockRead(FromF, Buffer[0], SizeOf(Buffer), NumRead);
      FileLength := FileLength - NumRead;
      BlockWrite(ToF, Buffer[0], NumRead);
      t2       := GetTickCount;
      Min      := Min + 1;
      Position := Position + NumRead;
      // Update is a 'callback' procedure
      Update(Position, Max, Round(((t2 - t1) / min * maxi - t2 + t1) / 1000));
      Application.ProcessMessages;
    end;
    CloseFile(FromF);
    CloseFile(ToF);
    if Position >= Max then
      Update(Position, Max, 0);
    Result := True;
  except
    Result := False;
  end;
end;

// IsEqualWith: compare this file with another file
// Returns: true if both files are equal
function TFileInfo.IsEqualWith(const OtherFile: string): Boolean;
var
  ms1, ms2: TMemoryStream;
begin
  Result := False;
  ms1    := TMemoryStream.Create;
  try
    ms1.LoadFromFile(FFileName);
    ms2 := TMemoryStream.Create;
    try
      ms2.LoadFromFile(OtherFile);
      if ms1.Size = ms2.Size then 
        Result := CompareMem(ms1.Memory, ms2.memory, ms1.Size); 
    finally 
      ms2.Free; 
    end;
  finally
    ms1.Free;
  end
end;

// IsAscii: checks whether a file in in ASCII format
// Returns: true if it is an ASCII file
function TFileInfo.IsAscii: Boolean;
const
  SETT = 2048;
var
  i: Integer;
  F: file;
  a: Boolean;
  TotSize, IncSize, ReadSize: Integer;
  c: array[0..Sett] of Byte;
begin
  if FileExists(FFileName) then
  begin
    {$I-}
    AssignFile(F, FFileName);
    Reset(F, 1);
    TotSize := FileSize(F);
    IncSize := 0;
    a       := True;
    while (IncSize < TotSize) and (a = True) do
    begin
      ReadSize := SETT;
      if IncSize + ReadSize > TotSize then ReadSize := TotSize - IncSize;
      IncSize := IncSize + ReadSize;
      BlockRead(F, c, ReadSize);
      // Iterate
      for i := 0 to ReadSize - 1 do
        if (c[i] < 32) and (not (c[i] in [9, 10, 13, 26])) then a := False;
    end; { while }
    CloseFile(F);
    {$I+}
    if IOResult <> 0 then Result := False
    else
      Result := a;
  end;
end;

// IsInUse: checks whether the file is in use by another app
// Returs: true if in use
function TFileInfo.IsInUse: Boolean;
var
  HFileRes: HFILE;
begin
  Result := False;
  if not FileExists(FFileName) then Exit;
  HFileRes := CreateFile(PChar(FFileName),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0);
  Result   := (HFileRes = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(HFileRes);
end;

// DialogOpenWith: shows the 'Open with' dialogbox
procedure TFileInfo.DialogOpenWith;
begin
  ShellExecute(Application.Handle, 'open', PChar('rundll32.exe'),
    PChar('shell32.dll,OpenAs_RunDLL ' + FFileName), nil, SW_SHOWNORMAL);
end;

// DialogProperties: shows the 'Properties' dialogbox
procedure TFileInfo.DialogProperties;
var
  sei: TShellExecuteInfo;
begin
  FillChar(sei, SizeOf(sei), 0);
  sei.cbSize := SizeOf(sei);
  sei.lpFile := PChar(FFileName);
  sei.lpVerb := 'properties';
  sei.fMask  := SEE_MASK_INVOKEIDLIST;
  ShellExecuteEx(@sei);
end;

{ -- private -- }

procedure TFileInfo.PerformSHGetFileInfo;
begin
  SHGETFILEINFO(PChar(FFileName), FdwFileAttr, FshFileInfo, FcbFileInfo, FuFlags);
end;

procedure TFileInfo.InternalOpen;
begin
  if FFileName <> '' then
  begin
    OpenStorage;
    OpenStream;
    InternalInitPropertyDefs;
  end;
end;

procedure TFileInfo.InternalClose;
begin
  if prgPropertyValue <> nil then FreeMem(prgPropertyValue);
  if prgPropIDOffset <> nil then FreeMem(prgPropIDOffset);
  if stm <> nil then stm.Release;
  if stgOpen <> nil then stgOpen.Release;
  stgOpen:=nil;
  stm:=nil;
  prgPropIDOffset:=nil;
  prgPropertyValue:=nil;
end;

procedure TFileInfo.InternalInitPropertyDefs;
begin
  ReadPropertySetHeader;
  ReadFormatIdOffset;
  ReadPropertySectionHeader;
  ReadPropertyIdOffset;
  ReadPropertySet;
end;

function TFileInfo.OpenStorage: HResult;
var
  awcName: array[0..MAX_PATH-1] of WideChar;
begin
  StringToWideChar(FFileName,awcName,MAX_PATH);
  Result:=StgOpenStorage(awcName,               //Points to the pathname of the file containing storage object
                         nil,                   //Points to a previous opening of a root storage object
                         STGM_READ or           //Specifies the access mode for the object
                         STGM_SHARE_EXCLUSIVE,
                         nil,                   //Points to an SNB structure specifying elements to be excluded
                         0,                     //Reserved; must be zero
                         stgOpen	        //Points to location for returning the storage object
                        );

  OleCheck(Result);
end;

function TFileInfo.OpenStream: HResult;
var
  awcName: array[0..MAX_PATH-1] of WideChar;
begin
  StringToWideChar(#5'SummaryInformation',awcName,MAX_PATH);
  Result:=stgOpen.OpenStream(awcName,               //Points to name of stream to open
                             nil,                   //Reserved; must be NULL
                             STGM_READ or           //Access mode for the new stream
                             STGM_SHARE_EXCLUSIVE,
                             0, 	              //Reserved; must be zero
                             stm	              //Points to opened stream object
                            );

  OleCheck(Result);
end;

function TFileInfo.ReadPropertySetHeader: HResult;
var
  cbRead: Longint;
begin
  Result:=stm.Read(@PropertySetHeader,        //Pointer to buffer into which the stream is read
                   SizeOf(PropertySetHeader), //Specifies the number of bytes to read
                   @cbRead                    //Pointer to location that contains actual number of bytes read
                  );

  OleCheck(Result);
end;

function TFileInfo.ReadFormatIdOffset: HResult;
var
  cbRead: Longint;
begin
  Result:=stm.Read(@FormatIDOffset,        //Pointer to buffer into which the stream is read
                   SizeOf(FormatIDOffset), //Specifies the number of bytes to read
                   @cbRead                 //Pointer to location that contains actual number of bytes read
                  );

  OleCheck(Result);
end;

function TFileInfo.ReadPropertySectionHeader: HResult;
var
  cbRead: Longint;
  libNewPosition: Largeint;
begin
  Result:=Stm.Seek(FormatIDOffset.dwOffset, //Offset relative to dwOrigin
                   STREAM_SEEK_SET,         //Specifies the origin for the offset
                   libNewPosition           //Pointer to location containing new seek pointer
                  );

  OleCheck(Result);

  Result:=stm.Read(@PropertySectionHeader,        //Pointer to buffer into which the stream is read
                   SizeOf(PropertySectionHeader), //Specifies the number of bytes to read
                   @cbRead                        //Pointer to location that contains actual number of bytes read
                  );

  OleCheck(Result);
end;

function TFileInfo.ReadPropertyIdOffset: HResult;
var
  Size: Cardinal;
  cbRead: Longint;
begin
  Size:=PropertySectionHeader.cProperties*SizeOf(prgPropIDOffset^);
  GetMem(prgPropIDOffset,Size);
  Result:=stm.Read(prgPropIDOffset, //Pointer to buffer into which the stream is read
                   Size,            //Specifies the number of bytes to read
                   @cbRead          //Pointer to location that contains actual number of bytes read
                  );

  OleCheck(Result);
end;

function TFileInfo.ReadPropertySet: HResult;
var
  I: Integer;
  Buffer: PChar;
  I4: Integer;
  dwType: DWORD;
  Size: Cardinal;
  cb, cbRead: Longint;
  FileTime: TFileTime;
  dlibMove, libNewPosition: Largeint;
begin
  Result:=S_OK;
  Size:=PropertySectionHeader.cProperties*SizeOf(prgPropertyValue^);
  GetMem(prgPropertyValue,Size);
  for I:=0 to PropertySectionHeader.cProperties-1 do
  begin
    dlibMove:=FormatIDOffset.dwOffset+prgPropIDOffset^[I].dwOffset;
    Result:=Stm.Seek(dlibMove,        //Offset relative to dwOrigin
                     STREAM_SEEK_SET, //Specifies the origin for the offset
                     libNewPosition   //Pointer to location containing new seek pointer
                    );

    OleCheck(Result);

    Result:=stm.Read(@dwType,        //Pointer to buffer into which the stream is read
                     SizeOf(dwType), //Specifies the number of bytes to read
                     @cbRead         //Pointer to location that contains actual number of bytes read
                    );

    OleCheck(Result);

    case dwType of
      VT_EMPTY:               ;{ [V]   [P]  nothing                     }
      VT_NULL:                ;{ [V]        SQL style Null              }
      VT_I2:                  ;{ [V][T][P]  2 byte signed int           }
      VT_I4:                   { [V][T][P]  4 byte signed int           }
      begin
        Result:=stm.Read(@I4,        //Pointer to buffer into which the stream is read
                         SizeOf(I4), //Specifies the number of bytes to read
                         @cbRead     //Pointer to location that contains actual number of bytes read
                        );

        OleCheck(Result);

        AddProperty(prgPropIDOffset^[I].propid,@I4);
      end;
      VT_R4:                  ;{ [V][T][P]  4 byte real                 }
      VT_R8:                  ;{ [V][T][P]  8 byte real                 }
      VT_CY:                  ;{ [V][T][P]  currency                    }
      VT_DATE:                ;{ [V][T][P]  date                        }
      VT_BSTR:                ;{ [V][T][P]  binary string               }
      VT_DISPATCH:            ;{ [V][T]     IDispatch FAR*              }
      VT_ERROR:               ;{ [V][T]     SCODE                       }
      VT_BOOL:                ;{ [V][T][P]  True=-1, False=0            }
      VT_VARIANT:             ;{ [V][T][P]  VARIANT FAR*                }
      VT_UNKNOWN:             ;{ [V][T]     IUnknown FAR*               }

      VT_I1:                  ;{    [T]     signed char                 }
      VT_UI1:                 ;{    [T]     unsigned char               }
      VT_UI2:                 ;{    [T]     unsigned short              }
      VT_UI4:                 ;{    [T]     unsigned short              }
      VT_I8:                  ;{    [T][P]  signed 64-bit int           }
      VT_UI8:                 ;{    [T]     unsigned 64-bit int         }
      VT_INT:                 ;{    [T]     signed machine int          }
      VT_UINT:                ;{    [T]     unsigned machine int        }
      VT_VOID:                ;{    [T]     C style void                }
      VT_HRESULT:             ;{    [T]                                 }
      VT_PTR:                 ;{    [T]     pointer type                }
      VT_SAFEARRAY:           ;{    [T]     (use VT_ARRAY in VARIANT)   }
      VT_CARRAY:              ;{    [T]     C style array               }
      VT_USERDEFINED:         ;{    [T]     user defined type           }
      VT_LPSTR:                {    [T][P]  null terminated string      }
      begin
        Result:=stm.Read(@cb,        //Pointer to buffer into which the stream is read
                         SizeOf(cb), //Specifies the number of bytes to read
                         @cbRead     //Pointer to location that contains actual number of bytes read
                        );

        OleCheck(Result);

        GetMem(Buffer,cb*SizeOf(Char));
        try
          Result:=stm.Read(Buffer, //Pointer to buffer into which the stream is read
                           cb,     //Specifies the number of bytes to read
                           @cbRead //Pointer to location that contains actual number of bytes read
                          );

          OleCheck(Result);

          AddProperty(prgPropIDOffset^[I].propid,Buffer);
        finally
          FreeMem(Buffer);
        end;
      end;
      VT_LPWSTR:              ;{    [T][P]  wide null terminated string }

      VT_FILETIME:             {       [P]  FILETIME                    }
      begin
        Result:=stm.Read(@FileTime,        //Pointer to buffer into which the stream is read
                         SizeOf(FileTime), //Specifies the number of bytes to read
                         @cbRead           //Pointer to location that contains actual number of bytes read
                        );

        OleCheck(Result);

        AddProperty(prgPropIDOffset^[I].propid,@FileTime);
      end;
      VT_BLOB:                ;{       [P]  Length prefixed bytes       }
      VT_STREAM:              ;{       [P]  Name of the stream follows  }
      VT_STORAGE:             ;{       [P]  Name of the storage follows }
      VT_STREAMED_OBJECT:     ;{       [P]  Stream contains an object   }
      VT_STORED_OBJECT:       ;{       [P]  Storage contains an object  }
      VT_BLOB_OBJECT:         ;{       [P]  Blob contains an object     }
      VT_CF:                  ;{       [P]  Clipboard format            }
      VT_CLSID:               ;{       [P]  A Class ID                  }

      VT_VECTOR:              ;{       [P]  simple counted array        }
      VT_ARRAY:               ;{ [V]        SAFEARRAY*                  }
      VT_BYREF:               ;{ [V]                                    }
      VT_RESERVED:            ;
    end;
  end;
end;

procedure TFileInfo.AddProperty(propid: DWORD; Value: Pointer);
var
  FileTime: TFileTime;
begin
  with FdiDocInfo do
  begin
  case propid of
    PID_TITLE:
      Title:=PChar(Value);
    PID_SUBJECT:
      Subject:=PChar(Value);
    PID_AUTHOR:
      Author:=PChar(Value);
    PID_KEYWORDS:
      Keywords:=PChar(Value);
    PID_COMMENTS:
      Comments:=PChar(Value);
    PID_TEMPLATE:
      Template:=PChar(Value);
    PID_LASTAUTHOR:
      LastAuthor:=PChar(Value);
    PID_REVNUMBER:
      RevNumber:=PChar(Value);
    PID_EDITTIME:
    begin
      CopyMemory(@FileTime,Value,SizeOf(FileTime));
      EditTime:=FileTimeToElapsedTime(FileTime);
    end;
    PID_LASTPRINTED:
    begin
      CopyMemory(@FileTime,Value,SizeOf(FileTime));
      LastPrintedDate:=FileTimeToDateTime(FileTime);
    end;
    PID_CRAETE_DTM:
    begin
      CopyMemory(@FileTime,Value,SizeOf(FileTime));
      CreateDate:=FileTimeToDateTime(FileTime);
    end;
    PID_LASTSAVE_DTM:
    begin
      CopyMemory(@FileTime,Value,SizeOf(FileTime));
      LastSaveDate:=FileTimeToDateTime(FileTime);
    end;
    PID_PAGECOUNT:
      CopyMemory(@PageCount,Value,SizeOf(PageCount));
    PID_WORDCOUNT:
      CopyMemory(@WordCount,Value,SizeOf(WordCount));
    PID_CHARCOUNT:
      CopyMemory(@CharCount,Value,SizeOf(CharCount));
    PID_THUMBAIL: ;
    PID_APPNAME: ;
    PID_SECURITY: ;
  end; // case
  end; // with FdiDocInfo do
end;

function TFileInfo.FileTimeToElapsedTime(FileTime: TFileTime): Integer;
var
  SystemTime: TSystemTime;
  LocalFileTime: TFileTime;
begin
  Result:=0;
  if FileTimeToLocalFileTime(FileTime, LocalFileTime) and
     FileTimeToSystemTime(LocalFileTime, SystemTime)
  then
    Result:=SystemTime.wMinute;
end;

function TFileInfo.FileTimeToDateTime(FileTime: TFileTime): TDateTime;
var
  FileDate: Integer;
  LocalFileTime: TFileTime;
begin
  Result:=0;
  if FileTimeToLocalFileTime(FileTime, LocalFileTime) and
     FileTimeToDosDateTime(LocalFileTime,
                           LongRec(FileDate).Hi, LongRec(FileDate).Lo)
  then
    try Result:=FileDateToDateTime(FileDate); except Result:=0; end;
end;

// MP3OPen - for errorcodes in the errofield see GetMP3Info
function TFileInfo.MP3Open: boolean;

   { Strips empty spaces at the end of word }
   function Strip(WordToStrip:String; CharToStripAway: Char):String;
   var i: Integer;
   begin
      for i:=length(WordToStrip) downto 1 do begin
         if WordToStrip[i]<>' ' then begin
            Strip:=Copy(WordToStrip, 0, i);
            exit;
         end;
      end;
      Strip:='';
   end;

var dat:file of char;
    id3:array [0..TAGLEN] of char;
    Ok: boolean;
begin
   OK    := True;
   Saved := False;
   FmiMP3Info.Valid := True;
   if FileExists(FFilename) then begin
     try
      assignfile(dat,FFilename);
      reset(dat);
      seek(dat,FileSize(dat)-128);
      blockread(dat,id3,128);
      closefile(dat);
     except
       FmiMP3Info.Error := 5;
       Ok := False;
       Result := Ok;
       Exit;
     end;
      FmiMP3Info.Tag:=copy(id3, 1, 3);
      if FmiMP3Info.Tag='TAG' then begin
        with FmiMP3Info do begin
          Title:=strip(copy(id3, 4, 30),' ');
          Artist:=strip(copy(id3, 34, 30), ' ');
          Album:=strip(copy(id3, 64, 30), ' ');
          Comment:=strip(copy(id3, 98, 30), ' ');
          Year:=strip(copy(id3, 94, 4), ' ');
          GenreID:=ord(id3[127]);
          if GenreID>MP3Genres.Count then GenreID:=12;
          Genre:=MP3Genres[GenreID];
        end;
      end else begin
        with FmiMP3Info do begin
          Valid:=False;
          Title:='';
          Artist:='';
          Album:='';
          Comment:='';
          Year:='';
          GenreID:=12;
          Error:=1; // Wrong file format or no ID3 Tag !
          Ok := False;
          Exit;
        end;
      end;
   end else begin
      FmiMP3Info.Valid:=False;
      FmiMP3Info.Error:=0; // File doesn`t exist !
      Ok := False;
      Exit;
   end;
  Result := Ok;
end;

{ Removes the ID3-tag from currently open file }
// Returns:

function TFileInfo.MP3RemoveID3: boolean;
var
  dat : file of char;
  Ok : boolean;
begin
  Ok := True;
  // does the file exist ?
  if Not FileExists(FFilename) then
     begin
       FmiMP3Info.Error:=0; // File doesn`t exist !
       Ok := False;
       Result := Ok;
       Exit;
     end;
  // is the file already untagged ?
  if (FmiMP3Info.Valid=false) then
     begin
       FmiMP3Info.Error:=4; //File is already untagged !
       Ok := False;
       Result := Ok;
       exit;
     end;
  // remove readonly-attribute
  If (FileGetAttr(FFilename) and faReadOnly >0) then
     FileSetAttr(FFileName,FileGetAttr(FFilename)-faReadOnly);
  // if readonly attr. already exists it cannot be removed to cut ID3 Tag
  If (FileGetAttr(FFilename) and faReadOnly >0) then
     begin
       FmiMP3Info.Error:=1; // Can´t write ID3 tag information !
       Ok := False;
       Result := Ok;
       Exit;
     end;
  // open current mp3 file if ID3 tag exists
  If (FmiMP3Info.Valid=true) then
     begin
       {I-}
         assignfile(dat,FFilename);
         reset(dat);
       {I+}
       If IOResult<>0 then
          begin
            FmiMP3Info.Error:=5; // Could not open file !
            Ok := False;
            Result := Ok;
            exit;
          end;
       seek(dat,FileSize(dat)-128);
       truncate(dat);  // cut all 128 bytes of file
       closefile(dat);
       FmiMP3Info.Valid:=false;  // set Valid to false because the tag has been removed
     end;
end;

{ Saves ID3 Tag to currently opened file }
// Returns:

function TFileInfo.MP3Save: boolean;

   { Empties 128 character array } { Don't tell me that there is a function for this in Pascal }
   procedure EmptyArray(var Destination: array of char);
   var i: Integer;
   begin
      for i:=0 to TAGLEN do begin
         Destination[i]:=' ';
      end;
   end;

   { Insert a substring into character array at index position of array }
   procedure InsertToArray(Source: String; var Destination: array of char; Index: Integer);
   var i: Integer;
   begin
      for i:=0 to length(Source)-1 do begin
         Destination[Index+i]:=Source[i+1];
      end;
   end;

var dat:file of char;
    id3:array [0..TAGLEN] of char;
    Ok : boolean;
begin
   Ok := True;
   Saved:=true;
   // does the filename exist ?
   if FileExists(FFilename) then begin
     with FmiMP3Info do begin
      // fill 128 bytes long array with ID3 Tag information
      EmptyArray(id3);
      InsertToArray('TAG', id3, 0);
      InsertToArray(Title, id3, 3);
      InsertToArray(Artist, id3, 33);
      InsertToArray(Album, id3, 63);
      InsertToArray(Comment, id3, 97);
      InsertToArray(Year, id3, 93);
      id3[127]:=chr(GenreID);
     end;
      // remove readonly-attribute
      If (FileGetAttr(FFilename) and faReadOnly >0) then
         FileSetAttr(FFileName,FileGetAttr(FFilename)-faReadOnly);
      // if readonly attr. already exists it cannot be removed to write ID3
      If (FileGetAttr(FFilename) and faReadOnly >0) then
         begin
           Saved:=False;
           FmiMP3Info.Error:=1; // Can´t write ID3 tag information !
           Ok := False;
           Result := Ok;
           exit;
         end;
      // if valid then overwrite existing ID3 Tag, else append to file
      if (FmiMP3Info.Valid=True) then begin
         {I-}
           assignfile(dat,FFilename);
           reset(dat);
           seek(dat,FileSize(dat)-128);
           blockwrite(dat,id3,128);
           closefile(dat);
         {I+}
         If IOResult<>0 then Saved:=false;
      end else begin
         {I-}
           assignfile(dat,FFilename);
           reset(dat);
           seek(dat,FileSize(dat));
           blockwrite(dat,id3,128);
           closefile(dat);
         {I+}
         If IOResult<>0 then Saved:=false;
      end
   end else begin
      FmiMP3Info.Valid:=False;
      Saved:=False;
      FmiMP3Info.Error:=0;  // File doesn`t exist or is not valid !
      Ok := False;
      Result := Ok;
      Exit;
   end;
end;

function TFileInfo.MPGCalcFrameLength (SampleRate, BitRate : LongInt; Padding : Boolean) : Integer;
begin
  If SampleRate > 0 then
    Result := Trunc (144 * BitRate * 1000 / SampleRate + Integer (Padding))
  else Result := 0;
end;


function TFileInfo.MPGFrameHeaderValid: boolean;
begin
  with FmiMP3ExInfo do begin
    Result := (Version > 0) and
              (Layer > 0) and
              (BitRate > 0) and (SampleRate > 0);
  end;
end;


function TFileInfo.MPGDecodeHeader (MPGHeader : LongInt) : Boolean;
  { Decode MPEG Frame Header and store data to TMPEGData fields.
    Return True if header seems valid }
var
  BitrateIndex : byte;
  VersionIndex : byte;
  bolsche:boolean;
begin
    FmiMP3ExInfo.Version := 0;
    FmiMP3ExInfo.Layer := 0;
    FmiMP3ExInfo.SampleRate := 0;
    FmiMP3ExInfo.Mode := 0;
    FmiMP3ExInfo.Copyright := False;
    FmiMP3ExInfo.Original := False;
    FmiMP3ExInfo.ErrorProt := False;
    FmiMP3ExInfo.Padding := False;
    FmiMP3ExInfo.BitRate := 0;
    FmiMP3ExInfo.FrameLength := 0;
  If (MPGHeader and $ffe00000) = $ffe00000 then begin
    VersionIndex := (MPGHeader shr 19) and $3;
    case VersionIndex of
      0 : FmiMP3ExInfo.Version := MPEG_VERSION_25;      { Version 2.5 }
      1 : FmiMP3ExInfo.Version := MPEG_VERSION_UNKNOWN; { Unknown }
      2 : FmiMP3ExInfo.Version := MPEG_VERSION_2;       { Version 2 }
      3 : FmiMP3ExInfo.Version := MPEG_VERSION_1;       { Version 1 }
    end;
    { if Version is known, read other data }
    If FmiMP3ExInfo.Version <> MPEG_VERSION_UNKNOWN then begin
      FmiMP3ExInfo.Layer := 4 - ((MPGHeader shr 17) and $3);
      If (FmiMP3ExInfo.Layer > 3) then FmiMP3ExInfo.Layer := 0;

      BitrateIndex := ((MPGHeader shr 12) and $F);
      FmiMP3ExInfo.SampleRate := MPEG_SAMPLE_RATES[FmiMP3ExInfo.Version][((MPGHeader shr 10) and $3)];
      FmiMP3ExInfo.ErrorProt := ((MPGHeader shr 16) and $1) = 1;
      FmiMP3ExInfo.Copyright := ((MPGHeader shr 3) and $1) = 1;
      FmiMP3ExInfo.Original := ((MPGHeader shr 2) and $1) = 1;
      FmiMP3ExInfo.Mode := ((MPGHeader shr 6) and $3);
      FmiMP3ExInfo.Padding := ((MPGHeader shr 9) and $1) = 1;
      bolsche:=(FmiMP3ExInfo.Version in [1..3]) and (FmiMP3ExInfo.Layer in [1..3]) and (BitrateIndex in [0..15]);
      if bolsche then
       begin
        FmiMP3ExInfo.BitRate := MPEG_BIT_RATES[FmiMP3ExInfo.Version][FmiMP3ExInfo.Layer][BitrateIndex];
       end;
      If FmiMP3ExInfo.BitRate = 0 then
        FmiMP3ExInfo.Duration := 0
      else
        FmiMP3ExInfo.Duration := (FmiMP3ExInfo.FileLength*8) div (longint(FmiMP3ExInfo.Bitrate)*1000);
      FmiMP3ExInfo.FrameLength := MPGCalcFrameLength (FmiMP3ExInfo.SampleRate, FmiMP3ExInfo.BitRate, FmiMP3ExInfo.Padding);
    end;
    Result := MPGFrameHeaderValid;
  end else Result := False;

end;


procedure TFileInfo.MPGResetData;
{ Empty MPEG data }
const
  Notag = '[notag]';
begin
  with FmiMP3ExInfo do begin
    Duration    := 0;
    FileLength  := 0;
    Version     := 0;
    Layer       := 0;
    SampleRate  := 0;
    Mode        := 0;
    Copyright   := False;
    Original    := False;
    ErrorProt   := False;
    Padding     := False;
    FrameLength := 0;
    BitRate     := 0;
  end; { with }
end; { function }


end.
