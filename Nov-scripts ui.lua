-- Global color variables
_G.Primary = Color3.fromRGB(32, 38, 51)
_G.Dark = Color3.fromRGB(24, 28, 38)
_G.Third = Color3.fromRGB(0, 162, 255)

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Configuration table for saving/loading
local Config = setmetatable({
    save = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfolder("Nexus") then
                makefolder("Nexus")
            end
            if not isfolder("Nexus/Library") then
                makefolder("Nexus/Library")
            end
            local encoded = HttpService:JSONEncode(config)
            writefile("Nexus/Library/" .. file_name .. ".json", encoded)
        end)
        if not success then
            warn("Failed to save config: " .. tostring(result))
        end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfile("Nexus/Library/" .. file_name .. ".json") then
                self:save(file_name, config)
                return config
            end
            local content = readfile("Nexus/Library/" .. file_name .. ".json")
            return HttpService:JSONDecode(content)
        end)
        if not success then
            warn("Failed to load config: " .. tostring(result))
            return config
        end
        return result
    end
}, {__index = Config})

-- Connection management
local Connections = {}

-- Settings library
local SettingsLib = {
    SaveSettings = true,
    LoadAnimation = true,
    flags = {}
}

-- Clean up existing Nexus instance
local old_Nexus = CoreGui:FindFirstChild("Nexus")
if old_Nexus then
    Debris:AddItem(old_Nexus, 0)
end

-- Utility function to create rounded corners
local function CreateRounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 5)
    corner.Parent = instance
end

-- Utility function to make a frame draggable
local function MakeDraggable(frame, target)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(target, TweenInfo.new(0.2), {Position = newPos}):Play()
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Main library
local Update = {}
Update.__index = Update

function Update:Notify(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 300, 0, 60)
    Notification.BackgroundTransparency = 1
    Notification.Parent = CoreGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", CoreGui)
    Notification.Position = UDim2.new(0.8, 0, 0, 10)
    CreateRounded(Notification, 4)

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)
    InnerFrame.BackgroundColor3 = _G.Primary
    InnerFrame.BackgroundTransparency = 0.1
    InnerFrame.Parent = Notification
    CreateRounded(InnerFrame, 4)

    local Title = Instance.new("TextLabel")
    Title.Text = settings.Title or "Notification"
    Title.TextColor3 = Color3.fromRGB(210, 210, 210)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.Text or "This is a notification."
    Body.TextColor3 = Color3.fromRGB(180, 180, 180)
    Body.Font = Enum.Font.Gotham
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.Parent = InnerFrame

    task.spawn(function()
        wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
        Notification.Size = UDim2.new(0, 300, 0, totalHeight)
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()
        wait(settings.Duration or 5)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(1, 310, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Update:StartLoad()
    local LoadScreen = Instance.new("ScreenGui")
    LoadScreen.Name = "LoadScreen"
    LoadScreen.Parent = CoreGui
    LoadScreen.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = _G.Primary
    Frame.BackgroundTransparency = 0.1
    Frame.Parent = LoadScreen

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 300, 0, 20)
    ProgressBar.Position = UDim2.new(0.5, 0, 0.5, 0)
    ProgressBar.AnchorPoint = Vector2.new(0.5, 0.5)
    ProgressBar.BackgroundColor3 = _G.Dark
    ProgressBar.Parent = Frame
    CreateRounded(ProgressBar, 5)

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(0, 0, 1, 0)
    Bar.BackgroundColor3 = _G.Third
    Bar.Parent = ProgressBar
    CreateRounded(Bar, 5)

    local Text = Instance.new("TextLabel")
    Text.Text = "Please wait..."
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.Font = Enum.Font.Gotham
    Text.TextSize = 14
    Text.Size = UDim2.new(1, 0, 0, 30)
    Text.Position = UDim2.new(0, 0, 0, -40)
    Text.BackgroundTransparency = 1
    Text.TextXAlignment = Enum.TextXAlignment.Center
    Text.Parent = ProgressBar

    task.spawn(function()
        local dots = 0
        while LoadScreen.Parent do
            Text.Text = "Please wait" .. string.rep(".", dots % 4)
            dots = dots + 1
            wait(0.5)
        end
    end)

    local tween = TweenService:Create(Bar, TweenInfo.new(2), {Size = UDim2.new(1, 0, 1, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        LoadScreen:Destroy()
    end)
end

function Update:Window(settings)
    local Window = {}
    Window.__index = Window
    setmetatable(Window, Window)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Nexus"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.Size = settings.Size or UDim2.new(0, 600, 0, 400)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = _G.Primary
    Frame.BackgroundTransparency = 0.05
    Frame.Parent = ScreenGui
    CreateRounded(Frame, 10)
    MakeDraggable(Frame, Frame)

    local Title = Instance.new("TextLabel")
    Title.Text = settings.Title or "Nexus"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Size = UDim2.new(1, -10, 0, 30)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Text = settings.SubTitle or ""
    SubTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 12
    SubTitle.Size = UDim2.new(1, -10, 0, 20)
    SubTitle.Position = UDim2.new(0, 5, 0, 35)
    SubTitle.BackgroundTransparency = 1
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Parent = Frame

    local TabFrame = Instance.new("ScrollingFrame")
    TabFrame.Size = UDim2.new(0, settings.TabWidth or 100, 1, -60)
    TabFrame.Position = UDim2.new(0, 10, 0, 60)
    TabFrame.BackgroundTransparency = 1
    TabFrame.ScrollBarThickness = 0
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabFrame.Parent = Frame

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabFrame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -settings.TabWidth - 20, 1, -60)
    ContentFrame.Position = UDim2.new(0, settings.TabWidth + 15, 0, 60)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = Frame

    local SettingsButton = Instance.new("TextButton")
    SettingsButton.Text = "⚙"
    SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsButton.Font = Enum.Font.Gotham
    SettingsButton.TextSize = 16
    SettingsButton.Size = UDim2.new(0, 30, 0, 30)
    SettingsButton.Position = UDim2.new(1, -35, 0, 5)
    SettingsButton.BackgroundTransparency = 1
    SettingsButton.Parent = Frame

    local SettingsFrame = Instance.new("Frame")
    SettingsFrame.Size = UDim2.new(1, -settings.TabWidth - 20, 1, -60)
    SettingsFrame.Position = UDim2.new(0, settings.TabWidth + 15, 0, 60)
    SettingsFrame.BackgroundTransparency = 1
    SettingsFrame.Visible = false
    SettingsFrame.Parent = Frame

    local SettingsList = Instance.new("UIListLayout")
    SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
    SettingsList.Padding = UDim.new(0, 5)
    SettingsList.Parent = SettingsFrame

    local SaveSettingsToggle = Instance.new("Frame")
    SaveSettingsToggle.Size = UDim2.new(1, 0, 0, 30)
    SaveSettingsToggle.BackgroundTransparency = 1
    SaveSettingsToggle.Parent = SettingsFrame

    local SaveSettingsLabel = Instance.new("TextLabel")
    SaveSettingsLabel.Text = "Save Settings"
    SaveSettingsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveSettingsLabel.Font = Enum.Font.Gotham
    SaveSettingsLabel.TextSize = 14
    SaveSettingsLabel.Size = UDim2.new(1, -50, 1, 0)
    SaveSettingsLabel.BackgroundTransparency = 1
    SaveSettingsLabel.TextXAlignment = Enum.TextXAlignment.Left
    SaveSettingsLabel.Parent = SaveSettingsToggle

    local SaveSettingsCheck = Instance.new("TextButton")
    SaveSettingsCheck.Size = UDim2.new(0, 20, 0, 20)
    SaveSettingsCheck.Position = UDim2.new(1, -25, 0.5, 0)
    SaveSettingsCheck.AnchorPoint = Vector2.new(0, 0.5)
    SaveSettingsCheck.BackgroundColor3 = SettingsLib.SaveSettings and _G.Third or _G.Dark
    SaveSettingsCheck.Text = ""
    SaveSettingsCheck.Parent = SaveSettingsToggle
    CreateRounded(SaveSettingsCheck, 3)

    SaveSettingsCheck.MouseButton1Click:Connect(function()
        SettingsLib.SaveSettings = not SettingsLib.SaveSettings
        SaveSettingsCheck.BackgroundColor3 = SettingsLib.SaveSettings and _G.Third or _G.Dark
        Config:save(Players.LocalPlayer.Name, SettingsLib)
    end)

    local LoadAnimationToggle = Instance.new("Frame")
    LoadAnimationToggle.Size = UDim2.new(1, 0, 0, 30)
    LoadAnimationToggle.BackgroundTransparency = 1
    LoadAnimationToggle.Parent = SettingsFrame

    local LoadAnimationLabel = Instance.new("TextLabel")
    LoadAnimationLabel.Text = "Load Animation"
    LoadAnimationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadAnimationLabel.Font = Enum.Font.Gotham
    LoadAnimationLabel.TextSize = 14
    LoadAnimationLabel.Size = UDim2.new(1, -50, 1, 0)
    LoadAnimationLabel.BackgroundTransparency = 1
    LoadAnimationLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoadAnimationLabel.Parent = LoadAnimationToggle

    local LoadAnimationCheck = Instance.new("TextButton")
    LoadAnimationCheck.Size = UDim2.new(0, 20, 0, 20)
    LoadAnimationCheck.Position = UDim2.new(1, -25, 0.5, 0)
    LoadAnimationCheck.AnchorPoint = Vector2.new(0, 0.5)
    LoadAnimationCheck.BackgroundColor3 = SettingsLib.LoadAnimation and _G.Third or _G.Dark
    LoadAnimationCheck.Text = ""
    LoadAnimationCheck.Parent = LoadAnimationToggle
    CreateRounded(LoadAnimationCheck, 3)

    LoadAnimationCheck.MouseButton1Click:Connect(function()
        SettingsLib.LoadAnimation = not SettingsLib.LoadAnimation
        LoadAnimationCheck.BackgroundColor3 = SettingsLib.LoadAnimation and _G.Third or _G.Dark
        Config:save(Players.LocalPlayer.Name, SettingsLib)
    end)

    local ResetButton = Instance.new("TextButton")
    ResetButton.Text = "Reset Config"
    ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResetButton.Font = Enum.Font.Gotham
    ResetButton.TextSize = 14
    ResetButton.Size = UDim2.new(1, 0, 0, 30)
    ResetButton.BackgroundColor3 = _G.Dark
    ResetButton.Parent = SettingsFrame
    CreateRounded(ResetButton, 5)

    ResetButton.MouseButton1Click:Connect(function()
        if isfolder("Nexus/Library") then
            delfolder("Nexus/Library")
            SettingsLib.flags = {}
            Update:Notify({Title = "Success", Text = "Configuration reset!", Duration = 3})
        end
    end)

    SettingsButton.MouseButton1Click:Connect(function()
        ContentFrame.Visible = not ContentFrame.Visible
        SettingsFrame.Visible = not SettingsFrame.Visible
    end)

    if SettingsLib.LoadAnimation then
        Update:StartLoad()
    end
    SettingsLib = Config:load(Players.LocalPlayer.Name, SettingsLib)

    function Window:Tab(name)
        local uitab = {}
        uitab.__index = uitab

        local TabButton = Instance.new("TextButton")
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 14
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = _G.Dark
        TabButton.BackgroundTransparency = 0.8
        TabButton.Parent = TabFrame
        CreateRounded(TabButton, 5)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 0
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.Parent = ContentFrame
        TabPage.Visible = false

        local MainFramePage = Instance.new("Frame")
        MainFramePage.Size = UDim2.new(1, 0, 0, 0)
        MainFramePage.BackgroundTransparency = 1
        MainFramePage.Parent = TabPage
        MainFramePage.Name = "MainFramePage"

        local PageList = Instance.new("UIListLayout")
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Padding = UDim.new(0, 5)
        PageList.Parent = MainFramePage

        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(ContentFrame:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = false
                end
            end
            TabPage.Visible = true
            for _, button in pairs(TabFrame:GetChildren()) do
                if button:IsA("TextButton") then
                    button.BackgroundTransparency = 0.8
                end
            end
            TabButton.BackgroundTransparency = 0.5
        end)

        if TabFrame:GetChildren()[1] == TabButton then
            TabButton.BackgroundTransparency = 0.5
            TabPage.Visible = true
        end

        TabFrame.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y)

        local main = {}
        main.__index = main
        setmetatable(main, main)

        function main:Button(text, callback)
            local Button = Instance.new("TextButton")
            Button.Text = text
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Font = Enum.Font.Gotham
            Button.TextSize = 14
            Button.Size = UDim2.new(1, 0, 0, 30)
            Button.BackgroundColor3 = _G.Dark
            Button.BackgroundTransparency = 0.8
            Button.Parent = MainFramePage
            CreateRounded(Button, 5)

            Button.MouseButton1Click:Connect(function()
                callback()
            end)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Button
        end

        function main:Toggle(text, flag, value, callback)
            local Toggle = Instance.new("Frame")
            Toggle.Size = UDim2.new(1, 0, 0, 30)
            Toggle.BackgroundTransparency = 1
            Toggle.Parent = MainFramePage

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 14
            ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = Toggle

            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 20, 0, 20)
            ToggleButton.Position = UDim2.new(1, -25, 0.5, 0)
            ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
            ToggleButton.BackgroundColor3 = value and _G.Third or _G.Dark
            ToggleButton.Text = ""
            ToggleButton.Parent = Toggle
            CreateRounded(ToggleButton, 3)

            SettingsLib.flags[flag] = SettingsLib.flags[flag] or value
            ToggleButton.BackgroundColor3 = SettingsLib.flags[flag] and _G.Third or _G.Dark

            ToggleButton.MouseButton1Click:Connect(function()
                SettingsLib.flags[flag] = not SettingsLib.flags[flag]
                ToggleButton.BackgroundColor3 = SettingsLib.flags[flag] and _G.Third or _G.Dark
                if SettingsLib.SaveSettings then
                    Config:save(Players.LocalPlayer.Name, SettingsLib)
                end
                callback(SettingsLib.flags[flag])
            end)

            callback(SettingsLib.flags[flag])
            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Toggle
        end

        function main:Dropdown(text, flag, options, callback)
            local Dropdown = Instance.new("Frame")
            Dropdown.Size = UDim2.new(1, 0, 0, 30)
            Dropdown.BackgroundTransparency = 1
            Dropdown.Parent = MainFramePage

            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Text = text
            DropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextSize = 14
            DropdownLabel.Size = UDim2.new(1, -50, 0, 20)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = Dropdown

            local DropdownBox = Instance.new("Frame")
            DropdownBox.Size = UDim2.new(1, 0, 0, 30)
            DropdownBox.Position = UDim2.new(0, 0, 0, 20)
            DropdownBox.BackgroundColor3 = _G.Dark
            DropdownBox.BackgroundTransparency = 0.8
            DropdownBox.Parent = Dropdown
            CreateRounded(DropdownBox, 5)

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Text = SettingsLib.flags[flag] or options[1] or "Select"
            DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            DropdownButton.Font = Enum.Font.Gotham
            DropdownButton.TextSize = 12
            DropdownButton.Size = UDim2.new(1, -10, 1, 0)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
            DropdownButton.Parent = DropdownBox

            local DropdownList = Instance.new("ScrollingFrame")
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Position = UDim2.new(0, 0, 1, 0)
            DropdownList.BackgroundColor3 = _G.Dark
            DropdownList.BackgroundTransparency = 0.8
            DropdownList.ScrollBarThickness = 0
            DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropdownList.Parent = DropdownBox
            DropdownList.Visible = false
            CreateRounded(DropdownList, 5)

            local DropdownListLayout = Instance.new("UIListLayout")
            DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropdownListLayout.Padding = UDim.new(0, 2)
            DropdownListLayout.Parent = DropdownList

            SettingsLib.flags[flag] = SettingsLib.flags[flag] or options[1]
            DropdownButton.Text = SettingsLib.flags[flag]

            local function updateDropdown()
                DropdownList.CanvasSize = UDim2.new(0, 0, 0, DropdownListLayout.AbsoluteContentSize.Y)
                Dropdown.Size = DropdownList.Visible and UDim2.new(1, 0, 0, 30 + DropdownListLayout.AbsoluteContentSize.Y) or UDim2.new(1, 0, 0, 50)
                TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            end

            for _, option in pairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Text = option
                OptionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.TextSize = 12
                OptionButton.Size = UDim2.new(1, 0, 0, 20)
                OptionButton.BackgroundTransparency = 1
                OptionButton.Parent = DropdownList
                OptionButton.MouseButton1Click:Connect(function()
                    SettingsLib.flags[flag] = option
                    DropdownButton.Text = option
                    DropdownList.Visible = false
                    updateDropdown()
                    if SettingsLib.SaveSettings then
                        Config:save(Players.LocalPlayer.Name, SettingsLib)
                    end
                    callback(option)
                end)
            end

            DropdownButton.MouseButton1Click:Connect(function()
                DropdownList.Visible = not DropdownList.Visible
                updateDropdown()
            end)

            updateDropdown()
            callback(SettingsLib.flags[flag])
            return Dropdown
        end

        function main:Slider(text, flag, min, max, value, callback)
            local Slider = Instance.new("Frame")
            Slider.Size = UDim2.new(1, 0, 0, 50)
            Slider.BackgroundTransparency = 1
            Slider.Parent = MainFramePage

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Text = text
            SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextSize = 14
            SliderLabel.Size = UDim2.new(1, -50, 0, 20)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = Slider

            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, 0, 0, 10)
            SliderBar.Position = UDim2.new(0, 0, 0, 30)
            SliderBar.BackgroundColor3 = _G.Dark
            SliderBar.Parent = Slider
            CreateRounded(SliderBar, 5)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(0, 0, 1, 0)
            Fill.BackgroundColor3 = _G.Third
            Fill.Parent = SliderBar
            CreateRounded(Fill, 5)

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(value)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.TextSize = 12
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -55, 0, 0)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Parent = Slider

            SettingsLib.flags[flag] = value
            local mediator = Instance.new("TextButton")
            mediator.Size = UDim2.new(1, 0, 1, 0)
            mediator.BackgroundTransparency = 1
            mediator.TextTransparency = 1
            mediator.Parent = SliderBar

            local dragging = false
            mediator.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)

            mediator.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mouseX = input.Position.X
                    local barX = SliderBar.AbsolutePosition.X
                    local barWidth = SliderBar.AbsoluteSize.X
                    local t = math.clamp((mouseX - barX) / barWidth, 0, 1)
                    local newValue = min + t * (max - min)
                    newValue = math.floor(newValue + 0.5)
                    SettingsLib.flags[flag] = newValue
                    Fill.Size = UDim2.new(t, 0, 1, 0)
                    ValueLabel.Text = tostring(newValue)
                    if SettingsLib.SaveSettings then
                        Config:save(Players.LocalPlayer.Name, SettingsLib)
                    end
                    callback(newValue)
                end
            end)

            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            callback(value)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Slider
        end

        function main:Textbox(text, flag, callback)
            local Textbox = Instance.new("Frame")
            Textbox.Size = UDim2.new(1, 0, 0, 30)
            Textbox.BackgroundTransparency = 1
            Textbox.Parent = MainFramePage

            local TextboxLabel = Instance.new("TextLabel")
            TextboxLabel.Text = text
            TextboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextboxLabel.Font = Enum.Font.Gotham
            TextboxLabel.TextSize = 14
            TextboxLabel.Size = UDim2.new(1, -100, 1, 0)
            TextboxLabel.BackgroundTransparency = 1
            TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextboxLabel.Parent = Textbox

            local Input = Instance.new("TextBox")
            Input.Size = UDim2.new(0, 90, 0, 20)
            Input.Position = UDim2.new(1, -95, 0.5, 0)
            Input.AnchorPoint = Vector2.new(0, 0.5)
            Input.BackgroundColor3 = _G.Dark
            Input.TextColor3 = Color3.fromRGB(255, 255, 255)
            Input.Font = Enum.Font.Gotham
            Input.TextSize = 12
            Input.Text = SettingsLib.flags[flag] or ""
            Input.Parent = Textbox
            CreateRounded(Input, 5)

            Input.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    SettingsLib.flags[flag] = Input.Text
                    if SettingsLib.SaveSettings then
                        Config:save(Players.LocalPlayer.Name, SettingsLib)
                    end
                    callback(Input.Text)
                end
            end)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Textbox
        end

        function main:Label(text)
            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = MainFramePage

            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Label
        end

        function main:Separator(text)
            local Separator = Instance.new("Frame")
            Separator.Size = UDim2.new(1, 0, 0, 20)
            Separator.BackgroundTransparency = 1
            Separator.Parent = MainFramePage

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 2)
            Line.Position = UDim2.new(0, 0, 0.5, 0)
            Line.BackgroundColor3 = _G.Third
            Line.Parent = Separator
            CreateRounded(Line, 1)

            local SeparatorLabel = Instance.new("TextLabel")
            SeparatorLabel.Text = text
            SeparatorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SeparatorLabel.Font = Enum.Font.Gotham
            SeparatorLabel.TextSize = 12
            SeparatorLabel.Size = UDim2.new(0, 100, 0, 20)
            SeparatorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            SeparatorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            SeparatorLabel.BackgroundColor3 = _G.Primary
            SeparatorLabel.BackgroundTransparency = 0.8
            SeparatorLabel.TextXAlignment = Enum.TextXAlignment.Center
            SeparatorLabel.Parent = Separator
            CreateRounded(SeparatorLabel, 3)

            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)
            return Separator
        end

        function main:Module(text, flag, defaultKey, disableToggle, callback, buttonCallback)
            local Module = Instance.new("Frame")
            local ModuleCorner = Instance.new("UICorner")
            local ModuleButton = Instance.new("TextButton")
            local RightContainer = Instance.new("Frame")
            local RightLayout = Instance.new("UIListLayout")
            local KeybindBox = Instance.new("TextLabel")
            local KeybindButton = Instance.new("TextButton")
            local KeybindCorner = Instance.new("UICorner")
            local KeybindStroke = Instance.new("UIStroke")

            Module.Name = "Module"
            Module.Parent = MainFramePage
            Module.BackgroundColor3 = _G.Primary
            Module.BackgroundTransparency = 1
            Module.Size = UDim2.new(1, 0, 0, 30)

            ModuleCorner.CornerRadius = UDim.new(0, 5)
            ModuleCorner.Name = "ModuleCorner"
            ModuleCorner.Parent = Module

            ModuleButton.Name = "ModuleButton"
            ModuleButton.Parent = Module
            ModuleButton.BackgroundColor3 = _G.Dark
            ModuleButton.BackgroundTransparency = 0.8
            ModuleButton.Size = UDim2.new(1, -50, 0, 30)
            ModuleButton.Position = UDim2.new(0, 0, 0, 0)
            ModuleButton.Font = Enum.Font.Nunito
            ModuleButton.Text = "   " .. text
            ModuleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ModuleButton.TextSize = 15
            ModuleButton.TextXAlignment = Enum.TextXAlignment.Left
            ModuleButton.AutoButtonColor = false
            CreateRounded(ModuleButton, 5)

            RightContainer.Name = "RightContainer"
            RightContainer.Parent = Module
            RightContainer.BackgroundColor3 = _G.Primary
            RightContainer.BackgroundTransparency = 1
            RightContainer.Size = UDim2.new(0, 50, 0, 30)
            RightContainer.Position = UDim2.new(1, -50, 0, 0)

            RightLayout.Name = "RightLayout"
            RightLayout.Parent = RightContainer
            RightLayout.FillDirection = Enum.FillDirection.Horizontal
            RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
            RightLayout.Padding = UDim.new(0, 5)

            KeybindBox.Name = "KeybindBox"
            KeybindBox.Parent = RightContainer
            KeybindBox.BackgroundColor3 = _G.Third
            KeybindBox.BackgroundTransparency = 0.8
            KeybindBox.Size = UDim2.new(0, 20, 0, 20)
            KeybindBox.Position = UDim2.new(0, 0, 0.5, 0)
            KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
            KeybindBox.Font = Enum.Font.Gotham
            KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            KeybindBox.TextSize = 12
            KeybindBox.TextXAlignment = Enum.TextXAlignment.Center
            KeybindBox.LayoutOrder = 2
            CreateRounded(KeybindBox, 3)

            KeybindStroke.Name = "KeybindStroke"
            KeybindStroke.Parent = KeybindBox
            KeybindStroke.Color = _G.Third
            KeybindStroke.Thickness = 1
            KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            KeybindButton.Name = "KeybindButton"
            KeybindButton.Parent = KeybindBox
            KeybindButton.Size = UDim2.new(1, 0, 1, 0)
            KeybindButton.BackgroundTransparency = 1
            KeybindButton.TextTransparency = 1
            KeybindButton.Text = ""

            if not SettingsLib.flags then
                SettingsLib.flags = {}
            end
            if not SettingsLib.flags[flag] then
                SettingsLib.flags[flag] = {
                    checked = false,
                    keybind = defaultKey or "Unknown"
                }
            end

            local checked = SettingsLib.flags[flag].checked
            KeybindBox.Text = SettingsLib.flags[flag].keybind
            if KeybindBox.Text == "Unknown" then
                KeybindBox.Text = "..."
            end

            local toggleFunc = nil

            if not disableToggle then
                local Toggle = Instance.new("TextButton")
                local ToggleCorner = Instance.new("UICorner")
                local ToggleStroke = Instance.new("UIStroke")

                Toggle.Name = "Toggle"
                Toggle.Parent = RightContainer
                Toggle.BackgroundColor3 = checked and _G.Third or _G.Dark
                Toggle.Size = UDim2.new(0, 20, 0, 20)
                Toggle.Position = UDim2.new(0, 0, 0.5, 0)
                Toggle.AnchorPoint = Vector2.new(0, 0.5)
                Toggle.Text = ""
                Toggle.AutoButtonColor = false
                Toggle.LayoutOrder = 1
                CreateRounded(Toggle, 3)

                ToggleStroke.Name = "ToggleStroke"
                ToggleStroke.Parent = Toggle
                ToggleStroke.Color = _G.Third
                ToggleStroke.Thickness = 1
                ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                local function toggleState()
                    checked = not checked
                    Toggle.BackgroundColor3 = checked and _G.Third or _G.Dark
                    SettingsLib.flags[flag].checked = checked
                    if SettingsLib.SaveSettings then
                        Config:save(Players.LocalPlayer.Name, SettingsLib)
                    end
                    if callback then
                        callback(checked)
                    end
                end

                toggleFunc = toggleState
                local toggleConnection = Toggle.MouseButton1Click:Connect(toggleState)
                Connections["module_toggle_" .. flag] = toggleConnection
            else
                toggleFunc = function()
                    if buttonCallback then
                        buttonCallback()
                    end
                end
            end

            local keybindConnection
            KeybindButton.MouseButton1Click:Connect(function()
                KeybindBox.Text = "..."
                local inputConnection
                inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local newKey = input.KeyCode.Name
                        SettingsLib.flags[flag].keybind = newKey
                        if newKey ~= "Unknown" then
                            KeybindBox.Text = newKey
                        end
                        if SettingsLib.SaveSettings then
                            Config:save(Players.LocalPlayer.Name, SettingsLib)
                        end
                        inputConnection:Disconnect()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                        SettingsLib.flags[flag].keybind = "Unknown"
                        KeybindBox.Text = "..."
                        if SettingsLib.SaveSettings then
                            Config:save(Players.LocalPlayer.Name, SettingsLib)
                        end
                        inputConnection:Disconnect()
                    end
                end)
                Connections["module_keybind_input_" .. flag] = inputConnection
            end)

            keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode.Name == SettingsLib.flags[flag].keybind then
                        toggleFunc()
                    end
                end
            end)
            Connections["module_keybind_press_" .. flag] = keybindConnection

            local buttonConnection = ModuleButton.MouseButton1Click:Connect(function()
                if buttonCallback then
                    buttonCallback()
                end
            end)
            Connections["module_button_" .. flag] = buttonConnection

            if not disableToggle then
                callback(checked)
            end

            TabPage.CanvasSize = UDim2.new(0, 0, 0, MainFramePage.AbsoluteContentSize.Y + 10)

            -- Cleanup function
            Module.Destroying:Connect(function()
                for key, connection in pairs(Connections) do
                    if key:match("^module_.*_" .. flag) then
                        connection:Disconnect()
                        Connections[key] = nil
                    end
                end
            end)

            return Module
        end

        return main
    end

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    -- Cleanup connections on GUI destruction
    ScreenGui.Destroying:Connect(function()
        for _, connection in pairs(Connections) do
            connection:Disconnect()
        end
        Connections = {}
    end)

    return Window
end

return Update
