
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
# Public event bus class, no side effects or creative_device inheritance
eventdata<public>:=class():
    AgentMap<public>: ?[string]agent = false
    Agent<public>: ?agent = false
    ValueF<public>: float = 0.0
    ValueFA<public>: ?[]float = false
    ValueI<public>: int = 0
    Location<public>: ?vector3 = false
    Msg<public>: ?string = false
    
event_bus<public> := class():
    var Listeners: [string][]listener_wrapper = map{}

    Subscribe<public>(EventName: string, Id: string, Listener: event_listener): void =
        Wrapper := listener_wrapper{Id := Id, Handler := Listener}
        if (Current := Listeners[EventName]):
            if(set Listeners[EventName] = Current + array{Wrapper}):
        else:
            if(set Listeners[EventName] = array{Wrapper}):

    Unsubscribe<public>(EventName: string, Id: string): void =
        var Remaining:[] listener_wrapper = array{}
        if (Current := Listeners[EventName]):
            for (L : Current):
                if (L.Id <> Id):  # compare by ID string
                    set Remaining = Remaining + array{L}
                else:
                    Print("Unsubscribed listener with Id: {Id} from event: {EventName}")
            if(set Listeners[EventName] = Remaining):

    Notify<public>(EventName: string, Data: eventdata): void =
        Print("Notifying Event: {EventName}")
        if (Handlers := Listeners[EventName]):
            for (L : Handlers):
                L.Handler.OnEvent(EventName,Data)

# ✅ Safe global for shared event bus per match/session
var singleton_map: weak_map(session, event_bus) = map{}

GetGlobalBus<public>(): event_bus =
    if (Map:= singleton_map[GetSession()]):
        return Map
    else:
        bus := event_bus{}
        if (set singleton_map[GetSession()] = bus):
            return bus
        else:
            return bus