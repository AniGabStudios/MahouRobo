using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }


elimination_callback := class():
    Player: agent
    Handle(Result: elimination_result): void = HandleElimination(Player, Result)

damaged_callback := class():
    Player: agent
    Handle(Result: damage_result): void = HandleDamaged(Player, Result)
    
HandleDamaged(Player:agent, Result:damage_result):void=
    Victim := Player
    GetGlobalBus().Notify("PlayerTakenDamage",eventdata{Agent:=option{Player}})
   
HandleElimination(Player: agent, Result: elimination_result): void =
    Victim := Result.EliminatedCharacter
    if (MaybeKiller := Result.EliminatingCharacter?):
        if (MaybeKiller = Victim):
            GetGlobalBus().Notify("PlayerSelfEliminated",eventdata{Agent:= option{Player}})
        else if (VictimAgent := Victim.GetAgent[], KillerAgent := MaybeKiller.GetAgent[]):
            GetGlobalBus().Notify("PlayerEliminatedPlayer", eventdata{AgentMap := option{map{
                "killer" => KillerAgent,
                "victim" => VictimAgent
            }}})
    else:
        GetGlobalBus().Notify("PlayerEliminatedCreature", eventdata{Agent:= option{Player}})

player_event_bus_device := class(creative_device):
    @editable
    var EliminationManager : elimination_manager_device = elimination_manager_device{}

    OnBegin<override>()<suspends>: void =
    
        Self.GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        Self.GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerLeft)
        Sleep(0.3)
        for(Player:Self.GetPlayspace().GetPlayers()): 
            if (Character := Player.GetFortCharacter[]):
                CharacterDamageCallback := damaged_callback{ Player := Player }
                Character.DamagedEvent().Subscribe(CharacterDamageCallback.Handle)
                CharacterElimCallback := elimination_callback{ Player := Player }
                Character.EliminatedEvent().Subscribe(CharacterElimCallback.Handle)
            Print("For body")

    OnPlayerAdded(Player: agent): void =
        Print("Player Added:")
        spawn{OnPlayerJoined(Player)}

    OnPlayerJoined(Player: agent)<suspends>: void =
        Print("Player Joined:")
        GetGlobalBus().Notify("PlayerJoined", eventdata{Agent:= option{Player}})

        # Safe character bind with delay
        Sleep(0.3)
        if (Character := Player.GetFortCharacter[]):
            CharacterElimCallback := elimination_callback{ Player := Player }
            Character.EliminatedEvent().Subscribe(CharacterElimCallback.Handle)

    OnPlayerLeft(Player: agent): void =
        Print("Player Left Match")
        GetGlobalBus().Notify("PlayerLeft", eventdata{Agent:= option{Player}})

    OnPlayspaceElimination(Result: elimination_result): void =
        # Global catch if needed
        Print("Playspace Elimination triggered")

   