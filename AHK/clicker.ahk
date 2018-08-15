global stopPressed = 0

^B::
    SoundBeep
    stopPressed = 1
return


^Numpad5::
        SoundBeep 750,200
        SoundBeep 700,150
        SoundBeep 850,500
return