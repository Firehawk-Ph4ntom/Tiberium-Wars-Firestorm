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
function onCreatedForbidCommands(self)
	ObjectForbidPlayerCommands( self, true )
end

function OnAlienPhotonCannonCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_SHARD", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end

function OnRavagerCreated(self)
	ObjectHideSubObjectPermanently( self, "AUSTALKER_GUN", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKER_SHARD", true )
end

function OnAlienSeekerTankCreated(self)
	ObjectHideSubObjectPermanently( self, "AUSHARDWEAPON_C_G", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end

function OnGDITechCenterCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Mortar", true )
	ObjectHideSubObjectPermanently( self, "UG_Rail", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan", true )
	ObjectHideSubObjectPermanently( self, "B_MortarRound_1", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive01", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive", true )
	ObjectHideSubObjectPermanently( self, "FXELEC01", true )
	ObjectHideSubObjectPermanently( self, "PLANE02", true )
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
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector03", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan02", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo02", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan01", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo01", true )
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

function OnGDIPowerPlantCreated(self)
	ObjectHideSubObjectPermanently( self, "Turbines", true )
	ObjectHideSubObjectPermanently( self, "TurbineGlows", true )
end

function OnGDITankArmoryCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Injector", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP01", true )
	ObjectHideSubObjectPermanently( self, "UG_CompositeArmor", true )
	ObjectHideSubObjectPermanently( self, "UG_CompositeArmor02", true )
end

function OnGDIBattleBaseCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_TURRETL", true )
	ObjectHideSubObjectPermanently( self, "UG_TURRETR", true )
end

function OnGDIWatchTowerCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_BASE", true )
end

function OnGDIMammothMechHuskCreated(self)
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTL", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTR", true )
	ObjectHideSubObjectPermanently( self, "LIGHTL", true )
	ObjectHideSubObjectPermanently( self, "LIGHTR", true )
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

function OnGDIV35Ox_SummonedForVehicleCreated(self)
	ObjectHideSubObjectPermanently( self, "LOADREF", true )
end

function OnGDIZoneTrooperCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
	ObjectHideSubObjectPermanently( self, "UGINJECTOR", true )
end

function OnGDIGrenadeSoldierCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_STRAPS", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP_PROJECTILE", true )
end

function OnGenericSpotterCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
end

function OnGDIPitbullCreated(self)
	ObjectHideSubObjectPermanently( self, "MortorTube", true )
end

function OnGDIAPCCreated(self)
	ObjectHideSubObjectPermanently( self, "APC_UGAB", true )
	ObjectHideSubObjectPermanently( self, "APC_UGTURRET", true )
end

function OnGDIWolverineCreated(self)
	ObjectHideSubObjectPermanently( self, "UGAMMO", true )
end

function OnGDITitanCreated(self)
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
end

function OnNODVenomCreated(self)
	ObjectHideSubObjectPermanently( self, "SIGGEN", true )
end

function OnNODVertigoCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_RD", true )
end

function OnNODAttackBikeCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILEL", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER", true )
end

function OnNODAvatarCreated(self)
	ObjectHideSubObjectPermanently( self, "NUBEAM", true )
	ObjectHideSubObjectPermanently( self, "S_DETECTOR", true )
	ObjectHideSubObjectPermanently( self, "S_GENERATOR", true )
end

function OnNODAvatarGenericEvent(self, data)

	local str = tostring( data )

	if str == "upgrades_copied" then
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_VETERAN" );
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_ELITE" );
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_HEROIC" );
	end
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
	ObjectHideSubObjectPermanently( self, "FX_GLOWHEROIC", true )
end

function OnAlienAdvProductionPurchased(self)
	if ObjectHasUpgrade( self, "Upgrade_AdvancedProduction" ) == 1 then
		ObjectGrantUpgrade( self, "Upgrade_ProductionDummy" )
	end
end

function OnAlienMotherShipCreated(self)
	ObjectSetObjectStatus( self, "AIRBORNE_TARGET" )
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