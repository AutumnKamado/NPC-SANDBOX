-- Connected Discord-GitHub
--[[
	by @CxRDev
	
	NOTES:
	----------------
	• NPC appearance is randomized by selecting assets from dedicated folders.
	• Helper functions are separated to avoid repeating random selection logic.
	• A single Random object is reused throughout the script to keep random generation consistent.
	• Wandering runs inside its own thread so each NPC can move independently.
	• Non Angry NPC Waves at you.
]]

--// Variables \\--
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Map = workspace.Map

--// Workspace Stuff
local CharacterFolder = Map.Characters
local SpawnLocationsFolder = Map.SpawnLocations
local NPCZone = Map.NPCZone

--// Attributes Stuff
local CharacterAttributesFolder = ReplicatedStorage.CharacterItems
local BodyColorFolder = CharacterAttributesFolder.SkinColor
local ShirtsFolder = CharacterAttributesFolder.Shirts
local PantsFolder = CharacterAttributesFolder.Pants
local AccessoriesFolder = CharacterAttributesFolder.Accessories
local HatsFolder = CharacterAttributesFolder.Hats

local CloneCharacter = CharacterAttributesFolder.CharacterRig

local MaxNPC = 10
local CurrentAmountofNPC = 0  
local DetectionRadius = 15

local Random = Random.new()

------------------- 
--// Functions \\--

local function FiftyFifty(Option1, Option2)
	--// Generate a random number between 0 and 1
	if Random:NextNumber() < 0.5 then
		return Option1 --// Anything below 0.5 = Option 1
	else
		return Option2 --// Anything 0.5 or above = Option 2
	end
end

local function RandomDeleteFromFolder(folder)
	--// Get all objects inside the folder
	local Objects = folder:GetChildren()

	--// If there are no objects, stop
	if #Objects == 0 then
		return	
	end

	--// Pick a random object
	local RandomObject = Objects[Random:NextInteger(1, #Objects)]

	--// Delete the randomly selected object
	RandomObject:Destroy()
end

local function RandomFromFolder(folder)
	local objects = folder:GetChildren() --// Gets all children in folder

	if #objects == 0 then
		return nil
	end

	return objects[Random:NextInteger(1, #objects)]
end

local function CountFolderChildren(folder)
	local Count = 0

	--// Count all NPC models
	for _, Object in ipairs(folder:GetChildren()) do
		if Object:IsA("Model") then
			Count += 1
		end
	end

	return Count
end

local function SkinTone(OldSkinTone : BodyColors, NewSkinTone : BodyColors)
	--// Changing body colors
	OldSkinTone.HeadColor3 = NewSkinTone.HeadColor3
	OldSkinTone.LeftArmColor3 = NewSkinTone.LeftArmColor3
	OldSkinTone.LeftLegColor3 = NewSkinTone.LeftLegColor3
	OldSkinTone.RightArmColor3 = NewSkinTone.RightArmColor3
	OldSkinTone.RightLegColor3 = NewSkinTone.RightLegColor3
	OldSkinTone.TorsoColor3 = NewSkinTone.TorsoColor3
end

local function SpawnCharacter()
	local CloneNPC = CloneCharacter:Clone()
	local BodyColors = CloneNPC["Body Colors"]
	local CloneHead = CloneNPC.Head
	local Face = CloneHead.face

	local RandomHat = RandomFromFolder(HatsFolder)
	local RandomShirt = RandomFromFolder(ShirtsFolder)
	local RandomPants = RandomFromFolder(PantsFolder)
	local RandomSpawnLocation = RandomFromFolder(SpawnLocationsFolder)
	local RandomSkinTone = RandomFromFolder(BodyColorFolder)

	--// Stop spawning if required assets are missing
	if not RandomHat
		or not RandomShirt
		or not RandomPants
		or not RandomSpawnLocation
		or not RandomSkinTone then
		return
	end

	RandomHat = RandomHat:Clone()
	RandomShirt = RandomShirt:Clone()
	RandomPants = RandomPants:Clone()

	local AngrySkinTone = CharacterAttributesFolder.AngrySkin
	local Glasses = AccessoriesFolder.Glasses:Clone()

	--// Random Chance of having glasses
	local GlassesChance = FiftyFifty("yes", "no")

	if GlassesChance == "yes" then
		Glasses.Parent = CloneNPC
	end

	--// Changing body colors
	BodyColors.Parent = CloneNPC

	RandomShirt.Parent = CloneNPC
	RandomPants.Parent = CloneNPC
	RandomHat.Parent = CloneNPC

	SkinTone(BodyColors, RandomSkinTone)

	--// Random Chance of being angry
	local MoodChance = FiftyFifty("Angry", "Normal")
	local MoodValue = CloneNPC.Mood

	if MoodChance == "Angry" then
		Face.Texture = "rbxassetid://172160569"
		SkinTone(BodyColors, AngrySkinTone)
		MoodValue.Value = true
	end

	CloneNPC.HumanoidRootPart.Position = RandomSpawnLocation.Position
	CloneNPC.Parent = CharacterFolder
end

local function GetNearestPlayer(NPC : Model)
	local MoodValue = NPC:FindFirstChild("Mood")

	if not MoodValue then
		return nil
	end

	--// Angry NPCs cannot detect players
	if MoodValue.Value == true then
		return nil
	end

	--// Normal NPCs can detect players
	local HumanoidRootPart = NPC:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then
		return nil
	end

	local closestPlayer
	local closestDistance = DetectionRadius

	--// Loop through every player currently in the game
	for _, Player in ipairs(Players:GetPlayers()) do
		local Character = Player.Character

		if Character then
			local PlayerHRP = Character:FindFirstChild("HumanoidRootPart")
			local Humanoid : Humanoid = Character:FindFirstChild("Humanoid")

			--// Make sure the player has a HumanoidRootPart and is still alive
			if PlayerHRP and Humanoid and Humanoid.Health > 0 then

				--// Calculate the distance between NPC and Player
				local Distance = (PlayerHRP.Position - HumanoidRootPart.Position).Magnitude

				--// Check if player is closer than the closest player so far
				if Distance < closestDistance then
					--// Redefine the closest player and distance
					closestPlayer = Player
					closestDistance = Distance
				end
			end
		end
	end

	return closestPlayer
end

local function Wander(NPC)
	local Humanoid = NPC:FindFirstChildOfClass("Humanoid")
	local RootPart = NPC:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not RootPart then
		return
	end

	--// Wave Animation
	local Animator = Humanoid:FindFirstChildOfClass("Animator")

	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = Humanoid
	end

	local WaveAnimation = Instance.new("Animation")
	WaveAnimation.AnimationId = "rbxassetid://92131881445743"

	local WaveTrack = Animator:LoadAnimation(WaveAnimation)
	WaveTrack.Looped = false
	WaveTrack.Priority = Enum.AnimationPriority.Action

	while NPC.Parent and Humanoid.Health > 0 do

		--// Check if there is a nearby player
		local NearestPlayer = GetNearestPlayer(NPC)

		if NearestPlayer then
			local PlayerCharacter = NearestPlayer.Character
			local PlayerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")

			if PlayerRoot then
				--// Stop moving
				Humanoid:MoveTo(RootPart.Position)

				--// Make the NPC face the player
				local LookPosition = Vector3.new(
					PlayerRoot.Position.X,
					RootPart.Position.Y,
					PlayerRoot.Position.Z
				)

				RootPart.CFrame = CFrame.lookAt(
					RootPart.Position,
					LookPosition
				)

				--// Tell the normal animations that the NPC is reacting
				NPC:SetAttribute("Reacting", true)

				--// Play the wave animation
				if not WaveTrack.IsPlaying then
					WaveTrack:Play()
				end

				--// Wait until the wave animation finishes
				WaveTrack.Stopped:Wait()

				--// Allow normal animations again
				NPC:SetAttribute("Reacting", false)

				--// Small cooldown
				task.wait(2)

				continue
			end
		end

		--// Get a random position inside the part
		local Size = NPCZone.Size
		local Position = NPCZone.Position

		local RandomX = Position.X + math.random(-Size.X * 50, Size.X * 50) / 100
		local RandomZ = Position.Z + math.random(-Size.Z * 50, Size.Z * 50) / 100

		local TargetPosition = Vector3.new(
			RandomX,
			RootPart.Position.Y,
			RandomZ
		)

		--// Move to the random position
		Humanoid:MoveTo(TargetPosition)

		--// Wait until NPC reaches the position
		Humanoid.MoveToFinished:Wait()

		--// Small pause before choosing another position
		task.wait(1)
	end
end

local function SetupAnimations(NPC)
	local Humanoid = NPC.Humanoid
	local Animator = Humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator', Humanoid)

	--// Animations
	local IdleAnimation = Instance.new('Animation')
	IdleAnimation.AnimationId = 'rbxassetid://108066746330414'

	local WalkAnimation = Instance.new('Animation')
	WalkAnimation.AnimationId = 'rbxassetid://110617147914303'

	local IdleTrack = Animator:LoadAnimation(IdleAnimation)
	local WalkTrack = Animator:LoadAnimation(WalkAnimation)

	--// Making sure they're looped
	IdleTrack.Looped = true
	WalkTrack.Looped = true

	IdleTrack:Play()

	--// Detect walking
	Humanoid.Running:Connect(function(Speed)
		--// Don't change animations while the NPC is reacting
		if NPC:GetAttribute("Reacting") then
			return
		end

		if Speed > 0.1 then
			if not WalkTrack.IsPlaying then
				IdleTrack:Stop()
				WalkTrack:Play()
			end
		else
			if not IdleTrack.IsPlaying then
				WalkTrack:Stop()
				IdleTrack:Play()
			end
		end
	end)
end

----------------------
--// Main Scripts \\--

--// Handles the NPC Spawning and Deleting
Players.PlayerAdded:Connect(function(player) 
	player.CharacterAdded:Connect(function()
		--// I'd usually use a local script for this part but,
		--// I am keeping it all in one main script

		local PlayerGUI = player.PlayerGui
		local NPCGUI = PlayerGUI.CharacterGUI

		local SpawnButton = NPCGUI.AddCharacter
		local DeleteButton = NPCGUI.DeleteCharacter

		local CounterTextLabel = NPCGUI.Counter

		SpawnButton.MouseButton1Click:Connect(function()
			if CountFolderChildren(CharacterFolder) < MaxNPC then
				SpawnCharacter()

				CurrentAmountofNPC = CountFolderChildren(CharacterFolder)
				CounterTextLabel.Text = "NPC's : "..CurrentAmountofNPC
			end
		end)

		DeleteButton.MouseButton1Click:Connect(function()
			if CountFolderChildren(CharacterFolder) > 0 then
				RandomDeleteFromFolder(CharacterFolder)

				CurrentAmountofNPC = CountFolderChildren(CharacterFolder)
				CounterTextLabel.Text = "NPC's : "..CurrentAmountofNPC	
			end
		end)
	end)
end)

--// Handles the Wandering and reacting to the Player
CharacterFolder.ChildAdded:Connect(function(NPC)
	SetupAnimations(NPC)

	task.spawn(function()
		Wander(NPC)
	end)
end)
