squadTable = {} -- Tracks all squad objects on the map

unitType = { -- Get the hash of the aircraft unit
	["3006676643"] = "GDIFireHawk",
	["1789238550"] = "NODVertigo",
	["3755615724"] = "NODBanshee"
}

unitAmmoSize = { -- Get the total ammo count of the aircraft unit
	["GDIFireHawk"] = 6,
	["NODVertigo"] = 1,
	["NODBanshee"] = 8
}

unitAmmoCount = {} -- Third array to store the ammo in when unit fires, until it reaches 0, then the conditions fire to disable AI control

harvRedTib = {} -- For counting the Red Tiberium in the Harvester
harvBlueTib = {} -- For counting the Blue Tiberium in the Harvester
harvGreenTib = {} -- For counting the Green Tiberium in the Harvester

bar1 = {} -- For tracking the first bar of the Harvester
bar2 = {} -- For tracking the second bar of the Harvester
bar3 = {} -- For tracking the third bar of the Harvester
bar4 = {} -- For tracking the fourth bar of the Harvester

harvesterDataTable = {}
crystalDataTable = {}

MAX_HARVEST_CHAIN_RESET_GAP = 900 -- 60s
MAX_CRYSTAL_KILL_THRESHOLD = 33 -- 15 frames is 1s (Harvest action time is 2.2s -> 33 frames)
PER_HARVEST_OFFSET = 4 -- Subtract frames for each time the Harvester is ordered to stop and harvest the same crystal again

-- =========================================================
-- SHARED HELPERS
-- =========================================================

function getObjectId(x)
	if x == nil then
		return nil
	end

	local desc = ObjectDescription(x)
	if desc == nil then
		return nil
	end

	desc = tostring(desc)

	if desc == "" or desc == "<No Object>" then
		return nil
	end

	local tPos = strfind(desc, "t")
	local bPos = strfind(desc, "%[")

	if tPos == nil or bPos == nil then
		return nil
	end

	return strsub(desc, tPos + 2, bPos - 2)
end

function ClampNonNegative(value)
	if value == nil or value < 0 then
		return 0
	end

	return value
end

function FlushSubTable(t, seen)
	if t == nil or type(t) ~= "table" then
		return
	end

	if seen[t] then
		return
	end
	seen[t] = 1

	for k, v in t do
		if type(v) == "table" then
			FlushSubTable(v, seen)
		end
		t[k] = nil
	end
end

function FlushTable(t)
	if t == nil or type(t) ~= "table" then
		return
	end

	FlushSubTable(t, {})
end

-- =========================================================
-- FULL STATE RESET
-- =========================================================

-- Function to flush all tables' data to prevent desyncs, triggered via the GenericCrateSpawner, as it exists on every map
function OnGenericCrateSpawnerCreated()
	FlushTable(squadTable)

	FlushTable(unitAmmoCount)

	FlushTable(harvRedTib)
	FlushTable(harvBlueTib)
	FlushTable(harvGreenTib)

	FlushTable(bar1)
	FlushTable(bar2)
	FlushTable(bar3)
	FlushTable(bar4)

	FlushTable(harvesterDataTable)
	FlushTable(crystalDataTable)

	collectgarbage()
end

-- =========================================================
-- EA LUA FUNCTIONS
-- =========================================================

function NoOp(self, source)
end

function kill(self)
	ExecuteAction("NAMED_KILL", self)
end

function RadiateUncontrollableFear(self)
	ObjectBroadcastEventToEnemies(self, "BeUncontrollablyAfraid", 350)
end

function RadiateGateDamageFear(self)
	ObjectBroadcastEventToAllies(self, "BeAfraidOfGateDamaged", 200)
end

function OnNeutralGarrisonableBuildingCreated(self)
	ObjectHideSubObjectPermanently(self, "ARMOR", true)
end

function OnCreatedControlPointFunctions(self)
	ObjectHideSubObjectPermanently(self, "TB_CP_ALN", true)
	ObjectHideSubObjectPermanently(self, "TB_CP_GDI", true)
	ObjectHideSubObjectPermanently(self, "TB_CP_NOD", true)
	ObjectHideSubObjectPermanently(self, "LIGHTSF01", true)
	ObjectHideSubObjectPermanently(self, "100", false)
	ObjectHideSubObjectPermanently(self, "75", false)
	ObjectHideSubObjectPermanently(self, "50", false)
	ObjectHideSubObjectPermanently(self, "25", false)
end

function GoIntoRampage(self)
	ObjectEnterRampageState(self)

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

	ObjectEnterCowerState(self, other)
end

function ChantForUnit(self)
	ObjectBroadcastEventToAllies(self, "BeginChanting", 9999)
end

function StopChantForUnit(self)
	ObjectBroadcastEventToAllies(self, "StopChanting", 9999)
end

function SpyMoving(self, other)
	print(ObjectDescription(self) .. " spying movement of " .. ObjectDescription(other))
end

function OnGarrisonableCreated(self)
	ObjectHideSubObjectPermanently(self, "GARRISON01", true)
	ObjectHideSubObjectPermanently(self, "GARRISON02", true)
end

function OnRubbleDropshipCreated(self)
	ObjectHideSubObjectPermanently(self, "Loadref", true)
end

-- =========================================================
-- FIRESTORM LUA FUNCTIONS
-- =========================================================

function OnMutantViceroidCreated(self)
	ObjectHideSubObjectPermanently(self, "UGSCANNER", true)
end

function OnMutantAPCCreated(self)
	ObjectHideSubObjectPermanently(self, "BUNKER", true)
end

function OnCreatedForbidCommands(self)
	ObjectForbidPlayerCommands(self, true)
end

function OnUnitCreatedUnselectable(self)
	ObjectSetObjectStatus(self, "UNSELECTABLE")
end

function OnGDITechCenterCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_Mortar", true)
	ObjectHideSubObjectPermanently(self, "UG_Scan", true)
	ObjectHideSubObjectPermanently(self, "UG_Rail", true)
	ObjectHideSubObjectPermanently(self, "B_MortarRound_1", true)
	ObjectHideSubObjectPermanently(self, "UG_Adaptive", true)
	ObjectHideSubObjectPermanently(self, "UG_Adaptive01", true)
	ObjectHideSubObjectPermanently(self, "FXELEC01", true)
	ObjectHideSubObjectPermanently(self, "PLANE02", true)
end

function OnGDITechCenterPowerOutage(self)
	if ObjectHasUpgrade(self, "Upgrade_GDIArmoryRailgunTech") == 1 then
		ObjectHideSubObjectPermanently(self, "FXELEC01", true)
		ObjectHideSubObjectPermanently(self, "PLANE02", true)
	end
end

function OnGDITechCenterPowerRestored(self)
	if ObjectHasUpgrade(self, "Upgrade_GDIArmoryRailgunTech") == 1 then
		ObjectHideSubObjectPermanently(self, "FXELEC01", false)
		ObjectHideSubObjectPermanently(self, "PLANE02", false)
	end
end

function OnGDIAirfieldCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_Hardpoints01", true)
	ObjectHideSubObjectPermanently(self, "UG_Hardpoints", true)
	ObjectHideSubObjectPermanently(self, "UG_Hardpoints03", true)
	ObjectHideSubObjectPermanently(self, "UG_Hardpoints02", true)
	ObjectHideSubObjectPermanently(self, "UG_Boost", true)
end

function OnGDICommandPostCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_Scan", true)
	ObjectHideSubObjectPermanently(self, "UG_StealthDetector", true)
	ObjectHideSubObjectPermanently(self, "UG_StealthDetector01", true)
	ObjectHideSubObjectPermanently(self, "UG_StealthDetector02", true)
	ObjectHideSubObjectPermanently(self, "UG_Scan02", true)
	ObjectHideSubObjectPermanently(self, "UG_APAmmo", true)
	ObjectHideSubObjectPermanently(self, "UG_APAmmo02", true)
	ObjectHideSubObjectPermanently(self, "UG_Scan01", true)
	ObjectHideSubObjectPermanently(self, "UG_APAmmo01", true)
	ObjectHideSubObjectPermanently(self, "UG_StealthDetector03", true)
end

function OnGDICommandPostPowerOutage(self)
	if ObjectHasUpgrade(self, "Upgrade_GDICompositePacks") == 1 then
		ObjectHideSubObjectPermanently(self, "UG_StealthDetector01", true)
	end
end

function OnGDICommandPostPowerRestored(self)
	if ObjectHasUpgrade(self, "Upgrade_GDICompositePacks") == 1 then
		ObjectHideSubObjectPermanently(self, "UG_StealthDetector01", false)
	end
end

function OnGDITankArmoryCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_Injector", true)
	ObjectHideSubObjectPermanently(self, "UG_GRENADEEMP", true)
	ObjectHideSubObjectPermanently(self, "UG_GRENADEEMP01", true)
	ObjectHideSubObjectPermanently(self, "CRATE", true)
end

function OnGDIBattleBaseCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_TURRETL", true)
	ObjectHideSubObjectPermanently(self, "UG_TURRETR", true)
end

function OnGDIWatchTowerCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_BASE", true)
end

function OnGDIRepairDroneCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_TURRET", true)
end

function OnBuildingPowerOutage(self)
	ObjectHideSubObjectPermanently(self, "TV", true)
	ObjectHideSubObjectPermanently(self, "LINKS", true)
	ObjectHideSubObjectPermanently(self, "MESH01", true)
	ObjectHideSubObjectPermanently(self, "MESH28", true)
	ObjectHideSubObjectPermanently(self, "GLOWS", true)
	ObjectHideSubObjectPermanently(self, "FXGLOWS", true)
	ObjectHideSubObjectPermanently(self, "LIGHTL", true)
	ObjectHideSubObjectPermanently(self, "LIGHTR", true)
	ObjectHideSubObjectPermanently(self, "LIGHT_01", true)
	ObjectHideSubObjectPermanently(self, "LIGHT_02", true)
	ObjectHideSubObjectPermanently(self, "LIGHTS", true)
	ObjectHideSubObjectPermanently(self, "LIGHTS1", true)
	ObjectHideSubObjectPermanently(self, "FXLIGHTS", true)
	ObjectHideSubObjectPermanently(self, "FX_LIGHTS", true)
	ObjectHideSubObjectPermanently(self, "FXLIGHTS05", true)
	ObjectHideSubObjectPermanently(self, "FX_LIGHTS01", true)
	ObjectHideSubObjectPermanently(self, "CENTERLIGHTS", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS01", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS02", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS03", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS04", true)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS05", true)
	ObjectHideSubObjectPermanently(self, "POWERPLANTGLOWS", true)
	ObjectHideSubObjectPermanently(self, "NBCHEMICALPTE1", true)
	ObjectHideSubObjectPermanently(self, "AUDRONSHIPLIGHTS", true)
	ObjectHideSubObjectPermanently(self, "NEXUSBEAM", true)
	ObjectHideSubObjectPermanently(self, "NEXUSSTREAM", true)
	ObjectHideSubObjectPermanently(self, "TURBINEGLOWS", true)
end

function OnBuildingPowerRestored(self)
	ObjectHideSubObjectPermanently(self, "TV", false)
	ObjectHideSubObjectPermanently(self, "LINKS", false)
	ObjectHideSubObjectPermanently(self, "MESH01", false)
	ObjectHideSubObjectPermanently(self, "MESH28", false)
	ObjectHideSubObjectPermanently(self, "GLOWS", false)
	ObjectHideSubObjectPermanently(self, "FXGLOWS", false)
	ObjectHideSubObjectPermanently(self, "LIGHTL", false)
	ObjectHideSubObjectPermanently(self, "LIGHTR", false)
	ObjectHideSubObjectPermanently(self, "LIGHT_01", false)
	ObjectHideSubObjectPermanently(self, "LIGHT_02", false)
	ObjectHideSubObjectPermanently(self, "LIGHTS", false)
	ObjectHideSubObjectPermanently(self, "LIGHTS1", false)
	ObjectHideSubObjectPermanently(self, "FXLIGHTS", false)
	ObjectHideSubObjectPermanently(self, "FX_LIGHTS", false)
	ObjectHideSubObjectPermanently(self, "FXLIGHTS05", false)
	ObjectHideSubObjectPermanently(self, "FX_LIGHTS01", false)
	ObjectHideSubObjectPermanently(self, "CENTERLIGHTS", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS01", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS02", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS03", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS04", false)
	ObjectHideSubObjectPermanently(self, "FLASHINGLIGHTS05", false)
	ObjectHideSubObjectPermanently(self, "POWERPLANTGLOWS", false)
	ObjectHideSubObjectPermanently(self, "NBCHEMICALPTE1", false)
	ObjectHideSubObjectPermanently(self, "AUDRONSHIPLIGHTS", false)
	ObjectHideSubObjectPermanently(self, "NEXUSBEAM", false)
	ObjectHideSubObjectPermanently(self, "NEXUSSTREAM", false)
	ObjectHideSubObjectPermanently(self, "TURBINEGLOWS", false)
end

function OnGDIV35Ox_Carrying(self)
	ObjectGrantUpgrade(self, "Upgrade_Transporting")
end

function OnGDIZoneTrooperCreated(self)
	ObjectSetObjectStatus(self, "CAN_SPOT_FOR_BOMBARD")
	ObjectHideSubObjectPermanently(self, "UGINJECTOR", true)
	ObjectHideSubObjectPermanently(self, "UGSCANNER", true)
end

function OnGDIGrenadeSoldierCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_STRAPS", true)
	ObjectHideSubObjectPermanently(self, "UG_GRENADEEMP_PROJECTILE", true)
end

function OnGenericSpotterCreated(self)
	ObjectSetObjectStatus(self, "CAN_SPOT_FOR_BOMBARD")
end

function OnGDIAPCCreated(self)
	ObjectHideSubObjectPermanently(self, "APC_UGAB", true)
	ObjectHideSubObjectPermanently(self, "APC_UGTURRET", true)
end

function OnGDIArmadilloCreated(self)
	ObjectHideSubObjectPermanently(self, "APC_UGAB", true)
end

function OnGDIWolverineCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_AMMO", true)
end

function OnNODHangarCreated(self)
	ObjectHideSubObjectPermanently(self, "DISRUPTIONPODS", true)
	ObjectHideSubObjectPermanently(self, "UG_SIGGEN", true)
	ObjectHideSubObjectPermanently(self, "UG_SIGGEN_02", true)
end

function OnNODOperationsCenterCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_DOZERBLADES", true)
	ObjectHideSubObjectPermanently(self, "UG_SIGGEN", true)
	ObjectHideSubObjectPermanently(self, "UG_QUADTURRETS", true)
end

function OnNODSecretShrineCreated(self)
	ObjectHideSubObjectPermanently(self, "PURIFYINGFLAME02", true)
	ObjectHideSubObjectPermanently(self, "PURIFYINGFLAME01", true)
	ObjectHideSubObjectPermanently(self, "BLACKDISCIPLESUPGRD", true)
	ObjectHideSubObjectPermanently(self, "BLACKDISCIPLES_GLOWS", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_01", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_02", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_03", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_04", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_05", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_06", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_07", true)
	ObjectHideSubObjectPermanently(self, "CYBERNETICLEGS_08", true)
end

function OnNODSecretShrinePowerOutage(self)
	if ObjectHasUpgrade(self, "Upgrade_BlackHandBlackTemplarsUpgrade") == 1 then
		ObjectHideSubObjectPermanently(self, "BLACKDISCIPLES_GLOWS", true)
	end
end

function OnNODSecretShrinePowerRestored(self)
	if ObjectHasUpgrade(self, "Upgrade_BlackHandBlackTemplarsUpgrade") == 1 then
		ObjectHideSubObjectPermanently(self, "BLACKDISCIPLES_GLOWS", false)
	end
end

function OnNODTechAssemblyPlantCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_Lasers", true)
	ObjectHideSubObjectPermanently(self, "UG_EMP", true)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILER02", true)
	ObjectHideSubObjectPermanently(self, "CHARGEDPARTICALBEAM_01", true)
	ObjectHideSubObjectPermanently(self, "CHARGEDPARTICALBEAM_02", true)
	ObjectHideSubObjectPermanently(self, "CHARGEDPARTICALBEAM_03", true)
end

function OnNODCarryall_SummonedForVehicleCreated(self)
	ObjectHideSubObjectPermanently(self, "CARGO", true)
	ObjectSetObjectStatus(self, "UNSELECTABLE")
end

function OnNODVenomCreated(self)
	ObjectHideSubObjectPermanently(self, "SIGGEN", true)
end

function OnNODMilitantIsConfessor(self)
	ObjectGrantUpgrade(self, "Upgrade_MilitantIsConfessor")
end

function OnNODAttackBikeCreated(self)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILEL", true)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILER", true)
end

function OnNODRedeemerWarmechCreated(self)
	ObjectHideSubObjectPermanently(self, "FX_LAZERGLOWHEROIC", true)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILEL", true)
end

function OnNODReaperCreated(self)
	ObjectHideSubObjectPermanently(self, "FX_LAZERGLOWHEROIC", true)
end

function OnNODPummelerCreated(self)
	ObjectHideSubObjectPermanently(self, "WEAPON_EMP", true)
end

function OnNODAvatarCreated(self)
	ObjectHideSubObjectPermanently(self, "WEBLAUNCHER", true)
	ObjectHideSubObjectPermanently(self, "S_GENERATOR", true)
end

function OnNODRaiderTankCreated(self)
	ObjectHideSubObjectPermanently(self, "DOZERBLADE", true)
end

function OnNODScorpionBuggyCreated(self)
	ObjectHideSubObjectPermanently(self, "EMP", true)
end

function OnGDICommandoCreated(self)
	ObjectSetObjectStatus(self, "CAN_SPOT_FOR_BOMBARD")
	ObjectHideSubObjectPermanently(self, "FX_GLOWHEROIC", true)
end

function OnAlienAdvProductionPurchased(self)
	if ObjectHasUpgrade(self, "Upgrade_AdvancedProduction") == 1 then
		ObjectGrantUpgrade(self, "Upgrade_ProductionDummy")
	end
end

function OnGDIHammerheadCreated(self)
	ObjectHideSubObjectPermanently(self, "L_UGAP", true)
	ObjectHideSubObjectPermanently(self, "R_UGAP", true)
	ObjectGrantUpgrade(self, "Upgrade_AirSupremacyDummyUpgrade")
end

function OnGDIAircraftCreated(self)
	ObjectGrantUpgrade(self, "Upgrade_AirSupremacyDummyUpgrade")
end

function OnGDIAirSupremacyPurchased(self)
	ObjectGrantUpgrade(self, "Upgrade_AirSupremacyLevelup")
end

function OnGDIPredatorTankCreated(self)
	ObjectHideSubObjectPermanently(self, "LASER", true)
end

function OnGDIMammothTankCreated(self)
	ObjectHideSubObjectPermanently(self, "LASERPOINTER", true)
	ObjectHideSubObjectPermanently(self, "LASER", true)
end

function OnGDIPaladinTankCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_AMMO", true)
	ObjectHideSubObjectPermanently(self, "LASER", true)
end

function OnAlienMotherShipCreated(self)
	ObjectSetObjectStatus(self, "CAN_SPOT_FOR_BOMBARD")
	ObjectSetObjectStatus(self, "AIRBORNE_TARGET")
end

function OnWeaponSwapNoAttack(self)
	ObjectGrantUpgrade(self, "Upgrade_WeaponSwapNoAttack")
end

function OnWeaponSwapNoAttackEnd(self)
	ObjectRemoveUpgrade(self, "Upgrade_WeaponSwapNoAttack")
end

function OnAlienEradicatorHexapodCreated(self)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_RR", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_RR", true)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_RM", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_RM", true)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_RF", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_RF", true)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_LF", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_LF", true)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_LM", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_LM", true)
	ObjectHideSubObjectPermanently(self, "AUTELEPORT_LR", true)
	ObjectHideSubObjectPermanently(self, "FX_HEALTHRINGS_LR", true)
end

function OnAlienDevastatorWarshipCreated(self)
	ObjectHideSubObjectPermanently(self, "UG_SHARD", true)
end

function OnNODRocketBunkerCreated(self)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILE", true)
	ObjectHideSubObjectPermanently(self, "HOSE", true)
	ObjectHideSubObjectPermanently(self, "TCMHUB_UPGRADE", true)
end

function OnNODRocketBunkerSpawnCreated(self)
	ObjectHideSubObjectPermanently(self, "TIBCOREMISSILE", true)
	ObjectHideSubObjectPermanently(self, "HOSE", true)
end

function OnNODDisruptionModulesUpgradePurchased(self)
	if ObjectHasUpgrade(self, "Upgrade_NODDisruptionModules") == 1 then
		ObjectGrantUpgrade(self, "Upgrade_ActivateDisruptionModule")
	end
end

function OnUnitCreatedSetRider2(self)
	ObjectSetObjectStatus(self, "RIDER2")
end

function OnUnitCreatedSetRider4(self)
	ObjectSetObjectStatus(self, "RIDER4")
end

function OnTibChargeNoAttack(self)
	ObjectGrantUpgrade(self, "Upgrade_TibChargeNoAttack")
end

function OnTibChargeNoAttackEnd(self)
	ObjectRemoveUpgrade(self, "Upgrade_TibChargeNoAttack")
end

function OnNODPropagandaUpgradePurchased(self)
	if ObjectHasUpgrade(self, "Upgrade_PropagandaBuff") == 1 then
		ObjectGrantUpgrade(self, "Upgrade_DummyPropagandaBuff")
	end
end

function OnNODTiberiumInfusionUpgradePurchased(self)
	if ObjectHasUpgrade(self, "Upgrade_TiberiumInfusion") == 1 then
		ObjectGrantUpgrade(self, "Upgrade_TiberiumInfusionDummy")
	end
end

function OnAlienIchorPlatingUpgradePurchased(self)
	if ObjectHasUpgrade(self, "Upgrade_IchorPlating") == 1 then
		ObjectGrantUpgrade(self, "Upgrade_IchorPlatingDummy")
	end
end

function OnPVEGameModeActivated(self)
	if ObjectTestModelCondition(self, "USER_45") then
		ObjectGrantUpgrade(self, "Upgrade_PVEGameModeObject")
		ObjectGrantUpgrade(self, "Upgrade_PVEGameModePlayer")
	end
end

function OnUnitArmorUpgraded(self)
	if ObjectTestModelCondition(self, "USER_21") then
		ObjectGrantUpgrade(self, "Upgrade_ArmorCrateCollected")
	end
end

function OnUnitSpeedUpgraded(self)
	if ObjectTestModelCondition(self, "USER_22") then
		ObjectGrantUpgrade(self, "Upgrade_SpeedCrateCollected")
	end
end

function OnUnitFirepowerUpgraded(self)
	if ObjectTestModelCondition(self, "USER_23") then
		ObjectGrantUpgrade(self, "Upgrade_FirepowerCrateCollected")
	end
end

function OnCloakingCratePickedUp(self)
	if ObjectTestModelCondition(self, "USER_24") then
		ObjectGrantUpgrade(self, "Upgrade_CloakingFieldInvisibility")
	end
end

function OnUnitROFUpgraded(self)
	if ObjectTestModelCondition(self, "USER_25") then
		ObjectGrantUpgrade(self, "Upgrade_ROFCrateCollected")
	end
end

function OnUnitAttackRangeUpgraded(self)
	if ObjectTestModelCondition(self, "USER_26") then
		ObjectGrantUpgrade(self, "Upgrade_AttackRangeCrateCollected")
	end
end

-- =========================================================
-- GENERIC CRATE SPAWNER
-- =========================================================

function GenericCrateSpawnerCheck()
	setcallhook()

	local neutralTeam = "/team"
	local tempRef = "object_" .. tostring(floor(9999999 * GetRandomNumber()))

	ExecuteAction("TEAM_SET_PLAYERS_NEAREST_UNIT_OF_TYPE_TO_REFERENCE", "GenericCrateSpawner", neutralTeam, tempRef)

	if not EvaluateCondition("NAMED_NOT_DESTROYED", tempRef) then
		ExecuteAction("CREATE_OBJECT", "GenericCrateSpawner", neutralTeam, "x=0,y=0,z=0", 0)
	end
end

setcallhook(GenericCrateSpawnerCheck)

-- =========================================================
-- AIRCRAFT AI / AMMO TRACKING
-- =========================================================

function GetAircraftAmmoKey(self)
	return getObjectId(self) or tostring(self)
end

function ResetAircraftAmmo(self)
	local key = GetAircraftAmmoKey(self)
	if key ~= nil then
		unitAmmoCount[key] = nil
	end
end

function OnAircraftAmmoDepleted(self)
	if self == nil or not IsUnitAI(self) then
		return
	end

	local hash = GetObj.Hash(self)
	if hash == nil then
		return
	end

	local unitName = unitType[tostring(hash)]
	if unitName == nil then
		return
	end

	local maxAmmo = unitAmmoSize[unitName]
	if maxAmmo == nil then
		return
	end

	local key = GetAircraftAmmoKey(self)
	if key == nil then
		return
	end

	if unitAmmoCount[key] == nil then
		unitAmmoCount[key] = maxAmmo - 1
	else
		unitAmmoCount[key] = unitAmmoCount[key] - 1
	end

	if unitAmmoCount[key] <= 0 then
		unitAmmoCount[key] = nil
		ExecuteAction("UNIT_AI_TRANSFER", self, 0)
		ExecuteAction("NAMED_FIRE_SPECIAL_POWER", GetObj.String(self), "SpecialPowerReturnToProducer")
	else
		ExecuteAction("UNIT_AI_TRANSFER", self, 1)
	end
end

function OnAircraftCreated(self)
	ResetAircraftAmmo(self)
end

function OnAircraftDestroyed(self)
	ResetAircraftAmmo(self)
end

-- =========================================================
-- SQUAD TRACKING
-- =========================================================

function SquadLookupTable(x)
	local delay1 = 1 -- 1 Second Delay
	local delay5 = 5 -- 5 Second Delay
	local squadDelay = nil

	if strfind(tostring(x), "9096966E") ~= nil then -- GDIRifleSoldierSquad
		squadDelay = 6 * delay1
	elseif strfind(tostring(x), "EF1252DB") ~= nil then -- GDIMissileSoldierSquad
		squadDelay = 2 * delay1
	elseif strfind(tostring(x), "42896060") ~= nil then -- GDIGrenadeSoldierSquad
		squadDelay = 4 * delay1
	elseif strfind(tostring(x), "BCB36A05") ~= nil then -- GDISniperSquad
		squadDelay = 2 * delay1
	elseif strfind(tostring(x), "81C1827B") ~= nil then -- GDIMedicSquad
		squadDelay = 3 * delay1
	elseif strfind(tostring(x), "5D5E5931") ~= nil then -- GDIZoneTrooperSquad
		squadDelay = 4 * delay1
	elseif strfind(tostring(x), "2D1766F8") ~= nil then -- GDIZoneRaiderSquad
		squadDelay = 4 * delay1
	elseif strfind(tostring(x), "FCFB2118") ~= nil then -- GDIZoneDefenderSquad
		squadDelay = 4 * delay5

	elseif strfind(tostring(x), "BC36257A") ~= nil then -- NODMilitantSquad
		squadDelay = 7 * delay1
	elseif strfind(tostring(x), "89C45844") ~= nil then -- NODMilitantRocketSquad
		squadDelay = 2 * delay1
	elseif strfind(tostring(x), "BE7C389D") ~= nil then -- NODFanaticSquad
		squadDelay = 5 * delay1
	elseif strfind(tostring(x), "128ABF1") ~= nil then -- NODBlackHandSquad
		squadDelay = 6 * delay1
	elseif strfind(tostring(x), "A6E10008") ~= nil then -- NODShadowSquad
		squadDelay = 5 * delay1
	elseif strfind(tostring(x), "346EDC73") ~= nil then -- NODCyborgInfantrySquad
		squadDelay = 3 * delay1
	elseif strfind(tostring(x), "157B3FF8") ~= nil then -- NODTiberiumTrooperSquad
		squadDelay = 5 * delay1
	elseif strfind(tostring(x), "4E7D033E") ~= nil then -- NODPummelerSquad
		squadDelay = 3 * delay1
	elseif strfind(tostring(x), "BF15A95E") ~= nil then -- NODDecimatorSquad
		squadDelay = 2 * delay5

	elseif strfind(tostring(x), "2B9428D0") ~= nil then -- AlienRazorDroneSquad
		squadDelay = 6 * delay5
	elseif strfind(tostring(x), "6495F509") ~= nil then -- AlienShockTrooperSquad
		squadDelay = 3 * delay5
	elseif strfind(tostring(x), "D6D1E79A") ~= nil then -- AlienRavagerSquad
		squadDelay = 3 * delay5
	elseif strfind(tostring(x), "69CEE4E7") ~= nil then -- AlienHiveStalkerSquad
		squadDelay = 3 * delay1
	elseif strfind(tostring(x), "D8D33555") ~= nil then -- AlienHunterSquad
		squadDelay = 3 * delay5
	elseif strfind(tostring(x), "D6D67027") ~= nil then -- AlienCultistSquad
		squadDelay = 4 * delay5
	elseif strfind(tostring(x), "87AC5812") ~= nil then -- AlienGroundShakerSquad
		squadDelay = 3 * delay5

	elseif strfind(tostring(x), "1AF4B91") ~= nil then -- MutantMarauderSquad
		squadDelay = 5 * delay5
	elseif strfind(tostring(x), "F5D5BCD2") ~= nil then -- MutantFiendSquad
		squadDelay = 3 * delay5
	elseif strfind(tostring(x), "EAAE1E11") ~= nil then -- MutantViceroidSquad
		squadDelay = 5 * delay5
	elseif strfind(tostring(x), "498A2D0E") ~= nil then -- MutantSkirmisherSquad
		squadDelay = 2 * delay5
	end

	return squadDelay
end

function OnSquadAppearingAtBarracks(self)
	if self == nil then
		return
	end

	local curFrame = GetFrame()
	local squadType = ObjectDescription(self)
	if squadType ~= nil then
		squadTable[squadType] = curFrame
	end
end

function OnSquadExitingBarracks(self)
	if self == nil then
		return
	end

	local curFrame = GetFrame()
	local squadType = ObjectDescription(self)
	if squadType == nil then
		return
	end

	local startFrame = squadTable[squadType]
	if startFrame ~= nil then
		local diff = curFrame - startFrame
		local threshold = SquadLookupTable(ObjectTemplateName(self))

		if threshold ~= nil and diff < threshold then
			ExecuteAction("NAMED_DELETE", self)
		end

		squadTable[squadType] = nil
	end
end

function OnSquadDestroyed(self)
	if self == nil then
		return
	end

	local squadType = ObjectDescription(self)
	if squadType ~= nil then
		squadTable[squadType] = nil
	end
end

-- =========================================================
-- HARVESTER / TIBERIUM STATE
-- =========================================================

-- =========================================================
-- HELPERS
-- =========================================================

function EnsureHarvesterCounters(harvId)
	if harvId == nil then
		return
	end

	harvRedTib[harvId] = harvRedTib[harvId] or 0
	harvBlueTib[harvId] = harvBlueTib[harvId] or 0
	harvGreenTib[harvId] = harvGreenTib[harvId] or 0
end

function CreateHarvesterRuntime()
	return {
		tiberiumTypeHarvested = nil,
		lastTiberiumTypeHarvested = nil,
		isAlreadyHarvesting = false,
		crystalCurrentlyHarvesting = nil,
		currentCrystalId = nil,
		lastCrystalHarvestedId = nil,
		harvestStartFrame = nil,
		harvestChainFrames = 0,
		lastHarvestEndFrame = nil,
	}
end

function GetHarvesterData(self)
	local harvId = getObjectId(self)
	if harvId == nil then
		return nil, nil
	end

	harvesterDataTable[harvId] = harvesterDataTable[harvId] or CreateHarvesterRuntime()

	return harvId, harvesterDataTable[harvId]
end

function GetCrystalData(self)
	local crystalId = getObjectId(self)
	if crystalId == nil then
		return nil, nil
	end

	crystalDataTable[crystalId] = crystalDataTable[crystalId] or {
		beingHarvestedBy = nil,
		firstHarvestedFrame = nil,
		lastHarvestedFrame = nil,
		framesBeingHarvested = 0,
		destroyed = false
	}

	return crystalId, crystalDataTable[crystalId]
end

function ClearCrystalHarvesterBinding(crystal, fallbackCrystalId)
	local crystalId = nil

	if crystal ~= nil then
		crystalId = getObjectId(crystal)
	end

	if crystalId == nil then
		crystalId = fallbackCrystalId
	end

	if crystalId == nil then
		return
	end

	local crystalData = crystalDataTable[crystalId]
	if crystalData ~= nil then
		crystalData.beingHarvestedBy = nil
	end
end

function ResetHarvesterRuntime(harvData)
	if harvData == nil then
		return
	end

	harvData.tiberiumTypeHarvested = nil
	harvData.lastTiberiumTypeHarvested = nil
	harvData.isAlreadyHarvesting = false
	harvData.crystalCurrentlyHarvesting = nil
	harvData.currentCrystalId = nil
	harvData.lastCrystalHarvestedId = nil
	harvData.harvestStartFrame = nil
	harvData.harvestChainFrames = 0
	harvData.lastHarvestEndFrame = nil
end

function DetectTiberiumType(crystal)
	if crystal == nil then
		return nil
	end

	local templateName = ObjectTemplateName(crystal)
	local desc = ObjectDescription(crystal)

	if templateName ~= nil then
		if strfind(templateName, "TiberiumCrystalRed") ~= nil
		or strfind(templateName, "TiberiumCrystalRedNoStageGrowth") ~= nil then
			return "Red"
		elseif strfind(templateName, "TiberiumCrystalBlue") ~= nil
		or strfind(templateName, "TiberiumCrystalBlueNoStageGrowth") ~= nil then
			return "Blue"
		elseif strfind(templateName, "TiberiumCrystal") ~= nil
		or strfind(templateName, "TiberiumCrystalNoStageGrowth") ~= nil then
			return "Green"
		end
	end

	if desc ~= nil then
		if strfind(desc, "3E2065DC") ~= nil
		or strfind(desc, "C65F97F8") ~= nil
		or strfind(desc, "TiberiumCrystalRed") ~= nil
		or strfind(desc, "TiberiumCrystalRedNoStageGrowth") ~= nil then
			return "Red"
		elseif strfind(desc, "BA9F66AB") ~= nil
		or strfind(desc, "88569083") ~= nil
		or strfind(desc, "TiberiumCrystalBlue") ~= nil
		or strfind(desc, "TiberiumCrystalBlueNoStageGrowth") ~= nil then
			return "Blue"
		elseif strfind(desc, "F80E808") ~= nil
		or strfind(desc, "E54FDB2E") ~= nil
		or strfind(desc, "TiberiumCrystal") ~= nil
		or strfind(desc, "TiberiumCrystalNoStageGrowth") ~= nil then
			return "Green"
		end
	end

	return nil
end

function ClearHarvesterTibFX(self)
	if self == nil then
		return
	end

	if ObjectHasUpgrade(self, "Upgrade_UpgradeRedTib") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeRedTib")
	end
	if ObjectHasUpgrade(self, "Upgrade_UpgradeBlueTib") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueTib")
	end
	if ObjectHasUpgrade(self, "Upgrade_UpgradeGreenTib") then
		ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenTib")
	end
end

function ApplyHarvesterTibFX(self, tibType)
	if self == nil or tibType == nil then
		return
	end

	if tibType == "Red" then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeRedTib")
	elseif tibType == "Blue" then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueTib")
	elseif tibType == "Green" then
		ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenTib")
	end
end

-- =========================================================
-- MONEY BAR HELPERS
-- =========================================================

function AddTibToBar(self, barTable, redUpgrade, blueUpgrade, greenUpgrade)
	if self == nil or barTable == nil then
		return
	end

	local harvId = getObjectId(self)
	if harvId == nil then
		return
	end

	local harvData = harvesterDataTable[harvId]
	if harvData == nil then
		return
	end

	if ObjectTestModelCondition(self, "DOCKING") then
		return
	end

	EnsureHarvesterCounters(harvId)

	local tibType = harvData.tiberiumTypeHarvested
	if tibType == nil then
		tibType = harvData.lastTiberiumTypeHarvested
	end

	if tibType == nil then
		return
	end

	if tibType == "Red" then
		ObjectGrantUpgrade(self, redUpgrade)
		harvRedTib[harvId] = harvRedTib[harvId] + 1
		barTable[harvId] = 2
	elseif tibType == "Blue" then
		ObjectGrantUpgrade(self, blueUpgrade)
		harvBlueTib[harvId] = harvBlueTib[harvId] + 1
		barTable[harvId] = 1
	elseif tibType == "Green" then
		ObjectGrantUpgrade(self, greenUpgrade)
		harvGreenTib[harvId] = harvGreenTib[harvId] + 1
		barTable[harvId] = 0
	end
end

function RemoveTibFromBar(self, barTable, redUpgrade, blueUpgrade, greenUpgrade)
	if self == nil or barTable == nil then
		return
	end

	local harvId = getObjectId(self)
	if harvId == nil then
		return
	end

	if not ObjectTestModelCondition(self, "DOCKING") then
		return
	end

	EnsureHarvesterCounters(harvId)

	if ObjectHasUpgrade(self, redUpgrade) then
		ObjectRemoveUpgrade(self, redUpgrade)
	end
	if ObjectHasUpgrade(self, blueUpgrade) then
		ObjectRemoveUpgrade(self, blueUpgrade)
	end
	if ObjectHasUpgrade(self, greenUpgrade) then
		ObjectRemoveUpgrade(self, greenUpgrade)
	end

	if barTable[harvId] == 2 then
		harvRedTib[harvId] = ClampNonNegative(harvRedTib[harvId] - 1)
	elseif barTable[harvId] == 1 then
		harvBlueTib[harvId] = ClampNonNegative(harvBlueTib[harvId] - 1)
	elseif barTable[harvId] == 0 then
		harvGreenTib[harvId] = ClampNonNegative(harvGreenTib[harvId] - 1)
	end

	barTable[harvId] = nil
end

-- =========================================================
-- HARVEST DETECTION
-- =========================================================

-- self = crystal, other = harvester
function OnTiberiumCrystalHarvested(self, other)
	if self == nil or other == nil then
		return
	end

	local tibType = DetectTiberiumType(self)
	if tibType == nil then
		return
	end

	local harvRef, harvData = GetHarvesterData(other)
	if harvRef == nil or harvData == nil then
		return
	end

	local crystalId, crystalData = GetCrystalData(self)
	if crystalId == nil or crystalData == nil then
		return
	end

	local objectStringRef = "object_" .. harvRef
	ExecuteAction("SET_UNIT_REFERENCE", objectStringRef, self)

	if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", objectStringRef, 116) then
		return
	end

	if harvData.isAlreadyHarvesting then
		local currentCrystal = harvData.crystalCurrentlyHarvesting
		local currentCrystalId = harvData.currentCrystalId

		if currentCrystalId ~= nil and currentCrystalId == crystalId then
			return
		end

		if currentCrystal ~= nil or currentCrystalId ~= nil then
			OffTiberiumHarvested(other, currentCrystal, currentCrystalId)
			ClearCrystalHarvesterBinding(currentCrystal, currentCrystalId)
		end

		ClearHarvesterTibFX(other)

		harvData.isAlreadyHarvesting = false
		harvData.crystalCurrentlyHarvesting = nil
		harvData.currentCrystalId = nil
		harvData.tiberiumTypeHarvested = nil
		harvData.harvestStartFrame = nil
	end

	if crystalData.beingHarvestedBy ~= nil and crystalData.beingHarvestedBy ~= harvRef then
		return
	end

	if harvData.lastCrystalHarvestedId ~= nil and harvData.lastCrystalHarvestedId ~= crystalId then
		harvData.harvestChainFrames = 0
		harvData.harvestStartFrame = nil
		harvData.lastHarvestEndFrame = nil
	end

	harvData.lastCrystalHarvestedId = crystalId

	ClearHarvesterTibFX(other)

	harvData.crystalCurrentlyHarvesting = self
	harvData.currentCrystalId = crystalId
	harvData.tiberiumTypeHarvested = tibType
	harvData.lastTiberiumTypeHarvested = tibType
	harvData.isAlreadyHarvesting = true

	ApplyHarvesterTibFX(other, tibType)

	crystalData.beingHarvestedBy = harvRef

	OnHarvestTimeUpdated(other)
end

function OnHarvestTimeUpdated(self)
	local _, harvData = GetHarvesterData(self)
	if harvData == nil then
		return
	end

	local curFrame = GetFrame()

	if harvData.lastHarvestEndFrame ~= nil then
		local gap = curFrame - harvData.lastHarvestEndFrame
		if gap > MAX_HARVEST_CHAIN_RESET_GAP then
			harvData.harvestChainFrames = 0
			harvData.lastHarvestEndFrame = nil
		end
	end

	harvData.harvestStartFrame = curFrame

	local crystal = harvData.crystalCurrentlyHarvesting
	if crystal == nil then
		return
	end

	local _, crystalData = GetCrystalData(crystal)
	if crystalData == nil then
		return
	end

	crystalData.firstHarvestedFrame = curFrame

	if crystalData.lastHarvestedFrame ~= nil then
		local gap = curFrame - crystalData.lastHarvestedFrame
		if gap > MAX_HARVEST_CHAIN_RESET_GAP then
			crystalData.framesBeingHarvested = 0
			crystalData.lastHarvestedFrame = nil
		end
	end
end

function OnHarvestedCrystalTypeCleared(self)
	local _, harvData = GetHarvesterData(self)
	if harvData == nil then
		return
	end

	local crystal = harvData.crystalCurrentlyHarvesting
	local crystalId = harvData.currentCrystalId
	harvData.isAlreadyHarvesting = false

	if crystal ~= nil or crystalId ~= nil then
		OffTiberiumHarvested(self, crystal, crystalId)
		ClearCrystalHarvesterBinding(crystal, crystalId)
	end

	ClearHarvesterTibFX(self)

	harvData.crystalCurrentlyHarvesting = nil
	harvData.currentCrystalId = nil
	harvData.tiberiumTypeHarvested = nil
	harvData.harvestStartFrame = nil
end

-- =========================================================
-- MONEY BAR EVENTS
-- =========================================================

function OnMoney1(self)
	AddTibToBar(self, bar1, "Upgrade_UpgradeRedOne", "Upgrade_UpgradeBlueOne", "Upgrade_UpgradeGreenOne")
end

function OnMoney2(self)
	AddTibToBar(self, bar2, "Upgrade_UpgradeRedTwo", "Upgrade_UpgradeBlueTwo", "Upgrade_UpgradeGreenTwo")
end

function OnMoney3(self)
	AddTibToBar(self, bar3, "Upgrade_UpgradeRedThree", "Upgrade_UpgradeBlueThree", "Upgrade_UpgradeGreenThree")
end

function OnMoney4(self)
	AddTibToBar(self, bar4, "Upgrade_UpgradeRedFour", "Upgrade_UpgradeBlueFour", "Upgrade_UpgradeGreenFour")
end

function OffMoney1(self)
	RemoveTibFromBar(self, bar1, "Upgrade_UpgradeRedOne", "Upgrade_UpgradeBlueOne", "Upgrade_UpgradeGreenOne")
end

function OffMoney2(self)
	RemoveTibFromBar(self, bar2, "Upgrade_UpgradeRedTwo", "Upgrade_UpgradeBlueTwo", "Upgrade_UpgradeGreenTwo")
end

function OffMoney3(self)
	RemoveTibFromBar(self, bar3, "Upgrade_UpgradeRedThree", "Upgrade_UpgradeBlueThree", "Upgrade_UpgradeGreenThree")
end

function OffMoney4(self)
	RemoveTibFromBar(self, bar4, "Upgrade_UpgradeRedFour", "Upgrade_UpgradeBlueFour", "Upgrade_UpgradeGreenFour")
end

function OnHarvesterDockingEnd(self)
	local harvId = getObjectId(self)
	if harvId == nil then
		return
	end

	local harvData = harvesterDataTable[harvId]
	if harvData == nil then
		return
	end

	harvData.lastTiberiumTypeHarvested = nil
end

-- =========================================================
-- HARVESTER LIFECYCLE
-- =========================================================

function OnHarvesterCreated(self)
	local harvId = getObjectId(self)
	if harvId == nil then
		return
	end

	harvesterDataTable[harvId] = CreateHarvesterRuntime()

	harvRedTib[harvId] = 0
	harvBlueTib[harvId] = 0
	harvGreenTib[harvId] = 0

	bar1[harvId] = nil
	bar2[harvId] = nil
	bar3[harvId] = nil
	bar4[harvId] = nil
end

function OnHarvesterDeath(self)
	local harvId = getObjectId(self)
	if harvId == nil then
		return
	end

	local harvData = harvesterDataTable[harvId]

	ClearHarvesterTibFX(self)

	if harvData ~= nil and (harvData.crystalCurrentlyHarvesting ~= nil or harvData.currentCrystalId ~= nil) then
		ClearCrystalHarvesterBinding(harvData.crystalCurrentlyHarvesting, harvData.currentCrystalId)
		ResetHarvesterRuntime(harvData)
	end

	if (harvRedTib[harvId] or 0) >= 2 then
		ObjectCreateAndFireTempWeapon(self, "DeployRedTiberium")
	elseif (harvBlueTib[harvId] or 0) >= 2 then
		ObjectCreateAndFireTempWeapon(self, "DeployBlueTiberium")
	elseif (harvGreenTib[harvId] or 0) > 0
		or (harvBlueTib[harvId] or 0) == 1
		or (harvRedTib[harvId] or 0) == 1 then
		ObjectCreateAndFireTempWeapon(self, "DeployGreenTiberium")
	end

	harvRedTib[harvId] = nil
	harvBlueTib[harvId] = nil
	harvGreenTib[harvId] = nil

	bar1[harvId] = nil
	bar2[harvId] = nil
	bar3[harvId] = nil
	bar4[harvId] = nil

	harvesterDataTable[harvId] = nil
end

-- =========================================================
-- EXPLOIT FIX
-- =========================================================

function OnHarvestingTiberiumCrystal(self)
	ObjectBroadcastEventToUnits(self, "TiberiumCrystalEvent", 25)
end

function AddHarvestFrames(totalFrames, diff)
	local oldValue = totalFrames or 0
	totalFrames = oldValue

	if diff <= -3 then
		totalFrames = totalFrames + diff + 6
	elseif diff <= -2 then
		totalFrames = totalFrames + diff + 5
	elseif diff <= -1 then
		totalFrames = totalFrames + diff + 4
	elseif diff <= 0 then
		totalFrames = totalFrames + diff + 3
	elseif diff <= 1 then
		totalFrames = totalFrames + diff + 2
	elseif diff <= 2 then
		totalFrames = totalFrames + diff + 1
	else
		totalFrames = totalFrames + diff
	end

	totalFrames = ClampNonNegative(totalFrames)

	return totalFrames
end

function OffTiberiumHarvested(harvester, crystal, fallbackCrystalId)
	if harvester == nil then
		return
	end

	local _, harvData = GetHarvesterData(harvester)
	if harvData == nil then
		return
	end

	local curFrame = GetFrame()
	local startFrame = harvData.harvestStartFrame

	if startFrame == nil then
		harvData.lastHarvestEndFrame = curFrame
	else
		local diff = curFrame - startFrame - PER_HARVEST_OFFSET
		harvData.harvestChainFrames = AddHarvestFrames(harvData.harvestChainFrames, diff)
		harvData.harvestStartFrame = nil
		harvData.lastHarvestEndFrame = curFrame
	end

	local crystalId = nil

	if crystal ~= nil then
		crystalId = getObjectId(crystal)
	end
	if crystalId == nil then
		crystalId = fallbackCrystalId
	end
	if crystalId == nil then
		crystalId = harvData.currentCrystalId
	end
	if crystalId == nil then
		crystalId = harvData.lastCrystalHarvestedId
	end

	if crystalId == nil then
		return
	end

	local crystalData = crystalDataTable[crystalId]
	if crystalData == nil then
		return
	end

	crystalData.beingHarvestedBy = nil

	local firstFrame = crystalData.firstHarvestedFrame or curFrame
	local crystalDiff = curFrame - firstFrame - PER_HARVEST_OFFSET

	crystalData.framesBeingHarvested = AddHarvestFrames(
		crystalData.framesBeingHarvested,
		crystalDiff
	)

	crystalData.lastHarvestedFrame = curFrame

	if crystalData.framesBeingHarvested >= MAX_CRYSTAL_KILL_THRESHOLD and not crystalData.destroyed then
		if crystal ~= nil then
			ObjectSetObjectStatus(crystal, "RIDER1")
			ExecuteAction("NAMED_KILL", crystal)
		end
		crystalData.destroyed = true
	end

	if crystalData.destroyed then
		crystalDataTable[crystalId] = nil
	end
end

function OffTiberiumGrowing(self)
	if self == nil then
		return
	end

	local crystalId = getObjectId(self)
	if crystalId == nil then
		return
	end

	local crystalData = crystalDataTable[crystalId]
	if crystalData ~= nil then
		crystalData.destroyed = true
	end
end