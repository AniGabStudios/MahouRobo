
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using {CoreCode}

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

timed_event<public> := class():
    @editable TimeToTrigger: float = 0.0
    @editable ID: string = "SetEventID"

# A Verse-authored creative device that can be placed in a level
timer_manager<public> := class(creative_device,event_listener):
    @editable Duration: float = 1800.0
    @editable Timer: timer_device = timer_device{}

    @editable var TimedEvents : []timed_event = array{}

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
        currentTime := Duration - timeRemaining
        for (Event:TimedEvents):
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

    
