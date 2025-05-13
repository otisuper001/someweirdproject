--yea thats Diddys car fly but deobsfuscated and modified

local userInputServiceName = "UserInputService"
local starterGuiName = "StarterGui"
local runServiceName = "RunService"
local playersName = "Players"
local humanoidRootPartName = "HumanoidRootPart"
local sendNotificationTitle = "SendNotification"
local notificationTitleOn = "Flight Enabled"
local notificationTextOn = "LeftControl to boost"
local notificationTitleOff = "Flight Disabled"
local notificationTextOff = "Flight mode has been disabled"

local boostKey = Enum.KeyCode.LeftControl
local boostMultiplier = 3
local flySpeed = 125
local smoothness = 4
local rotationSpeed = 16

local userInputService = cloneref(game:GetService(userInputServiceName))
local starterGui = cloneref(game:GetService(starterGuiName))
local runService = cloneref(game:GetService(runServiceName))
local Workspace = cloneref(game:GetService("Workspace"))
local players = cloneref(game:GetService(playersName))

local player = players.LocalPlayer
local camera = Workspace.CurrentCamera
local flyConnection = nil
local humanoidRootPart = nil
local character = nil

local config = getgenv().config

local function setupCharacter(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild(humanoidRootPartName)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    setupCharacter(player.Character)
end

local velocity = Vector3.new(0, 0, 0)

local function updateFly(deltaTime)
    if not config.carFlyEnabled then return end
    
    local movement = Vector3.new(0, 0, 0)
    
    if not userInputService:GetFocusedTextBox() then
        if userInputService:IsKeyDown(Enum.KeyCode.W) then
            movement = movement + (camera.CFrame.LookVector * flySpeed)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.S) then
            movement = movement - (camera.CFrame.LookVector * flySpeed)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.A) then
            movement = movement - (camera.CFrame.RightVector * flySpeed)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.D) then
            movement = movement + (camera.CFrame.RightVector * flySpeed)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.Space) then
            movement = movement + (camera.CFrame.UpVector * flySpeed)
        end
        if userInputService:IsKeyDown(boostKey) then
            movement = movement * boostMultiplier
        end
    end
    
    if humanoidRootPart then
        local rootPart = humanoidRootPart:GetRootPart()
        if rootPart.Anchored then return end
        if not isnetworkowner(rootPart) then return end
        
        velocity = velocity:Lerp(movement, math.clamp(deltaTime * smoothness, 0, 1))
        rootPart.Velocity = velocity + Vector3.new(0, -2, 0)
        
        if rootPart ~= humanoidRootPart then
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = rootPart.CFrame:Lerp(
                CFrame.lookAt(rootPart.Position, rootPart.Position + velocity + camera.CFrame.LookVector),
                math.clamp(deltaTime * rotationSpeed, 0, 1)
            )
        end
    end
end

local function manageFlight()
    if config.carFlyEnabled then
        if not flyConnection then
            velocity = humanoidRootPart and humanoidRootPart.Velocity or Vector3.new(0, 0, 0)
            flyConnection = runService.Heartbeat:Connect(updateFly)
        end
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
end

runService.Heartbeat:Connect(manageFlight)
