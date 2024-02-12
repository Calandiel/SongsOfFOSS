---@alias love.KeyConstant characterKeys | symbolKeys | numpadKeys | navigationKeys | editingKeys | functionKeys | modifierKeys | applicationKeys | miscKeys
---@alias characterKeys "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" | "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
---@alias symbolKeys "!" | "\"" | "#" | "$" | "&" | "\'" | "(" | ")" | "*" | "+" | "," | "-" | "." | "/" | ":" | ";" | "<" | "=" | ">" | "?" | "@" | "\[" | "\\" | "\]" | "^" | "_" | "`"
---@alias numpadKeys "kp0" | "kp1" | "kp2" | "kp3" | "kp4" | "kp5" | "kp6" | "kp7" | "kp8" | "kp9" | "kp." | "kp," | "kp/" | "kp*" | "kp+" | "kpenter" | "kp="
---@alias navigationKeys "up" | "down" | "right" | "left" | "home" | "end" | "pageup" | "pagedown"
---@alias editingKeys "insert" | "backspace" | "tab" | "clear" | "return" | "delete"
---@alias functionKeys "f1" | "f2" | "f3" | "f4" | "f5" | "f6" | "f7" | "f8" | "f9" | "f10" | "f11" | "f12" | "f13" | "f14" | "f15" | "f16" | "f17" | "f18"
---@alias applicationKeys "www" | "mail" | "calculator" | "computer" | "appsearch" | "apphome" | "appback" | "appforward" | "apprefresh" | "appbookmarks"
---@alias modifierKeys "numlock" | "capslock" | "scrolllock" | "rshift" | "lshift" | "rctrl" | "lctrl" | "ralt" | "lalt" | "rgui" | "lgui" | "mode"
---@alias miscKeys "pause" | "escape" | "help" | "printscreen" | "sysreq" | "menu" | "application" | "power" | "currencyunit" | "undo"

---@alias love.AlignMode "center"  | "left" | "right"

---@class love.Image
---@field getWidth fun():number
---@field getHeight fun():number

---@class FileData

---@alias ImageEncodingFormat "tga" | "png" | "exr" | "jpg" | "bmp"
---@class love.ImageData
---@field encode fun(self: love.ImageData, foramt: ImageEncodingFormat, fielname: string?): FileData

---@class love.Source
---@field stop fun():boolean
---@field play fun():boolean