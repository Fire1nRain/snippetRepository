^g::
    Gui, +AlwaysOnTop -SysMenu +ToolWindow +Owner
    Gui, Add, Text,, State:0
    Gui, Show, NoActivate W200 H50, Eve runner state
    Sleep, 2000
    ControlSetText, Static1, State:1, Eve runner state,State:
return