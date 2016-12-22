program Svchost32ZombieKiller;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  TlHelp32,
  Math;

var
  Snapshot : THandle;
  pe : TProcessEntry32;
  Handle : Cardinal;
  Usage, Delta : Int64;
  mCreationTime, mExitTime, mKernelTime, mUserTime : _FILETIME;
  KillCommand : String;
begin
  while True do
  begin
    Snapshot :=CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
    try
      pe.dwSize := SizeOf(pe);
      if Process32First(Snapshot, pe) then
      begin
        while Process32Next(Snapshot, pe) do
        begin
        if pe.szExeFile <> 'svchost.exe' then Continue;
          Handle := OpenProcess(PROCESS_QUERY_INFORMATION, false, pe.th32ProcessID);
          if Handle = 0 then Continue;
          try
            if GetProcessTimes(Handle, mCreationTime, mExitTime, mKernelTime, mUserTime) then
            begin
              Usage := int64(mKernelTime.dwLowDateTime or (mKernelTime.dwHighDateTime shr 32)) +
                       int64(mUserTime.dwLowDateTime or (mUserTime.dwHighDateTime shr 32));
              Delta := GetTickCount;
              Sleep(250);
              Delta := GetTickCount - Delta;
              if GetProcessTimes(Handle, mCreationTime, mExitTime, mKernelTime, mUserTime) then
              begin
                Usage := int64(mKernelTime.dwLowDateTime or (mKernelTime.dwHighDateTime shr 32)) +
                       int64(mUserTime.dwLowDateTime or (mUserTime.dwHighDateTime shr 32)) - Usage;
                Usage := Floor((Usage / Delta) / 100);
                if Usage > 90 then
                begin
                  WriteLn(pe.th32ProcessID, ' ', pe.szExeFile, ' ', Usage);
                  KillCommand := 'taskkill /f /pid ' + IntToStr(pe.th32ProcessID);
                  WinExec(PChar(KillCommand), SW_HIDE);
                  Exit;
                end;
              end;
            end;
            finally
              CloseHandle(Handle);
          end;
        end;
      end;
    finally
      CloseHandle(Snapshot);
    end;
//    Sleep(5000);
  end;
end.
