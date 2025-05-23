local global = getgenv()

local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local npcs = Workspace.game_assets.NPCs:GetChildren()
local Players = cloneref(game:GetService("Players"))

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local objectsToShow = {}



local function contructEspObject(data)
    assert(data.part, "no part given lol")
    return {

        part = data.part,
        text = data.text or data.part.Name,
        color = data.color or Color3.fromRGB(255, 255, 255),
        textSize = data.textSize or 20,
        update = data.update or function(self) end

    }
end

local ZombieSearcher = {}
ZombieSearcher.isBlackCardZombie = function(zombieModel)

    if not zombieModel:FindFirstChild("Equipment") then
        return false
    end
    for _, obj in ipairs(zombieModel.Equipment:GetDescendants()) do
        if obj:IsA("BasePart") then
            if string.find(string.lower(obj.Name), "beret") 
            or string.find(string.lower(obj.Name), "insigna") then
                return true
            end
        end
    end
    return false


end
ZombieSearcher.checkIsZombieHaveEquipment = function(zombie)
    if not zombie:FindFirstChild("Equipment") then
        return false
    end

    if #zombie.Equipment:GetChildren() == 2 then
        totalChildren = 0
        for _, model in ipairs(zombie.Equipment:GetChildren()) do
            

            totalChildren += #model:GetChildren()

           

        end
        if totalChildren == 0 then
            return false
        end
    end

    return true

end

ZombieSearcher.isRedCardZombie = function(zombieModel)

    if not zombieModel:FindFirstChild("Equipment") then
        return false
    end
    if zombieModel.Torso.Shirt.ColorMap == "rbxassetid://17661939530" then
        return true
    end
    if #zombieModel:GetDescendants() == 84 then
        return true
    end

    return false

end

ZombieSearcher.search = function()

    if not config.showChineseZombies and not config.showTacticalZombies then
        return
    end

    for index, zombieModel in ipairs(npcs) do
        if zombieModel:IsA("Model") then
            if not objectsToShow[zombieModel] and ZombieSearcher.checkIsZombieHaveEquipment(zombieModel) then
                
                if (zombieModel.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
                    continue
                end
                
                if config.showChineseZombies then
                    if ZombieSearcher.isRedCardZombie(zombieModel) then
                        objectsToShow[zombieModel] = contructEspObject({
                            part = zombieModel.HumanoidRootPart,
                            text = "Chinese Zombie",
                            color = Color3.fromRGB(255, 0, 0),
                        })
                        continue
                    end
                end
                if config.showTacticalZombies then
                    if ZombieSearcher.isBlackCardZombie(zombieModel) then
                        objectsToShow[zombieModel] = contructEspObject({
                            part = zombieModel.HumanoidRootPart,
                            text = "Tactical Zombie",
                            color = Color3.fromRGB(0, 255, 0),
                        })
                        continue
                    end
                end
            end
        end
    end
end


local function findObjectsInWorkspace()

    if not config.showGrenades and not config.showPlayerBags then
        return
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if objectsToShow[child] then
            continue
        end
        if config.showGrenades then
            if child.Name=="Grenade" and child:FindFirstChild("Handle") then
                objectsToShow[child] = contructEspObject({

                    part = child.Handle,
                    text = "Grenade",
                    color = Color3.fromRGB(187, 0, 0),

                })
            end
        end
        if config.showPlayerBags then
            if child.Name == "Default" and child:FindFirstChildWhichIsA("BasePart") then --Meshes/Trash_bag2_Untitled.002
                objectsToShow[child] = contructEspObject({

                    part = child:FindFirstChildWhichIsA("BasePart"),
                    text = "Bag",
                    color = Color3.fromRGB(146, 134, 93),

                })
            end
        end
        if config.showVehicles then
            if child:FindFirstChild("Chassis") then
                objectsToShow[child] = contructEspObject({

                    part = child:FindFirstChildWhichIsA("BasePart"),
                    text = "Vehicle[?/?]",
                    color = Color3.fromRGB(255, 255, 255),
                    textSize = 25,
                    update = function(self)
                        local vehicle = self.part.Parent
                        local states = vehicle.States

                        self.text = `Машонка[{math.floor(states:GetAttribute("Health"))}/{states:GetAttribute("MaxHealth")}]`
                    end

                })
            end
        end
    end
end

local function createText(txt, color, size)
    local text = Drawing.new("Text")
    text.Size = size or 20
    text.Text = txt
    text.Color = color
    text.Center = true
    text.Outline = true
    text.Font = 2

    return text
end

local function search()
    ZombieSearcher.search()
    findObjectsInWorkspace()
end

search()
Workspace.DescendantAdded:Connect(search)

RunService.RenderStepped:Connect(function()

    local toRemove = {}
    for target, object in pairs(objectsToShow) do
        if not object.part:FindFirstAncestorOfClass("Workspace") then
            if object.textUi then
                object.textUi.Visible = false
                object.textUi:Destroy()
            end
            table.insert(toRemove, 1, target)
            continue
        end
        local screenPos, visible = Camera:WorldToViewportPoint(object.part.Position)
        if visible then
            local textUi = object.textUi
            if not textUi then
                textUi = createText(object.text, object.color)
                object.textUi = textUi
            end
            object:update()
            textUi.Text = object.text.."\n["..math.floor((object.part.Position - player.Character.HumanoidRootPart.Position).Magnitude).." studs]"
            textUi.Visible = true
            textUi.Position = screenPos

        elseif object.textUi then
            object.textUi.Visible = false
        end       
    end
    for _, target in ipairs(toRemove) do
        objectsToShow[target] = nil
    end
end)
