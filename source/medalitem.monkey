Strict
Import vsat
Import medals
Import extra

Class MedalItem Extends VRect
	
	Global font:AngelFont
	
	Method New(name:String, fileName:String)
		Super.New(0, 0, 0, 0)
		Self.name = name
		Self.description = Medals.DescriptionFor(name)
		image = ImageCache.GetImage(RealPath("medals/" + fileName), Image.MidHandle)
		times = Medals.HowManyOf(name)
		color.Set(Color.NewBlue)
		AssertWithException(font, "MedalItem has no font set.")
	End
	
	Method Width:Float() Property
		Return Max(image.Width(), font.TextWidth(name))
	End
	
	Method Height:Float() Property
		Return image.Height() + font.height*2
	End
	
	Method Draw:Void()
		Local h:Float = image.Height()
		PushMatrix()
		Scale(0.8, 0.8)
		font.DrawText(name, 0, 0, AngelFont.ALIGN_CENTER, AngelFont.ALIGN_TOP)
		PopMatrix()
		PushMatrix()
			ScaleAt(0, h * 1.55, 0.8, 0.8)
			font.DrawText("x "+times, 0, font.height + image.Height(), AngelFont.ALIGN_CENTER, AngelFont.ALIGN_TOP)
		PopMatrix()
		DrawImage(image, 0, font.height + image.Height()/2)
	End
	
	Method Name:String() Property
		Return name
	End
	
	Method Description:String() Property
		Return description
	End
	
	
	Private
	Field image:Image
	Field name:String
	Field description:String
	Field times:Int

End

