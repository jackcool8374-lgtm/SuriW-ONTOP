--!nocheck
-- OXIRO V3 — CHASE + VOID + SPEEDWALK + RB-BYPASS + BLOCK DETECTION + 2026 GUI
-- Delta / Mobile compatible
-- Paste into executor. Key: hello

local MAX_ATTEMPTS = 3
local CORRECT_KEY  = "hello"

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TextChatService   = game:GetService("TextChatService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local Player   = Players.LocalPlayer
local attempts = 0

local immunePlayers = {}

-- =========================================================
-- HELPERS
-- =========================================================
local function getHRP(plr)
    local p = plr or Player
    return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end

local function isProtected(t)
    if not t then return false end
    if type(t) == "string" then
        for p, s in pairs(immunePlayers) do
            if s and (p.Name == t or p.DisplayName == t) then return true end
        end
    elseif typeof(t) == "Instance" then
        if t:IsA("Player") then return immunePlayers[t] == true
        elseif t:IsA("Model") then
            local p = Players:GetPlayerFromCharacter(t)
            return p and immunePlayers[p] == true
        end
    end
    return false
end
local function isPlayerSafe(p) return isProtected(p) end

-- Immune metatable guard
pcall(function()
    local gmt = getrawmetatable(game)
    local oldNamecall = gmt.__namecall
    setreadonly(gmt, false)
    gmt.__namecall = newcclosure(function(self, ...)
        local args  = {...}
        local meth  = getnamecallmethod()
        if meth == "FireServer" or meth == "InvokeServer" then
            for p, s in pairs(immunePlayers) do
                if s and p and p.Character then
                    for _, a in pairs(args) do
                        if a == p or a == p.Character or (type(a) == "table" and rawget(a, "Instance") == p) then
                            return nil
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(gmt, true)
end)

-- =========================================================
-- KEY UI
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OXIROGATE"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
MainFrame.Position = UDim2.new(0.5, -185, 0.5, -125)
MainFrame.Size = UDim2.new(0, 370, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local OuterStroke = Instance.new("UIStroke")
OuterStroke.Parent = MainFrame
OuterStroke.Color = Color3.fromRGB(60, 220, 255)
OuterStroke.Thickness = 3
TweenService:Create(OuterStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Color = Color3.fromRGB(140, 240, 255), Thickness = 5
}):Play()

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 18)
Title.Size = UDim2.new(1, 0, 0, 55)
Title.Font = Enum.Font.GothamBold
Title.Text = "OXIRO GATE"
Title.TextColor3 = Color3.fromRGB(80, 240, 255)
Title.TextSize = 36

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = MainFrame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 0, 0, 70)
SubTitle.Size = UDim2.new(1, 0, 0, 22)
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.Text = "SECURITY VERIFICATION"
SubTitle.TextColor3 = Color3.fromRGB(160, 200, 220)
SubTitle.TextSize = 13

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = MainFrame
KeyBox.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
KeyBox.Position = UDim2.new(0.07, 0, 0, 100)
KeyBox.Size = UDim2.new(0.86, 0, 0, 50)
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Enter access key..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(220, 250, 255)
KeyBox.TextSize = 16
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 10)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(20, 130, 200)
SubmitBtn.Position = UDim2.new(0.18, 0, 0, 165)
SubmitBtn.Size = UDim2.new(0.64, 0, 0, 45)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "VERIFY"
SubmitBtn.TextColor3 = Color3.fromRGB(240, 255, 255)
SubmitBtn.TextSize = 17
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0, 0, 0, 218)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Font = Enum.Font.GothamMedium
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 90, 90)
Status.TextSize = 12

-- =========================================================
-- MAIN SCRIPT
-- =========================================================
local function runMainScript()
    ScreenGui:Destroy()

    local OWNER_USERNAME = "Markarenoob"
    local isOwner        = Player.Name == OWNER_USERNAME

    -- ---------- state ----------
    local mode               = "idle"
    local attackTarget       = nil
    local savedTargetUserId  = nil
    local savedPosition      = nil
    local HITBOX_SIZE        = 100
    local BLOCK_ENABLED      = true
    local UNLIMITED_M1_ENABLED = true
    local M2_SPAM_ENABLED    = true
    local NOCLIP_ENABLED     = false
    local AUTO_EQUIP_ENABLED = false
    local SPEEDWALK_ENABLED  = false
    local SPEEDWALK_SPEED    = 90
    local VOID_MODE_ENABLED  = false
    local HVH_MODE           = false
    local HVH_TARGET_USERID  = nil
    local HVH_VOID           = false
    local HVH_NOCLIP         = false
    local isVoiding          = false
    local isSpammingM2       = false
    local isChasing          = false
    local chaseTarget        = nil
    local chaseConnection    = nil
    local noclipConnection   = nil
    local blockConnection    = nil
    local rbConnection       = nil
    local speedConnection    = nil
    local playerButtons      = {}
    local currentTab         = "target"

    -- ---------- chase constants ----------
    local CHASE_DISTANCE  = 3.5
    local PREDICTION_MULT = 1.0     -- <-- multpred multiplier
    local PREDICTION_BASE = 0.2     -- base lookahead seconds

    -- ---------- void constants ----------
    local FALL_SPEED           = -3500
    local FALL_CHECK_Y         = -4900
    local ATTACK_RESET_INTERVAL = 4

    -- ---------- helpers ----------
    local function findPlayerByFuzzy(str)
        if not str or str == "" then return nil end
        str = str:lower()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.DisplayName:lower():find(str) or plr.Name:lower():find(str) then
                return plr
            end
        end
        return nil
    end

    local function notify(title, text)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification",
                { Title = title, Text = text, Duration = 3 })
        end)
    end

    local function sayChat(text)
        pcall(function()
            local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if ev and ev:FindFirstChild("SayMessageRequest") then
                ev.SayMessageRequest:FireServer(text, "All")
            end
        end)
    end

    -- ---------- NOCLIP ----------
    local function setNoclip(enabled)
        NOCLIP_ENABLED = enabled
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if enabled then
            noclipConnection = RunService.Stepped:Connect(function()
                local c = Player.Character
                if not c then return end
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        end
    end

    -- ---------- CHASE ----------
    local function stopChase()
        isChasing   = false
        chaseTarget = nil
        if chaseConnection then chaseConnection:Disconnect(); chaseConnection = nil end
        if Player.Character then
            for _, v in ipairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end

    local function startChase(target)
        if chaseConnection then chaseConnection:Disconnect() end
        chaseTarget = target
        isChasing   = true

        chaseConnection = RunService.RenderStepped:Connect(function()
            if isVoiding then return end                    -- void takes over
            if not isChasing or not chaseTarget or not chaseTarget.Character then
                stopChase(); return
            end
            local myHRP = getHRP(Player)
            local tHRP  = getHRP(chaseTarget)
            if not myHRP or not tHRP then stopChase(); return end

            for _, v in ipairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end

            local pred = PREDICTION_BASE * PREDICTION_MULT
            local tVel = tHRP.Velocity
            local predictedPos = tHRP.Position + (tVel * pred)
            local look = tHRP.CFrame.LookVector
            local desired = predictedPos - (look * CHASE_DISTANCE) + Vector3.new(0, 1, 0)

            if (desired - myHRP.Position).Magnitude > 1 then
                myHRP.CFrame = CFrame.new(desired, tHRP.Position)
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
            else
                myHRP.Velocity = tVel
            end
        end)
    end

    -- ---------- VOID ----------
    local function goVoid(target)
        if isVoiding or not VOID_MODE_ENABLED or isPlayerSafe(target) then return end
        if not target or not target.Character then return end
        local myHRP = getHRP(Player)
        local tHRP  = getHRP(target)
        if not myHRP or not tHRP then return end

        isVoiding    = true
        isSpammingM2 = true

        myHRP.CFrame   = CFrame.new(tHRP.Position.X, myHRP.Position.Y, tHRP.Position.Z)
        myHRP.Velocity = Vector3.new(0, FALL_SPEED, 0)

        -- no task.wait on entry — fire the loop immediately
        task.spawn(function()
            for _ = 1, 8 do
                if not myHRP or not isVoiding then break end
                myHRP.Velocity = Vector3.new(0, FALL_SPEED, 0)
                RunService.Heartbeat:Wait()
            end
        end)

        -- FAST RESUME — zero-delay snap back
        task.delay(0, function()
            isVoiding    = false
            isSpammingM2 = false
            if attackTarget and not isPlayerSafe(attackTarget) then
                local t = getHRP(attackTarget)
                local m = getHRP(Player)
                if t and m then
                    local pred = PREDICTION_BASE * PREDICTION_MULT
                    m.CFrame = CFrame.new(t.Position + t.Velocity * pred, t.Position)
                end
                if not isChasing then startChase(attackTarget) end
            end
        end)
    end

    -- void watchdog (no task.wait on hot path)
    RunService.Heartbeat:Connect(function()
        if not VOID_MODE_ENABLED or mode ~= "attack" then return end
        if not attackTarget or isPlayerSafe(attackTarget) then return end
        local hrp = getHRP(Player)
        if hrp and hrp.Position.Y < FALL_CHECK_Y then
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(ATTACK_RESET_INTERVAL)
            if VOID_MODE_ENABLED and mode == "attack"
                and attackTarget and not isPlayerSafe(attackTarget)
            then
                goVoid(attackTarget)
            end
        end
    end)

    -- ---------- BLOCK + BLOCK DETECTION ----------
    local function setInfBlock(enabled)
        BLOCK_ENABLED = enabled
        if blockConnection then blockConnection:Disconnect(); blockConnection = nil end
        if not enabled then return end

        blockConnection = RunService.RenderStepped:Connect(function()
            if not BLOCK_ENABLED then return end
            local c = Player.Character
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Blocking, true)
                local st = hum:GetState()
                -- DETECTION: if we lost block state, force re-block same frame
                if st ~= Enum.HumanoidStateType.Blocking then
                    if st == Enum.HumanoidStateType.Stunned
                       or st == Enum.HumanoidStateType.FallingDown then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    hum:ChangeState(Enum.HumanoidStateType.Blocking)
                end
            end

            pcall(function()
                local cr = ReplicatedStorage:FindFirstChild("CombatRemote")
                if cr then cr:FireServer("Block") end
                for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
                    if rem:IsA("RemoteEvent") then
                        local n = rem.Name:lower()
                        if n:find("block") or n:find("guard")
                           or n:find("shield") or n:find("def") then
                            rem:FireServer(true)
                        end
                    end
                end
                local bp = Player:FindFirstChild("Backpack")
                if bp and hum then
                    for _, tool in ipairs(bp:GetChildren()) do
                        if tool:IsA("Tool") and
                           (tool.Name:lower():find("block") or tool.Name:lower():find("shield")) then
                            hum:EquipTool(tool)
                        end
                    end
                end
            end)
        end)
    end

    -- ---------- EQUIP REMOTE ----------
    local EQUIP_LIST = { "Katana", "Short sword", "Bat", "Pickaxe" }
    local function equipWeapon(name)
        local ok = false
        pcall(function()
            local rem = ReplicatedStorage:WaitForChild("EquippingRemote", 3)
            if rem then rem:FireServer(name); ok = true end
        end)
        notify("EQUIP", ok and ("Fired " .. name) or ("No EquippingRemote for " .. name))
    end
    local function autoEquip()
        local c = Player.Character
        if not c or not c:FindFirstChildOfClass("Humanoid") then return end
        if c:FindFirstChildOfClass("Tool") then return end
        local bp = Player:FindFirstChild("Backpack")
        if not bp then return end
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                pcall(function() c:FindFirstChildOfClass("Humanoid"):EquipTool(t) end)
                return
            end
        end
        -- fallback to EquippingRemote
        local rem = ReplicatedStorage:FindFirstChild("EquippingRemote")
        if rem then pcall(function() rem:FireServer(EQUIP_LIST[1]) end) end
    end
    task.spawn(function()
        while true do
            task.wait(0.75)
            if AUTO_EQUIP_ENABLED then autoEquip() end
        end
    end)

    -- ---------- SPEEDWALK + RUBBER-BAND BYPASS ----------
    local lastGoodCFrame = nil
    local rbSuppress     = false

    -- rubber-band detection: if the server resets us far from lastGoodCFrame, snap back
    if rbConnection then rbConnection:Disconnect() end
    rbConnection = RunService.Stepped:Connect(function()
        local hrp = getHRP(Player)
        if not hrp then return end
        local here = hrp.Position
        if lastGoodCFrame then
            local delta = (here - lastGoodCFrame.Position).Magnitude
            -- >100 studs in one tick without our own movement = server rubber-band
            if delta > 100 and not rbSuppress then
                rbSuppress = true
                hrp.CFrame = lastGoodCFrame
                hrp.Velocity = Vector3.zero
                hrp.AssemblyLinearVelocity = Vector3.zero
                task.defer(function() rbSuppress = false end)
                return
            end
        end
        lastGoodCFrame = hrp.CFrame
    end)

    local function setSpeedwalk(enabled, speed)
        SPEEDWALK_ENABLED = enabled
        SPEEDWALK_SPEED   = speed or SPEEDWALK_SPEED
        if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
        if not enabled then return end

        speedConnection = RunService.RenderStepped:Connect(function()
            if not SPEEDWALK_ENABLED then return end
            local c = Player.Character
            if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            local hrp = getHRP(Player)
            if not hum or not hrp then return end
            hum.WalkSpeed = 16   -- keep server happy

            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local step = dir * (SPEEDWALK_SPEED / 60)
                hrp.CFrame = hrp.CFrame + step
                lastGoodCFrame = hrp.CFrame
            end
        end)
    end

    -- ---------- M1 ----------
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            if UNLIMITED_M1_ENABLED then
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("CombatRemote")
                    if r then r:FireServer("M1") end
                end)
            end
        end
    end)

    -- ---------- M2 (void-synced) ----------
    task.spawn(function()
        while true do
            local waitTime = isSpammingM2 and 0.01 or 0.1
            task.wait(waitTime)
            if M2_SPAM_ENABLED then
                pcall(function()
              local r = ReplicatedStorage:FindFirstChild("CombatRemote")
                    if r then r:FireServer("M2") end
                end)
            end
        end
    end)

    -- ---------- TARGET SELECT ----------
    local function selectTarget(plr)
        if plr == Player or isPlayerSafe(plr) then return end
        mode = "attack"
        attackTarget = plr
        savedTargetUserId = plr.UserId
        startChase(plr)
        notify("TARGET", "Locked: " .. plr.Name)
        sayChat("Found You " .. plr.Name .. "!")
    end

    -- ---------- RESPAWN ----------
    Player.CharacterAdded:Connect(function()
        task.defer(function()
            if HVH_MODE and HVH_TARGET_USERID then
                local t = Players:GetPlayerByUserId(HVH_TARGET_USERID)
                if t and not isPlayerSafe(t) then
                    attackTarget = t
                    if HVH_VOID then VOID_MODE_ENABLED = true end
                    if HVH_NOCLIP then setNoclip(true) end
                    if not isChasing then startChase(t) end
                end
            elseif savedTargetUserId then
                local t = Players:GetPlayerByUserId(savedTargetUserId)
                if t and not isPlayerSafe(t) then
                    attackTarget = t
                    if not isChasing then startChase(t) end
                end
            end
        end)
    end)

    -- =========================================================
    -- GUI (2026 glass)
    -- =========================================================
    pcall(function()
        if CoreGui:FindFirstChild("OxiroGui") then CoreGui.OxiroGui:Destroy() end
    end)

    local ScreenGuiMain = Instance.new("ScreenGui")
    ScreenGuiMain.Name = "OxiroGui"
    ScreenGuiMain.Parent = Player:WaitForChild("PlayerGui")
    ScreenGuiMain.ResetOnSpawn = false
    ScreenGuiMain.DisplayOrder = 99999

    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Size = UDim2.new(0, 160, 0, 55)
    OpenBtn.Position = UDim2.new(0.82, 0, 0.88, 0)
    OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
    OpenBtn.Text = isOwner and "OXIRO [OWNER]" or "OXIRO"
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.TextColor3 = Color3.fromRGB(80, 240, 255)
    OpenBtn.TextSize = 20
    OpenBtn.Parent = ScreenGuiMain
    Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 12)
    local obs = Instance.new("UIStroke", OpenBtn)
    obs.Color = Color3.fromRGB(80, 240, 255)
    obs.Thickness = 1.5

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 440, 0, 740)
    Main.Position = UDim2.new(0.2, 0, 0.03, 0)
    Main.BackgroundColor3 = Color3.fromRGB(8, 12, 24)
    Main.Active = true
    Main.Draggable = true
    Main.Visible = false
    Main.Parent = ScreenGuiMain
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    local ms = Instance.new("UIStroke", Main)
    ms.Color = Color3.fromRGB(40, 80, 120)
    ms.Thickness = 1.5

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 50, 0, 36)
    CloseBtn.Position = UDim2.new(1, -55, 0, 6)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 30)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
    CloseBtn.TextSize = 20
    CloseBtn.Parent = Main
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

    local Title2 = Instance.new("TextLabel")
    Title2.Size = UDim2.new(1, -60, 0, 40)
    Title2.Position = UDim2.new(0, 15, 0, 8)
    Title2.BackgroundTransparency = 1
    Title2.Text = isOwner and "OXIRO — OWNER PANEL" or "OXIRO V3"
    Title2.Font = Enum.Font.GothamBold
    Title2.TextColor3 = Color3.fromRGB(80, 240, 255)
    Title2.TextSize = 20
    Title2.TextXAlignment = Enum.TextXAlignment.Left
    Title2.Parent = Main

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -30, 0, 40)
    TabContainer.Position = UDim2.new(0, 15, 0, 55)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = Main
    local TL = Instance.new("UIListLayout")
    TL.FillDirection = Enum.FillDirection.Horizontal
    TL.Padding = UDim.new(0, 8)
    TL.Parent = TabContainer

    local function mkTab(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 0, 1, 0)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
        b.Font = Enum.Font.GothamBold
        b.Text = text
        b.TextColor3 = Color3.fromRGB(180, 200, 220)
        b.TextSize = 13
        b.Parent = TabContainer
        local pad = Instance.new("UIPadding", b)
        pad.PaddingLeft  = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local TargetTabBtn   = mkTab("TARGET")
    local SettingsTabBtn = mkTab("SETTINGS")
    local ImmuneTabBtn   = mkTab("IMMUNE")
    local EquipTabBtn    = mkTab("EQUIP")
    local ControlTabBtn  = isOwner and mkTab("CONTROL") or nil

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -30, 1, -125)
    Content.Position = UDim2.new(0, 15, 0, 105)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local function mkPage(scrollChild)
        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = Content
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.Parent = page
        local lay = Instance.new("UIListLayout", scroll)
        lay.Padding = UDim.new(0, 8)
        return page, scroll
    end

    local TargetPage,   PlayerScroll   = mkPage()
    local SettingsPage, SettingsScroll = mkPage()
    local ImmunePage,   ImmuneScroll   = mkPage()
    local EquipPage,    EquipScroll    = mkPage()
    local ControlPage,  ControlScroll  = nil, nil
    if isOwner then ControlPage, ControlScroll = mkPage() end

    TargetPage.Visible = true

    local function switchTab(name)
        currentTab = name
        TargetPage.Visible   = name == "target"
        SettingsPage.Visible = name == "settings"
        ImmunePage.Visible   = name == "immune"
        EquipPage.Visible    = name == "equip"
        if isOwner then ControlPage.Visible = name == "control" end
        local function u(btn, active)
            btn.BackgroundColor3 = active and Color3.fromRGB(25, 60, 90) or Color3.fromRGB(25, 35, 55)
        end
        u(TargetTabBtn,   name == "target")
        u(SettingsTabBtn, name == "settings")
        u(ImmuneTabBtn,   name == "immune")
        u(EquipTabBtn,    name == "equip")
        if ControlTabBtn then u(ControlTabBtn, name == "control") end
    end

    TargetTabBtn.MouseButton1Click:Connect(function() switchTab("target") end)
    SettingsTabBtn.MouseButton1Click:Connect(function() switchTab("settings") end)
    ImmuneTabBtn.MouseButton1Click:Connect(function() switchTab("immune") end)
    EquipTabBtn.MouseButton1Click:Connect(function() switchTab("equip") end)
    if ControlTabBtn then ControlTabBtn.MouseButton1Click:Connect(function() switchTab("control") end) end
    OpenBtn.MouseButton1Click:Connect(function() Main.Visible = true end)
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

    -- ---------- TARGET LIST ----------
    local function refreshPlayerList()
        for _, b in ipairs(playerButtons) do b:Destroy() end
        table.clear(playerButtons)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                local safe = isPlayerSafe(plr)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 40)
                btn.BackgroundColor3 = safe and Color3.fromRGB(20, 60, 40) or Color3.fromRGB(25, 40, 65)
                btn.Font = Enum.Font.GothamMedium
                btn.Text = (safe and "[SAFE] " or "") .. plr.DisplayName .. "  (@" .. plr.Name .. ")"
                btn.TextColor3 = safe and Color3.fromRGB(120, 255, 170) or Color3.fromRGB(180, 220, 255)
                btn.TextSize = 13
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = PlayerScroll
                local pad = Instance.new("UIPadding", btn)
                pad.PaddingLeft = UDim.new(0, 12)
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

                local stroke = Instance.new("UIStroke", btn)
                stroke.Color = safe and Color3.fromRGB(60, 180, 110) or Color3.fromRGB(50, 90, 140)
                stroke.Thickness = 1

                btn.MouseButton1Click:Connect(function()
                    if safe then
                        notify("IMMUNE", plr.Name .. " is protected")
                        return
                    end
                    selectTarget(plr)
                    switchTab("target")
                end)
                table.insert(playerButtons, btn)
            end
        end
    end

    Players.PlayerAdded:Connect(function() task.defer(refreshPlayerList) end)
    Players.PlayerRemoving:Connect(function() task.defer(refreshPlayerList) end)
    refreshPlayerList()

    -- ---------- SETTINGS PAGE ----------
    local function mkToggle(parent, label, initial, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(190, 215, 235)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 54, 0, 28)
        btn.Position = UDim2.new(1, -66, 0.5, -14)
        btn.BackgroundColor3 = initial and Color3.fromRGB(30, 120, 80) or Color3.fromRGB(60, 40, 50)
        btn.Font = Enum.Font.GothamBold
        btn.Text = initial and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(230, 245, 255)
        btn.TextSize = 12
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local state = initial
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "ON" or "OFF"
            btn.BackgroundColor3 = state and Color3.fromRGB(30, 120, 80) or Color3.fromRGB(60, 40, 50)
            callback(state)
        end)
        return row
    end

    mkToggle(SettingsScroll, "Unlimited M1", UNLIMITED_M1_ENABLED, function(v) UNLIMITED_M1_ENABLED = v end)
    mkToggle(SettingsScroll, "M2 Spam", M2_SPAM_ENABLED, function(v) M2_SPAM_ENABLED = v end)
    mkToggle(SettingsScroll, "Noclip", NOCLIP_ENABLED, function(v) setNoclip(v) end)
    mkToggle(SettingsScroll, "Infinite Block", BLOCK_ENABLED, function(v) setInfBlock(v) end)
    mkToggle(SettingsScroll, "Auto Equip", AUTO_EQUIP_ENABLED, function(v) AUTO_EQUIP_ENABLED = v end)
    mkToggle(SettingsScroll, "Speedwalk", SPEEDWALK_ENABLED, function(v) setSpeedwalk(v, SPEEDWALK_SPEED) end)
    mkToggle(SettingsScroll, "Void Mode", VOID_MODE_ENABLED, function(v) VOID_MODE_ENABLED = v end)
    mkToggle(SettingsScroll, "HVH Mode", HVH_MODE, function(v) HVH_MODE = v end)

    -- multpred input
    local mpRow = Instance.new("Frame")
    mpRow.Size = UDim2.new(1, 0, 0, 44)
    mpRow.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
    mpRow.Parent = SettingsScroll
    Instance.new("UICorner", mpRow).CornerRadius = UDim.new(0, 8)

    local mpLbl = Instance.new("TextLabel")
    mpLbl.Size = UDim2.new(1, -120, 1, 0)
    mpLbl.Position = UDim2.new(0, 12, 0, 0)
    mpLbl.BackgroundTransparency = 1
    mpLbl.Font = Enum.Font.GothamMedium
    mpLbl.Text = "multpred (prediction multiplier)"
    mpLbl.TextColor3 = Color3.fromRGB(190, 215, 235)
    mpLbl.TextSize = 13
    mpLbl.TextXAlignment = Enum.TextXAlignment.Left
    mpLbl.Parent = mpRow

    local mpBox = Instance.new("TextBox")
    mpBox.Size = UDim2.new(0, 90, 0, 28)
    mpBox.Position = UDim2.new(1, -100, 0.5, -14)
    mpBox.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
    mpBox.Font = Enum.Font.GothamMedium
    mpBox.Text = tostring(PREDICTION_MULT)
    mpBox.TextColor3 = Color3.fromRGB(120, 240, 255)
    mpBox.TextSize = 13
    mpBox.Parent = mpRow
    Instance.new("UICorner", mpBox).CornerRadius = UDim.new(0, 8)
    mpBox.FocusLost:Connect(function()
        local n = tonumber(mpBox.Text)
        if n and n >= 0 then
            PREDICTION_MULT = n
            notify("MULTPRED", "Prediction × " .. tostring(n))
        else
            mpBox.Text = tostring(PREDICTION_MULT)
        end
    end)

    -- ---------- IMMUNE PAGE ----------
    local addRow = Instance.new("Frame")
    addRow.Size = UDim2.new(1, 0, 0, 44)
    addRow.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
    addRow.Parent = ImmuneScroll
    Instance.new("UICorner", addRow).CornerRadius = UDim.new(0, 8)

    local addBox = Instance.new("TextBox")
    addBox.Size = UDim2.new(1, -130, 0, 30)
    addBox.Position = UDim2.new(0, 8, 0.5, -15)
    addBox.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
    addBox.Font = Enum.Font.Gotham
    addBox.PlaceholderText = "Player name / display / @user"
    addBox.Text = ""
    addBox.TextColor3 = Color3.fromRGB(220, 245, 255)
    addBox.TextSize = 13
    addBox.Parent = addRow
    Instance.new("UICorner", addBox).CornerRadius = UDim.new(0, 8)

    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 110, 0, 30)
    addBtn.Position = UDim2.new(1, -118, 0.5, -15)
    addBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 80)
    addBtn.Font = Enum.Font.GothamBold
    addBtn.Text = "ADD SAFE"
    addBtn.TextColor3 = Color3.fromRGB(230, 255, 240)
    addBtn.TextSize = 12
    addBtn.Parent = addRow
    Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 8)

    local immuneCards = {}
    local function refreshImmuneCards()
        for _, c in ipairs(immuneCards) do c:Destroy() end
        table.clear(immuneCards)
        for plr, s in pairs(immunePlayers) do
            if s then
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 52)
                card.BackgroundColor3 = Color3.fromRGB(16, 40, 30)
                card.Parent = ImmuneScroll
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

                local st = Instance.new("UIStroke", card)
                st.Color = Color3.fromRGB(60, 200, 130)
                st.Thickness = 1.2

                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(1, -120, 1, 0)
                name.Position = UDim2.new(0, 12, 0, 0)
                name.BackgroundTransparency = 1
                name.Font = Enum.Font.GothamBold
                name.Text = "[SAFE] " .. plr.DisplayName .. "  (@" .. plr.Name .. ")"
                name.TextColor3 = Color3.fromRGB(140, 255, 190)
                name.TextSize = 13
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Parent = card

                local rm = Instance.new("TextButton")
                rm.Size = UDim2.new(0, 100, 0, 30)
                rm.Position = UDim2.new(1, -110, 0.5, -15)
                rm.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
                rm.Font = Enum.Font.GothamBold
                rm.Text = "REMOVE"
                rm.TextColor3 = Color3.fromRGB(255, 200, 200)
                rm.TextSize = 12
                rm.Parent = card
                Instance.new("UICorner", rm).CornerRadius = UDim.new(0, 8)

                rm.MouseButton1Click:Connect(function()
                    immunePlayers[plr] = nil
                    refreshImmuneCards()
                    refreshPlayerList()
                end)
                table.insert(immuneCards, card)
            end
        end
    end

    addBtn.MouseButton1Click:Connect(function()
        local txt = addBox.Text:gsub("@", "")
        local found = findPlayerByFuzzy(txt)
        if not found then
            notify("IMMUNE", "Player not found: " .. txt)
            return
        end
        if found == Player then
            notify("IMMUNE", "Cannot protect yourself")
            return
        end
        immunePlayers[found] = true
        addBox.Text = ""
        notify("IMMUNE", "Protected " .. found.Name)
        refreshImmuneCards()
        refreshPlayerList()
    end)
    refreshImmuneCards()

    -- ---------- EQUIP PAGE ----------
    for _, wname in ipairs(EQUIP_LIST) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 42)
        b.BackgroundColor3 = Color3.fromRGB(25, 40, 65)
        b.Font = Enum.Font.GothamBold
        b.Text = "EQUIP " .. wname:upper()
        b.TextColor3 = Color3.fromRGB(180, 220, 255)
        b.TextSize = 14
        b.Parent = EquipScroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        b.MouseButton1Click:Connect(function() equipWeapon(wname) end)
    end

    -- ---------- CONTROL PAGE (OWNER ONLY) ----------
    if isOwner and ControlPage then
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, 0, 0, 60)
        info.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
        info.Font = Enum.Font.GothamMedium
        info.Text = "Owner controls\nUse chat: sv <player>, uh <player>, x <player>"
        info.TextColor3 = Color3.fromRGB(180, 220, 255)
        info.TextSize = 13
        info.Parent = ControlScroll
        Instance.new("UICorner", info).CornerRadius = UDim.new(0, 8)

        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(1, 0, 0, 40)
        stopBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.Text = "STOP ALL (CHASE / VOID / SPEEDWALK)"
        stopBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
        stopBtn.TextSize = 12
        stopBtn.Parent = ControlScroll
        Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)
        stopBtn.MouseButton1Click:Connect(function()
            mode = "idle"
            attackTarget = nil
            isVoiding = false
            isSpammingM2 = false
            VOID_MODE_ENABLED = false
            setSpeedwalk(false)
            stopChase()
            notify("OXIRO", "All actions stopped")
        end)
    end

    -- =========================================================
    -- CHAT COMMAND DISPATCHER
    -- =========================================================
    local function handleCommand(msg)
        local args = {}
        for w in msg:gmatch("%S+") do table.insert(args, w) end
        local cmd = (args[1] or ""):lower()

        if cmd == "ws" then
            local n = tonumber(args[2])
            if n then
                setSpeedwalk(true, n)
                notify("SPEEDWALK", "Set to " .. n)
            else
                setSpeedwalk(not SPEEDWALK_ENABLED, SPEEDWALK_SPEED)
                notify("SPEEDWALK", SPEEDWALK_ENABLED and "ON" or "OFF")
            end

        elseif cmd == "sv" then
            local p = findPlayerByFuzzy(args[2] or "")
            if p then
                immunePlayers[p] = true
                refreshImmuneCards()
                refreshPlayerList()
                notify("SAFE", p.Name .. " protected")
            else
                notify("SAFE", "Player not found")
            end

        elseif cmd == "sp" then
            local p = findPlayerByFuzzy(args[2] or "")
            if p then selectTarget(p) end

        elseif cmd == "usp" then
            stopChase()
            mode = "idle"
            attackTarget = nil
            notify("OXIRO", "Target unset")

        elseif cmd == "multpred" then
            local n = tonumber(args[2])
            if n and n >= 0 then
                PREDICTION_MULT = n
                mpBox.Text = tostring(n)
                notify("MULTPRED", "Prediction × " .. n)
            else
                notify("MULTPRED", "Usage: multpred <number>")
            end

        elseif cmd == "h" then
            local p = findPlayerByFuzzy(args[2] or "")
            if p and not isPlayerSafe(p) then
                selectTarget(p)
                sayChat("Found You " .. p.Name .. "!")
            end

        elseif cmd == "uh" then
            savedTargetUserId = nil
            stopChase()
            mode = "idle"
            attackTarget = nil
            notify("OXIRO", "Cleared target")

        elseif cmd == "x" then
            local p = findPlayerByFuzzy(args[2] or "")
            if p and not isPlayerSafe(p) then
                goVoid(p)
            end

        elseif cmd == "jerk" then
            local hrp = getHRP(Player)
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)
            end

        elseif cmd == "equip" then
            local name = args[2]
            if name then equipWeapon(name) end

        elseif cmd == "rb" then
            -- manual rubber-band resync
            if lastGoodCFrame then
                local hrp = getHRP(Player)
                if hrp then
                    hrp.CFrame = lastGoodCFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    notify("RB", "Resynced")
                end
            end
        end
    end

    Player.Chatted:Connect(handleCommand)

    pcall(function()
        TextChatService.MessageReceived:Connect(function(m)
            if m.TextSource and m.TextSource.UserId == Player.UserId then
                handleCommand(m.Text)
            end
        end)
    end)

    -- Initial state apply
    setInfBlock(BLOCK_ENABLED)
    if NOCLIP_ENABLED then setNoclip(true) end
end

-- =========================================================
-- KEY VERIFY
-- =========================================================
SubmitBtn.MouseButton1Click:Connect(function()
    if KeyBox.Text == CORRECT_KEY then
        Status.TextColor3 = Color3.fromRGB(90, 255, 150)
        Status.Text = "Access granted. Loading..."
        task.delay(0.4, runMainScript)
    else
        attempts += 1
        if attempts >= MAX_ATTEMPTS then
            Status.Text = "Too many attempts. Closing."
            task.delay(0.6, function() ScreenGui:Destroy() end)
        else
            Status.Text = "Invalid key (" .. attempts .. "/" .. MAX_ATTEMPTS .. ")"
        end
    end
end)
