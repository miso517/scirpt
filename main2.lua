local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local flying = false
local flySpeed = 50
local bodyVelocity
local bodyGyro

-- Keybind to toggle flying
local flyKey = Enum.KeyCode.F

-- Ensure the character's PrimaryPart is set
local function getPrimaryPart()
    return character:FindFirstChild("HumanoidRootPart")
end

-- Function to enable flying
local function startFlying()
    local primaryPart = getPrimaryPart()
    if not primaryPart then
        warn("Character's PrimaryPart (HumanoidRootPart) is missing!")
        return
    end

    flying = true
    humanoid.PlatformStand = true -- Prevents walking animations while flying

    -- Create BodyVelocity to control movement
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5) -- High force to counter gravity
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = primaryPart

    -- Create BodyGyro to stabilize orientation
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.CFrame = primaryPart.CFrame
    bodyGyro.Parent = primaryPart
end

-- Function to disable flying
local function stopFlying()
    local primaryPart = getPrimaryPart()
    if not primaryPart then return end

    flying = false
    humanoid.PlatformStand = false -- Re-enable normal movement

    -- Remove BodyVelocity and BodyGyro
    if bodyVelocity then 
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then 
        bodyGyro:Destroy() 
        bodyGyro = nil
    end
end

-- Toggle fly mode on key press
game:GetService("UserInputService").InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == flyKey then
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end
end)

-- Update flying mechanics
game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    if flying and bodyVelocity and bodyGyro then
        local primaryPart = getPrimaryPart()
        if not primaryPart then return end

        -- Handle movement direction based on user input
        local moveDirection = Vector3.new(0, 0, 0)
        local camera = workspace.CurrentCamera
        local inputService = game:GetService("UserInputService")

        if inputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if inputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if inputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if inputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if inputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0) -- Ascend
        end
        if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0) -- Descend
        end

        -- Normalize and apply speed
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * flySpeed
        end

        bodyVelocity.Velocity = moveDirection
        bodyGyro.CFrame = CFrame.new(primaryPart.Position, primaryPart.Position + camera.CFrame.LookVector)
    end
end)
