-- renders round results for player
local client = shared.Client
local requirements = client._requirements

-- requirements
local Util = requirements.Util

-- service
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI

-- paths
local MainUI = requirements.UI
local reference: Frame? = MainUI.reference.Screen.Results
assert( reference, 'No Results frame exists in ScreenGui' )


-- ResultsScreen initial
local ResultsScreen = {}
ResultsScreen.enabled = false
ResultsScreen.reference = reference

-- initial method
function ResultsScreen:Init()
end

-- sets ResultsScreen frame visible
function ResultsScreen:SetEnabled(enabled: boolean)
end

-- runs sequence of animations and changes for Results screen (EPIC)
function ResultsScreen:RunSequence(round_results_data)
end


return ResultsScreen