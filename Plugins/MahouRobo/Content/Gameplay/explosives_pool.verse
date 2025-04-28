
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using {CoreCode}
using { /Verse.org }
using { /Fortnite.com/Characters }
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
explosives_pool := class(creative_device,event_listener):
    @editable HitSFX: audio_player_device:= audio_player_device{}
    @editable Explosives: []explosive_device = array{}
    @editable Home: vector3 = vector3{}
    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        GetGlobalBus().Subscribe("MedKaijuAttacked","Explosives_pool", Self)
        GetGlobalBus().Subscribe("SmKaijuAttacked","Explosives_pool", Self)
        GetGlobalBus().Subscribe("LrgKaijuAttacked","Explosives_pool", Self)

    CheckPlayersInFrontAndDamage(NPCChar:fort_character, Radius:float, FOVAngleDegrees:float, Damage:float)<suspends>:void =
        MonsterTransform := NPCChar.GetTransform()
        MonsterForward := MonsterTransform.Rotation.GetLocalForward()
    
        for (Player : GetPlayspace().GetPlayers(), PlayerChar := Player.GetFortCharacter[]):
            PlayerPos := PlayerChar.GetTransform().Translation
            ToPlayer := PlayerPos - MonsterTransform.Translation
    
            DistanceToPlayer := ToPlayer.Length()
            if (DistanceToPlayer <= Radius):
                DirToPlayer := ToPlayer / DistanceToPlayer
                Dot := DotProduct(MonsterForward, DirToPlayer)
                FOVThreshold := Cos(DegreesToRadians(FOVAngleDegrees / 2.0))
    
                if (Dot >= FOVThreshold):
                    PlayerChar.Damage(Damage)
                    if(Agent:=PlayerChar.GetAgent[]):
                        HitSFX.Play(Agent)
                    


    OnEvent<override>(EventName: string, Data:eventdata): void =
        if(EventName = "MedKaijuAttacked"):
            if(MaybeAgent:= Data.Agent?,MaybeFArray:= Data.ValueFA?,Radius:= MaybeFArray[0], FOVAngleDegrees:= MaybeFArray[1], FCharacter:= MaybeAgent.GetFortCharacter[]):
                spawn{CheckPlayersInFrontAndDamage(FCharacter,Radius,FOVAngleDegrees,30.0)}

        if(EventName = "SmKaijuAttacked"):
            if(MaybeAgent:= Data.Agent?,MaybeFArray:= Data.ValueFA?,Radius:= MaybeFArray[0], FOVAngleDegrees:= MaybeFArray[1], FCharacter:= MaybeAgent.GetFortCharacter[]):
                spawn{CheckPlayersInFrontAndDamage(FCharacter,Radius,FOVAngleDegrees,5.0)}

        if(EventName = "LrgKaijuAttacked"):
            if(MaybeAgent:= Data.Agent?,MaybeFArray:= Data.ValueFA?,Radius:= MaybeFArray[0], FOVAngleDegrees:= MaybeFArray[1], FCharacter:= MaybeAgent.GetFortCharacter[]):
                spawn{CheckPlayersInFrontAndDamage(FCharacter,Radius,FOVAngleDegrees,125.0)}