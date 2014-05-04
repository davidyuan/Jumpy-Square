Strict
Import vsat.foundation
#If TARGET = "ios"
	Import brl.gamecenter
#End

Const GAMECENTER_LEADERBOARD:String = "highscore"


Function InitGameCenter:Void()
	#If TARGET = "ios"
		gameCenter = GameCenter.GetGameCenter()
		If gameCenter.GameCenterState() = 0 And gameCenter.GameCenterAvail()
			gameCenter.StartGameCenter()
		End
	#End
End

Function SyncGameCenter:Void(withScore:Int)
	#If TARGET = "ios"
		InitGameCenter()
		If gameCenter.GameCenterState() = 2 And gameCenter.GameCenterAvail()
			gameCenter.ReportScore(withScore, GAMECENTER_LEADERBOARD)
		End
	#End
End

Function ShowGameCenter:Void()
	#If TARGET = "ios"
		InitGameCenter()
		If gameCenter.GameCenterAvail() And gameCenter.GameCenterState() = 2
			gameCenter.ShowLeaderboard(GAMECENTER_LEADERBOARD)
		End
	#End
End

Private
Global gameCenter:GameCenter
