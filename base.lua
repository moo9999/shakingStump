-- BSS Teleport Chain, Hotbar Emulation, & Anti-Lag Optimizer (Zero-Delay Mode)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ==================== CONFIGURATION ====================
local MIDPOINT_CHECKPOINT = Vector3.new(280, 150, -200)
local STAGE_ONE_COORDS = Vector3.new(535.572998046875, 183.99293518066406, -350.5929260253906)
local TELEPORT_TWO_ENABLED = true
local STAGE_TWO_COORDS = Vector3.new(-444.8290100097656, 121.40953063964844, 353.9067077636719) 
local RETURN_FIELD_NAME = "Sunflower Field"

-- HOTBAR SETTING: Keys tied to your target slots
local HOTBAR_KEYS = {Enum.KeyCode.Two, Enum.KeyCode.Three}
-- =======================================================

local remotesFolder = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Remotes")

-- PERFORMANCE OPTIMIZER
local function optimizePerformance()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Material = Enum.Material.SmoothPlastic
            descendant.CastShadow = false
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant:Destroy()
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            descendant.Enabled = false
        end
    end
end

-- NETWORK TRANSPORT
local function invokeNetworkBypass(targetCFrame)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    if remotesFolder then
        local networkBridge = remotesFolder:FindFirstChild("PlayerTeleport") or remotesFolder:FindFirstChild("UsePlatform")
        if networkBridge and networkBridge:IsA("RemoteEvent") then
            networkBridge:FireServer(targetCFrame)
        elseif networkBridge and networkBridge:IsA("RemoteFunction") then
            networkBridge:InvokeServer(targetCFrame)
        end
    end
    task.wait(0.02)
    HumanoidRootPart.CFrame = targetCFrame
end

local function createTemporaryFloor(targetPosition)
    local tempFloor = Instance.new("Part")
    tempFloor.Size = Vector3.new(15, 1, 15)
    tempFloor.Position = targetPosition - Vector3.new(0, 3.5, 0)
    tempFloor.Anchored = true
    tempFloor.Transparency = 1
    tempFloor.Parent = Workspace
    return tempFloor
end

-- HARDWARE INPUT EMULATION
local function fireHotbarSequence()
    for _, keyCode in ipairs(HOTBAR_KEYS) do
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        task.wait(0.1) -- Minimal mechanical safety gap
    end
end

-- FIELD ROUTING & DEPLOYMENT (ZERO DELAY)
local function teleportAndDeploy()
    local flowerZones = Workspace:FindFirstChild("FlowerZones")
    if flowerZones then
        local fieldPart = flowerZones:FindFirstChild(RETURN_FIELD_NAME)
        if fieldPart then
            invokeNetworkBypass(CFrame.new(fieldPart.Position + Vector3.new(0, 3, 0)))
            -- Removed Field_Landing_Delay
            fireHotbarSequence()
        end
    end
end

-- GUI INTERFACE
local function createRetryInterface()
    local targetStorage = game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")
    local oldGui = targetStorage:FindFirstChild("BSS_ItemRetryGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSS_ItemRetryGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999
    screenGui.Parent = targetStorage

    local retryButton = Instance.new("TextButton")
    retryButton.Size = UDim2.new(0, 160, 0, 50)
    retryButton.Position = UDim2.new(0.02, 0, 0.45, 0) 
    retryButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    retryButton.Text = "Teleport & Retry Items"
    retryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    retryButton.Font = Enum.Font.SourceSansBold
    retryButton.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner", retryButton)
    uiCorner.CornerRadius = UDim.new(0, 8)
    retryButton.Active = true
    retryButton.Draggable = true

    retryButton.MouseButton1Click:Connect(function()
        teleportAndDeploy()
    end)
end

-- EXECUTION
local function executeRun()
    optimizePerformance()
    createRetryInterface()
    
    invokeNetworkBypass(CFrame.new(MIDPOINT_CHECKPOINT))
    task.wait(0.3)
    
    local floorOne = createTemporaryFloor(STAGE_ONE_COORDS)
    invokeNetworkBypass(CFrame.new(STAGE_ONE_COORDS))
    task.wait(1.5)
    floorOne:Destroy()
    
    if TELEPORT_TWO_ENABLED then
        local floorTwo = createTemporaryFloor(STAGE_TWO_COORDS)
        invokeNetworkBypass(CFrame.new(STAGE_TWO_COORDS))
        task.wait(1.5)
        floorTwo:Destroy()
    end
    
    teleportAndDeploy()
end

executeRun()