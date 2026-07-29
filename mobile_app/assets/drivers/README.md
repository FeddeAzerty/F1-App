Drop driver photos here named by Jolpica's `driver_ref`, e.g.:

```
max_verstappen.png
lewis_hamilton.png
```

`DriverAvatar` (`lib/widgets/driver_avatar.dart`) looks up
`assets/drivers/{driver_ref}.png` and falls back to a generic person icon
if the file isn't present — nothing else needs to change to wire a photo
in once you have one.
