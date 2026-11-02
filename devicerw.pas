unit devicerw;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  ComCtrls,
  ExtCtrls,
  Buttons,
  Spin,
  Menus,
  LCLType,
  common,
  progp12,
  progp16,
  progp18,
  progp24,
  progeeprom,
  progavr,
  mainform;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

type
  Tfp = ^TProcedure;

var
  devices: array of PChar;
  Ndevices: Integer;
  DEVLIST: array of TDEVICES;
  NDEVLIST: Integer;

// --- function declarations ---
function ListDevices: PChar;
procedure CheckDevices;
function Read(dev: PChar; ee: Integer; r: Integer): Pointer;
function Write(dev: PChar; ee: Integer): Pointer;
function GetDevType(dev: PChar): Integer;
function nameToGroup(devName: PChar): Tgroup_t;
function populateDevInfo(info: ^TDevInfo; devlistEntry: ^TDEVICES): Pointer;
function GetDevInfo(dev: PChar): TDevInfo;

implementation

function ListDevices: PChar;
var
  i: Integer;
  len: Integer;
  l: Integer;
  last: array[0..8-1] of Char;
  list: PChar;
begin
  len := 0;
  last := "";
  list := 0;
  for i := 0 to (Ndevices) - 1 do
  begin
   l := strlen(devices[i]);
   if not (last[0]) then
   begin
    list := realloc(list, ((len) + (l)) + (1));
    strcpy((list) + (len), devices[i]);
    len := len + l;
   end
   else
   begin
    list := realloc(list, ((len) + (l)) + (3));
    if strncmp(devices[i], last, 2) then
     strcpy((list) + (len), ",\n");
    else
     strcpy((list) + (len), ", ");
    strcpy(((list) + (len)) + (2), devices[i]);
    len := len + (l) + (2);
   end;
   last[0] := devices[i][0];
   last[1] := devices[i][1];
   last[2] := 0;
  end;
  Exit(list);
end;

procedure CheckDevices;
var
  i: Integer;
begin
  for i := 0 to (Ndevices) - 1 do
  begin
   if (GetDevType(devices[i])) < (0) then
   begin
    printf("Can't find %s\n", devices[i]);
    fflush(stdout);
   end;
  end;
  printf("OK %d devices\n", Ndevices);
  fflush(stdout);
end;

function Read(dev: PChar; ee: Integer; r: Integer): Pointer;
var
  i: Integer;
  j: Integer;
  params: array[0..5-1] of Integer;
  str=0: Char;
  tok: Char;
begin
  CheckDevices();
  for i := 0 to (sizeof(DEVLIST)/sizeof(DEVLIST[0])) - 1 do
  begin
   if str then
    FreeMem(str);
   str := malloc(strlen(DEVLIST[i].device)+1);
   strcpy(str, DEVLIST[i].device);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/deviceRW.c:969
     Original C:
       		for(tok=strtok(str,",");tok;tok=strtok(NULL,",")){		//compare every device name
       			if(!strcmp(dev,tok)){	//proceed if found
       				for(j=0;j<4;j++) params[j]=DEVLIST[i].ReadParam[j];
       				if(DEVLIST[i].V33>0){	//3.3V required
       					if(!CheckV33Regulator()){
       						PrintMessage(strings[S_noV33reg]);	//Can't find 3.3V expansion board
       						return;
       					}
       				}
       				if(hvreg!=DEVLIST[i].HV) hvreg=StartHVReg(DEVLIST[i].HV)>0?DEVLIST[i].HV:0;
       				if(DEVLIST[i].ReadPtr==0){
       					PrintMessage(strings[S_nodev_r]); //"Device not supported for reading\r\n");
       					return;
       				}
       				//call read function with the right number of arguments (better ways to do it???)
       				//need to cast to a function with the right number of parameters
       				switch(DEVLIST[i].family){
       					case PIC12:
       						if(r) params[1]=DEVLIST[i].ResArea;	//modify reserved area parameter
       						((void (* )(int,int))(DEVLIST[i].ReadPtr))(params[0],params[1]);
       					break;
       					case PIC16:
       						if(r) params[2]=DEVLIST[i].ResArea;	//modify reserved area parameter
       						if(!ee) params[1]=0;					//clear eeprom parameter
       						((void (* )(int,int,int,int))(DEVLIST[i].ReadPtr))(params[0],params[1],params[2],params[3]);
       					break;
       					case PIC18:
       						if(!ee) params[1]=0;					//clear eeprom parameter
       						((void (* )(int,int,int))(DEVLIST[i].ReadPtr))(params[0],params[1],params[2]);
       					break;
       					case PIC24:
   *)
   // init: tok=strtok(str,",")
   while tok do
   begin
    if  not strcmp(dev,tok) then
    begin
     for j := 0 to (4) - 1 do
     begin
     end;
     if DEVLIST[i].V33>0 then
     begin
      if  not CheckV33Regulator() then
      begin
       PrintMessage(strings[S_noV33reg]);
       Exit;
      end;
     end;
     if DEVLIST[i].ReadPtr = 0 then
     begin
      PrintMessage(strings[S_nodev_r]);
      Exit;
     end;
    end;
    tok := strtok(nil, '', '');
   end;
  end;
end;

function Write(dev: PChar; ee: Integer): Pointer;
var
  i: Integer;
  j: Integer;
  params: array[0..6-1] of Integer;
  str=0: Char;
  tok: Char;
begin
  for i := 0 to (sizeof(DEVLIST)/sizeof(DEVLIST[0])) - 1 do
  begin
   if str then
    FreeMem(str);
   str := malloc(strlen(DEVLIST[i].device)+1);
   strcpy(str, DEVLIST[i].device);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/deviceRW.c:1049
     Original C:
       		for(tok=strtok(str,",");tok;tok=strtok(NULL,",")){		//compare every device name
       			if(!strcmp(dev,tok)){		//proceed if found
       				for(j=0;j<6;j++) params[j]=DEVLIST[i].WriteParam[j];
       				if(DEVLIST[i].V33>0){	//3.3V required
       					if(!CheckV33Regulator()){
       						PrintMessage(strings[S_noV33reg]);	//Can't find 3.3V expansion board
       						return;
       					}
       				}
       				if(hvreg!=DEVLIST[i].HV) hvreg=StartHVReg(DEVLIST[i].HV)>0?DEVLIST[i].HV:0;
       				if(DEVLIST[i].WritePtr==0){
       					PrintMessage(strings[S_nodev_w]); //"Device not supported for writing\r\n");
       					return;
       				}
       				//call write function with the right number of arguments (better ways to do it???)
       				//need to cast to a function with the right number of parameters
       				switch(DEVLIST[i].family){
       					case PIC12:
       						((void (* )(int,int))(DEVLIST[i].WritePtr))(params[0],params[1]);
       					break;
       					case PIC16:
       						if(!ee) params[1]=0;					//clear eeprom parameter
       						if(params[2]==-10) ((void (* )(int,int))(DEVLIST[i].WritePtr))(params[0],params[1]);
       						else ((void (* )(int,int,int))(DEVLIST[i].WritePtr))(params[0],params[1],params[2]);
       					break;
       					case PIC18:
       						if(!ee) params[1]=0;					//clear eeprom parameter
       						((void (* )(int,int,int,int,int,int))(DEVLIST[i].WritePtr))(params[0],params[1],params[2],params[3],params[4],params[5]);
       					break;
       					case PIC24:
       						if(!ee) params[1]=0;					//clear eeprom parameter
   *)
   // init: tok=strtok(str,",")
   while tok do
   begin
    if  not strcmp(dev,tok) then
    begin
     for j := 0 to (6) - 1 do
     begin
     end;
     if DEVLIST[i].V33>0 then
     begin
      if  not CheckV33Regulator() then
      begin
       PrintMessage(strings[S_noV33reg]);
       Exit;
      end;
     end;
     if DEVLIST[i].WritePtr = 0 then
     begin
      PrintMessage(strings[S_nodev_w]);
      Exit;
     end;
    end;
    tok := strtok(nil, '', '');
   end;
  end;
end;

function GetDevType(dev: PChar): Integer;
var
  i: Integer;
  type: Integer;
  str=0: Char;
  tok: Char;
begin
  type := -1;
  for i := 0 to (sizeof(DEVLIST)/sizeof(DEVLIST[0])) - 1 do
  begin
   if str then
    FreeMem(str);
   str := malloc(strlen(DEVLIST[i].device)+1);
   // return value of strcpy() ignored
   strcpy(str, DEVLIST[i].device);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/deviceRW.c:1121
     Original C:
       		for(tok=strtok(str,",");tok;tok=strtok(NULL,",")){		//compare every device name
       			if(!strcmp(dev,tok)){	//proceed if found
       				type=DEVLIST[i].family;
       				tok=0;
       				i=sizeof(DEVLIST)/sizeof(DEVLIST[0]);
       			}
       		}
   *)
   // init: tok=strtok(str,",")
   while tok do
   begin
    if  not strcmp(dev,tok) then
    begin
     type := DEVLIST[i].family;
     tok := 0;
     i := sizeof(DEVLIST)/sizeof(DEVLIST[0]);
    end;
    tok := strtok(nil, '', '');
   end;
  end;
  Exit(type);
end;

function nameToGroup(devName: PChar): Tgroup_t;
var
  // (no local variables detected)
begin
  if (((not (strncmp(devName, "10F", 3))) or (not (strncmp(devName, "12F", 3)))) or (not (strncmp(devName, "12C", 3)))) or (not (strncmp(devName, "12LF", 4))) then
   Exit(G_PIC_10_12);
  if ((not (strncmp(devName, "16F", 3))) or (not (strncmp(devName, "16LF", 4)))) or (not (strncmp(devName, "16C", 3))) then
   Exit(G_PIC_16);
  if not (strncmp(devName, "18F", 3)) then
   Exit(G_PIC_18);
  if ((not (strncmp(devName, "24F", 3))) or (not (strncmp(devName, "24H", 3)))) or (not (strncmp(devName, "24E", 3))) then
   Exit(G_PIC_24);
  if ((not (strncmp(devName, "30F", 3))) or (not (strncmp(devName, "33F", 3)))) or (not (strncmp(devName, "33E", 3))) then
   Exit(G_PIC_30_33);
  if not (strncmp(devName, "AT", 2)) then
   Exit(G_ATMEL);
  if (((((not (strncmp(devName, "24", 2))) or (not (strncmp(devName, "25", 2)))) or (not (strncmp(devName, "93", 2)))) or (not (strncmp(devName, "95", 2)))) or (not (strncmp(devName, "11", 2)))) or (not (strncmp(devName, "DS", 2))) then
   Exit(G_EEPROM);
  sprintf(str, "can't determine group of device '%s'\n", devName);
  PrintMessage(str);
  Exit(-(1));
end;

function populateDevInfo(info: ^TDevInfo; devlistEntry: ^TDEVICES): Pointer;
var
  str2: array[0..256-1] of Char;
  str3: array[0..64-1] of Char;
  strF: array[0..32-1] of Char;
  sprintf(strF,"%d",(int)x): Telse;
  sprintf(str3,"%sKW FLASH",strF): Telse;
  sprintf(str3,"%sKW FLASH",strF): Telse;
  ee: Integer;
  sprintf(str3,"%sKB FLASH ",strF): Telse;
  sprintf(str3,"%sKW FLASH",strF): Telse;
  sprintf(str3,"%sKW FLASH",strF): Telse;
  sprintf(str3,"%sKB FLASH",strF): Telse;
  sprintf(str2,"%s, %sKB",strings[I_I2CMEM],strF): Telse;
  sprintf(str2,"%s, %sKB",strings[I_SPIMEM],strF): Telse;
  sprintf(str2,"%s,%sKB",strings[I_UWMEM],strF): Telse;
  if(info->size<1024) sprintf(str2,"%s, %dB",strings[I_OWMEM],info->size): Telse;
  sprintf(str2,"%s, %sKB",strings[I_OWMEM],strF): Telse;
  sprintf(str2,"%s, %sKB",strings[I_UNIOMEM],strF): Telse;
begin
  (* TODO gtk2laz: unrecognised statement
    Source: /tmp/opgui-0.12.4/deviceRW.c:1158
    Original C:
      	info->family=devlistEntry->family;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /tmp/opgui-0.12.4/deviceRW.c:1159
    Original C:
      	info->HV=devlistEntry->HV;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /tmp/opgui-0.12.4/deviceRW.c:1160
    Original C:
      	info->V33=devlistEntry->V33;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /tmp/opgui-0.12.4/deviceRW.c:1161
    Original C:
      	info->size=devlistEntry->ReadParam[0];
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /tmp/opgui-0.12.4/deviceRW.c:1162
    Original C:
      	info->sizeEE=devlistEntry->WriteParam[1];	//some devices implement auto EE size on read, but never on write
  *)
  str2[0] := 0;
  (* TODO gtk2laz: do-while without while
    Source: /tmp/opgui-0.12.4/deviceRW.c:1164
    Original C:
      	double x=info->size/1024.0;
  *)
  if x-(int)x then
   sprintf(strF, '%.1f', x);
  case info->family of
   PIC12:
   begin
    sprintf(str2, "PIC12, '');
    if info->size<1024 then
     sprintf(str3, '%dW FLASH', info->size);
    strcat(str2, str3);
   end;
   PIC16:
   begin
    sprintf(str2, "PIC16, '');
    if info->size<1024 then
     sprintf(str3, '%dW FLASH', info->size);
    strcat(str2, str3);
    if info->sizeEE then
    begin
     ee := info->sizeEE;
     if ee<0 then
      ee := -ee;
     sprintf(str3, ' + %dB EEPROM', ee);
     strcat(str2, str3);
    end;
   end;
   PIC18:
   begin
    sprintf(str2, "PIC18, '');
    if info->size<1024 then
     sprintf(str3, '%dB FLASH ', info->size);
    strcat(str2, str3);
    if info->sizeEE then
    begin
     sprintf(str3, '+ %dB EEPROM ', info->sizeEE);
     strcat(str2, str3);
    end;
   end;
   PIC24:
   begin
    sprintf(str2, "PIC24, '');
    if info->size<1024 then
     sprintf(str3, '%dW FLASH', info->size);
    strcat(str2, str3);
    if info->sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info->sizeEE);
     strcat(str2, str3);
    end;
   end;
   PIC32:
   begin
    sprintf(str2, "PIC32, '');
    if info->size<1024 then
     sprintf(str3, '%dW FLASH', info->size);
    strcat(str2, str3);
    if info->sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info->sizeEE);
     strcat(str2, str3);
    end;
   end;
   AVR:
   begin
    sprintf(str2, "AVR, '');
    if info->size<1024 then
     sprintf(str3, '%dB FLASH', info->size);
    strcat(str2, str3);
    if info->sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info->sizeEE);
     strcat(str2, str3);
    end;
   end;
   I2CEE:
   begin
    if info->size<1024 then
     sprintf(str2, "%s, %dB", strings[I_I2CMEM], info->size);
   end;
   SPIEE:
   begin
    if info->size<1024 then
     sprintf(str2, "%s, %dB", strings[I_SPIMEM], info->size);
   end;
   UWEE:
   begin
    if info->size<1024 then
     sprintf(str2, "%s, %dB", strings[I_UWMEM], info->size);
   end;
   OWEE:
   begin
    if info->size<0 then
     sprintf(str2, strings[I_OWDEV]);
   end;
   UNIOEE:
   begin
    if info->size<1024 then
     sprintf(str2, "%s, %dB", strings[I_UNIOMEM], info->size);
    (* TODO gtk2laz: unrecognised statement
      Source: /tmp/opgui-0.12.4/deviceRW.c:1153
      Original C:
        
        /// Copies the device info from the passed devlist entry into the passed DevInfo
        /// Does NOT populate fields 'device' and 'group' as these are device-specific
        void populateDevInfo(struct DevInfo *info, const struct DEVICES *devlistEntry) {
        	char str2[256],str3[64],strF[32];
        	info->family=devlistEntry->family;
        	info->HV=devlistEntry->HV;
        	info->V33=devlistEntry->V33;
        	info->size=devlistEntry->ReadParam[0];
        	info->sizeEE=devlistEntry->WriteParam[1];	//some devices implement auto EE size on read, but never on write
        	str2[0]=0;
        	double x=info->size/1024.0;
        	if(x-(int)x) sprintf(strF,"%.1f",x);
        	else sprintf(strF,"%d",(int)x);
        	switch(info->family){
        		case PIC12:
        			sprintf(str2,"PIC12, ");
        			if(info->size<1024) sprintf(str3,"%dW FLASH",info->size);
        			else sprintf(str3,"%sKW FLASH",strF);
        			strcat(str2,str3);
        			break;
        		case PIC16:
        			sprintf(str2,"PIC16, ");
        			if(info->size<1024) sprintf(str3,"%dW FLASH",info->size);
        			else sprintf(str3,"%sKW FLASH",strF);
        			strcat(str2,str3);
        			if(info->sizeEE){
        				int ee=info->sizeEE;
        				if(ee<0) ee=-ee;
        				sprintf(str3," + %dB EEPROM",ee);
        				strcat(str2,str3);
    *)
   end;
   else
   begin
    sprintf(str2, '!!unknown family!!');
   end;
  end;
  strcpy(info->features, str2);
end;

function GetDevInfo(dev: PChar): TDevInfo;
var
  i: Integer;
  str=0: Char;
  tok: Char;
  info: Tstruct DevInfo;
begin
  info.device := 0;
  info.family := -1;
  info.HV := -1;
  info.V33 := -1;
  info.size := -1;
  info.sizeEE := -1;
  info.features := 0;
  for i := 0 to (NDEVLIST) - 1 do
  begin
   str := malloc(strlen(DEVLIST[i].device)+1);
   // return value of strcpy() ignored
   strcpy(str, DEVLIST[i].device);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/deviceRW.c:1280
     Original C:
       		for(tok=strtok(str,",");tok;tok=strtok(NULL,",")){		//compare every device name
       			if(!strcmp(dev,tok)){	//proceed if found
       				info.device=malloc(strlen(tok)+1);
       				strcpy(info.device,tok);
       				info.group=nameToGroup(info.device);
       				populateDevInfo(&info, &(DEVLIST[i]));
       				free(str);
       				return info;
       			}
       		}
   *)
   // init: tok=strtok(str,",")
   while tok do
   begin
    if  not strcmp(dev,tok) then
    begin
     info.device := malloc(strlen(tok)+1);
     // return value of strcpy() ignored
     strcpy(info.device, tok);
     info.group := nameToGroup(info.device);
     // return value of populateDevInfo() ignored
     populateDevInfo(&info, &(DEVLIST[i]));
     FreeMem(str);
     Exit(info);
    end;
    tok := strtok(nil, '', '');
   end;
  end;
end;

end.
