using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }
using { /Verse.org/Random }
using { CoreCode}
using { /Verse.org/Verse }
# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
BehaviorKaijuLg := class(NPC_Kaiju):
    @editable projectile_asset : creative_prop_asset = DefaultCreativePropAsset
    @editable projectile_speed : float = 5.0
    @editable projectile_damage : float = 5.0
    @editable move_speed : float = 20.0
    @editable waypoint_list : []creative_prop = array{}
    @editable waypoint_wait : float = 15.0
    var currentPOIIndex : int = 0
    var poiMoveCount : int = 0
    @editable poi_switch_interval : float = 60.0  # Move every 60 seconds

    var Attack1 : animation_sequence = (/anigab@fortnite.com/MahouRobo/Kaiju:)Giant_Anim_EnemyArmature_Attack

    # Fire projectile at targeted player
    FireProjectile(Target:vector3)<suspends>:void =
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
        then:
            MyPosition := NPCChar.GetTransform().Translation
            MyRotation := NPCChar.GetViewRotation()
            ForwardVec := MyRotation.GetLocalForward() * 400.0
            RangeVec := MyRotation.GetLocalForward() * 5000.0
            SpawnPos := MyPosition + ForwardVec + vector3{X := 0.0, Y := 0.0, Z := 100.0}
            NewEndPos:=Target
            EndPos := MyPosition + RangeVec
            if (NewProp := SpawnProp(projectile_asset, SpawnPos, IdentityRotation())(0)? ):
                race:
                    block:
                        NewProp.MoveTo(NewEndPos, IdentityRotation(), projectile_speed)
                        NewProp.Dispose()
                        return
                    DamageCheck(NewProp)
    
    # Projectile damage check and damage proc
    DamageCheck(Prop : creative_prop)<suspends>:void =
        loop:
            Sleep(0.1)
            for(Player : Prop.GetPlayspace().GetPlayers(), FC := Player.GetFortCharacter[]):
                if(Distance(FC.GetTransform().Translation, Prop.GetTransform().Translation) < 100.0):
                    FC.Damage(projectile_damage)
                    Prop.Dispose()
   
    OnBegin<override>()<suspends>:void =
        (super:)OnBegin()
        Sleep(0.5)
        set point_value = 5
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
        then:
            NPCChar.EliminatedEvent().Subscribe(OnKaijuEliminated)
            spawn { StartPOILoop() }

    MovementLoop()<suspends>:void =
        Sleep(GetRandomFloat(0.2, 0.4))  # Desync from others

        loop:
            Sleep(poi_switch_interval)  # Move every 60s
    
            set poiMoveCount += 1
            set currentPOIIndex += 1
    
            if (currentPOIIndex >= waypoint_list.Length):
                set currentPOIIndex = 0
    
            if (poiMoveCount >= 4):
                set currentPOIIndex = 0
                set poiMoveCount = 0
    
            if (TargetPOI := waypoint_list[currentPOIIndex]):
                POITransform := TargetPOI.GetTransform()
                spawn { MoveToTarget(POITransform.Translation) }

    DoMoveToTarget(NewLocation:vector3)<suspends>:void =
        set isMoving = true
        spawn{MoveToTarget(NewLocation)}  # Call and ignore result
        set isMoving = false

    MoveToTarget<override>(NewLocation: vector3)<suspends>: logic =
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
            NPCNav := NPCChar.GetNavigatable[]
            NPCFocus := NPCChar.GetFocusInterface[]
        then:
            TargetPos := NewLocation
            spawn { NPCFocus.MaintainFocus(TargetPos) }
    
            NavTarget := MakeNavigationTarget(TargetPos)
            NavResult := NPCNav.NavigateTo(
                NavTarget,
                ?MovementType := movement_types.Running,
                ?ReachRadius := 250.0,
                ?AllowPartialPath := true
            )
    
            if (NavResult = navigation_result.Reached or NavResult = navigation_result.PartiallyReached):
                spawn { AttackPOIArea(TargetPos) }
                return true
            else:
                return false
        else:
            return false

    StartPOILoop()<suspends>: void =
        var TimeRemaining: float = 0.0
    
        loop:
            if (waypoint_list.Length > 0):
                if (TimeRemaining <= 0.0):
                    # Move to next POI
                    if(POI := waypoint_list[currentPOIIndex]):
                        POILoc := POI.GetTransform().Translation
                        var Reached: logic = MoveToTarget(POILoc)
        
                        # Reset timer
                        set TimeRemaining = poi_switch_interval
        
                        # Advance index
                        if(PI:= Mod[currentPOIIndex + 1, waypoint_list.Length]):
                            set currentPOIIndex = PI
    
                # Attack periodically during wait time
                spawn { PlayAttackAnimation() }
    
                AttackDelay := GetRandomFloat(3.0, 5.0)
                Sleep(AttackDelay)
                set TimeRemaining -= AttackDelay
            else:
                Sleep(1.0)
            

    AttackPOIArea(TargetPos:vector3)<suspends>:void =
        Sleep(GetRandomFloat(0.2, 0.6))
    
        if (NPCAgent := GetAgent[], NPCChar := NPCAgent.GetFortCharacter[]):
            loop:
                Sleep(GetRandomFloat(1.0, 2.0))
    
                KaijuPos := NPCChar.GetTransform().Translation
    
                if (Distance(KaijuPos, TargetPos) < 600.0):
                    spawn { PlayAttackAnimation() }
                    spawn { FireProjectile(TargetPos) }
    
    # Play defined attack animation
    PlayAttackAnimation<override>()<suspends>:logic = 
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
            NPCAnim := NPCChar.GetPlayAnimationController[]
        then:
            # Wait before attacking to add unpredictability
            Delay := GetRandomFloat(0.1, attack_delay_variance)
            Sleep(Delay)
    
            result := NPCAnim.PlayAndAwait(Attack1)
    
            if (result = play_animation_result.Completed):
                set lastTargetLocation = vector3{X := 0.0, Y := 0.0, Z := 0.0}
                GetGlobalBus().Notify(
                    "LrgKaijuAttacked",
                    eventdata{
                        Agent := option{NPCAgent},
                        ValueFA := option{array{600.0, 360.0}}
                    }
                )
                return true
            else:
                return false
        else:
            return false

    # Event handler for elimination
    OnKaijuEliminated<override>(Result:elimination_result):void=
        (super:)OnKaijuEliminated(Result)

    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        Print("Big Kaiju despawned")