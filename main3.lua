local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Insane custom physical property values:
local insaneDensity = 10000        -- Much higher than the default (~1)
local defaultFriction = 0.3
local defaultElasticity = 0.5
local defaultFrictionWeight = 1
local defaultElasticityWeight = 1

---------------------------------------------------------
-- Create the Tool with Insane Density Properties:
---------------------------------------------------------
local tool = Instance.new("Tool")
tool.Name = "Mass: 0.00 | Density: " .. tostring(insaneDensity)
tool.Parent = player:WaitForChild("Backpack")
tool.RequiresHandle = true

-- Create the Handle for the Tool (size 50,1,50)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(50, 1, 50)
handle.Transparency = 0.5
handle.CanCollide = false   -- So it won't physically interfere with the player
handle.Parent = tool

-- Apply insane custom physical properties to the handle (giving it mass)
local toolProps = PhysicalProperties.new(
	insaneDensity,
	defaultFriction,
	defaultElasticity,
	defaultFrictionWeight,
	defaultElasticityWeight
)
handle.CustomPhysicalProperties = toolProps

---------------------------------------------------------
-- Functions for Insane Density on the Character:
---------------------------------------------------------
local function setInsaneProperties(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local newProps = PhysicalProperties.new(
				insaneDensity,
				defaultFriction,
				defaultElasticity,
				defaultFrictionWeight,
				defaultElasticityWeight
			)
			part.CustomPhysicalProperties = newProps
		end
	end
end

local function calculateTotalMass(character)
	local totalMass = 0
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			totalMass = totalMass + part:GetMass()
		end
	end
	return totalMass
end

local massUpdateConn
local function startMassUpdate(character)
	if massUpdateConn then
		massUpdateConn:Disconnect()
	end
	massUpdateConn = RunService.Heartbeat:Connect(function()
		if character and character.Parent then
			local totalMass = calculateTotalMass(character)
			tool.Name = string.format("Mass: %.2f | Density: %.2f", totalMass, insaneDensity)
		end
	end)
end

local function onCharacterAdded(character)
	setInsaneProperties(character)
	startMassUpdate(character)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

---------------------------------------------------------
-- Teleport Features:
---------------------------------------------------------
-- 1. Constant Teleport while Equipped:  
--    Constantly run the line that teleports the entire character 500 studs upward relative to its current HumanoidRootPart.
local constantTeleportConn

tool.Equipped:Connect(function()
	local character = player.Character
	if character then
		local hrp = character:WaitForChild("HumanoidRootPart")
		-- Ensure the character's PrimaryPart is set (using the HumanoidRootPart)
		if not character.PrimaryPart then
			character.PrimaryPart = hrp
		end
		-- Start a loop that constantly updates the character's position.
		constantTeleportConn = RunService.Heartbeat:Connect(function()
			-- Always teleport the "real" character to 500 studs above its current HRP position.
			local newCFrame = hrp.CFrame + Vector3.new(0, 500, 0)
			character:SetPrimaryPartCFrame(newCFrame)
		end)
	end
end)

tool.Unequipped:Connect(function()
	if constantTeleportConn then
		constantTeleportConn:Disconnect()
		constantTeleportConn = nil
	end
end)

-- 2. Teleport-to-Nearest-Spawn on "E" Key Press:
local function teleportToNearestSpawn()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	-- Ensure the PrimaryPart is set.
	if not character.PrimaryPart then
		character.PrimaryPart = hrp
	end

	local nearestSpawn = nil
	local nearestDistance = math.huge

	-- Loop through all SpawnLocations in the workspace.
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("SpawnLocation") then
			local distance = (hrp.Position - obj.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestSpawn = obj
			end
		end
	end

	if nearestSpawn then
		local targetCFrame = CFrame.new(nearestSpawn.Position + Vector3.new(0, 5, 0))
		character:SetPrimaryPartCFrame(targetCFrame)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		teleportToNearestSpawn()
	end
end)
