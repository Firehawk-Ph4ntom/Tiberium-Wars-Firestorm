squadtable = {} -- tracks all squad objects on the map

harvbluetib = {} -- for counting the amount of blue tiberium in the harvester
harvgreentib = {} -- for counting the amount of green tiberium in the harvester
harvredtib = {} -- for counting the amount of red tiberium in the harvester

-- 0 is for green, 1 is for blue, 2 is for red
bar1 = {} -- for tracking the first bar of the harvester.
bar2 = {} -- for tracking the second bar of the harvester.
bar3 = {} -- for tracking the third bar of the harvester.
bar4 = {} -- for tracking the last bar of the harvester.

-- get the hash of the unit
UnitType = {["3006676643"] = "GDIFireHawk", ["3045524383"] = "GDIOrca", ["1789238550"] = "NODVertigo", ["3755615724"] = "NODBanshee"}
-- get the total ammo count of the unit
UnitAmmoSize = {["GDIFireHawk"] = 4, ["GDIOrca"] = 8, ["NODVertigo"] = 1, ["NODBanshee"] = 4}
-- second array to store the ammo in when unit fires, until it reaches 0, the conditions fire to disable AI control
UnitAmmoCount = {}

--- define lua functions 
function NoOp(self, source)
end

function kill(self) -- Kill unit self.
	ExecuteAction("NAMED_KILL", self);
end

function RadiateUncontrollableFear( self )
	ObjectBroadcastEventToEnemies( self, "BeUncontrollablyAfraid", 350 )
end

function RadiateGateDamageFear(self)
	ObjectBroadcastEventToAllies(self, "BeAfraidOfGateDamaged", 200)
end

function OnNeutralGarrisonableBuildingCreated(self)
	ObjectHideSubObjectPermanently( self, "ARMOR", true )
end

function onCreatedControlPointFunctions(self)
	ObjectHideSubObjectPermanently( self, "TB_CP_ALN", true )
	ObjectHideSubObjectPermanently( self, "TB_CP_GDI", true )
	ObjectHideSubObjectPermanently( self, "TB_CP_NOD", true )
	ObjectHideSubObjectPermanently( self, "LIGHTSF01", true )
	ObjectHideSubObjectPermanently( self, "100", false)
	ObjectHideSubObjectPermanently( self, "75", false)
	ObjectHideSubObjectPermanently( self, "50", false)
	ObjectHideSubObjectPermanently( self, "25", false )
end

function GoIntoRampage(self)
	ObjectEnterRampageState(self)

	--Broadcast fear to surrounding unit(if we actually rampaged)
	if ObjectTestModelCondition(self, "WEAPONSET_RAMPAGE") then
		ObjectBroadcastEventToUnits(self, "BeAfraidOfRampage", 250)
	end
end

function MakeMeAlert(self)
	ObjectEnterAlertState(self)
end

function BecomeUncontrollablyAfraid(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterUncontrollableCowerState(self, other)
end

function BecomeAfraidOfRampage(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterCowerState(self, other)
end

function RadiateTerror(self, other)
	ObjectBroadcastEventToEnemies(self, "BeTerrified", 180)
end

function RadiateTerrorEx(self, other, terrorRange)
	ObjectBroadcastEventToEnemies(self, "BeTerrified", terrorRange)
end


function BecomeTerrified(self, other)
	ObjectEnterRunAwayPanicState(self, other)
end

function BecomeAfraidOfGateDamaged(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterCowerState(self,other)
end


function ChantForUnit(self) -- Used by units to broadcast the chant event to their own side.
	ObjectBroadcastEventToAllies(self, "BeginChanting", 9999)
end

function StopChantForUnit(self) -- Used by units to stop the chant event to their own side.
	ObjectBroadcastEventToAllies(self, "StopChanting", 9999)
end

function SpyMoving(self, other)
	print(ObjectDescription(self).." spying movement of "..ObjectDescription(other));
end

function OnGarrisonableCreated(self)
	ObjectHideSubObjectPermanently( self, "GARRISON01", true )
	ObjectHideSubObjectPermanently( self, "GARRISON02", true )
end

function OnRubbleDropshipCreated(self)
	ObjectHideSubObjectPermanently( self, "Loadref", true )
end

-- XPACK LUA FUNCTION DEFINITIONS
function OnMutantViceroidCreated(self)
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
end

function onCreatedForbidCommands(self)
	ObjectForbidPlayerCommands( self, true )
end

function onAlienMCVUnpackingCreated(self)
	ObjectSetObjectStatus( self, "UNSELECTABLE" )
end

function OnAlienPhotonCannonCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_SHARD", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end

function OnGDITechCenterCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Mortar", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan", true )
	ObjectHideSubObjectPermanently( self, "UG_Rail", true )
	ObjectHideSubObjectPermanently( self, "B_MortarRound_1", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive01", true )
	ObjectHideSubObjectPermanently( self, "FXELEC01", true )
	ObjectHideSubObjectPermanently( self, "PLANE02", true )
end

function OnGDITechCenterPowerOutage(self)
	if ObjectHasUpgrade( self, "Upgrade_GDIArmoryRailgunTech" ) == 1 then
		ObjectHideSubObjectPermanently( self, "FXELEC01", true )
		ObjectHideSubObjectPermanently( self, "PLANE02", true )
	end
end

function OnGDITechCenterPowerRestored(self)
	if ObjectHasUpgrade( self, "Upgrade_GDIArmoryRailgunTech" ) == 1 then
		ObjectHideSubObjectPermanently( self, "FXELEC01", false )
		ObjectHideSubObjectPermanently( self, "PLANE02", false )
	end
end

function OnGDIAirfieldCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints01", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints03", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints02", true )
	ObjectHideSubObjectPermanently( self, "UG_Boost", true )
end

function OnGDICommandPostCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Scan", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector01", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector02", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan02", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo02", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan01", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo01", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector03", true )
end

function OnGDICommandPostPowerOutage(self)
	if ObjectHasUpgrade( self, "Upgrade_ZoneTrooperScannerPack" ) == 1 then
		ObjectHideSubObjectPermanently( self, "UG_StealthDetector01", true )
	end
end

function OnGDICommandPostPowerRestored(self)
	if ObjectHasUpgrade( self, "Upgrade_ZoneTrooperScannerPack" ) == 1 then
		ObjectHideSubObjectPermanently( self, "UG_StealthDetector01", false )
	end
end

function OnGDITankArmoryCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Injector", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP01", true )
	ObjectHideSubObjectPermanently( self, "CRATE", true )
end

function OnGDIBattleBaseCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_TURRETL", true )
	ObjectHideSubObjectPermanently( self, "UG_TURRETR", true )
end

function OnGDIWatchTowerCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_BASE", true )
end

function onBuildingPowerOutage(self)
	ObjectHideSubObjectPermanently( self, "TV", true )
	ObjectHideSubObjectPermanently( self, "LINKS", true )
	ObjectHideSubObjectPermanently( self, "MESH01", true )
	ObjectHideSubObjectPermanently( self, "MESH28", true )
	ObjectHideSubObjectPermanently( self, "GLOWS", true )
	ObjectHideSubObjectPermanently( self, "FXGLOWS", true )
	ObjectHideSubObjectPermanently( self, "LIGHTL", true )
	ObjectHideSubObjectPermanently( self, "LIGHTR", true )
	ObjectHideSubObjectPermanently( self, "LIGHT_01", true )
	ObjectHideSubObjectPermanently( self, "LIGHT_02", true )
	ObjectHideSubObjectPermanently( self, "LIGHTS", true )
	ObjectHideSubObjectPermanently( self, "LIGHTS1", true )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FX_LIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS05", true )
	ObjectHideSubObjectPermanently( self, "FX_LIGHTS01", true )
	ObjectHideSubObjectPermanently( self, "CENTERLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS01", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS02", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS03", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS04", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS05", true )
	ObjectHideSubObjectPermanently( self, "POWERPLANTGLOWS", true )
	ObjectHideSubObjectPermanently( self, "NBCHEMICALPTE1", true )
	ObjectHideSubObjectPermanently( self, "AUDRONSHIPLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "NEXUSBEAM", true )
	ObjectHideSubObjectPermanently( self, "NEXUSSTREAM", true )
	ObjectHideSubObjectPermanently( self, "TURBINEGLOWS", true )
end

function onBuildingPowerRestored(self)
	ObjectHideSubObjectPermanently( self, "TV", false )
	ObjectHideSubObjectPermanently( self, "LINKS", false )
	ObjectHideSubObjectPermanently( self, "MESH01", false )
	ObjectHideSubObjectPermanently( self, "MESH28", false )
	ObjectHideSubObjectPermanently( self, "GLOWS", false )
	ObjectHideSubObjectPermanently( self, "FXGLOWS", false )
	ObjectHideSubObjectPermanently( self, "LIGHTL", false )
	ObjectHideSubObjectPermanently( self, "LIGHTR", false )
	ObjectHideSubObjectPermanently( self, "LIGHT_01", false )
	ObjectHideSubObjectPermanently( self, "LIGHT_02", false )
	ObjectHideSubObjectPermanently( self, "LIGHTS", false )
	ObjectHideSubObjectPermanently( self, "LIGHTS1", false )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FX_LIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS05", false )
	ObjectHideSubObjectPermanently( self, "FX_LIGHTS01", false )
	ObjectHideSubObjectPermanently( self, "CENTERLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS01", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS02", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS03", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS04", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS05", false )
	ObjectHideSubObjectPermanently( self, "POWERPLANTGLOWS", false )
	ObjectHideSubObjectPermanently( self, "NBCHEMICALPTE1", false )
	ObjectHideSubObjectPermanently( self, "AUDRONSHIPLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "NEXUSBEAM", false )
	ObjectHideSubObjectPermanently( self, "NEXUSSTREAM", false )
	ObjectHideSubObjectPermanently( self, "TURBINEGLOWS", false )
end

function OnGDIV35Ox_SummonedCreated(self)
	ObjectSetObjectStatus( self, "UNSELECTABLE" )
end

function OnGDIV35Ox_SummonedForVehicleCreated(self)
	ObjectHideSubObjectPermanently( self, "LOADREF", true )
	ObjectSetObjectStatus( self, "UNSELECTABLE" )
end

function OnGDIV35Ox_Carrying(self)
	ObjectGrantUpgrade( self, "Upgrade_Transporting" )
end

function OnGDIZoneTrooperCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
	ObjectHideSubObjectPermanently( self, "UGINJECTOR", true )
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
end

function OnGDIGrenadeSoldierCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_STRAPS", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP_PROJECTILE", true )
end

function OnGenericSpotterCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
end

function OnGDIAPCCreated(self)
	ObjectHideSubObjectPermanently( self, "APC_UGAB", true )
	ObjectHideSubObjectPermanently( self, "APC_UGTURRET", true )
end

function OnGDIWolverineCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_AMMO", true )
end

function OnNODHangarCreated(self)
	ObjectHideSubObjectPermanently( self, "DISRUPTIONPODS", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN_02", true )
end

function OnNODOperationsCenterCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_DOZERBLADES", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN", true )
	ObjectHideSubObjectPermanently( self, "UG_QUADTURRETS", true )
end

function OnNODSecretShrineCreated(self)
	ObjectHideSubObjectPermanently( self, "PURIFYINGFLAME02", true )
	ObjectHideSubObjectPermanently( self, "PURIFYINGFLAME01", true )
	ObjectHideSubObjectPermanently( self, "BLACKDISCIPLESUPGRD", true )
	ObjectHideSubObjectPermanently( self, "BLACKDISCIPLES_GLOWS", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_01", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_02", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_03", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_04", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_05", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_06", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_07", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_08", true )
end

function OnNODSecretShrinePowerOutage(self)
	if ObjectHasUpgrade( self, "Upgrade_BlackHandBlackTemplarsUpgrade" ) == 1 then
		ObjectHideSubObjectPermanently( self, "BLACKDISCIPLES_GLOWS", true )
	end
end

function OnNODSecretShrinePowerRestored(self)
	if ObjectHasUpgrade( self, "Upgrade_BlackHandBlackTemplarsUpgrade" ) == 1 then
		ObjectHideSubObjectPermanently( self, "BLACKDISCIPLES_GLOWS", false )
	end
end

function OnNODTechAssembleyPlantCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Lasers", true )
	ObjectHideSubObjectPermanently( self, "UG_EMP", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER02", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_01", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_02", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_03", true )
end

function OnNODCarryall_SummonedForVehicleCreated(self)
	ObjectHideSubObjectPermanently( self, "HANGAR", true )
	ObjectSetObjectStatus( self, "UNSELECTABLE" )
end

function OnNODVenomCreated(self)
	ObjectHideSubObjectPermanently( self, "SIGGEN", true )
end

function OnNODAttackBikeCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILEL", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER", true )
end

function OnNODRedeemerWarmechCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILEL", true )
end

function OnNODAvatarCreated(self)
	ObjectHideSubObjectPermanently( self, "WEBLAUNCHER", true )
	ObjectHideSubObjectPermanently( self, "S_GENERATOR", true )
end

function OnNODReckonerCreated(self)
	ObjectHideSubObjectPermanently( self, "DOZERBLADE", true )
	ObjectHideSubObjectPermanently( self, "UG_SPEAKERS", true )
end

function OnNODReckonerHuskCreated(self)
	ObjectHideSubObjectPermanently( self, "DOZERBLADE", true )
	ObjectHideSubObjectPermanently( self, "UG_SPEAKERS", true )
	ObjectHideSubObjectPermanently( self, "TV", true )
end

function OnNODRaiderTankCreated(self)
	ObjectHideSubObjectPermanently( self, "DOZERBLADE", true )
end

function OnNODScorpionBuggyCreated(self)
	ObjectHideSubObjectPermanently( self, "EMP", true )
end

function OnGDICommandoCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
	ObjectHideSubObjectPermanently( self, "FX_GLOWHEROIC", true )
end

function OnAlienAdvProductionPurchased(self)
	if ObjectHasUpgrade( self, "Upgrade_AdvancedProduction" ) == 1 then
		ObjectGrantUpgrade( self, "Upgrade_ProductionDummy" )
	end
end

function OnGDIAircraftCreated(self)
	ObjectGrantUpgrade( self, "Upgrade_AirSupremacyDummyUpgrade" )
end

function OnGDIAirSupremacyPurchased(self)
	ObjectGrantUpgrade( self, "Upgrade_AirSupremacyLevelup" )
end

function OnGDIPredatorTankCreated(self)
	ObjectHideSubObjectPermanently( self, "LASER", true )
end

function OnGDIMammothTankCreated(self)
	ObjectHideSubObjectPermanently( self, "LASERPOINTER", true )
	ObjectHideSubObjectPermanently( self, "LASER", true )
end

function OnGDIPaladinTankCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_AMMO", true )
	ObjectHideSubObjectPermanently( self, "LASER", true )
end

function OnAlienMotherShipCreated(self)
	ObjectSetObjectStatus( self, "AIRBORNE_TARGET" )
end

function OnWeaponSwapNoAttack(self)
	ObjectGrantUpgrade( self, "Upgrade_WeaponSwapNoAttack" )
end

function OnWeaponSwapNoAttackEnd(self)
	ObjectRemoveUpgrade( self, "Upgrade_WeaponSwapNoAttack" )
end

function OnAlienEradicatorHexapodCreated(self)
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RR", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RR", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RM", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RM", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RF", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RF", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LF", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LF", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LM", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LM", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LR", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LR", true )
end

function OnAlienDevastatorWarshipCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_SHARD", true )
end

function OnNODRocketBunkerCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILE", true )
	ObjectHideSubObjectPermanently( self, "HOSE", true )
	ObjectHideSubObjectPermanently( self, "TCMHUB_UPGRADE", true )
end

function OnNODRocketBunkerSpawnCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILE", true )
	ObjectHideSubObjectPermanently( self, "HOSE", true )
end

function OnNODDisruptionModulesUpgradePurchased(self)
	if ObjectHasUpgrade( self, "Upgrade_NODDisruptionModules" ) == 1 then
		ObjectGrantUpgrade( self, "Upgrade_ActivateDisruptionModule" )
	end
end

function OnUnitCreatedSetRider4(self)
	ObjectSetObjectStatus ( self, "RIDER4" )
end

function OnTibChargeNoAttack(self)
	ObjectGrantUpgrade( self, "Upgrade_TibChargeNoAttack" )
end

function OnTibChargeNoAttackEnd(self)
	ObjectRemoveUpgrade( self, "Upgrade_TibChargeNoAttack" )
end

function OnNODPropagandaUpgradePurchased(self)
	if ObjectHasUpgrade ( self, "Upgrade_PropagandaBuff" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_DummyPropagandaBuff" )
	end
end

function OnNODTiberiumInfusionUpgradePurchased(self)
	if ObjectHasUpgrade ( self, "Upgrade_TiberiumInfusion" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_TiberiumInfusionDummy" )
	end
end

function OnAlienIchorPlatingUpgradePurchased(self)
	if ObjectHasUpgrade ( self, "Upgrade_IchorPlating" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_IchorPlatingDummy" )
	end
end

function CheckJetAircraftAmmoDepleted(self)
	if IsUnitAI(self) then
		if UnitAmmoCount.self == nil then
			UnitAmmoCount.self = UnitAmmoSize[UnitType[GetObj.Hash(self)]] - 1
		else
			UnitAmmoCount.self = UnitAmmoCount.self - 1
		end
		if UnitAmmoCount.self <= 0 then
			ExecuteAction("UNIT_AI_TRANSFER", self, 0)
			ExecuteAction("NAMED_FIRE_SPECIAL_POWER", GetObj.String(self), "SpecialPowerReturnToProducer")
		else
			ExecuteAction("UNIT_AI_TRANSFER", self, 1)
		end
	end
end

function GenericCrateSpawnerCheck()
	setcallhook()
	local NeutralTeam = "/team"
	local TempRef = "object_" .. tostring(floor(9999999 * GetRandomNumber()))
	ExecuteAction("TEAM_SET_PLAYERS_NEAREST_UNIT_OF_TYPE_TO_REFERENCE", "GenericCrateSpawner", NeutralTeam, TempRef)
	if not EvaluateCondition("NAMED_NOT_DESTROYED", TempRef) then 
		ExecuteAction("CREATE_OBJECT", "GenericCrateSpawner", NeutralTeam, "x=0,y=0,z=0", 0)
	end
end
setcallhook(GenericCrateSpawnerCheck)

function SquadLookupTable(x)  -- x = object template
	local delay1 = 1 -- 1 second delay
	local delay5 = 5 -- 5 second delay

	-- GDI Infantry
	-- Rifleman Squad
	if strfind(tostring(x), "9096966E") ~= nil then
		ans = 6*delay1
	-- Missile Squad
	elseif strfind(tostring(x), "EF1252DB") ~= nil then
		ans = 2*delay1
	-- Grenadier Squad
	elseif strfind(tostring(x), "42896060") ~= nil then
		ans = 4*delay1
	-- Sniper Team
	elseif strfind(tostring(x), "BCB36A05") ~= nil then
		ans = 2*delay1
	-- Combat Medic Team
	elseif strfind(tostring(x), "81C1827B") ~= nil then
		ans = 3*delay1
	-- Zone Troopers
	elseif strfind(tostring(x), "5D5E5931") ~= nil then
		ans = 4*delay1
	-- Zone Raiders
	elseif strfind(tostring(x), "2D1766F8") ~= nil then
		ans = 4*delay1
	-- Zone Defenders
	elseif strfind(tostring(x), "FCFB2118") ~= nil then
		ans = 4*delay5

	-- NOD Infantry
	-- Militant Squad
	elseif strfind(tostring(x), "BC36257A") ~= nil then
		ans = 9*delay1
	-- Militant Rocket Squad
	elseif strfind(tostring(x), "89C45844") ~= nil then
		ans = 2*delay1
	-- Fanatics
	elseif strfind(tostring(x), "BE7C389D") ~= nil then
		ans = 5*delay1
	-- Black Hand Squad
	elseif strfind(tostring(x), "128ABF1") ~= nil then
		ans = 6*delay1
	-- Confessor Squad
	elseif strfind(tostring(x), "AB1BD4E2") ~= nil then
		ans = 6*delay1
	-- Shadow Team
	elseif strfind(tostring(x), "A6E10008") ~= nil then
		ans = 5*delay1
	-- Cyborg Gunners
	elseif strfind(tostring(x), "346EDC73") ~= nil then
		ans = 3*delay1
	-- Tiberium Troopers
	elseif strfind(tostring(x), "157B3FF8") ~= nil then
		ans = 5*delay1
	-- Ascended Squad
	elseif strfind(tostring(x), "CEE03DE9") ~= nil then
		ans = 3*delay1
	-- Decimator Cyborgs
	elseif strfind(tostring(x), "BF15A95E") ~= nil then
		ans = 2*delay5

	-- Alien Infantry
	-- Disintigrators
	elseif strfind(tostring(x), "2B9428D0") ~= nil then
		ans = 5*delay5
	-- Shock Troopers
	elseif strfind(tostring(x), "6495F509") ~= nil then
		ans = 3*delay5
	-- Ravagers
	elseif strfind(tostring(x), "D6D1E79A") ~= nil then
		ans = 3*delay5
	-- Terminators
	elseif strfind(tostring(x), "D8D33555") ~= nil then
		ans = 3*delay5
	-- Cultists
	elseif strfind(tostring(x), "D6D67027") ~= nil then
		ans = 4*delay5
	-- Seismic Troopers
	elseif strfind(tostring(x), "87AC5812") ~= nil then
		ans = 3*delay5

	-- Mutant Infantry
	-- Mutant Marauders
	elseif strfind(tostring(x), "1AF4B91") ~= nil then
		ans = 5*delay5
	-- Mutant Fiends
	elseif strfind(tostring(x), "F5D5BCD2") ~= nil then
		ans = 3*delay5
	-- Mutant Viceroids
	elseif strfind(tostring(x), "EAAE1E11") ~= nil then
		ans = 5*delay5
	-- Mutant Sentinels
	elseif strfind(tostring(x), "8F2FA9FD") ~= nil then
		ans = 4*delay5
	-- Mutant Skirmishers
	elseif strfind(tostring(x), "498A2D0E") ~= nil then
		ans = 2*delay5
	end
	return ans
end

-- When squad appears at Barracks
function OnSquadAppearingAtBarracks(self)
	local c = GetFrame()
	local a = ObjectDescription(self)
	squadtable[a] = c
end

-- When squad finishes leaving Barracks
function OnSquadExitingBarracks(self)
	local c = GetFrame()
	local a = ObjectDescription(self)
	if squadtable[a] ~= nil then
		local diff = c - squadtable[a]
		if diff < SquadLookupTable(ObjectTemplateName(self)) then
			ExecuteAction("NAMED_DELETE", self);
		end
		squadtable[a] = nil
	end
end

function OnSquadDestroyed(self)
	local a = ObjectDescription(self)
	squadtable[a] = nil
end

function OnGenericHarvesterCreated(self)
	local a = getObjectId(self)
	harvredtib[a] = 0
	harvbluetib[a] = 0
	harvgreentib[a] = 0
end

function OnHarvesterHarvesting(self)
	if ObjectHasUpgrade(self, "Upgrade_UpgradeRedTib") == 0 and ObjectTestModelCondition(self, "USER_16") == true then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeRedTib")
	elseif
		ObjectHasUpgrade(self, "Upgrade_UpgradeRedTib") and ObjectTestModelCondition(self, "USER_16") == false then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedTib")
	elseif
		ObjectHasUpgrade(self, "Upgrade_UpgradeBlueTib") == 0 and ObjectTestModelCondition(self, "USER_15") == true then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueTib")
	elseif
		ObjectHasUpgrade(self, "Upgrade_UpgradeBlueTib") and ObjectTestModelCondition(self, "USER_15") == false then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueTib")
	elseif
		ObjectHasUpgrade(self, "Upgrade_UpgradeGreenTib") == 0 and ObjectTestModelCondition(self, "USER_14") == true then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenTib")
	elseif
		ObjectHasUpgrade(self, "Upgrade_UpgradeGreenTib") and ObjectTestModelCondition(self, "USER_14") == false then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenTib")
	end
end

function OffMoney0(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedOne")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueOne")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenOne")
			if bar1[a] == 2 then harvredtib[a] = harvredtib[a] - 1
			elseif bar1[a] == 1 then harvbluetib[a] = harvbluetib[a] - 1
			elseif bar1[a] == 0 then harvgreentib[a] = harvgreentib[a] - 1
		end
	end
end

function OffMoney1(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedTwo")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueTwo")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenTwo")
			if bar2[a] == 2 then harvredtib[a] = harvredtib[a] - 1
			elseif bar2[a] == 1 then harvbluetib[a] = harvbluetib[a] - 1
			elseif bar2[a] == 0 then harvgreentib[a] = harvgreentib[a] - 1
		end
	end
end

function OffMoney2(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedThree")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueThree")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenThree")
			if bar3[a] == 2 then harvredtib[a] = harvredtib[a] - 1
			elseif bar3[a] == 1 then harvbluetib[a] = harvbluetib[a] - 1
			elseif bar3[a] == 0 then harvgreentib[a] = harvgreentib[a] - 1
		end
	end
end

function OffMoney3(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedFour")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueFour")
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenFour") 
			if bar4[a] == 2 then harvredtib[a] = harvredtib[a] - 1
			elseif bar4[a] == 1 then harvbluetib[a] = harvbluetib[a] - 1
			elseif bar4[a] == 0 then harvgreentib[a] = harvgreentib[a] - 1
		end
	end
end

function OnMoney1(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if ObjectTestModelCondition(self, "USER_16") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedOne")
			harvredtib[a] = harvredtib[a] + 1
			bar1[a] = 2
		elseif ObjectTestModelCondition(self, "USER_15") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueOne")
			harvbluetib[a] = harvbluetib[a] + 1
			bar1[a] = 1
		elseif ObjectTestModelCondition(self, "USER_14") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenOne")
			harvgreentib[a] = harvgreentib[a] + 1
			bar1[a] = 0
		end
	end
end

function OnMoney2(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if ObjectTestModelCondition(self, "USER_16") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedTwo")
			harvredtib[a] = harvredtib[a] + 1
			bar2[a] = 2
		elseif ObjectTestModelCondition(self, "USER_15") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueTwo")
			harvbluetib[a] = harvbluetib[a] + 1
			bar2[a] = 1
		elseif ObjectTestModelCondition(self, "USER_14") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenTwo")
			harvgreentib[a] = harvgreentib[a] + 1
			bar2[a] = 0
		end
	end
end

function OnMoney3(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if ObjectTestModelCondition(self, "USER_16") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedThree")
			harvredtib[a] = harvredtib[a] + 1
			bar3[a] = 2
		elseif ObjectTestModelCondition(self, "USER_15") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueThree")
			harvbluetib[a] = harvbluetib[a] + 1
			bar3[a] = 1
		elseif ObjectTestModelCondition(self, "USER_14") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenThree")
			harvgreentib[a] = harvgreentib[a] + 1
			bar3[a] = 0
		end
	end
end

function OnMoney4(self)
	local a = getObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if ObjectTestModelCondition(self, "USER_16") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedFour")
			harvredtib[a] = harvredtib[a] + 1
			bar4[a] = 2
		elseif ObjectTestModelCondition(self, "USER_15") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueFour")
			harvbluetib[a] = harvbluetib[a] + 1
			bar4[a] = 1
		elseif ObjectTestModelCondition(self, "USER_14") then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenFour")
			harvgreentib[a] = harvgreentib[a] + 1
			bar4[a] = 0
		end
	end
end

function OnGenericHarvesterDeath(self)
	local a = getObjectId(self)
	if harvredtib[a] >= 2 then
		harvredtib[a] = nil
		harvbluetib[a] = nil
		harvgreentib[a] = nil
		bar1[a] = nil
		bar2[a] = nil
		bar3[a] = nil
		bar4[a] = nil
		ObjectCreateAndFireTempWeapon(self, "DeployRedTiberium")
	elseif harvbluetib[a] >= 2 then
		harvredtib[a] = nil
		harvbluetib[a] = nil
		harvgreentib[a] = nil
		bar1[a] = nil
		bar2[a] = nil
		bar3[a] = nil
		bar4[a] = nil
		ObjectCreateAndFireTempWeapon(self, "DeployBlueTiberium")
	elseif harvgreentib[a] > 0 or harvbluetib[a] == 1 or harvredtib[a] == 1 then
		harvredtib[a] = nil
		harvbluetib[a] = nil
		harvgreentib[a] = nil
		bar1[a] = nil
		bar2[a] = nil
		bar3[a] = nil
		bar4[a] = nil
		ObjectCreateAndFireTempWeapon(self, "DeployGreenTiberium")
	end
end

function getObjectId(x)
	return strsub(ObjectDescription(x),strfind(ObjectDescription(x),'t')+2,strfind(ObjectDescription(x),'%[')-2)
end