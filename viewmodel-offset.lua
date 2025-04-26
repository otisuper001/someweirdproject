getgenv().global = getgenv()

local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera
local RunService = cloneref(game:GetService("RunService"))

RunService.RenderStepped:Connect(function()
    local viewmodelHrp = Camera:FindFirstChild("CurrentWeapon") and Camera.CurrentWeapon:FindFirstChild("HumanoidRootPart")
    if viewmodelHrp and not global.rmbPressed then
        viewmodelHrp.CFrame = viewmodelHrp.CFrame + viewmodelHrp.CFrame:VectorToWorldSpace(
            Vector3.new(config.viewmodelOffsetX,config.viewmodelOffsetY,config.viewmodelOffsetZ)
        )
        
    end
    if config.viewmodelWeaponTexture and viewmodelHrp and Camera.CurrentWeapon:FindFirstChild("Weapon") then
        for _, obj in ipairs(Camera.CurrentWeapon.Weapon:GetDescendants()) do 
            if obj:IsA("SurfaceAppearance") then
                if obj.Name == "_coolSkin" then
                    obj.ColorMap = config.viewmodelWeaponTexture
                    obj.RoughnessMap = config.viewmodelWeaponTexture
                    obj.MetalnessMap = config.viewmodelWeaponTexture
                else
                    local new = Instance.new("SurfaceAppearance", obj.Parent)
                    new.ColorMap = config.viewmodelWeaponTexture
                    new.RoughnessMap = config.viewmodelWeaponTexture
                    new.MetalnessMap = config.viewmodelWeaponTexture
                    new.Name = "_coolSkin"
                    obj:Destroy()
                end
                
            end
        end
    end
end)
