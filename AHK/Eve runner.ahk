; 0 -> Init state
; 1 -> Finished
; 2 -> Found NoOBJ
; 3 -> Found Yellow target
; 4 -> Found Star gate warp
; 5 -> Found Station warp
; 6 -> Error/Exit state
global runnerState = 0
global stopPressed = 0
global warpWaitCount = 0

^B::
    stopPressed = 1
    Gui, Destroy
return

Numpad0 & Numpad5::
    ; some init work
    stopPressed = 0
    warpWaitCount = 0
    runnerState = 0
    initStateWindow()
    SetTitleMatchMode, 1 ; check for prefix
    ; start looping
    while(stopPressed = 0 and runnerState <> 6 and runnerState <> 1){
        ;wait for EVE window
        WinWaitActive, EVE - 
        if(runnerState = 0){
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                MouseMove, FoundX, FoundY
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else if(findNoOBJ(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(2)
                if(findYellowTarget(FoundX,FoundY)){
                    changeState(3)
                    MouseMove FoundX+100,FoundY+10
                    MouseClick, Left
                    Sleep 200
                    MouseMove, 0,0
                }else{
                   ; can't find target, beep and exit
                   notifyError()
                }

            }else{
                ; can't find target, beep and exit
                notifyError()
            }
        }else if(runnerState = 2){
            warpWaitCount += 1
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                MouseMove, FoundX, FoundY
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else if(findStationWarp(FoundX,FoundY)){
                changeState(5)
                MouseMove, FoundX, FoundY
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else if(findYellowTarget(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(3)
                MouseMove FoundX+100,FoundY+10
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else{
                if(warpWaitCount > 40){
                    notifyError()
                }
            }
        }else if(runnerState = 3){
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                MouseMove, FoundX, FoundY
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else if(findStationWarp(FOundX,FoundY)){
                changeState(5)
                MouseMove, FoundX, FoundY
                MouseClick, Left
                Sleep 200
                MouseMove, 0,0
            }else{
                ; can't find target, beep and exit
                notifyError()
            }
        }else if(runnerState = 4){
            warpWaitCount += 1
            if(warpWaitCount > 360){
                notifyError()
            }else if(findNoOBJ(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(2)
            }
        }else if(runnerState = 5){
            warpWaitCount += 1
            if(warpWaitCount > 480){
                notifyError()
            }else if(findUndock(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(1)
            }
        }else{
            warpWaitCount += 1
            if(warpWaitCount > 40){
                notifyError()
            }
        }

        Sleep, 500
    }
    if(runnerState = 1){
        SoundBeep 700,200
        SoundBeep 650,150
        SoundBeep 850,500
    }else
        SoundBeep 750,1000
return

initStateWindow(){
    Gui, Destroy
    Gui, +AlwaysOnTop -SysMenu +ToolWindow +Owner 
    Gui, Add, Text,, State: %runnerState%
    Gui, Add, Text,W200, Searching: None
    Gui, Show, NoActivate W200 H50 x40 y0, Eve runner
}

changeState(newState){
    runnerState := newState
    ControlSetText, Static1, State:%runnerState%, Eve runner,State:
}

changeSearching(newSearching){
    ControlSetText, Static2, Searching: %newSearching%, Eve runner,Searching:
}

findNoOBJ(ByRef FoundX, ByRef FoundY){
    changeSearching("No Object Selected")
    ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *50 No OBJ.png
    if (ErrorLevel = 2){
        SoundBeep, 750
        MsgBox Could not conduct the search.
        return False
    }else if (ErrorLevel = 1){
        ; SoundBeep
        return False
    }else
        return True
}
findYellowTarget(ByRef FoundX, ByRef FoundY){
    changeSearching("Next jump target")
    ImageSearch, FoundX, FoundY, 1460,200, 1920,1080, *TransBlack *80 yellowTarget.png
    if (ErrorLevel = 2){
        SoundBeep, 750
        MsgBox Could not conduct the search.
        return False
    }else if (ErrorLevel = 1){
        ; SoundBeep
        return False
    }else
        return True
}
findStationWarp(ByRef FoundX, ByRef FoundY){
    changeSearching("Station Warp icon")
    ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *150 stationWarp.png
    if (ErrorLevel = 2){
        SoundBeep, 750
        MsgBox Could not conduct the search.
        return False
    }else if (ErrorLevel = 1){
        ; SoundBeep
        return False
    }else
        return True
}
findStargate(ByRef FoundX, ByRef FoundY){
    changeSearching("Stargate Warp icon")
    ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *150 stargate.png
    if (ErrorLevel = 2){
        SoundBeep, 750
        MsgBox Could not conduct the search.
        return False
    }else if (ErrorLevel = 1){
        ; SoundBeep
        return False
    }else
        return True
}

findUndock(ByRef FoundX, ByRef FoundY){
    changeSearching("Undock Warp icon")
    ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *50 docking.png
    if (ErrorLevel = 2){
        SoundBeep, 750
        MsgBox Could not conduct the search.
        return False
    }else if (ErrorLevel = 1){
        ; SoundBeep
        return False
    }else
        return True
}

notifyError(){
    SoundBeep 750,500
    SoundBeep 750,500
    changeState(6)
}