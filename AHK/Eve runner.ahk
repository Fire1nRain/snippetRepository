; 0 -> Init state
; 1 -> Finished
; 2 -> Found NoOBJ
; 3 -> Found Yellow target
; 4 -> Found Star gate warp
; 5 -> Found Station warp
; 6 -> Error/Exit state
global runnerState = 0
global runnerStateMessage := ["Initializing","Finished","No OBJ selected","Select next jump","Warping to stargate","Warping to Station","Error!"]
global stopPressed = 0
global warpWaitCount = 0
global missionState = 0
global missionStateMessage := ["Initializing","Warping to target station","In target station","Waiting for quest window","Hand in mission","Mission completed","Warping back to origin","Finished"]

^B::
    stopPressed = 1
    Gui, Destroy
return

Numpad0 & Numpad5::
    ; some init work
    stopPressed = 0
    warpWaitCount = 0
    runnerState = 0
    missionState = 0
    initStateWindow()
    SetTitleMatchMode, 1 ; check for prefix
    ; start looping
    while(stopPressed = 0 and runnerState <> 6 and runnerState <> 1){
        ;wait for EVE window
        WinWaitActive, EVE - 
        if(runnerState = 0){
            changeMissionState(1)
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                moveAndClick(FoundX,FoundY)
            }else if(findNoOBJ(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(2)
                if(findYellowTarget(FoundX,FoundY)){
                    changeState(3)
                    moveAndClick(FoundX+100,FoundY,50,5)
                }else{
                   ; can't find target, beep and exit
                   notifyError("WarpIconNotFound")
                }

            }else{
                ; can't find target, beep and exit
                notifyError("NoWarpTargetNorIcon")
            }
        }else if(runnerState = 2){
            warpWaitCount += 1
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                moveAndClick(FoundX,FoundY)
            }else if(findStationWarp(FoundX,FoundY)){
                changeState(5)
                moveAndClick(FoundX,FoundY)
            }else if(findYellowTarget(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(3)
                moveAndClick(FoundX,FoundY)
            }else{
                if(warpWaitCount > 480){
                    notifyError("NoWarpTargetNorIcon")
                }
            }
        }else if(runnerState = 3){
            if(findStargate(FoundX,FoundY)){
                changeState(4)
                moveAndClick(FoundX,FoundY)
            }else if(findStationWarp(FOundX,FoundY)){
                changeState(5)
                moveAndClick(FoundX,FoundY)
            }else{
                ; can't find target, beep and exit
                notifyError("WarpIconNotFound")
            }
        }else if(runnerState = 4){
            warpWaitCount += 1
            if(warpWaitCount > 360){
                notifyError("WarpingTimeout")
            }else if(findNoOBJ(FoundX,FoundY)){
                warpWaitCount = 0
                changeState(2)
            }
        }else if(runnerState = 5){
            warpWaitCount += 1
            if(warpWaitCount > 480){
                notifyError("DockingTimeout")
            }else if(findUndock(FoundX,FoundY)){
                if(missionState = 1){
                    warpWaitCount = 0
                    changeMissionState(2)
                }else if(missionState = 2){
                    if(findMission(FoundX,FoundY)){
                        warpWaitCount = 0
                        moveAndClick(FoundX,FoundY,10,10,true)
                        changeMissionState(3)
                    }else
                        warpWaitCount++
                }else if(missionState = 3){
                    if(findMissionWindow(FoundX,FoundY)){
                        warpWaitCount = 0
                        moveAndClick(FoundX,FoundY)
                        changeMissionState(4)
                    }else
                        warpWaitCount++
                }else if(missionState = 4){
                    if(findMissionComplete(FoundX,FoundY)){
                        warpWaitCount = 0
                        moveAndClick(FoundX,FoundY)
                        changeMissionState(5)
                    }else
                        warpWaitCount++
                }else if(missionState = 5){
                    moveAndClick(FoundX,FoundY)
                    changeMissionState(6)
                    changeState(2)
                }else if(missionState = 6){
                    changeState(1)
                    changeMissionState(7)
                    notifySound("missionCompleted")
                }
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
    Gui, Add, Text,, % "Mission: " missionStateMessage[missionState+1]
    Gui, Add, Text,, % "State: " runnerStateMessage[runnerState+1]
    Gui, Add, Text,W200, Searching: None
    Gui, Show, NoActivate W220 H80 x40 y0, Eve runner
}

changeMissionState(newState){
    missionState := newState
    ControlSetText, Static1, % "Mission: " missionStateMessage[missionState+1], Eve runner,Mission:
}

changeState(newState){
    runnerState := newState
    ControlSetText, Static2, % "State: " runnerStateMessage[runnerState+1], Eve runner,State:
}

changeSearching(newSearching){
    ControlSetText, Static3, Searching: %newSearching%, Eve runner,Searching:
}

findNoOBJ(ByRef FoundX, ByRef FoundY){
    changeSearching("No Object Selected")
    return findImage(FoundX,FoundY,1640,0,1920,200,50,"No OBJ")
    ; ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *50 No OBJ.png
    ; if (ErrorLevel = 2){
    ;     SoundBeep, 750
    ;     MsgBox Could not conduct the search.
    ;     return False
    ; }else if (ErrorLevel = 1){
    ;     ; SoundBeep
    ;     return False
    ; }else
    ;     return True
}
findYellowTarget(ByRef FoundX, ByRef FoundY){
    changeSearching("Next jump target")
    return findImage(FoundX,FoundY,1460,200,1920,1080,40,"yellowTarget")
    ; ImageSearch, FoundX, FoundY, 1460,200, 1920,1080, *TransBlack *40 yellowTarget.png
    ; if (ErrorLevel = 2){
    ;     SoundBeep, 750
    ;     MsgBox Could not conduct the search.
    ;     return False
    ; }else if (ErrorLevel = 1){
    ;     ; SoundBeep
    ;     return False
    ; }else
    ;     return True
}
findStationWarp(ByRef FoundX, ByRef FoundY){
    changeSearching("Station Warp icon")
    return findImage(FoundX,FoundY,1640,0,1920,200,150,"stationWarp")
    ; ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *150 stationWarp.png
    ; if (ErrorLevel = 2){
    ;     SoundBeep, 750
    ;     MsgBox Could not conduct the search.
    ;     return False
    ; }else if (ErrorLevel = 1){
    ;     ; SoundBeep
    ;     return False
    ; }else
    ;     return True
}
findStargate(ByRef FoundX, ByRef FoundY){
    changeSearching("Stargate Warp icon")
    return findImage(FoundX,FoundY,1640,0,1920,200,150,"stargate")
    ; ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *150 stargate.png
    ; if (ErrorLevel = 2){
    ;     SoundBeep, 750
    ;     MsgBox Could not conduct the search.
    ;     return False
    ; }else if (ErrorLevel = 1){
    ;     ; SoundBeep
    ;     return False
    ; }else
    ;     return True
}

findUndock(ByRef FoundX, ByRef FoundY){
    changeSearching("Undock Warp icon")
    return findImage(FoundX,FoundY,1640,0,1920,200,50,"docking")
    ; ImageSearch, FoundX, FoundY, 1640,0, 1920,200, *TransBlack *50 docking.png
    ; if (ErrorLevel = 2){
    ;     SoundBeep, 750
    ;     MsgBox Could not conduct the search.
    ;     return False
    ; }else if (ErrorLevel = 1){
    ;     ; SoundBeep
    ;     return False
    ; }else
    ;     return True
}

findMission(ByRef FoundX, ByRef FoundY){
    changeSearching("Mission")
    return findImage(FoundX,FoundY,1460,200,1920,1080,40,"missionGiver")
}

findMissionWindow(ByRef FoundX, ByRef FoundY){
    changeSearching("Mission window")
    return findImage(FoundX,FoundY,0,0,1920,1080,40,"missionWindow")
}

findMissionComplete(ByRef FoundX, ByRef FoundY){
    changeSearching("Mission complete")
    return findImage(FoundX,FoundY,0,0,1920,1080,40,"missionComplete")
}


findImage(ByRef FoundX, ByRef FoundY, startX, startY, endX, endY, diviation, imgName){
    ImageSearch, FoundX, FoundY, %startX%, %startY%, %endX%, %endY%, *TransBlack *%diviation% %imgName%.png
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

notifyError(err:=0){
    if(err=0){
        SoundBeep 750,500
        SoundBeep 750,500
    }else{
        notifySound(err)
    }
    changeState(6)
}

notifySound(sound){
    SoundPlay, Sounds\%sound%.mp3
}

moveAndClick(moveX,moveY, devX:=10, devY:=10, doubleClick:=false){
    moveX += randDiviation()
    moveY += randDiviation()
    sleepDelay := randDiviation(50)
    sleepDelay += 200
    MouseMove, moveX, moveY, 10
    Sleep sleepDelay
    MouseClick, Left
    if(doubleClick){
        Sleep 100
        MouseClick, Left
    }
    Sleep sleepDelay
    MouseMove, randDiviation(200),randDiviation(200),10
}

randDiviation(range:=10){
    Random,_rand,0,range
    return _rand
}
