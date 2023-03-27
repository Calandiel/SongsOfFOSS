# Make sure a directory for Windows Love executable exists
mkdir love-windows # Put a copy of Love directly in this directory (path to love.exe should be love-windows/love.exe)

# Make sure directories for the binaries in release form exist
mkdir release
mkdir release/windows
mkdir release/linux-and-mac

# Compress to a love file
cd sote
zip -9 -r sote.love .
cd ..

# Move the file to the right directory
cp sote/sote.love release/linux-and-mac/sote.love
rm sote/sote.love

# Append the love exe with sote.love and rename it to sote.exe
cat love-windows/love.exe release/linux-and-mac/sote.love > release/windows/sote.exe

# Copy the files to release directories
cp love-windows/ release/windows/ -r -u -T

# Remove unnecessary files
rm release/windows/love.exe