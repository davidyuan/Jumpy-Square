Strict
Import vsat
Import extra
Import particles

Class Player Extends VRect
	
	Field velocity:Vec2
	Field isJumping:Bool
	Field jumpForce:Vec2 = New Vec2(Vsat.ScreenWidth * 2.1, -Vsat.ScreenHeight*1)
	Field gravity:Float = Vsat.ScreenHeight / 27
	Field willJump:Bool
	Field lastPositions:List<Vec2>
	Field maxPositions:Int = 12
	Field jumpSound:Sound
	Field image:Image
	
	'effects
	Field sparks:SparkEmitter
	Field wallhit:ExplosionEmitter
	
	Field widthRelative:Float = 12.8
	Field heightRelative:Float = 9.6
	
	'helpers
	Field isIntroAnimating:Bool
	Field didTouchAnyWall:Bool = True
	
	
'--------------------------------------------------------------------------
' * Init & Helpers
'--------------------------------------------------------------------------
	Method New()
		Super.New(0, 0, Int(Vsat.ScreenWidth/widthRelative), Int(Vsat.ScreenHeight/heightRelative))
		color.Set(Color.White)
		renderOutline = True
		velocity = New Vec2
		lastPositions = New List<Vec2>
		jumpSound = LoadSound("audio/jump.mp3")
		
		InitImageAndHandle()
		InitParticles()
	End
	
	Method InitImageAndHandle:Void()
		Select Vsat.ScreenHeight
			Case 960
				image = ImageCache.GetImage(RealPath("player.png"))
				image.SetHandle(6, 6)
			Case 1136
				image = ImageCache.GetImage(RealPath("player5.png"))
				image.SetHandle(6, 6)
			Case 1024
				image = ImageCache.GetImage(RealPath("player_ipad.png"))
				image.SetHandle(5, 5)
			Case 2048
				image = ImageCache.GetImage(RealPath("player.png"))
				image.SetHandle(10, 10)
		End
	End
	
	Method InitParticles:Void()
		sparks = New SparkEmitter
		sparks.InitWithSize(120)
		sparks.particleLifeSpan = 1.2
		sparks.particleLifeSpanVariance = 0.3
		sparks.slowDownSpeed = 0.9
		sparks.SetEmissionRate(40)
		sparks.positionVariance.Set(0, size.y/2)
		
		wallhit = New ExplosionEmitter
		wallhit.InitWithSize(30)
		wallhit.particleLifeSpan = 0.6
		wallhit.particleLifeSpanVariance = 0.1
		wallhit.oneShot = True
		wallhit.positionVariance.Set(0, size.y*0.75)
		wallhit.emissionAngleVariance = 45
		wallhit.size.Set(5, 5)
		wallhit.endSize.Set(0.2, 0.2)
		wallhit.endColor.Alpha = 0.0
		wallhit.speed = Vsat.ScreenWidth * 0.5
	End
	
	Method Reset:Void()
		position.y = Vsat.ScreenHeight * 0.1
		velocity.Set(0,0)
		If Rnd() > 0.5
			SetLeft()
		Else
			SetRight()
		End
		lastPositions.Clear()
		willJump = False
		sparks.StopNow()
		wallhit.StopNow()
	End
	

'--------------------------------------------------------------------------
' * Update
'--------------------------------------------------------------------------	
	Method Update:Void(dt:Float)
		UpdatePhysics(dt)
		UpdateLastPosition()
		UpdateParticles(dt)
	End
	
	Method UpdateLastPosition:Void()
		If Not isJumping
			maxPositions = 6
		Else
			maxPositions = 12
		End
		
		lastPositions.AddFirst(New Vec2(position))
		If lastPositions.Count() > maxPositions
			lastPositions.RemoveLast()
		End
	End
	
	Method UpdatePhysics:Void(dt:Float)
		If isJumping
			velocity.y += gravity * 1.4
			velocity.Limit(gravity * 50)
		Else
			velocity.y += gravity * 2
			velocity.Limit(gravity * 100)
		End
		
		position.Add(velocity.x * dt, velocity.y * dt)
		
		If (position.y - size.y * 0.3 > Vsat.ScreenHeight) Or (position.y < -Self.size.y)
			Local gameOver:= New VEvent
			gameOver.id = "GameOver"
			Vsat.FireEvent(gameOver)
		End
		
		'Stick to wall
		Local friction:Float = 0.2
		Local touchesAnyWall:Bool = False
		
		If Self.TouchesLeftWall()
			touchesAnyWall = True
			position.x = 1
		ElseIf Self.TouchesRightWall()
			touchesAnyWall = True
			position.x = Vsat.ScreenWidth - Self.size.x - 1
		End
		
		If touchesAnyWall
			If didTouchAnyWall = False
				OnWallImpact()
				didTouchAnyWall = True
			End
			
			'First reset position then apply velocity with friction
			position.Sub(velocity.x * dt, velocity.y * dt)
			position.Add(velocity.x * dt, velocity.y * dt * friction)
			isJumping = False
			If willJump Then Self.Jump()
		Else
			didTouchAnyWall = False
		End
	End
	
	Method UpdateParticles:Void(dt:Float)
		If position.x < 5
			sparks.SetPosition(1, Self.position.y + size.y/2)
			sparks.emissionAngle = -45
		ElseIf position.x > Vsat.ScreenWidth - size.x - 5
			sparks.SetPosition(Vsat.ScreenWidth-1, Self.position.y + size.y/2)
			sparks.emissionAngle = 45-180
		End
		sparks.Update(dt)
		wallhit.Update(dt)
	End
	
	Method Jump:Void()
		If Not isJumping
			isJumping = True
			willJump = False
			If position.x <= 1
				position.x = 3
				velocity.Set(jumpForce)
				VPlaySound(jumpSound, 28)
			ElseIf position.x + Self.size.x + 1 >= Vsat.ScreenWidth
				position.x = Vsat.ScreenWidth - 3 - Self.size.x
				velocity.Set(-jumpForce.x, jumpForce.y)
				VPlaySound(jumpSound, 29)
			End
		Else
			#rem
			If velocity.x < 0 And position.x < Vsat.ScreenWidth * 0.2
				willJump = True
			ElseIf velocity.x > 0 And position.x > (Vsat.ScreenWidth * 0.8) - Self.size.x
				willJump = True
			End
			#end
			willJump = True
		End
	End


'--------------------------------------------------------------------------
' * Render
'--------------------------------------------------------------------------	
	Method Render:Void()
		If color.Alpha = 0.0 Then Return
		
		sparks.Render()
		wallhit.Render()
		
		If isIntroAnimating And TouchesRightWall()
			RenderIntroAnimation()
		Else
			Super.Render()
		End
		
		If Not isJumping And lastPositions.IsEmpty() = False
			lastPositions.RemoveLast()
		End
		
		
		Local incrementAlpha:Float = (1.0 / maxPositions) * 0.2
		Local alphaCounter:Float = 0.3
		Local previous:Vec2 = position
		For Local vector:= EachIn lastPositions
			alphaCounter -= incrementAlpha
			SetAlpha(alphaCounter * Self.color.Alpha)
			PushMatrix()
			TranslateV(vector)
			DrawOutline()
			PopMatrix()
			previous = vector
		Next
	End
	
	Method DrawOutline:Void()
		DrawImage(image, 0, 0)
	End
	
	Method RenderIntroAnimation:Void()
		color.Use()
		PushMatrix()
			Translate(position.x, position.y)
			Rotate(rotation)
			ScaleAt(image.Width(), image.Height(), scale.x, scale.y)
			If Not renderOutline
				Draw()
			Else
				DrawOutline()
			End
		PopMatrix()
	End
	
	
'--------------------------------------------------------------------------
' * Helper
'--------------------------------------------------------------------------
	Method TouchesLeftWall:Bool()
		Return position.x <= 1
	End
	
	Method TouchesRightWall:Bool()
		Return position.x + Self.size.x + 1 >= Vsat.ScreenWidth
	End
	
	
	Method SetLeft:Void()
		position.x = 1
	End
	
	Method SetRight:Void()
		position.x = Vsat.ScreenWidth - Self.size.x - 1
	End
	
	
	Method OnWallImpact:Void()
		'First jump after game over
		If lastPositions.IsEmpty()
			Return
		End
		
		If position.x < 5
			wallhit.position.Set(1, Self.position.y + size.y/2)
			wallhit.emissionAngle = 0
		ElseIf position.x > Vsat.ScreenWidth-size.x-5
			wallhit.position.Set(Vsat.ScreenWidth-1, Self.position.y + size.y/2)
			wallhit.emissionAngle = 180
		End
		wallhit.StopNow()
		wallhit.Start()
	End
	
End







