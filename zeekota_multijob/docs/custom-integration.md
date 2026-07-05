# Custom Integration

## Notifications

Set:

```lua
Config.Notify = 'custom'
Config.CustomNotify = function(source, message, notificationType)
    -- call your notification resource here
end
```

## Job Display

Add entries to `Config.JobDisplay`:

```lua
Config.JobDisplay.police = {
    label = 'Los Santos Police Department',
    description = 'Protect and serve.',
    icon = 'shield',
    color = '#3B82F6'
}
```

## Restrictions

Use `Config.Restrictions` to block switching while cuffed, combat flagged, or when custom assignment rules fail.

## State Bags

The active job and duty state are exposed on the player state bag:

- `zeekota_multijob:job`
- `zeekota_multijob:duty`
