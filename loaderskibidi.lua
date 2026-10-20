-- Skibidi key loader (fixed). Держи этот файл как loaderskibidi.lua в репе.
local API = "https://skibidi-farm.pavlo-melnik001.workers.dev"
local SCRIPT_URL = "https://raw.githubusercontent.com/SecretSpeedW/skibidi-loader/refs/heads/main/skibidi_farm.lua"
local LOADER_URL = "https://raw.githubusercontent.com/SecretSpeedW/skibidi-loader/refs/heads/main/loaderskibidi.lua"
local KEYFILE = "skibidi_key.txt"
local CACHE = "skibidi_farm_cache.lua"
local STAMP = "skibidi_key_stamp.txt"
local CFGFILE = "skibidi_config.txt"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local pl = Players.LocalPlayer

local function hasFileApi()
    return typeof(writefile) == "function" and typeof(isfile) == "function"
end

local function queueNext()
    if typeof(queue_on_teleport) ~= "function" then return end
    pcall(queue_on_teleport, string.format([[pcall(function() loadstring(game:HttpGet("%s"))() end)]], LOADER_URL))
end

-- восстановить конфиг после телепорта (getgenv сбрасывается)
if hasFileApi() and isfile(CFGFILE) and type(getgenv().TTC_Config) ~= "table" then
    local ok, raw = pcall(readfile, CFGFILE)
    if ok and typeof(raw) == "string" then
        local okj, t = pcall(function() return HttpService:JSONDecode(raw) end)
        if okj and type(t) == "table" then getgenv().TTC_Config = t end
    end
end
if type(getgenv().TTC_Config) == "table" and hasFileApi() then
    pcall(function() writefile(CFGFILE, HttpService:JSONEncode(getgenv().TTC_Config)) end)
end

local function readSaved()
    if hasFileApi() and isfile(KEYFILE) then
        local ok, v = pcall(readfile, KEYFILE)
        if ok and typeof(v) == "string" then return v:gsub("%s+", "") end
    end
    return nil
end

local function saveKey(k)
    if hasFileApi() then
        pcall(writefile, KEYFILE, k)
        pcall(writefile, STAMP, tostring(os.time()))
    end
end

local function validBody(body)
    if typeof(body) ~= "string" then return false end
    if #body < 200 then return false end
    if body:find("AUTH_FAILED", 1, true) then return false end
    if body:find("GITHUB_ERROR", 1, true) then return false end
    return true
end

local function requestKey(key)
    local url = API .. "?key=" .. HttpService:UrlEncode(key)
    local ok, body
    for _ = 1, 3 do
        ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and validBody(body) then return true, body end
        task.wait(0.8)
    end
    if ok and typeof(body) == "string" and (body:find("AUTH_FAILED", 1, true) or body:find("GITHUB_ERROR", 1, true)) then
        return false, "expired"
    end
    return false, "net"
end

local function loadMain(workerBody)
    local src
    local ok, body = pcall(function() return game:HttpGet(SCRIPT_URL .. "?v=" .. tostring(os.time())) end)
    if ok and typeof(body) == "string" and #body > 500 and not body:find("404: Not Found", 1, true) then
        src = body
        if hasFileApi() then pcall(writefile, CACHE, body) end
    elseif hasFileApi() and isfile(CACHE) then
        local okc, cached = pcall(readfile, CACHE)
        if okc and typeof(cached) == "string" and #cached > 500 then src = cached end
    end
    if not src and validBody(workerBody) then src = workerBody end
    if not src then return false, "no script" end
    local chunk, err = loadstring(src)
    if not chunk then return false, tostring(err) end
    queueNext()
    local okr, err2 = pcall(chunk)
    if not okr then return false, tostring(err2) end
    return true
end

-- UI
local parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
local old = parent:FindFirstChild("SkibidiKeyUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "SkibidiKeyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2e7
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 390, 0, 178)
frame.Position = UDim2.new(0.5, -195, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 14, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = frame
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(150, 80, 255); stroke.Thickness = 1.5; stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 30)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "SKIBIDI FARM · KEY"
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -24, 0, 36)
box.Position = UDim2.new(0, 12, 0, 44)
box.BackgroundColor3 = Color3.fromRGB(28, 23, 38)
box.BorderSizePixel = 0
box.Font = Enum.Font.GothamMedium
box.TextSize = 14
box.PlaceholderText = "Вставь ключ"
box.ClearTextOnFocus = false
box.Text = readSaved() or ""
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
box.Parent = frame
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = box

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -24, 0, 36)
btn.Position = UDim2.new(0, 12, 0, 90)
btn.BackgroundColor3 = Color3.fromRGB(120, 60, 210)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Text = "ПРОВЕРИТЬ И ЗАПУСТИТЬ"
btn.BorderSizePixel = 0
btn.Parent = frame
local btc = Instance.new("UICorner"); btc.CornerRadius = UDim.new(0, 8); btc.Parent = btn

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 30)
status.Position = UDim2.new(0, 12, 0, 134)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamMedium
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(180, 180, 190)
status.Text = ""
status.Parent = frame

local busy = false
local function say(t, c) status.Text = t; status.TextColor3 = c or Color3.fromRGB(180, 180, 190) end

local function start(key)
    if busy then return end
    busy = true
    btn.Text = "..."
    local ok, body = requestKey(key)
    if ok then
        say("Ключ принят, загрузка...", Color3.fromRGB(110, 230, 130))
        saveKey(key)
        local ok2, err = loadMain(body)
        if ok2 then
            gui:Destroy()
        else
            say("Ошибка скрипта: " .. tostring(err):sub(1, 90), Color3.fromRGB(255, 120, 120))
        end
    elseif body == "expired" then
        say("Ключ неверный или истёк", Color3.fromRGB(255, 110, 110))
    else
        if hasFileApi() and isfile(CACHE) then
            say("Нет сети, запуск из кэша...", Color3.fromRGB(255, 190, 90))
            local ok2, err = loadMain(nil)
            if ok2 then gui:Destroy() else say("Ошибка: " .. tostring(err):sub(1, 80), Color3.fromRGB(255, 120, 120)) end
        else
            say("Нет связи с сервером ключей", Color3.fromRGB(255, 160, 90))
        end
    end
    busy = false
    btn.Text = "ПРОВЕРИТЬ И ЗАПУСТИТЬ"
end

btn.MouseButton1Click:Connect(function()
    local key = box.Text:gsub("%s+", "")
    if key == "" then say("Введи ключ", Color3.fromRGB(255, 190, 90)) return end
    task.spawn(start, key)
end)
box.FocusLost:Connect(function(enter)
    if enter then
        local key = box.Text:gsub("%s+", "")
        if key ~= "" then task.spawn(start, key) end
    end
end)

-- авто-вход по сохранённому ключу
task.spawn(function()
    local k = readSaved()
    if k and k ~= "" then
        say("Проверка сохранённого ключа...")
        start(k)
    else
        say("Введи ключ доступа")
    end
end)
