:: Prepare date format
::powershell get-date -format "{ddMMyy}"

:: Make sure a directory for Windows Love executable exists
:: Put a copy of Love's all files (not all are needed) directly in this directory (path to love.exe should be love-windows/love.exe)
:: mkdir love-windows

:: Make sure directories for the binaries in release form exist
mkdir release
mkdir release\windows
::mkdir release/linux-and-mac

:: Compress to a love file (add -v flag for list of packed files)
::cd sote
::tar -czf ..\release\windows\SotE.tar.gz .
::cd ..

:: Append the love.exe with sote.love and rename it to sote.exe
copy /b love-windows\love.exe+sote.zip release\windows\SotE.exe

:: Copy the files to release directories
::cp love-windows/* release/windows/
xcopy /s love-windows\*.dll release\windows
xcopy /s love-windows\license.txt release\windows

:: Remove unnecessary files
rm release/windows/SotE.tar.gz
rm sote.zip

::pause