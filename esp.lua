--Webhook
print("esp started")

local HttpService = game:GetService("HttpService")
local Webhook_URL = "https://discord.com/api/webhooks/1269112290217693327/aHPXP8kPiTWgc0XGX-snimU1NWLrvVg49TdfNg47llxtfdNj9hM1mdwZMXVLIaxvv4bc"

-- ESP
local FillColor = Color3.fromRGB(139,0,0)
local DepthMode = "AlwaysOnTop"
local FillTransparency = 0.5
local OutlineColor = Color3.fromRGB(139, 0,0)
local OutlineTransparency = 0
local CoreGui = cloneref(game:FindService("CoreGui"))
local connections = {}
local characterFolder = workspace:WaitForChild("Characters")

local Storage = Instance.new("Folder")
Storage.Parent = CoreGui
Storage.Name = "Highlight_Storage"

local players = cloneref(game:GetService("Players"))
local client = players.LocalPlayer
local camera = workspace.CurrentCamera
local lighting = cloneref(game:GetService("Lighting"))

getgenv().global = getgenv()

function global.declare(self, index, value, check)
    if self[index] == nil then
        self[index] = value
    elseif check then
        local methods = { "remove", "Disconnect" }

        for _, method in methods do
            pcall(function()
                value[method](value)
            end)
        end
    end

    return self[index]
end

declare(global, "services", {})

function global.get(service)
    return services[service]
end

declare(declare(services, "loop", {}), "cache", {})

get("loop").new = function(self, index, func, disabled)
    if disabled == nil and (func == nil or typeof(func) == "boolean") then
        disabled = func func = index
    end

    self.cache[index] = {
        ["enabled"] = (not disabled),
        ["func"] = func,
        ["toggle"] = function(self, boolean)
            if boolean == nil then
                self.enabled = not self.enabled
            else
                self.enabled = boolean
            end
        end,
        ["remove"] = function()
            self.cache[index] = nil
        end
    }

    return self.cache[index]
end

declare(get("loop"), "connection", cloneref(game:GetService("RunService")).RenderStepped:Connect(function(delta)
    for _, loop in get("loop").cache do
        if loop.enabled then
            local success, result = pcall(function()
                loop.func(delta)
            end)

            if not success then
                warn(result)
            end
        end
    end
end), true)

declare(services, "new", {})

get("new").drawing = function(class, properties)
    local drawing = Drawing.new(class)
    for property, value in properties do
        pcall(function()
            drawing[property] = value
        end)
    end
    return drawing
end

declare(declare(services, "player", {}), "cache", {})

get("player").find = function(self, player)
    for character, data in self.cache do
        if data.player == player then
            return character
        end
    end
end

get("player").check = function(self, player)
    local success, check = pcall(function()
        local character = getFullCharacterModel(player)
        if not character or not character:IsDescendantOf(characterFolder) then
            return false
        end
        return character:FindFirstChild('UpperTorso') ~= nil
    end)

    return success and check
end

get("player").new = function(self, player)
    if player == game.Players.LocalPlayer then
        return
    end
    
    local function monitorCharacter()
        local character = getFullCharacterModel(player)
        if character and character:IsDescendantOf(characterFolder) then
            self:setupESP(player, character)
        end
        
        local connection
        connection = characterFolder.ChildAdded:Connect(function(child)
            if child.Name == player.Name and child:IsA("Model") then
                self:setupESP(player, child)
                connection:Disconnect()
            end
        end)
    end

    if player.Character then monitorCharacter() end
    player.CharacterAdded:Connect(monitorCharacter)
end

get("player").setupESP = function(self, player, character)
    if self.cache[character] then return end
    
    self.cache[character] = {
        ["player"] = player,
        ["drawings"] = {
            ["box"] = get("new").drawing("Square", { Visible = false }),
            ["boxFilled"] = get("new").drawing("Square", { Visible = false, Filled = true }),
            ["boxOutline"] = get("new").drawing("Square", { Visible = false }),
            ["name"] = get("new").drawing("Text", { Visible = false, Center = true}),
            ["distance"] = get("new").drawing("Text", { Visible = false, Center = true}),
        },
        ["highlight"] = nil
    }

    local Highlight = Instance.new("Highlight")
    Highlight.Name = player.Name
    Highlight.FillColor = FillColor
    Highlight.DepthMode = DepthMode
    Highlight.FillTransparency = FillTransparency
    Highlight.OutlineColor = OutlineColor
    Highlight.OutlineTransparency = OutlineTransparency
    Highlight.Parent = Storage
    Highlight.Adornee = character

    self.cache[character].highlight = Highlight
    
    local function onCharacterChanged()
        local newChar = getFullCharacterModel(player)
        if newChar and newChar:IsDescendantOf(characterFolder) then
            Highlight.Adornee = newChar
        else
            Highlight.Adornee = nil
        end
    end

    connections[player] = {
        added = player.CharacterAdded:Connect(onCharacterChanged),
        removed = character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self:remove(character)
            end
        end)
    }
end

get("player").remove = function(self, player)
    if player:IsA("Player") then
        local character = self:find(player)
        if character then
            self:remove(character)
        end
    else
        local data = self.cache[player]
        if not data then return end

        local drawings = data.drawings
        local highlight = data.highlight

        self.cache[player] = nil

        for _, drawing in drawings do
            drawing:Remove()
        end

        if highlight then
            highlight:Destroy()
        end

        if connections[player] then
            connections[player].added:Disconnect()
            connections[player].removed:Disconnect()
        end
    end
end

get("player").update = function(self, character, data)
    character = getFullCharacterModel(data.player)
    if not character or not character:IsDescendantOf(characterFolder) or not character:FindFirstChild('UpperTorso') then
        self:remove(character)
        return
    end

    local player = data.player
    local root = character:FindFirstChild('UpperTorso')
    local drawings = data.drawings

    if not root then 
        if data.highlight then
            data.highlight.Adornee = nil
        end
        for _, drawing in pairs(data.drawings) do
            drawing.Visible = false
        end
        return
    end

    local clientChar = getFullCharacterModel(client)
    if clientChar and clientChar:FindFirstChild('UpperTorso') then
        data.distance = (clientChar.UpperTorso.CFrame.Position - root.CFrame.Position).Magnitude
    end

    task.spawn(function()
        local position, visible = camera:WorldToViewportPoint(root.CFrame.Position)

        local visuals = features.visuals

        local function check()
            local team
            if visuals.teamCheck then team = player.Team ~= client.Team else team = true end
            return visuals.enabled and data.distance and data.distance <= visuals.renderDistance and team
        end

        local function color(color)
            if visuals.teamColor then
                color = player.TeamColor.Color
            end
            return color
        end

        if visible and check() then
            local scale = 1 / (position.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
            local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
            local x, y = math.floor(position.X), math.floor(position.Y)
            local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))

            drawings.box.Size = Vector2.new(width, height)
            drawings.box.Position = Vector2.new(xPosition, yPosition)
            drawings.boxFilled.Size = drawings.box.Size
            drawings.boxFilled.Position = drawings.box.Position
            drawings.boxOutline.Size = drawings.box.Size
            drawings.boxOutline.Position = drawings.box.Position

            drawings.box.Color = color(visuals.boxes.color)
            drawings.box.Thickness = 1
            drawings.boxFilled.Color = color(visuals.boxes.filled.color)
            drawings.boxFilled.Transparency = visuals.boxes.filled.transparency
            drawings.boxOutline.Color = visuals.boxes.outline.color
            drawings.boxOutline.Thickness = 3

            drawings.boxOutline.ZIndex = drawings.box.ZIndex - 1
            drawings.boxFilled.ZIndex = drawings.boxOutline.ZIndex - 1

            drawings.name.Text = `[ {player.Name} ]`
            drawings.name.Size = math.max(math.min(math.abs(12.5 * scale), 12.5), 10)
            drawings.name.Position = Vector2.new(x, (yPosition - drawings.name.TextBounds.Y) - 2)
            drawings.name.Color = color(visuals.names.color)
            drawings.name.Outline = visuals.names.outline.enabled
            drawings.name.OutlineColor = visuals.names.outline.color

            drawings.name.ZIndex = drawings.box.ZIndex + 1

            drawings.distance.Text = `[ {math.floor(data.distance)} ]`
            drawings.distance.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
            drawings.distance.Position = Vector2.new(x, (yPosition + height) + (drawings.distance.TextBounds.Y * 0.25))
            drawings.distance.Color = color(visuals.distance.color)
            drawings.distance.Outline = visuals.distance.outline.enabled
            drawings.distance.OutlineColor = visuals.distance.outline.color
        end

        drawings.box.Visible = (check() and visible and visuals.boxes.enabled)
        drawings.boxFilled.Visible = (check() and drawings.box.Visible and visuals.boxes.filled.enabled)
        drawings.boxOutline.Visible = (check() and drawings.box.Visible and visuals.boxes.outline.enabled)
        drawings.name.Visible = (check() and visible and visuals.names.enabled)
        drawings.distance.Visible = (check() and visible and visuals.distance.enabled)
    end)
end

declare(get("player"), "loop", get("loop"):new(function ()
    for character, data in get("player").cache do
        get("player"):update(character, data)
    end
end), true)

declare(global, "features", {})

features.toggle = function(self, feature, boolean)
    if self[feature] then
        if boolean == nil then
            self[feature].enabled = not self[feature].enabled
        else
            self[feature].enabled = boolean
        end

        if self[feature].toggle then
            task.spawn(function()
                self[feature]:toggle()
            end)
        end
    end
end

declare(features, "visuals", {
    ["enabled"] = true,
    ["teamCheck"] = false,
    ["teamColor"] = true,
    ["renderDistance"] = 4000,

    ["boxes"] = {
        ["enabled"] = true,
        ["color"] = Color3.fromRGB(139, 0, 0),
        ["outline"] = {
            ["enabled"] = true,
            ["color"] = Color3.fromRGB(0, 0, 0),
        },
        ["filled"] = {
            ["enabled"] = false,
            ["color"] = Color3.fromRGB(139, 0, 0),
            ["transparency"] = 0.25
        },
    },
    ["names"] = {
        ["enabled"] = true,
        ["color"] = Color3.fromRGB(139, 0, 0),
        ["outline"] = {
            ["enabled"] = true,
            ["color"] = Color3.fromRGB(0, 0, 0),
        },
    },
    ["distance"] = {
        ["enabled"] = true,
        ["color"] = Color3.fromRGB(139, 0, 0),
        ["outline"] = {
            ["enabled"] = true,
            ["color"] = Color3.fromRGB(0, 0, 0),
        },
    },
})

-- Инициализация существующих игроков
for _, player in players:GetPlayers() do
    if player ~= client then
        get("player"):new(player)
    end
end

-- Обработка новых игроков
players.PlayerAdded:Connect(function(player)
    get("player"):new(player)
end)

-- Обработка выхода игроков
players.PlayerRemoving:Connect(function(player)
    get("player"):remove(player)
end)

-- Мониторинг изменений в папке Characters
characterFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        local player = players:FindFirstChild(child.Name)
        if player and player ~= client then
            get("player"):setupESP(player, child)
        end
    end
end)

characterFolder.ChildRemoved:Connect(function(child)
    if child:IsA("Model") then
        get("player"):remove(child)
    end
end)

-- Key
local isEnabled = true

local function toggleFeature()
    isEnabled = not isEnabled
    features.visuals.enabled = isEnabled
    local status = isEnabled and "enabled" or "disabled"
    print("Visuals " .. status)
end

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F1 then
        toggleFeature()
    end
end)
