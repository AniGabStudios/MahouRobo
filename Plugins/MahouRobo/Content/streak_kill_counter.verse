
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }


using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }

Art := module:
    UI<public> := module{}

TextToMessage<localizes>(InText : string) : message = "{InText}"

UIClass_2 := class<unique>{
    Player : player
    

    var PlayerUICanvas : ?canvas = false
    TextBlockTarget : text_block = text_block{DefaultTextColor := NamedColors.White, DefaultShadowColor:=NamedColors.Black, DefaultShadowOffset:=option{vector2{X:=2.0, Y:=2.0}}}
    TextBlockStreak : text_block = text_block{DefaultTextColor := NamedColors.White, DefaultShadowColor:=NamedColors.Black, DefaultShadowOffset:=option{vector2{X:=2.0, Y:=2.0}}}
    Init(): void ={
        TextBlockTarget.SetText(TextToMessage("0"))
        TextBlockStreak.SetText(TextToMessage("0"))

        TextBlockTarget.SetShadowOpacity(1.0)
        TextBlockStreak.SetShadowOpacity(1.0)
    }

    CreateCanvas(): canvas ={

        Canvas := canvas{
            Slots := array{
                canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 1.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.0}}
                    Offsets := margin{Top := 450.0, Left := -100.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 1.0, Y := 0.0}
                    Widget := stack_box{
                        Orientation := orientation.Horizontal
                        Slots := array{
                            stack_box_slot{
                                Widget:= texture_block{DefaultImage := Art.UI.target}
                            }
                            stack_box_slot{
                                
                                Padding := margin{Left := 5.0}
                                Widget:= TextBlockTarget
                            }
                            stack_box_slot{
                                
                                Padding := margin{Left := 30.0}
                                Widget:= texture_block{DefaultImage := Art.UI.flame}
                            }
                            stack_box_slot{
                                
                                Padding := margin{Left := 15.0}
                                Widget:= TextBlockStreak
                            }
                        }
                    }
                }
            }
        }
        return Canvas
    }


    ShowUIForPlayer(): void ={
        if(not PlayerUICanvas?){
            CreatedCanvas := CreateCanvas()
            set PlayerUICanvas = option{CreatedCanvas}
        }

        if(PlayerUI := GetPlayerUI[Player], Canvas := PlayerUICanvas?){
            PlayerUI.AddWidget(Canvas)
        }
    }

    HideUIForPlayer(): void ={
        if(PlayerUI := GetPlayerUI[Player], Canvas := PlayerUICanvas?){
            PlayerUI.RemoveWidget(Canvas)
        }
    }
}

streak_kill_counter := class(creative_device):

    @editable ElimManager : elimination_manager_device = elimination_manager_device{}
    @editable DBNODevice : down_but_not_out_device = down_but_not_out_device{}

    var UIClassPerPlayer : [player]UIClass_2 = map{}

    OnBegin<override>()<suspends>:void=
        ElimManager.EliminationEvent.Subscribe(UpdateScore)
        DBNODevice.AgentDownedEvent.Subscribe(ResetScore)
        for(Player : GetPlayspace().GetPlayers()){
            NewClass := UIClass_2{Player:=Player}
            if(set UIClassPerPlayer[Player] = NewClass, set TotalKillsPerPlayer[Player] = 0, set StreakPerPlayer[Player] = 0){
                NewClass.Init()
                NewClass.ShowUIForPlayer()
            }
        }
        GetPlayspace().PlayerAddedEvent().Subscribe(NewPlayerJoin)

    var TotalKillsPerPlayer : [agent]int = map{}
    var StreakPerPlayer : [agent]int = map{}


    NewPlayerJoin(Player : player): void={
        NewClass := UIClass_2{Player:=Player}
            if(set UIClassPerPlayer[Player] = NewClass, set TotalKillsPerPlayer[Player] = 0, set StreakPerPlayer[Player] = 0){
                NewClass.Init()
                NewClass.ShowUIForPlayer()
            }
    }
    UpdateScore(Agent : ?agent): void={
        if(set TotalKillsPerPlayer[Agent?] +=1, set StreakPerPlayer[Agent?] +=1){}
        if(UIClassPlayer := UIClassPerPlayer[Agent?], TotalKills := TotalKillsPerPlayer[Agent?], StreakTotal := StreakPerPlayer[Agent?]){
            UIClassPlayer.TextBlockTarget.SetText(TextToMessage("{TotalKills}"))
            UIClassPlayer.TextBlockStreak.SetText(TextToMessage("{StreakTotal}"))
        }
    }

    ResetScore(Agent : agent): void={
        if(UIClassPlayer := UIClassPerPlayer[Agent]){
            if(set StreakPerPlayer[Agent] = 0){}
            UIClassPlayer.TextBlockStreak.SetText(TextToMessage("0"))
        }
    }


    