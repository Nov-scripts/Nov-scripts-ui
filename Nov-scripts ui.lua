local Nexus = {}
Nexus.__index = Nexus

-- Theme (modifiable)
_G.Primary = Color3.fromRGB(0,191,255) -- electric blue
_G.Dark    = Color3.fromRGB(22,22,26)
_G.Third   = Color3.fromRGB(255,0,0)   -- accent

-- util
local function CreateRounded(parent, size)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, size)
    c.Parent = parent
    return c
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Config helpers (safe if executor not present)
local function safe_isfolder(p) return isfolder and isfolder(p) end
local function safe_makefolder(p) if makefolder then makefolder(p) end end
local function safe_isfile(p) return isfile and isfile(p) end
local function safe_readfile(p) if readfile then return readfile(p) end end
local function safe_writefile(p, d) if writefile then writefile(p, d) end end
local function safe_delfolder(p) if delfolder then delfolder(p) end end

-- Notification container
local function CreateNotificationContainer()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NexusNotifications"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local container = Instance.new("Frame", gui)
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(1,0)
    container.Position = UDim2.new(0.99, 0, 0.02, 0)
    container.Size = UDim2.new(0, 320, 0, 0)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    local list = Instance.new("UIListLayout", container)
    list.FillDirection = Enum.FillDirection.Vertical
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    return gui, container
end

local notifGui, notifContainer = CreateNotificationContainer()

local function Notify(title, text, duration)
    duration = duration or 4
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 64)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.1
    frame.Parent = notifContainer
    frame.AnchorPoint = Vector2.new(1,0)

    CreateRounded(frame, 8)
    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Text = tostring(title or "Nexus")
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(245,245,245)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.Size = UDim2.new(1, -20, 0, 18)

    local body = Instance.new("TextLabel", frame)
    body.Text = tostring(text or "")
    body.Font = Enum.Font.Gotham
    body.TextSize = 12
    body.TextColor3 = Color3.fromRGB(200,200,200)
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 10, 0, 26)
    body.Size = UDim2.new(1, -20, 0, 32)
    body.TextWrapped = true

    frame.Position = UDim2.new(1, 0, 0, 0)
    frame.LayoutOrder = #notifContainer:GetChildren() + 1

    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -10, 0, 0)})
    tweenIn:Play()

    delay(duration, function()
        local tweenOut = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 0, 0), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        pcall(function() frame:Destroy() end)
    end)
end

-- Draggable helper
local function MakeDraggable(dragHandle, target)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(target, TweenInfo.new(0.12), {Position = newPos}):Play()
    end
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- Main CreateWindow
function Nexus:CreateWindow(params)
    params = params or {}
    local cfg = {
        Title = params.Title or "Nexus",
        SubTitle = params.SubTitle or "",
        Size = params.Size or UDim2.new(0, 698, 0, 479),
        NebulaImage = params.NebulaImage or ""
    }

    -- clean old
    local old = CoreGui:FindFirstChild("NexusUI_Full")
    if old then pcall(function() old:Destroy() end) end

    local screen = Instance.new("ScreenGui", CoreGui)
    screen.Name = "NexusUI_Full"
    screen.ResetOnSpawn = false

    local container = Instance.new("Frame", screen)
    container.Name = "Container"
    container.Size = UDim2.new(0, 104.5, 0, 52) -- start small and animate
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = Color3.fromRGB(12,13,15)
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    CreateRounded(container, 12)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(52,66,89)
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Handler frame (holds tabs, divider, sections)
    local handler = Instance.new("Frame", container)
    handler.Name = "Handler"
    handler.Size = UDim2.new(0, 698, 0, 479)
    handler.Position = UDim2.new(0.5, 0, 0.5, 0)
    handler.AnchorPoint = Vector2.new(0.5, 0.5)
    handler.BackgroundTransparency = 1

    -- Nebula background
    local neb = Instance.new("ImageLabel", container)
    neb.Name = "Nebula"
    neb.Size = UDim2.new(1, 0, 1, 0)
    neb.Position = UDim2.new(0.5,0,0.5,0)
    neb.AnchorPoint = Vector2.new(0.5,0.5)
    neb.BackgroundTransparency = 1
    neb.Image = cfg.NebulaImage
    neb.ImageTransparency = 0.2

    -- Tabs scrolling frame (left)
    local tabs = Instance.new("ScrollingFrame", handler)
    tabs.Name = "Tabs"
    tabs.Size = UDim2.new(0, 129, 0, 401)
    tabs.Position = UDim2.new(0.026,0,0.11,0)
    tabs.BackgroundTransparency = 1
    tabs.ScrollBarThickness = 0
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local tabsLayout = Instance.new("UIListLayout", tabs)
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Pin/indicator & icon/title
    local pin = Instance.new("Frame", handler)
    pin.Name = "Pin"
    pin.Size = UDim2.new(0,2,0,16)
    pin.Position = UDim2.new(0.026,0,0.136,0)
    pin.BackgroundColor3 = _G.Primary
    CreateRounded(pin, 100)

    local icon = Instance.new("ImageLabel", handler)
    icon.Name = "Icon"
    icon.Image = "rbxassetid://107819132007001"
    icon.Size = UDim2.new(0,18,0,18)
    icon.Position = UDim2.new(0.025,0,0.055,0)
    icon.BackgroundTransparency = 1
    icon.ImageColor3 = _G.Primary

    local clientName = Instance.new("TextLabel", handler)
    clientName.Name = "ClientName"
    clientName.Text = cfg.Title
    clientName.Font = Enum.Font.Gotham
    clientName.TextColor3 = _G.Primary
    clientName.TextSize = 13
    clientName.Position = UDim2.new(0.056,0,0.055,0)
    clientName.BackgroundTransparency = 1
    clientName.TextXAlignment = Enum.TextXAlignment.Left

    -- Divider
    local divider = Instance.new("Frame", handler)
    divider.Name = "Divider"
    divider.Size = UDim2.new(0,1,1,0)
    divider.Position = UDim2.new(0.235,0,0,0)
    divider.BackgroundColor3 = Color3.fromRGB(52,66,89)
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0

    -- Sections holder (three columns)
    local sectionsFolder = Instance.new("Folder", handler)
    sectionsFolder.Name = "Sections"

    local leftSection = Instance.new("ScrollingFrame", sectionsFolder)
    leftSection.Name = "LeftSection"
    leftSection.Size = UDim2.new(0,243,0,445)
    leftSection.Position = UDim2.new(0.259,0,0.5,0)
    leftSection.AnchorPoint = Vector2.new(0,0.5)
    leftSection.BackgroundTransparency = 1
    leftSection.ScrollBarThickness = 0
    leftSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local leftLayout = Instance.new("UIListLayout", leftSection)
    leftLayout.Padding = UDim.new(0,11)
    leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local leftPad = Instance.new("UIPadding", leftSection)
    leftPad.PaddingTop = UDim.new(0,1)

    local midSection = Instance.new("ScrollingFrame", sectionsFolder)
    midSection.Name = "MidSection"
    midSection.Size = UDim2.new(0,243,0,445)
    midSection.Position = UDim2.new(0.444,0,0.5,0) -- middle area
    midSection.AnchorPoint = Vector2.new(0,0.5)
    midSection.BackgroundTransparency = 1
    midSection.ScrollBarThickness = 0
    midSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local midLayout = Instance.new("UIListLayout", midSection)
    midLayout.Padding = UDim.new(0,11)
    midLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    midLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local midPad = Instance.new("UIPadding", midSection)
    midPad.PaddingTop = UDim.new(0,1)

    local rightSection = Instance.new("ScrollingFrame", sectionsFolder)
    rightSection.Name = "RightSection"
    rightSection.Size = UDim2.new(0,243,0,445)
    rightSection.Position = UDim2.new(0.629,0,0.5,0)
    rightSection.AnchorPoint = Vector2.new(0,0.5)
    rightSection.BackgroundTransparency = 1
    rightSection.ScrollBarThickness = 0
    rightSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local rightLayout = Instance.new("UIListLayout", rightSection)
    rightLayout.Padding = UDim.new(0,11)
    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local rightPad = Instance.new("UIPadding", rightSection)
    rightPad.PaddingTop = UDim.new(0,1)

    -- minimize button placeholder
    local minimize = Instance.new("TextButton", handler)
    minimize.Name = "Minimize"
    minimize.Text = ""
    minimize.AutoButtonColor = false
    minimize.Size = UDim2.new(0,24,0,24)
    minimize.Position = UDim2.new(0.02,0,0.029,0)
    minimize.BackgroundTransparency = 1

    -- UIScale for mobile
    local uiScale = Instance.new("UIScale", container)

    -- make container draggable by container (whole thing)
    MakeDraggable(container, container)

    -- animate open
    TweenService:Create(container, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = cfg.Size}):Play()

    -- library object to return
    local lib = {}
    lib._tabs = {}
    lib._ui = screen
    lib._sections = {left = leftSection, middle = midSection, right = rightSection}
    lib._config = { _flags = {}, _keybinds = {}, _library = {} }
    -- load config if exists
    if safe_isfolder("Nexus") then
        if safe_isfile("Nexus/config_"..tostring(game.GameId)..".json") then
            local ok, data = pcall(function() return HttpService:JSONDecode(safe_readfile("Nexus/config_"..tostring(game.GameId)..".json")) end)
            if ok and type(data) == "table" then lib._config = data end
        end
    else
        safe_makefolder("Nexus")
    end

    function lib:SaveConfig()
        pcall(function()
            safe_writefile("Nexus/config_"..tostring(game.GameId)..".json", HttpService:JSONEncode(self._config))
        end)
    end

    function lib:SendNotification(title, text, duration)
        Notify(title, text, duration)
    end

    -- Tab manager
    function lib:CreateTab(title, icon)
        local Tab = Instance.new("TextButton", tabs)
        Tab.Name = "Tab"
        Tab.Size = UDim2.new(0,129,0,38)
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Text = ""
        Tab.LayoutOrder = #tabs:GetChildren()
        CreateRounded(Tab, 6)

        local TabIcon = Instance.new("ImageLabel", Tab)
        TabIcon.Name = "Icon"
        TabIcon.Image = icon or ""
        TabIcon.Size = UDim2.new(0,12,0,12)
        TabIcon.Position = UDim2.new(0.1,0,0.5,0)
        TabIcon.AnchorPoint = Vector2.new(0,0.5)
        TabIcon.BackgroundTransparency = 1
        TabIcon.ImageColor3 = Color3.fromRGB(255,255,255)
        TabIcon.ImageTransparency = 0.8

        local TabLabel = Instance.new("TextLabel", Tab)
        TabLabel.Name = "TextLabel"
        TabLabel.Text = title
        TabLabel.Font = Enum.Font.Gotham
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Color3.fromRGB(255,255,255)
        TabLabel.TextTransparency = 0.7
        TabLabel.BackgroundTransparency = 1
        TabLabel.Position = UDim2.new(0.24,0,0.5,0)
        TabLabel.AnchorPoint = Vector2.new(0,0.5)
        local grad = Instance.new("UIGradient", TabLabel)
        grad.Offset = Vector2.new(0,0)

        -- Tab sections are already created globally; show/hide logic
        local function selectTab()
            -- animate pin and styles
            local targetY = 0.135 + (Tab.LayoutOrder * 0.113)
            TweenService:Create(pin, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.026,0, targetY, 0)}):Play()
            -- highlight current tab
            for _, child in pairs(tabs:GetChildren()) do
                if child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                    if child:FindFirstChild("Icon") and child:FindFirstChild("TextLabel") then
                        TweenService:Create(child.Icon, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.8, ImageColor3 = Color3.fromRGB(255,255,255)}):Play()
                        TweenService:Create(child.TextLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.7, TextColor3 = Color3.fromRGB(255,255,255)}):Play()
                    end
                end
            end
            TweenService:Create(Tab, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.2, ImageColor3 = _G.Primary}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.2, TextColor3 = _G.Primary}):Play()

            -- show left / mid / right sections for this tab only (hide others' children)
            for _, s in pairs(sectionsFolder:GetChildren()) do
                s.Visible = false
            end
            -- show sections (we reuse the global three and swap children)
            leftSection.Visible = true
            midSection.Visible = true
            rightSection.Visible = true
        end

        Tab.MouseButton1Click:Connect(selectTab)

        -- create tab manager returned to user
        local tabAPI = {}
        tabAPI._modules = {}

        -- create_module: settings: {title=, description=, flag=, section='left'|'middle'|'right', rich=false, callback=function}
        function tabAPI:AddModule(settings)
            settings = settings or {}
            local sectionKey = (settings.section and tostring(settings.section):lower()) or "left"
            if sectionKey ~= "left" and sectionKey ~= "middle" and sectionKey ~= "right" then sectionKey = "left" end
            local parentFrame = lib._sections[ (sectionKey == "middle" and "middle") or (sectionKey == "right" and "right") or "left" ]

            -- Module frame
            local module = Instance.new("Frame", parentFrame)
            module.Name = "Module"
            module.BackgroundColor3 = Color3.fromRGB(22,28,38)
            module.BackgroundTransparency = 0
            module.Size = UDim2.new(0,241,0,93)
            module.BorderSizePixel = 0
            CreateRounded(module, 5)
            local strokeM = Instance.new("UIStroke", module)
            strokeM.Color = Color3.fromRGB(52,66,89)
            strokeM.Transparency = 0.5

            local headerBtn = Instance.new("TextButton", module)
            headerBtn.Name = "Header"
            headerBtn.Size = UDim2.new(1,0,0,93)
            headerBtn.BackgroundTransparency = 1
            headerBtn.Text = ""
            headerBtn.AutoButtonColor = false

            local iconImg = Instance.new("ImageLabel", headerBtn)
            iconImg.Name = "Icon"
            iconImg.Size = UDim2.new(0,15,0,15)
            iconImg.Position = UDim2.new(0.072,0,0.82,0)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = settings.icon or ""

            local moduleName = Instance.new("TextLabel", headerBtn)
            moduleName.Name = "ModuleName"
            moduleName.Font = Enum.Font.Gotham
            moduleName.Text = settings.title or "Module"
            moduleName.TextColor3 = _G.Primary
            moduleName.TextTransparency = 0.2
            moduleName.TextSize = 13
            moduleName.BackgroundTransparency = 1
            moduleName.Position = UDim2.new(0.073,0,0.24,0)
            moduleName.Size = UDim2.new(0,205,0,13)
            moduleName.TextXAlignment = Enum.TextXAlignment.Left

            local descLbl = Instance.new("TextLabel", headerBtn)
            descLbl.Name = "Description"
            descLbl.Font = Enum.Font.Gotham
            descLbl.Text = settings.description or ""
            descLbl.TextColor3 = _G.Primary
            descLbl.TextTransparency = 0.7
            descLbl.TextSize = 10
            descLbl.BackgroundTransparency = 1
            descLbl.Position = UDim2.new(0.073,0,0.42,0)
            descLbl.Size = UDim2.new(0,205,0,13)
            descLbl.TextXAlignment = Enum.TextXAlignment.Left

            -- toggle area on module header
            local toggleFrame = Instance.new("Frame", headerBtn)
            toggleFrame.Size = UDim2.new(0,25,0,12)
            toggleFrame.Position = UDim2.new(0.82,0,0.757,0)
            toggleFrame.BackgroundTransparency = 0.7
            toggleFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
            CreateRounded(toggleFrame, 99)

            local circle = Instance.new("Frame", toggleFrame)
            circle.Size = UDim2.new(0,12,0,12)
            circle.Position = UDim2.new(0,0.5,0,0)
            circle.AnchorPoint = Vector2.new(0,0.5)
            circle.BackgroundColor3 = Color3.fromRGB(66,80,115)
            CreateRounded(circle, 99)

            -- keybind display
            local keyFrame = Instance.new("Frame", headerBtn)
            keyFrame.Size = UDim2.new(0,33,0,15)
            keyFrame.Position = UDim2.new(0.15,0,0.735,0)
            keyFrame.BackgroundColor3 = Color3.fromRGB(0,162,255)
            CreateRounded(keyFrame, 3)
            local keyText = Instance.new("TextLabel", keyFrame)
            keyText.Size = UDim2.new(1,0,1,0)
            keyText.BackgroundTransparency = 1
            keyText.Text = "None"
            keyText.Font = Enum.Font.Gotham
            keyText.TextSize = 10
            keyText.TextColor3 = Color3.fromRGB(209,222,255)

            -- divider
            local div = Instance.new("Frame", headerBtn)
            div.Size = UDim2.new(1,0,0,1)
            div.Position = UDim2.new(0,0,0.62,0)
            div.BackgroundColor3 = Color3.fromRGB(52,66,89)
            div.BackgroundTransparency = 0.5
            div.BorderSizePixel = 0

            -- options area (holds widget items)
            local options = Instance.new("Frame", module)
            options.Name = "Options"
            options.Size = UDim2.new(0,241,0,8)
            options.Position = UDim2.new(0,0,1,0)
            options.BackgroundTransparency = 1
            local optionsPadding = Instance.new("UIPadding", options)
            optionsPadding.PaddingTop = UDim.new(0,8)
            local optionsLayout = Instance.new("UIListLayout", options)
            optionsLayout.Padding = UDim.new(0,5)
            optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- module manager api
            local moduleAPI = {}
            moduleAPI._state = false
            moduleAPI._size = 0 -- total items height
            moduleAPI._flag = settings.flag or ("module_" .. tostring(math.random(1,99999)))
            moduleAPI._callback = settings.callback or function() end

            -- functions to change module size and toggle expand/collapse
            function moduleAPI:recalcSize(add)
                add = add or 0
                self._size = self._size + add
                if self._state then
                    module.Size = UDim2.fromOffset(241, 93 + self._size)
                    options.Size = UDim2.fromOffset(241, self._size)
                else
                    options.Size = UDim2.fromOffset(241, self._size)
                end
            end

            function moduleAPI:change_state(state)
                self._state = state
                if state then
                    TweenService:Create(module, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(241, 93 + self._size)}):Play()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.35), {BackgroundColor3 = _G.Primary}):Play()
                    TweenService:Create(circle, TweenInfo.new(0.35), {BackgroundColor3 = _G.Primary, Position = UDim2.fromScale(0.53, 0.5)}):Play()
                else
                    TweenService:Create(module, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(241, 93)}):Play()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
                    TweenService:Create(circle, TweenInfo.new(0.35), {BackgroundColor3 = Color3.fromRGB(66,80,115), Position = UDim2.fromScale(0,0.5)}):Play()
                end
                lib._config._flags[self._flag] = self._state
                lib:SaveConfig()
                pcall(self._callback, self._state)
            end

            headerBtn.MouseButton1Click:Connect(function()
                moduleAPI:change_state(not moduleAPI._state)
            end)

            -- keybind choosing on right click (RMB)
            local choosing = false
            headerBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 and not choosing then
                    choosing = true
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(inp, g)
                        if g then return end
                        if inp.KeyCode == Enum.KeyCode.Unknown then return end
                        if inp.KeyCode == Enum.KeyCode.Backspace then
                            lib._config._keybinds[moduleAPI._flag] = nil
                            keyText.Text = "None"
                            if conn then conn:Disconnect(); choosing = false end
                            lib:SaveConfig()
                            return
                        end
                        lib._config._keybinds[moduleAPI._flag] = tostring(inp.KeyCode)
                        keyText.Text = string.gsub(tostring(inp.KeyCode), "Enum.KeyCode.", "")
                        if conn then conn:Disconnect(); choosing = false end
                        moduleAPI:connect_keybind()
                        lib:SaveConfig()
                    end)
                end
            end)

            function moduleAPI:connect_keybind()
                if not lib._config._keybinds[self._flag] then return end
                if self._keyconn then self._keyconn:Disconnect(); self._keyconn = nil end
                self._keyconn = UserInputService.InputBegan:Connect(function(inp, g)
                    if g then return end
                    if tostring(inp.KeyCode) == lib._config._keybinds[self._flag] then
                        moduleAPI:change_state(not moduleAPI._state)
                    end
                end)
                local kstr = string.gsub(tostring(lib._config._keybinds[self._flag]), "Enum.KeyCode.", "")
                keyText.Text = kstr
            end

            if lib._config._keybinds[moduleAPI._flag] then
                moduleAPI:connect_keybind()
            end

            -- helper to add widget frames to options
            local function createWidgetBase(h)
                local frame = Instance.new("Frame", options)
                frame.Size = UDim2.new(0,207,0,h)
                frame.BackgroundColor3 = Color3.fromRGB(32,38,51)
                frame.BackgroundTransparency = 0.1
                frame.BorderSizePixel = 0
                CreateRounded(frame, 4)
                return frame
            end

            -- WIDGETS:

            -- Button
            function moduleAPI:AddButton(text, callback)
                local h = 36
                moduleAPI:recalcSize(h + 4)
                local btn = createWidgetBase(h)
                local t = Instance.new("TextButton", btn)
                t.Text = text or "Button"
                t.Font = Enum.Font.Gotham
                t.TextSize = 14
                t.TextColor3 = Color3.fromRGB(255,255,255)
                t.Size = UDim2.new(1, -10, 0, 30)
                t.Position = UDim2.new(0,5,0,3)
                t.BackgroundColor3 = _G.Primary
                CreateRounded(t, 6)
                t.AutoButtonColor = false
                t.MouseButton1Click:Connect(function() pcall(callback) end)
                return {
                    SetText = function(new) t.Text = new end,
                    Instance = t
                }
            end

            -- Toggle
            function moduleAPI:AddToggle(text, default, callback)
                default = default or false
                local h = 46
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local title = Instance.new("TextLabel", frame)
                title.Text = text or "Toggle"
                title.Font = Enum.Font.Gotham
                title.TextSize = 14
                title.TextColor3 = Color3.fromRGB(255,255,255)
                title.BackgroundTransparency = 1
                title.Position = UDim2.new(0,10,0,0)
                title.Size = UDim2.new(0,140,0,20)
                local toggleHolder = Instance.new("Frame", frame)
                toggleHolder.Size = UDim2.new(0,35,0,20)
                toggleHolder.Position = UDim2.new(1,-45,0.5,0)
                toggleHolder.AnchorPoint = Vector2.new(1,0.5)
                toggleHolder.BackgroundColor3 = Color3.fromRGB(200,200,200)
                toggleHolder.BackgroundTransparency = 0.8
                toggleHolder.AutoLocal = false
                CreateRounded(toggleHolder, 10)
                local circ = Instance.new("Frame", toggleHolder)
                circ.Size = UDim2.new(0,14,0,14)
                circ.Position = UDim2.new(0,3,0.5,0)
                circ.AnchorPoint = Vector2.new(0,0.5)
                circ.BackgroundColor3 = Color3.fromRGB(255,255,255)
                CreateRounded(circ, 8)
                local toggled = default
                local function applyState()
                    if toggled then
                        circ:TweenPosition(UDim2.new(0, (toggleHolder.AbsoluteSize.X - circ.AbsoluteSize.X - 4), 0.5,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                        toggleHolder.BackgroundColor3 = _G.Third
                    else
                        circ:TweenPosition(UDim2.new(0,3,0.5,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                        toggleHolder.BackgroundColor3 = Color3.fromRGB(200,200,200)
                    end
                end
                applyState()
                toggleHolder.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggled = not toggled
                        pcall(callback, toggled)
                        applyState()
                    end
                end)
                return {
                    Set = function(v) toggled = v; applyState(); pcall(callback, v) end,
                    State = function() return toggled end
                }
            end

            -- Slider
            function moduleAPI:AddSlider(text, min, max, default, callback)
                min = min or 0
                max = max or 100
                default = default or min
                local h = 50
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local title = Instance.new("TextLabel", frame)
                title.Text = (text or "Slider") .. " : " .. tostring(default)
                title.Font = Enum.Font.Gotham
                title.TextSize = 12
                title.TextColor3 = Color3.fromRGB(255,255,255)
                title.BackgroundTransparency = 1
                title.Position = UDim2.new(0,6,0,4)
                title.Size = UDim2.new(1,-12,0,14)

                local barBg = Instance.new("Frame", frame)
                barBg.Size = UDim2.new(1,-20,0,10)
                barBg.Position = UDim2.new(0,10,0,28)
                barBg.BackgroundColor3 = Color3.fromRGB(200,200,200)
                barBg.BackgroundTransparency = 0.8
                CreateRounded(barBg, 6)

                local fill = Instance.new("Frame", barBg)
                fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
                fill.BackgroundColor3 = _G.Primary
                CreateRounded(fill, 6)

                local dragging = false
                local function updateFromInput(x)
                    local abs = barBg.AbsolutePosition.X
                    local wid = barBg.AbsoluteSize.X
                    local rel = math.clamp((x - abs) / wid, 0, 1)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    local val = math.floor(min + (max - min) * rel)
                    title.Text = (text or "Slider") .. " : " .. tostring(val)
                    pcall(callback, val)
                end

                barBg.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateFromInput(i.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromInput(i.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)

                return {
                    Set = function(v) local rel = (v - min) / (max - min); fill.Size = UDim2.new(math.clamp(rel,0,1),0,1,0); title.Text = (text or "Slider").." : "..tostring(v); pcall(callback,v) end
                }
            end

            -- Dropdown
            function moduleAPI:AddDropdown(text, options, default, callback)
                options = options or {}
                default = default or options[1]
                local h = 40
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local label = Instance.new("TextLabel", frame)
                label.Text = text or "Dropdown"
                label.Font = Enum.Font.Gotham
                label.TextSize = 12
                label.TextColor3 = Color3.fromRGB(255,255,255)
                label.BackgroundTransparency = 1
                label.Position = UDim2.new(0,6,0,4)
                label.Size = UDim2.new(1,-12,0,14)

                local select = Instance.new("TextButton", frame)
                select.Size = UDim2.new(1,-10,0,26)
                select.Position = UDim2.new(0,6,0,14)
                select.Text = tostring(default)
                select.Font = Enum.Font.Gotham
                select.TextSize = 12
                select.BackgroundColor3 = Color3.fromRGB(24,24,26)
                CreateRounded(select, 6)
                select.AutoButtonColor = false

                local open = false
                local panel = Instance.new("Frame", frame)
                panel.Size = UDim2.new(1,-10,0,0)
                panel.Position = UDim2.new(0,6,0,40)
                panel.ClipsDescendants = true
                panel.BackgroundTransparency = 1

                local list = Instance.new("ScrollingFrame", panel)
                list.Size = UDim2.new(1,0,0,0)
                list.BackgroundTransparency = 1
                list.ScrollBarThickness = 0
                list.AutomaticCanvasSize = Enum.AutomaticSize.Y
                local listLayout = Instance.new("UIListLayout", list)
                listLayout.Padding = UDim.new(0,4)

                for _, opt in ipairs(options) do
                    local b = Instance.new("TextButton", list)
                    b.Size = UDim2.new(1,0,0,26)
                    b.Text = tostring(opt)
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 12
                    b.BackgroundColor3 = Color3.fromRGB(24,24,26)
                    CreateRounded(b, 6)
                    b.AutoButtonColor = false
                    b.MouseButton1Click:Connect(function()
                        select.Text = tostring(opt)
                        pcall(callback, opt)
                        -- close
                        open = false
                        list:TweenSize(UDim2.new(1,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
                    end)
                end

                select.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        local totalH = (listLayout.AbsoluteContentSize.Y)
                        list:TweenSize(UDim2.new(1,0,0,totalH), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
                    else
                        list:TweenSize(UDim2.new(1,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
                    end
                end)

                return {
                    Set = function(val) select.Text = tostring(val); pcall(callback, val) end,
                    Current = function() return select.Text end
                }
            end

            -- Textbox
            function moduleAPI:AddTextbox(title, placeholder, flag, callback)
                placeholder = placeholder or ""
                local h = 36
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local label = Instance.new("TextLabel", frame)
                label.Text = title or "Input"
                label.Font = Enum.Font.Gotham
                label.TextSize = 12
                label.TextColor3 = Color3.fromRGB(255,255,255)
                label.BackgroundTransparency = 1
                label.Position = UDim2.new(0,6,0,0)
                label.Size = UDim2.new(1,-12,0,14)

                local tb = Instance.new("TextBox", frame)
                tb.Size = UDim2.new(1,-12,0,18)
                tb.Position = UDim2.new(0,6,0,16)
                tb.PlaceholderText = placeholder
                tb.Text = (flag and lib._config._flags[flag]) or ""
                tb.Font = Enum.Font.Gotham
                tb.TextSize = 12
                tb.BackgroundColor3 = Color3.fromRGB(24,24,26)
                CreateRounded(tb, 4)
                tb.ClearTextOnFocus = false
                tb.FocusLost:Connect(function(enter)
                    local val = tb.Text
                    if flag then
                        lib._config._flags[flag] = val
                        lib:SaveConfig()
                    end
                    pcall(callback, val)
                end)
                return {
                    Set = function(v) tb.Text = v end,
                    Get = function() return tb.Text end
                }
            end

            -- Paragraph (title + body)
            function moduleAPI:AddParagraph(settings)
                settings = settings or {}
                local h = 50
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local title = Instance.new("TextLabel", frame)
                title.Text = settings.title or "Title"
                title.Font = Enum.Font.Gotham
                title.TextSize = 12
                title.TextColor3 = Color3.fromRGB(210,210,210)
                title.BackgroundTransparency = 1
                title.Position = UDim2.new(0,6,0,4)
                title.Size = UDim2.new(1,-12,0,16)

                local body = Instance.new("TextLabel", frame)
                body.Text = settings.text or ""
                body.Font = Enum.Font.Gotham
                body.TextSize = 11
                body.TextColor3 = Color3.fromRGB(180,180,180)
                body.BackgroundTransparency = 1
                body.Position = UDim2.new(0,6,0,22)
                body.Size = UDim2.new(1,-12,0,24)
                body.TextWrapped = true
                return {
                    Set = function(s) body.Text = s end
                }
            end

            -- Checkbox (like toggle but with box)
            function moduleAPI:AddCheckbox(title, default, flag, callback)
                default = default or false
                local h = 22
                moduleAPI:recalcSize(h + 4)
                local frame = createWidgetBase(h)
                local label = Instance.new("TextLabel", frame)
                label.Text = title or "Checkbox"
                label.Font = Enum.Font.Gotham
                label.TextSize = 12
                label.TextColor3 = Color3.fromRGB(255,255,255)
                label.BackgroundTransparency = 1
                label.Position = UDim2.new(0,6,0,0)
                label.Size = UDim2.new(1,-60,1,0)
                local box = Instance.new("Frame", frame)
                box.Size = UDim2.new(0,14,0,14)
                box.Position = UDim2.new(1,-20,0.5,0)
                box.AnchorPoint = Vector2.new(1,0.5)
                box.BackgroundColor3 = Color3.fromRGB(100,100,100)
                CreateRounded(box, 3)
                local fill = Instance.new("Frame", box)
                fill.Size = UDim2.new(0.7,0,0.7,0)
                fill.Position = UDim2.new(0.5,0,0.5,0)
                fill.AnchorPoint = Vector2.new(0.5,0.5)
                fill.BackgroundColor3 = Color3.fromRGB(255,0,0)
                CreateRounded(fill, 3)
                fill.Visible = default
                local state = default
                box.MouseButton1Click = nil
                box.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        state = not state
                        fill.Visible = state
                        if flag then lib._config._flags[flag] = state; lib:SaveConfig() end
                        pcall(callback, state)
                    end
                end)
                return {
                    State = function() return state end,
                    Set = function(v) state = v; fill.Visible = v; if flag then lib._config._flags[flag]=v; lib:SaveConfig(); end; pcall(callback, v) end
                }
            end

            -- expose module object
            moduleAPI.Instance = module
            table.insert(tabAPI._modules, moduleAPI)
            return moduleAPI
        end

        -- return tab API
        table.insert(lib._tabs, tabAPI)
        return tabAPI
    end

    -- done building - return lib
    return lib
end

-- Return module table (callable)
return setmetatable({}, { __call = function(_, ...) 
    return Nexus
end })
