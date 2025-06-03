# Raylita - A noita like simulation

[sample.mp4](sample.mp4)

## Compile & Run

```
odin run src/main/main.odin -file -out:raylita
```

## Controls

- `1-9`: switch material
- `[]`: increase decrease brush size
- `left-click`: spawn selected material
- `c`: clear screen

## TODO

- [ ] Apply multithreading, divide map into quadrants, apply common boundary to sync threads
- [ ] Add some shaders for fire bloom effect
- [ ] Only update pixels that are active, some kind of active cell tracking
- [ ] After all that, increase world size
