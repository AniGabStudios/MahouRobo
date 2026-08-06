
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { CoreCode }

win_team_data<public>:=class():
    var TeamIndex: int = 0
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
team_score_manager := class(creative_device,event_listener):

    var Scores : []int = array{}

    @editable
    var EliminationManagers : []elimination_manager_device = array{}

    @editable
    var HudMessages : []hud_message_device = array{}

    # The persistent frame/background for the two score values. This is kept
    # separate because HudMessages contains only the per-team number widgets.
    @editable
    ScoringHudVisuals : hud_message_device = hud_message_device{}

    @editable
    var GameEnders : []end_game_device = array{}

    IntToMessage<localizes>(I : int) : message = "{I}"

    var Teams : []team = array{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void =
        set Teams = GetPlayspace().GetTeamCollection().GetTeams()
        GetGlobalBus().Subscribe("RoundEnd","team_score_manager", Self)
        GetGlobalBus().Subscribe("PlayerEliminatedKaiju","team_score_manager", Self)
        GetGlobalBus().Subscribe("PlayerEliminatedPlayer","team_score_manager", Self)
        GetGlobalBus().Subscribe("TeamSelected","team_score_manager", Self)
        ClearScores()
       
    ClearScores(): void = 
        set Scores =
            for (CurrentTeam : Teams):
                0

        for(Hud:HudMessages):
            Hud.SetText(IntToMessage(0))

    OnEvent<override>(EventName: string, Data:eventdata) : void =
        case (EventName):
            "PlayerEliminatedPlayer"=>
                if(MaybeAgentMap:=Data.AgentMap?, Agent:= MaybeAgentMap["killer"]):
                    AwardTeamPoints(Agent,1)
            "PlayerEliminatedKaiju" =>
                if(MaybeAgentMap:=Data.AgentMap?, Agent:= MaybeAgentMap["killer"], Points:= Data.ValueI):
                    AwardTeamPoints(Agent,Points)
            "TeamSelected" =>
                if (PlayerAgent := Data.Agent?):
                    spawn{ShowScoringHud(PlayerAgent)}
            "RoundEnd" =>
                EndGame()
            _ => # default

    ShowScoringHud(PlayerAgent:agent)<suspends>:void=
        # Let the conversation modal finish releasing the player's UI stack
        # before restoring the persistent HUD Message widgets.
        Sleep(0.25)
        ScoringHudVisuals.Show(PlayerAgent)
        for (Hud : HudMessages):
            Hud.Show(PlayerAgent)
        Print("[ScoreHUD] Shown after team selection. ScoreWidgets={HudMessages.Length}")


    AwardTeamPoints(Agent:agent, Points:int):void=
        Print("Awarding Team Points")

        teamCollection := GetPlayspace().GetTeamCollection()
        if(teamCollection.IsOnTeam[Agent, Teams[0]]):
            GivePoints(0, Points)
                UpdateHud(0)

        if(teamCollection.IsOnTeam[Agent, Teams[1]]):
            GivePoints(1, Points)
                UpdateHud(1)

    GivePoints(InTeamIndex : int, InPoints : int) : void = 
        i := InTeamIndex
        if (var score : int := Scores[i]):
            set score += InPoints
            if (set Scores[i] = score):
                return
        Print("GivePoints got team {InTeamIndex} (must be 1..{Scores.Length})")
    
    GetWinningTeam() : int =
        if(Scores[0] > Scores[1]):
            return 0
        else if(Scores[1] > Scores[0]):
            return 1
        else:
            return 3


    
    UpdateHud(InTeamIndex : int) : void =
        i := InTeamIndex
        if (hudMessage := HudMessages[i]):
            if (score := Scores[i]):
                hudMessage.SetText(IntToMessage(score))
            else:
                Print("UpdateHud got team {InTeamIndex} (must be 1..{Scores.Length})")
        else:
            Print("team_score_manager missing a HUD Message Device for team {InTeamIndex}")

    
    EndGame() : void =
        WinningTeam := GetWinningTeam()

        if(WinningTeam = 0):
            GetGlobalBus().Notify("RoundEndRobots", eventdata{})
            Print("EndGame: Robots")
        else if(WinningTeam = 1):
            GetGlobalBus().Notify("RoundEndMagicalGirls", eventdata{})
            Print("EndGame: Magic")
        else :
            GetGlobalBus().Notify("RoundEndTie", eventdata{})
            Print("EndGame: Tie")

        if (WinningTeam = 3):
            Print("Draw or tiebreaker NYI")
            return
        
        teamCollection := GetPlayspace().GetTeamCollection()
        teams := teamCollection.GetTeams()
        if (Team := teams[WinningTeam]):
            if (Agents := teamCollection.GetAgents[Team]):
                if (Agent := Agents[0]):
                    if (GameEnder := GameEnders[WinningTeam]):
                        GameEnder.Activate(Agent)
                    else:
                        Print("team_score_manager missing an End Game Device for team {WinningTeam}")
                else:
                    Print("EndGame: No agents in team")
            else:
                Print("EndGame: tried to win with nonexistent team {WinningTeam}")
        else:
            Print("EndGame: tried to win with nonexistent team {WinningTeam}")
