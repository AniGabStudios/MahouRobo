
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
RespawningCollectibles := class(creative_device):
    @editable var Collectibles: []collectible_object_device = array{}

    @editable
    RespawnDelay: float = 10.0

    OnBegin<override>() : void =
        for (c : Collectibles):
            c.CollectedEvent.SubscribeAgent(HandleCollected,c)

    HandleCollected(Player: agent,collected: collectible_object_device) : void =
        collected.Hide()
        spawn{RespawnAfterDelay(collected)}

    RespawnAfterDelay(collected: collectible_object_device)<suspends> : void =
        Sleep(RespawnDelay)
        collected.Show()
        collected.RespawnForAll()