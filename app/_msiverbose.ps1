# Elevate: one verbose MSI repair to diagnose the 1603 failure cause.
Start-Process -FilePath 'msiexec.exe' -ArgumentList '/fa {28C90E10-A917-28CE-DC76-63B86B801968} /qn /norestart /l*v D:\Temp\sdk_repair_verbose.log' -Wait
