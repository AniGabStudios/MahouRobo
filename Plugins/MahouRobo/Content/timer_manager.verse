
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using {CoreCode}

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

timelines := enum{LongGame, ShortGame, BossRush, HordeMode}

timeline_event := struct<concrete>:
    TimeToTrigger: float = 0.0
    ID: string = "SetEventID"

# A Verse-authored creative device that can be placed in a level
timer_manager<public> := class(creative_device,event_listener):
    TimelineList : [timelines][]timeline_event = map{
        timelines.LongGame => array{
            timeline_event{ 
                TimeToTrigger := 10.0,
                ID := "Small Kaiju Phase"
            },
            timeline_event{ 
                TimeToTrigger := 180.0,
                ID := "3 Minute Check Phase"
            },
            timeline_event{ 
                TimeToTrigger := 540.0,
                ID := "Transition Phase"
            },
            timeline_event{ 
                TimeToTrigger := 600.0,
                ID := "Medium Kaiju Phase"
            },
            timeline_event{ 
                TimeToTrigger := 780.0,
                ID := "13 Minute Check Phase"
            },
            timeline_event{ 
                TimeToTrigger := 1200.0,
                ID := "Boss Transition Phase"
            },
            timeline_event{ 
                TimeToTrigger := 1320.0,
                ID := "Big Kaiju Phase"
            }
        },
        timelines.ShortGame => array{
            timeline_event{
                TimeToTrigger := 10.0,
                ID := "Small Kaiju Phase" 
            },
            timeline_event{
                TimeToTrigger := 150.0,
                ID := "Transition Phase" 
            },
            timeline_event{
                TimeToTrigger := 180.0,
                ID := "Medium Kaiju Phase" 
            },
            timeline_event{
                TimeToTrigger := 330.0,
                ID := "Transition Phase" 
            },
            timeline_event{
                TimeToTrigger := 360.0,
                ID := "Big Kaiju Phase" 
            }
        },
        timelines.BossRush => array{
            timeline_event{ TimeToTrigger := 0.0, ID := "EventID" }
        },
        timelines.HordeMode => array{
            timeline_event{ TimeToTrigger := 0.0, ID := "EventID" }
        }
    }
    DurationList : [timelines]float = map {
        timelines.LongGame => 1800.0,
        timelines.ShortGame => 600.0,
        timelines.BossRush => 600.0,
        timelines.HordeMode => 600.0
    }
    @editable Timeline : timelines = timelines.LongGame
    @editable Duration: float = 1800.0
    @editable Timer: timer_device = timer_device{}

    var CancelTimer: logic = false

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        GetGlobalBus().Subscribe("RoundStart","timer_manager", Self)
        GetGlobalBus().Subscribe("RoundEnd","timer_manager", Self)
    
    OnEvent<override>(EventName: string, Data:eventdata): void =
        Print("Received Event: {EventName}")
        if (EventName = "RoundStart"):
            set CancelTimer = false
            spawn{StartTimer()}
        else if (EventName = "RoundEnd"):
            set CancelTimer = true


    CheckForTimbeTriggeredEvent(timeRemaining : float): void =
        currentTime := 1800.0 - timeRemaining
        for (Event:TimelineList[Timeline]):
            if (Event.TimeToTrigger = currentTime):
                Print("Timer Triggered Event: {Event.ID}")
                GetGlobalBus().Notify(Event.ID,eventdata{})


    StartTimer()<suspends>: void =
        GetGlobalBus().Notify("TimerStarted",eventdata{})
        Timer.SetActiveDuration(Duration)
        Timer.StartForAll()
        var Remaining: float = Duration
        loop:
            CheckForTimbeTriggeredEvent(Remaining)
            if(CancelTimer?):
                Print("Timer canceled")
                GetGlobalBus().Notify("TimerCanceled",eventdata{})
                Timer.ResetForAll()
                break
            if(Remaining <= 0.0):
                Print("Timer complete")
                GetGlobalBus().Notify("TimerCompleted",eventdata{})
                GetGlobalBus().Notify("RoundEnd",eventdata{})

                Timer.ResetForAll()
                break
           
            Sleep(1.0)
            set Remaining = Remaining - 1.0

    
