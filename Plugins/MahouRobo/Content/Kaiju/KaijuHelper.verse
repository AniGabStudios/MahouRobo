using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { CoreCode }
using { /Verse.org/Random }
KaiJuHelperTag:= class(tag){}
KaijuHelper := class(creative_device,event_listener):
    @editable KaijutHitVFX: creative_prop_asset = DefaultCreativePropAsset
    OnBegin<override>()<suspends>:void =
        KaiJuTags:=FindCreativeObjectsWithTag(KaijuBehaviourTag)

        for(KT:KaiJuTags,Kai:=NPC_Kaiju[KT]):
            set Kai.HelperFunc = Self;

    OnEvent<override>(EventName: string, Data:eventdata) : void =
        if(EventName = "KaijuTakenDamage"):
            if(MaybeAgent:=Data.Agent?):
                spawn{DealDamageFX(MaybeAgent)}

    DealDamageFX<public>(Agent:agent)<suspends>:void=
        if(FortChar:= Agent.GetFortCharacter[]):
            RO:=SpawnProp(KaijutHitVFX,FortChar.GetTransform().Translation, rotation{})
            Sleep(0.3)
            if (SpawnedProp := RO(0)?):
                spawn{DisposeProp(SpawnedProp)}

    DisposeProp(V:creative_prop)<suspends>:void=
        V.Dispose()

    GetRandomNearbyLocation(Center: vector3, Radius: float): vector3 =
        RandOffset := vector3{
            X := (GetRandomFloat(-Radius, Radius)),
            Y := (GetRandomFloat(-Radius, Radius)),
            Z := 0.0
        }
        return Center + RandOffset

    AnyPlayerNearby<public>(NPC: agent, Radius: float)<transacts>: logic =
        if (NPCChar := NPC.GetFortCharacter[]):
            MyLoc := NPCChar.GetTransform().Translation
            DevicePlayspace := Self.GetPlayspace()
    
            for (Player : DevicePlayspace.GetPlayers()):
                if (PlayerChar := Player.GetFortCharacter[]):
                    PlayerLoc := PlayerChar.GetTransform().Translation
                    if (Distance(MyLoc, PlayerLoc) < Radius):
                        return true
        return false

    FindNearestTargetPosition(fromPosition:vector3)<decides><transacts>:vector3 =
        DevicePlayspace := Self.GetPlayspace()
        var ClosestPos : vector3 = vector3{X:= 0.0,Y:= 0.0,Z:= 0.0}
        var ClosestDistance : float = 999999.0
    
        for (Player : DevicePlayspace.GetPlayers()):
            if (PlayerChar := Player.GetFortCharacter[]):
                PlayerPos := PlayerChar.GetTransform().Translation
                DistanceTo := Distance(PlayerPos, fromPosition)
    
                if (DistanceTo < ClosestDistance):
                    set ClosestPos = PlayerPos
                    set ClosestDistance = DistanceTo
    
        return ClosestPos

    FindNearestTarget(FC : fort_character)<decides><transacts> : ?fort_character =
        var PossibleTarget : ?fort_character = false
        var CheckRange : float = 5000.0
        for(Player : Self.GetPlayspace().GetPlayers()):
            if:
                PlayerFC := Player.GetFortCharacter[]
                DistanceDifference := Distance(PlayerFC.GetTransform().Translation, FC.GetTransform().Translation) < CheckRange
                not PlayerFC = FC
            then:
                set PossibleTarget = option{PlayerFC}
                set CheckRange = DistanceDifference
        return PossibleTarget


    FindNearestTransform(FC : fort_character, Transforms: []transform)<decides><transacts> : transform =
        var PossibleTarget : ?transform = false
        var CheckRange : float = 5000.0
        for(Transform : Transforms):
            if:
                DistanceDifference := Distance(Transform.Translation, FC.GetTransform().Translation) < CheckRange
            then:
                set PossibleTarget = option{Transform}
                set CheckRange = DistanceDifference
        return PossibleTarget?

    FindNearestWaypoint(FC : fort_character, Transforms: []creative_prop)<decides><transacts> : transform =
        var PossibleTarget : ?transform = false
        var CheckRange : float = 5000.0
        for(Waypoint : Transforms):
            if:
                DistanceDifference := Distance(Waypoint.GetTransform().Translation, FC.GetTransform().Translation) < CheckRange
            then:
                set PossibleTarget = option{Waypoint.GetTransform()}
                set CheckRange = DistanceDifference
        return PossibleTarget?