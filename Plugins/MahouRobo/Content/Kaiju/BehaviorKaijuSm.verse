using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Game }
using {CoreCode}
using { /Verse.org/Random }


# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
BehaviorKaijuSm := class(NPC_Kaiju):
    var isTargetInRange : logic = false
    @editable projectile_speed : float := 20.0
    @editable projectile_damage : float := 5.0
    @editable move_speed : float := 20.0

    @editable safe_distance : float := 1000.0        # Ideal distance from player
    @editable min_attack_distance : float := 400.0  # When to attack
    @editable retreat_distance : float := 600.0     # How far to back up when too close
    var Attack1 : animation_sequence = (/anigab@fortnite.com/MahouRobo/Kaiju:)Demon_Anim_EnemyArmature_Attack

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        (super:)OnBegin()
       # spawn { StartPatrolBehavior(1500.0, 5.0) }
        Sleep(0.5)
        set point_value = 3

        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
        then:
            NPCChar.EliminatedEvent().Subscribe(OnKaijuEliminated)
            spawn { StartPatrolBehavior(8000.0, 5.0) }
            spawn { MovementLoop() }

    MovementLoop()<suspends>: void =
        loop:
            Sleep(GetRandomFloat(1.0, 3.0))
            if:
                NPCAgent := GetAgent[]
                NPCChar := NPCAgent.GetFortCharacter[]
            then:   
                if (Player := HelperFunc.FindNearestTarget[NPCChar]?):
                    PlayerLoc := Player.GetTransform().Translation
                    MyLoc := NPCChar.GetTransform().Translation
                    Dist := Distance(MyLoc, PlayerLoc)

                    if (Dist < min_attack_distance):
                        set currentState = KaijuState.Attacking
                        spawn{PlayAttackAnimation()}

                    else if (Dist < safe_distance):
                        set currentState = KaijuState.Retreating
                        RunAwayLoc := MyLoc + (MyLoc - PlayerLoc)
                        spawn { DoMoveToTarget(RunAwayLoc) }
                    
                    else:
                        set currentState = KaijuState.Patrolling
                        # Don't chase; just ignore and continue patrol
                else:
                    set currentState = KaijuState.Patrolling


    StartPatrolBehavior(PatrolRadius: float, DelayBetweenMoves: float)<suspends>: void =
        loop:
            if:
                NPCAgent := GetAgent[]
                NPCChar := NPCAgent.GetFortCharacter[]
            then:
                if (currentState = KaijuState.Idle or currentState = KaijuState.Patrolling):
                    if (not HelperFunc.AnyPlayerNearby(NPCAgent, 3000.0)?):
                        set currentState = KaijuState.Patrolling
    
                        if (PatrolPOIs.Length > 0):
                            if(POI := PatrolPOIs[GetRandomInt(0, PatrolPOIs.Length - 1)]):
                                PatrolTarget := HelperFunc.GetRandomNearbyLocation(POI, PatrolRadius)
                                spawn { DoMoveToTarget(PatrolTarget) }
                                Sleep(DelayBetweenMoves)
                    else:
                        set currentState = KaijuState.Chasing
            Sleep(1.0)

    DoMoveToTarget(NewLocation:vector3)<suspends>:void =
        set isMoving = true
        spawn{MoveToTarget(NewLocation)}  # Call and ignore result
        set isMoving = false

    OnKaijuEliminated<override>(Result:elimination_result):void=
        (super:)OnKaijuEliminated(Result)
    
    MoveToTarget<override>(NewLocation: vector3)<suspends>: logic =
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
            NPCNav := NPCChar.GetNavigatable[]
            NPCFocus := NPCChar.GetFocusInterface[]
        then:
            NavTarget := MakeNavigationTarget(NewLocation)
            NavResult := NPCNav.NavigateTo(
                NavTarget,
                ?MovementType := movement_types.Running,
                ?ReachRadius := 150.0,
                ?AllowPartialPath := true
            )
            return true
        return false
    
    PlayAttackAnimation<override>()<suspends>:logic =
        if:
            NPCAgent := GetAgent[]
            NPCChar := NPCAgent.GetFortCharacter[]
            NPCAnim := NPCChar.GetPlayAnimationController[]
        then:
            Delay := GetRandomFloat(0.1, attack_delay_variance)
            Sleep(Delay)
    
            result := NPCAnim.PlayAndAwait(Attack1)
    
            if (result = play_animation_result.Completed):
                set lastTargetLocation = vector3{X := 0.0, Y := 0.0, Z := 0.0}
                GetGlobalBus().Notify(
                    "SmKaijuAttacked",
                    eventdata{
                        Agent := option{NPCAgent},
                        ValueFA := option{array{300.0, 90.0}}
                    }
                )
                return true
            else:
                return false
        else:
            return false


    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        # TODO: Replace this with your code
        Print("Goodbye, NPC!")