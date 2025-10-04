SquadTable = {} -- Tracks all squad objects on the map

-- Global tables for tracking Harvester and Tiberium state
HarvRedTib = {}			-- For counting the Red Tiberium in the Harvester
HarvBlueTib = {}		-- For counting the Blue Tiberium in the Harvester
HarvGreenTib = {}		-- For counting the Green Tiberium in the Harvester

Bar1 = {}				-- For tracking the first bar of the Harvester
Bar2 = {}				-- For tracking the second bar of the Harvester
Bar3 = {}				-- For tracking the third bar of the Harvester
Bar4 = {}				-- For tracking the fourth bar of the Harvester

HarvesterDataTable = {}
CrystalDataTable = {}

MaxFramesWhenNotHarvested = 900			-- 60s
MaxFramesBeingHarvested = 33			-- 15 frames is 1s (Harvest action time is 2.2s -> 33 frames)
PerHarvestOffset = 4					-- Subtract frames for each time the Harvester is ordered to stop and harvest the same crystal again

-- Get the hash of the aircraft unit
UnitType = {["3006676643"] = "GDIFireHawk", ["1789238550"] = "NODVertigo", ["3755615724"] = "NODBanshee"}
-- Get the total ammo count of the aircraft unit
UnitAmmoSize = {["GDIFireHawk"] = 4, ["NODVertigo"] = 1, ["NODBanshee"] = 4}
-- Second array to store the ammo in when unit fires, until it reaches 0, then the conditions fire to disable AI control
UnitAmmoCount = {}

--- EA lua functions
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

-- FIRESTORM LUA FUNCTIONS
function OnMutantViceroidCreated(self)
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
end

function onCreatedForbidCommands(self)
	ObjectForbidPlayerCommands( self, true )
end

function onAlienMCVUnpackingCreated(self)
	ObjectSetObjectStatus( self, "UNSELECTABLE" )
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

function OnNODMilitantIsConfessor(self)
	ObjectGrantUpgrade( self, "Upgrade_MilitantIsConfessor" )
end

function OnNODAttackBikeCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILEL", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER", true )
end

function OnNODRedeemerWarmechCreated(self)
	ObjectHideSubObjectPermanently( self, "FX_LAZERGLOWHEROIC", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILEL", true )
end

function OnNODReaperCreated(self)
	ObjectHideSubObjectPermanently( self, "FX_LAZERGLOWHEROIC", true )
end

function OnNODCyborgInfantryCreated(self)
	ObjectHideSubObjectPermanently( self, "WEAPON_EMP", true )
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
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
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

function OnUnitCreatedSetRider1(self)
	ObjectSetObjectStatus ( self, "RIDER1" )
end

function OnUnitCreatedSetRider2(self)
	ObjectSetObjectStatus ( self, "RIDER2" )
end

function OnNODPowerPlantCreated(self)
	ObjectSetObjectStatus ( self, "RIDER1" )
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

function OnPVEGameModeObjectUpgrade(self)
	if ObjectTestModelCondition(self, "USER_45") then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
	end
end

function OnPVEGameModePlayerUpgrade(self)
	if ObjectHasUpgrade ( self, "Upgrade_PVEGameModePlayer" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
	end
end

function OnPVEGameModeCmdSetHackObjectUpgrade(self)
	if ObjectTestModelCondition(self, "USER_45") then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModePlayerCmdSetHack" )
	end
end

function OnPVEGameModeCmdSetHackPlayerUpgrade(self)
	if ObjectHasUpgrade ( self, "Upgrade_PVEGameModePlayer" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModePlayerCmdSetHack" )
	end
end

function OnPVEGameModeCapDelayHackObjectUpgrade(self)
	if ObjectTestModelCondition(self, "USER_45") then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModePlayerCapDelayHack" )
	end
end

function OnPVEGameModeCapDelayHackPlayerUpgrade(self)
	if ObjectHasUpgrade ( self, "Upgrade_PVEGameModePlayer" ) == 1 then
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModeObject" )
		ObjectGrantUpgrade ( self, "Upgrade_PVEGameModePlayerCapDelayHack" )
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
		squadDelay = 6*delay1
	-- Missile Squad
	elseif strfind(tostring(x), "EF1252DB") ~= nil then
		squadDelay = 2*delay1
	-- Grenadier Squad
	elseif strfind(tostring(x), "42896060") ~= nil then
		squadDelay = 4*delay1
	-- Sniper Team
	elseif strfind(tostring(x), "BCB36A05") ~= nil then
		squadDelay = 2*delay1
	-- Combat Medic Team
	elseif strfind(tostring(x), "81C1827B") ~= nil then
		squadDelay = 3*delay1
	-- Zone Troopers
	elseif strfind(tostring(x), "5D5E5931") ~= nil then
		squadDelay = 4*delay1
	-- Zone Raiders
	elseif strfind(tostring(x), "2D1766F8") ~= nil then
		squadDelay = 4*delay1
	-- Zone Defenders
	elseif strfind(tostring(x), "FCFB2118") ~= nil then
		squadDelay = 4*delay5

	-- NOD Infantry
	-- Militant Squad
	elseif strfind(tostring(x), "BC36257A") ~= nil then
		squadDelay = 7*delay1
	-- Militant Rocket Squad
	elseif strfind(tostring(x), "89C45844") ~= nil then
		squadDelay = 2*delay1
	-- Fanatics
	elseif strfind(tostring(x), "BE7C389D") ~= nil then
		squadDelay = 5*delay1
	-- Black Hand Squad
	elseif strfind(tostring(x), "128ABF1") ~= nil then
		squadDelay = 6*delay1
	-- Confessor Squad
	elseif strfind(tostring(x), "AB1BD4E2") ~= nil then
		squadDelay = 6*delay1
	-- Shadow Team
	elseif strfind(tostring(x), "A6E10008") ~= nil then
		squadDelay = 5*delay1
	-- Cyborg Gunners
	elseif strfind(tostring(x), "346EDC73") ~= nil then
		squadDelay = 3*delay1
	-- Tiberium Troopers
	elseif strfind(tostring(x), "157B3FF8") ~= nil then
		squadDelay = 5*delay1
	-- Ascended Squad
	elseif strfind(tostring(x), "CEE03DE9") ~= nil then
		squadDelay = 3*delay1
	-- Decimator Cyborgs
	elseif strfind(tostring(x), "BF15A95E") ~= nil then
		squadDelay = 2*delay5

	-- Alien Infantry
	-- Disintigrators
	elseif strfind(tostring(x), "2B9428D0") ~= nil then
		squadDelay = 5*delay5
	-- Shock Troopers
	elseif strfind(tostring(x), "6495F509") ~= nil then
		squadDelay = 3*delay5
	-- Ravagers
	elseif strfind(tostring(x), "D6D1E79A") ~= nil then
		squadDelay = 3*delay5
	-- Terminators
	elseif strfind(tostring(x), "D8D33555") ~= nil then
		squadDelay = 3*delay5
	-- Cultists
	elseif strfind(tostring(x), "D6D67027") ~= nil then
		squadDelay = 4*delay5
	-- Seismic Troopers
	elseif strfind(tostring(x), "87AC5812") ~= nil then
		squadDelay = 3*delay5

	-- Mutant Infantry
	-- Mutant Marauders
	elseif strfind(tostring(x), "1AF4B91") ~= nil then
		squadDelay = 5*delay5
	-- Mutant Fiends
	elseif strfind(tostring(x), "F5D5BCD2") ~= nil then
		squadDelay = 3*delay5
	-- Mutant Viceroids
	elseif strfind(tostring(x), "EAAE1E11") ~= nil then
		squadDelay = 5*delay5
	-- Mutant Skirmishers
	elseif strfind(tostring(x), "498A2D0E") ~= nil then
		squadDelay = 2*delay5
	end
	return squadDelay
end

-- When squad appears at Barracks
function OnSquadAppearingAtBarracks(self)
	local curFrame = GetFrame()
	local squadType = ObjectDescription(self)
	SquadTable[squadType] = curFrame
end

-- When squad finishes leaving Barracks
function OnSquadExitingBarracks(self)
	local curFrame = GetFrame()
	local squadType = ObjectDescription(self)
	if SquadTable[squadType] ~= nil then
		local diff = curFrame - SquadTable[squadType]
		if diff < SquadLookupTable(ObjectTemplateName(self)) then
			ExecuteAction("NAMED_DELETE", self);
		end
		SquadTable[squadType] = nil
	end
end

function OnSquadDestroyed(self)
	local squadType = ObjectDescription(self)
	SquadTable[squadType] = nil
end

-- self is the crystal, other is the harvester
function OnTiberiumCrystalHarvested(self, other)
	local harvRef, harvData = GetHarvesterData(other)
	local crystalData = GetcrystalData(self)
	local ObjectStringRef = "object_" .. harvRef
    ExecuteAction("SET_UNIT_REFERENCE", ObjectStringRef , self)

	-- if IS_BEING_HARVESTED is true and the harvester is not already harvesting nor crystal is the crystal also being harvested
	if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", ObjectStringRef , 116) and not harvData.isAlreadyHarvesting and crystalData.beingHarvestedBy == nil then

		-- Remove all Tib FX for a clean state
		if ObjectHasUpgrade(other, "Upgrade_UpgradeRedTib") then
			ObjectRemoveUpgrade(other, "Upgrade_UpgradeRedTib")
		end
		-- Remove the Blue Tib FX
		if ObjectHasUpgrade(other, "Upgrade_UpgradeBlueTib") then
			ObjectRemoveUpgrade(other, "Upgrade_UpgradeBlueTib")
		end
		-- Remove the Green Tib FX
		if ObjectHasUpgrade(other, "Upgrade_UpgradeGreenTib") then
			ObjectRemoveUpgrade(other, "Upgrade_UpgradeGreenTib")
		end

		-- assign the crystal this harvester is currently harvesting to the table
		harvData.crystalCurrentlyHarvesting = self

		-- Red tiberium check
		if strfind(ObjectDescription(self), "3E2065DC") ~= nil or strfind(ObjectDescription(self), "C65F97F8") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalRed") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalRedNoStageGrowth") ~= nil then
			harvData.tiberiumTypeHarvested = "Red"
			ObjectGrantUpgrade(other, "Upgrade_UpgradeRedTib")
		-- Blue tiberium check
		elseif strfind(ObjectDescription(self), "BA9F66AB") ~= nil or strfind(ObjectDescription(self), "88569083") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalBlue") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalBlueNoStageGrowth") ~= nil then
			harvData.tiberiumTypeHarvested = "Blue"
			ObjectGrantUpgrade(other, "Upgrade_UpgradeBlueTib")
		-- Green tiberium check
		elseif strfind(ObjectDescription(self), "F80E808") ~= nil or strfind(ObjectDescription(self), "E54FDB2E") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystal") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalNoStageGrowth") ~= nil then
			harvData.tiberiumTypeHarvested = "Green"
			ObjectGrantUpgrade(other, "Upgrade_UpgradeGreenTib")
		end

		harvData.isAlreadyHarvesting = true
		crystalData.beingHarvestedBy = ObjectDescription(other)
		OnHarvestTimeUpdated(other)
	end
end

function OnHarvestTimeUpdated(self)
	local harvRef, harvData = GetHarvesterData(self)
	local crystal = harvData.crystalCurrentlyHarvesting

	if crystal then
		local crystalData = GetcrystalData(crystal)
		crystalData.firstHarvestedFrame = GetFrame()

		if crystalData.lastHarvestedFrame ~= nil then
			if (GetFrame() - crystalData.lastHarvestedFrame) > MaxFramesWhenNotHarvested then
				-- reset harvested frames
				crystalData.framesBeingHarvested = 0
				crystalData.lastHarvestedFrame = nil
			end
		end
	end
end

function OnHarvestedCrystalTypeCleared(self)
	local harvRef, harvData = GetHarvesterData(self)
	harvData.isAlreadyHarvesting = false
	-- count frames for the crystal harvested
	OffTiberiumHarvested(harvData.crystalCurrentlyHarvesting)
end

function OnMoney1(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if HarvesterDataTable[harvId].tiberiumTypeHarvested == "Red" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedOne")
			HarvRedTib[harvId] = HarvRedTib[harvId] + 1
			Bar1[harvId] = 2
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Blue" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueOne")
			HarvBlueTib[harvId] = HarvBlueTib[harvId] + 1
			Bar1[harvId] = 1
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Green" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenOne")
			HarvGreenTib[harvId] = HarvGreenTib[harvId] + 1
			Bar1[harvId] = 0
		end
	end
end

function OnMoney2(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if HarvesterDataTable[harvId].tiberiumTypeHarvested == "Red" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedTwo")
			HarvRedTib[harvId] = HarvRedTib[harvId] + 1
			Bar2[harvId] = 2
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Blue" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueTwo")
			HarvBlueTib[harvId] = HarvBlueTib[harvId] + 1
			Bar2[harvId] = 1
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Green" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenTwo")
			HarvGreenTib[harvId] = HarvGreenTib[harvId] + 1
			Bar2[harvId] = 0
		end
	end
end

function OnMoney3(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if HarvesterDataTable[harvId].tiberiumTypeHarvested == "Red" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedThree")
			HarvRedTib[harvId] = HarvRedTib[harvId] + 1
			Bar3[harvId] = 2
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Blue" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueThree")
			HarvBlueTib[harvId] = HarvBlueTib[harvId] + 1
			Bar3[harvId] = 1
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Green" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenThree")
			HarvGreenTib[harvId] = HarvGreenTib[harvId] + 1
			Bar3[harvId] = 0
		end
	end
end

function OnMoney4(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if HarvesterDataTable[harvId].tiberiumTypeHarvested == "Red" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeRedFour")
			HarvRedTib[harvId] = HarvRedTib[harvId] + 1
			Bar4[harvId] = 2
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Blue" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueFour")
			HarvBlueTib[harvId] = HarvBlueTib[harvId] + 1
			Bar4[harvId] = 1
		elseif HarvesterDataTable[harvId].tiberiumTypeHarvested == "Green" then
			ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenFour")
			HarvGreenTib[harvId] = HarvGreenTib[harvId] + 1
			Bar4[harvId] = 0
		end
	end
end

function OffMoney1(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		if ObjectHasUpgrade(self, "Upgrade_UpgradeRedOne") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedOne") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeBlueOne") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueOne") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeGreenOne") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenOne") end
		if Bar1[harvId] == 2 then HarvRedTib[harvId] = HarvRedTib[harvId] - 1
		elseif Bar1[harvId] == 1 then HarvBlueTib[harvId] = HarvBlueTib[harvId] - 1
		elseif Bar1[harvId] == 0 then HarvGreenTib[harvId] = HarvGreenTib[harvId] - 1
		end
	end
end

function OffMoney2(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		if ObjectHasUpgrade(self, "Upgrade_UpgradeRedTwo") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedTwo") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeBlueTwo") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueTwo") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeGreenTwo") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenTwo") end
		if Bar2[harvId] == 2 then HarvRedTib[harvId] = HarvRedTib[harvId] - 1
		elseif Bar2[harvId] == 1 then HarvBlueTib[harvId] = HarvBlueTib[harvId] - 1
		elseif Bar2[harvId] == 0 then HarvGreenTib[harvId] = HarvGreenTib[harvId] - 1
		end
	end
end

function OffMoney3(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		if ObjectHasUpgrade(self, "Upgrade_UpgradeRedThree") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedThree") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeBlueThree") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueThree") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeGreenThree") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenThree") end
		if Bar3[harvId] == 2 then HarvRedTib[harvId] = HarvRedTib[harvId] - 1
		elseif Bar3[harvId] == 1 then HarvBlueTib[harvId] = HarvBlueTib[harvId] - 1
		elseif Bar3[harvId] == 0 then HarvGreenTib[harvId] = HarvGreenTib[harvId] - 1
		end
	end
end

function OffMoney4(self)
	local harvId = GetObjectId(self)
	if ObjectTestModelCondition(self, "DOCKING") then
		if ObjectHasUpgrade(self, "Upgrade_UpgradeRedFour") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedFour") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeBlueFour") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueFour") end
		if ObjectHasUpgrade(self, "Upgrade_UpgradeGreenFour") then ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenFour") end
		if Bar4[harvId] == 2 then HarvRedTib[harvId] = HarvRedTib[harvId] - 1
		elseif Bar4[harvId] == 1 then HarvBlueTib[harvId] = HarvBlueTib[harvId] - 1
		elseif Bar4[harvId] == 0 then HarvGreenTib[harvId] = HarvGreenTib[harvId] - 1
		end
	end
end

function OnHarvesterCreated(self)
	local harvRef, harvData = GetHarvesterData(self)
	HarvRedTib[harvRef] = 0
	HarvBlueTib[harvRef] = 0
	HarvGreenTib[harvRef] = 0
end

function OnHarvesterDeath(self)
	local harvId = GetObjectId(self)

	if HarvRedTib[harvId] >= 2 then
		ObjectCreateAndFireTempWeapon(self, "DeployRedTiberium")
	elseif HarvBlueTib[harvId] >= 2 then
		ObjectCreateAndFireTempWeapon(self, "DeployBlueTiberium")
	elseif HarvGreenTib[harvId] > 0 or HarvBlueTib[harvId] == 1 or HarvRedTib[harvId] == 1 then
		ObjectCreateAndFireTempWeapon(self, "DeployGreenTiberium")
	end

	HarvRedTib[harvId] = nil
	HarvBlueTib[harvId] = nil
	HarvGreenTib[harvId] = nil
	Bar1[harvId] = nil
	Bar2[harvId] = nil
	Bar3[harvId] = nil
	Bar4[harvId] = nil
	HarvesterDataTable[harvId] = nil
end

-- ####################### TIBERIUM EXPLOIT FIX ############################

-- this function assigns the frame when the harvester harvests it.
function OnHarvestingTiberiumCrystal(self)
	ObjectBroadcastEventToUnits(self, "TiberiumCrystalEvent", 75)
end

function GetHarvesterData(self)
	local harvId = GetObjectId(self)
	HarvesterDataTable[harvId] = HarvesterDataTable[harvId] or {
		tiberiumTypeHarvested = nil, -- the tib type being harvested
		isAlreadyHarvesting = false, -- the harvester is already harvesting
		crystalCurrentlyHarvesting = nil -- object reference to the last crystal harvested
	}
	return harvId, HarvesterDataTable[harvId]
end

function GetcrystalData(self)
	local crystalId = GetObjectId(self)
	CrystalDataTable[crystalId] = CrystalDataTable[crystalId] or {
		firstHarvestedFrame = 0, -- the frame where the crystal begins to be harvested
		lastHarvestedFrame = nil, -- the frame where the crystal finishes being harvested
		framesBeingHarvested = 0, -- the amount of frames the crystal has been harvested
		crystalHasBeenReset = false, -- the crystal has undergone a reset
		dontKillCrystal = false, -- flag to prevent the crystal from being killed with NAMED_KILL
		beingHarvestedBy = nil -- harvester thats currently harvesting this crystal
	}
	return CrystalDataTable[crystalId]
end

-- checks if the crystal has been harvested longer than the maximum frames and if it doesn't have a flag assigned, it kills it.
function OffTiberiumHarvested(self)
	local crystalData = GetcrystalData(self)
	local curFrame = GetFrame()

	-- if dontKillCrystal is false increment the framesBeingHarvested
	if not crystalData.dontKillCrystal then
		local diff = curFrame - crystalData.firstHarvestedFrame - PerHarvestOffset

		-- the lower diff is, the more the crystal has been repeatedly harvested
		if diff <= -3 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 6
		elseif diff <= -2 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 5
		elseif diff <= -1 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 4
		elseif diff <= 0 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 3
		elseif diff <= 1 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 2
		elseif diff <= 2 then
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff + 1
		else
			crystalData.framesBeingHarvested = crystalData.framesBeingHarvested + diff
		end
	end
	-- time since last harvest
	crystalData.lastHarvestedFrame = curFrame
	crystalData.beingHarvestedBy = nil

	if crystalData.framesBeingHarvested >= MaxFramesBeingHarvested and not crystalData.crystalHasBeenReset and not crystalData.dontKillCrystal then
		-- prevent death FX in FXListBehaviour
		ObjectSetObjectStatus(self, "RIDER1")
		-- cleanup
		CrystalDataTable[GetObjectId(self)] = nil
		ExecuteAction("NAMED_KILL", self)
		return
	end

	-- reset dontKillCrystal if its set to true
	crystalData.dontKillCrystal = false

	-- reset flag if time since last harvest is more than MaxFramesWhenNotHarvested
	if (GetFrame() - crystalData.lastHarvestedFrame) <= MaxFramesWhenNotHarvested then
		crystalData.crystalHasBeenReset = false
	else
		crystalData.crystalHasBeenReset = true
	end
end

-- when the crystal is completely harvested and not killed, clear the crystalData element
function OffTiberiumGrowing(self)
	-- clear it
	CrystalDataTable[GetObjectId(self)] = nil
end

function GetObjectId(x)
	return strsub(ObjectDescription(x),strfind(ObjectDescription(x),'t')+2,strfind(ObjectDescription(x),'%[')-2) -- Object id
end