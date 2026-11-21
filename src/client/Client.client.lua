local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local action = remotes:WaitForChild("Action")
local state = ReplicatedStorage:WaitForChild("GameState")

local gui = Instance.new("ScreenGui")
gui.Name = "TheMonsterHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.Name = "Status"
label.Size = UDim2.fromOffset(360, 72)
label.Position = UDim2.new(0.5, -180, 0, 22)
label.BackgroundColor3 = Color3.fromRGB(13, 20, 28)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.fromRGB(100, 235, 230)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.TextWrapped = true
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = label

local function updateHud()
  local seconds = state.TimeLeft.Value
  local clock = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
  local role = player:GetAttribute("Role") or "Lobby"
  label.Text = state.Status.Value .. "\n" .. role .. "  •  " .. clock
end
state.Status.Changed:Connect(updateHud)
state.TimeLeft.Changed:Connect(updateHud)
player:GetAttributeChangedSignal("Role"):Connect(updateHud)
updateHud()

local function nearestDoor()
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local doors = workspace:FindFirstChild("TheLab") and workspace.TheLab:FindFirstChild("Doors")
  if not root or not doors then return nil end
  local nearest, distance
  for _, door in ipairs(doors:GetChildren()) do
    if door:IsA("BasePart") and not door:GetAttribute("Broken") then
      local d = (door.Position - root.Position).Magnitude
      if d < 11 and (not distance or d < distance) then nearest, distance = door, d end
    end
  end
  return nearest
end

local function monsterAction()
  if player:GetAttribute("Role") ~= "Monster" then return end
  -- Server independently checks role, life state, target distance, and door distance.
  action:FireServer("Grab")
  local door = nearestDoor()
  if door then action:FireServer("DoorHit", door) end
end

UserInputService.InputBegan:Connect(function(input, processed)
  if processed then return end
  if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then monsterAction() end
end)

-- Prototype hand-push locomotion: while gripping, hand motion transfers to the
-- root only when a short ray confirms contact with a solid surface.
local lastHands = {}
local gripKeys = {
  [Enum.KeyCode.ButtonL1] = "Left",
  [Enum.KeyCode.ButtonR1] = "Right",
  [Enum.KeyCode.ButtonL2] = "Left",
  [Enum.KeyCode.ButtonR2] = "Right"
}
UserInputService.InputBegan:Connect(function(input)
  local hand = gripKeys[input.KeyCode]
  if hand then lastHands[hand] = nil end
end)
UserInputService.InputEnded:Connect(function(input)
  local hand = gripKeys[input.KeyCode]
  if hand then lastHands[hand] = nil end
end)

RunService.RenderStepped:Connect(function()
  if not VRService.VREnabled then return end
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local camera = workspace.CurrentCamera
  if not root or not camera then return end
  for keyCode, handName in pairs(gripKeys) do
    if UserInputService:IsKeyDown(keyCode) then
      local enumHand = handName == "Left" and Enum.UserCFrame.LeftHand or Enum.UserCFrame.RightHand
      local handFrame = camera.CFrame * VRService:GetUserCFrame(enumHand)
      local handPosition = handFrame.Position
      local previous = lastHands[handName]
      if previous then
        local delta = handPosition - previous
        if delta.Magnitude > 0.02 and delta.Magnitude < 1 then
          local params = RaycastParams.new()
          params.FilterType = Enum.RaycastFilterType.Exclude
          params.FilterDescendantsInstances = {character}
          local hit = workspace:Raycast(previous, delta, params)
          if hit then
            root.AssemblyLinearVelocity += Vector3.new(-delta.X * 22, math.clamp(-delta.Y * 16, -24, 24), -delta.Z * 22)
          end
        end
      end
      lastHands[handName] = handPosition
    end
  end
end)
