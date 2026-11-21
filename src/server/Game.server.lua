local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

Players.CharacterAutoLoads = true

local MAX_PLAYERS = 12
local ROUND_SECONDS = 180
local INTERMISSION_SECONDS = 15
local MIN_PLAYERS = 2

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes") or Instance.new("Folder")
remotes.Name = "GameRemotes"
remotes.Parent = ReplicatedStorage
local actionRemote = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes

local state = ReplicatedStorage:FindFirstChild("GameState") or Instance.new("Folder")
state.Name = "GameState"
state.Parent = ReplicatedStorage
local status = state:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Value = "Waiting for players"
status.Parent = state
local timeLeft = state:FindFirstChild("TimeLeft") or Instance.new("IntValue")
timeLeft.Name = "TimeLeft"
timeLeft.Value = 0
timeLeft.Parent = state
local monsterUserId = state:FindFirstChild("MonsterUserId") or Instance.new("IntValue")
monsterUserId.Name = "MonsterUserId"
monsterUserId.Value = 0
monsterUserId.Parent = state

local function part(parent, name, size, cframe, color, material)
  local p = Instance.new("Part")
  p.Name = name
  p.Size = size
  p.CFrame = cframe
  p.Anchored = true
  p.Color = color
  p.Material = material or Enum.Material.Metal
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p.Parent = parent
  return p
end

local function buildLab()
  local old = workspace:FindFirstChild("TheLab")
  if old then old:Destroy() end
  local lab = Instance.new("Model")
  lab.Name = "TheLab"
  lab.Parent = workspace
  local steel = Color3.fromRGB(55, 68, 79)
  local dark = Color3.fromRGB(23, 31, 39)
  local cyan = Color3.fromRGB(40, 220, 220)
  local floor = part(lab, "LabFloor", Vector3.new(150, 2, 150), CFrame.new(0, -1, 0), dark, Enum.Material.DiamondPlate)
  floor.CanCollide = true
  -- Modular corridor walls leave several routes through the facility.
  for _, z in ipairs({-55, -25, 5, 35, 65}) do
    part(lab, "NorthWall", Vector3.new(150, 22, 2), CFrame.new(0, 10, z), steel)
  end
  for _, x in ipairs({-55, -25, 5, 35, 65}) do
    part(lab, "SideWall", Vector3.new(2, 22, 150), CFrame.new(x, 10, 5), steel)
  end
  -- Strongly colored ceiling strips and glowing reactor cores help orientation.
  for _, pos in ipairs({Vector3.new(-40, 1, -40), Vector3.new(40, 1, -40), Vector3.new(-40, 1, 40), Vector3.new(40, 1, 40)}) do
    local lamp = part(lab, "CyanLight", Vector3.new(12, 0.4, 2), CFrame.new(pos), cyan, Enum.Material.Neon)
    lamp.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = cyan
    light.Brightness = 1.4
    light.Range = 26
    light.Parent = lamp
  end
  local reactor = part(lab, "Reactor", Vector3.new(12, 18, 12), CFrame.new(0, 8, 0), Color3.fromRGB(27, 105, 121), Enum.Material.Neon)
  reactor.CanCollide = false
  reactor.Transparency = 0.2
  -- Door frames with server-controlled sliding doors and prompts.
  local doors = Instance.new("Folder")
  doors.Name = "Doors"
  doors.Parent = lab
  for i, z in ipairs({-40, -10, 20, 50}) do
    local door = part(doors, "LabDoor" .. i, Vector3.new(2, 13, 12), CFrame.new(0, 6.5, z), Color3.fromRGB(150, 54, 45), Enum.Material.Metal)
    door:SetAttribute("Health", 3)
    door:SetAttribute("Broken", false)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Open / Close"
    prompt.ObjectText = "Lab blast door"
    prompt.HoldDuration = 0.2
    prompt.MaxActivationDistance = 10
    prompt.Parent = door
    prompt.Triggered:Connect(function(player)
      if not door.Parent or door:GetAttribute("Broken") then return end
      local character = player.Character
      local root = character and character:FindFirstChild("HumanoidRootPart")
      if not root or (root.Position - door.Position).Magnitude > 12 then return end
      local isOpen = door:GetAttribute("Open") == true
      door:SetAttribute("Open", not isOpen)
      prompt.ActionText = isOpen and "Open" or "Close"
      door.CanCollide = isOpen
      TweenService:Create(door, TweenInfo.new(0.35), {
        CFrame = door.CFrame * CFrame.new(0, isOpen and 0 or 15, 0),
        Transparency = isOpen and 0 or 0.55
      }):Play()
    end)
  end
  local exit = part(lab, "ExitBeacon", Vector3.new(8, 1, 8), CFrame.new(65, 0, 65), Color3.fromRGB(62, 220, 123), Enum.Material.Neon)
  exit.CanCollide = false
  exit.Transparency = 0.25
  return lab
end

buildLab()

local lobby = workspace:FindFirstChild("Lobby") or Instance.new("Part")
lobby.Name = "Lobby"
lobby.Size = Vector3.new(42, 2, 42)
lobby.Position = Vector3.new(0, 0, 190)
lobby.Anchored = true
lobby.Material = Enum.Material.SmoothPlastic
lobby.Color = Color3.fromRGB(29, 38, 51)
lobby.Parent = workspace

local function setRole(player, role)
  player:SetAttribute("Role", role)
  player:SetAttribute("Alive", true)
  if role == "Monster" then
    local character = player.Character
    if character then
      local humanoid = character:FindFirstChildOfClass("Humanoid")
      if humanoid then
        humanoid.WalkSpeed = 18
        humanoid.MaxHealth = 150
        humanoid.Health = 150
        humanoid.BodyDepthScale.Value = 1.08
        humanoid.BodyHeightScale.Value = 1.12
        humanoid.BodyWidthScale.Value = 0.78
      end
      local head = character:FindFirstChild("Head")
      if head then
        head.Color = Color3.fromRGB(19, 20, 24)
        for _, child in ipairs(head:GetChildren()) do
          if child:IsA("Decal") then child:Destroy() end
        end
      end
      for _, limbName in ipairs({"LeftHand", "RightHand", "Left Arm", "Right Arm"}) do
        local limb = character:FindFirstChild(limbName)
        if limb and limb:IsA("BasePart") then limb.Color = Color3.fromRGB(30, 31, 36) end
      end
    end
  end
end

local function teleport(player, position)
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if root then root.CFrame = CFrame.new(position + Vector3.new(0, 4, 0)) end
end

Players.PlayerAdded:Connect(function(player)
  player:SetAttribute("Role", "Lobby")
  player:SetAttribute("Alive", false)
  player.CharacterAdded:Connect(function(character)
    task.wait(0.2)
    local role = player:GetAttribute("Role")
    if role == "Monster" then setRole(player, role) end
    if role == "Lobby" then teleport(player, Vector3.new(0, 0, 190)) end
  end)
end)

local function cosmeticDefeat(character)
  local root = character:FindFirstChild("HumanoidRootPart")
  if not root then return end
  -- Abstract, neutral-colored fragments; no blood or realistic injury.
  for _, offset in ipairs({Vector3.new(-1, 1, 0), Vector3.new(1, 1, 0), Vector3.new(0, 2, 0), Vector3.new(0, 0, 0)}) do
    local fragment = Instance.new("Part")
    fragment.Name = "DefeatFragment"
    fragment.Shape = Enum.PartType.Block
    fragment.Size = Vector3.new(0.65, 0.8, 0.55)
    fragment.Material = Enum.Material.SmoothPlastic
    fragment.Color = Color3.fromRGB(115, 129, 139)
    fragment.CFrame = root.CFrame * CFrame.new(offset)
    fragment.CanCollide = false
    fragment.Anchored = false
    fragment.Parent = workspace
    fragment.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(7, 15), math.random(-10, 10))
    TweenService:Create(fragment, TweenInfo.new(1.3), {Transparency = 1}):Play()
    Debris:AddItem(fragment, 1.5)
  end
end

local function validPlayerRoot(player)
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  if root and humanoid and humanoid.Health > 0 then return character, root, humanoid end
end

actionRemote.OnServerEvent:Connect(function(player, action, target)
  if action == "Grab" then
    if player:GetAttribute("Role") ~= "Monster" or not player:GetAttribute("Alive") then return end
    local _, monsterRoot = validPlayerRoot(player)
    if not monsterRoot then return end
    local closest, closestRoot
    for _, other in ipairs(Players:GetPlayers()) do
      if other ~= player and other:GetAttribute("Role") == "Survivor" and other:GetAttribute("Alive") then
        local character, root = validPlayerRoot(other)
        if root and (root.Position - monsterRoot.Position).Magnitude <= 8 then
          if not closestRoot or (root.Position - monsterRoot.Position).Magnitude < (closestRoot.Position - monsterRoot.Position).Magnitude then
            closest, closestRoot = other, root
          end
        end
      end
    end
    if closest then
      closest:SetAttribute("Alive", false)
      local character = closest.Character
      if character then
        cosmeticDefeat(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
      end
    end
  elseif action == "DoorHit" and typeof(target) == "Instance" and target:IsA("BasePart") then
    if player:GetAttribute("Role") ~= "Monster" or not player:GetAttribute("Alive") then return end
    if not target:IsDescendantOf(workspace.TheLab.Doors) or target:GetAttribute("Broken") then return end
    local _, root = validPlayerRoot(player)
    if not root or (root.Position - target.Position).Magnitude > 11 then return end
    local health = (target:GetAttribute("Health") or 3) - 1
    target:SetAttribute("Health", health)
    target.Color = Color3.fromRGB(220, math.clamp(60 + health * 25, 0, 255), 45)
    if health <= 0 then
      target:SetAttribute("Broken", true)
      target.CanCollide = false
      local prompt = target:FindFirstChildOfClass("ProximityPrompt")
      if prompt then prompt.Enabled = false end
      TweenService:Create(target, TweenInfo.new(0.6), {Transparency = 1, CFrame = target.CFrame * CFrame.new(0, -15, 0)}):Play()
      task.delay(0.7, function() if target.Parent then target:Destroy() end end)
    end
  end
end)

local function aliveSurvivors()
  local alive = 0
  for _, player in ipairs(Players:GetPlayers()) do
    if player:GetAttribute("Role") == "Survivor" and player:GetAttribute("Alive") then alive += 1 end
  end
  return alive
end

local function runRound()
  local roster = Players:GetPlayers()
  if #roster < MIN_PLAYERS then
    status.Value = "Waiting for at least 2 players"
    timeLeft.Value = 0
    return
  end
  for _, p in ipairs(roster) do
    p:SetAttribute("Role", "Survivor")
    p:SetAttribute("Alive", true)
    if p.Character then p:LoadCharacter() end
  end
  task.wait(1)
  local monster = roster[math.random(1, #roster)]
  monster:SetAttribute("Role", "Monster")
  monsterUserId.Value = monster.UserId
  for i, p in ipairs(roster) do
    teleport(p, Vector3.new((i % 4) * 12 - 18, 0, (i % 2) * 12 - 24))
    if p == monster then setRole(p, "Monster") end
  end
  for remaining = ROUND_SECONDS, 0, -1 do
    if #Players:GetPlayers() < MIN_PLAYERS then break end
    timeLeft.Value = remaining
    status.Value = "Survive the monster!"
    if aliveSurvivors() == 0 then
      status.Value = "The monster wins!"
      break
    end
    task.wait(1)
  end
  if aliveSurvivors() > 0 and timeLeft.Value <= 0 then status.Value = "Survivors win!" end
  task.wait(5)
  monsterUserId.Value = 0
  for _, p in ipairs(Players:GetPlayers()) do
    p:SetAttribute("Role", "Lobby")
    p:SetAttribute("Alive", false)
    p:LoadCharacter()
  end
end

while true do
  while #Players:GetPlayers() < MIN_PLAYERS do
    status.Value = "Waiting for players (" .. #Players:GetPlayers() .. "/" .. MIN_PLAYERS .. ")"
    task.wait(2)
  end
  for n = INTERMISSION_SECONDS, 1, -1 do
    status.Value = "Round starts in " .. n
    timeLeft.Value = n
    task.wait(1)
  end
  runRound()
end
