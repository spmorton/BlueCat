$complete = 0
$action = {
write-host "complete: $complete"
if($complete -eq 1)
   {
     write-host "completed"
     $timer.stop()
     Unregister-Event thetimer
   }
}
Register-ObjectEvent -InputObject $timer -EventName elapsed `
–SourceIdentifier  thetimer -Action $action

$timer.start()

#to stop
$complete = 1