FILE=release/windows/SotE.exe
if [ -f "$FILE" ]; then
    $FILE
else 
    ./clear.sh
    ./distributeWin.bat
    ./release/windows/SotE.exe
fi

