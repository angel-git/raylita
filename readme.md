# Raylita - A noita like simulation

https://github.com/user-attachments/assets/196568d4-e50c-4c77-9e99-ecd49188cf92

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
