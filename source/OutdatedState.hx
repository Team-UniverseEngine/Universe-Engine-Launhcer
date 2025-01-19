package;

import PlayState;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class OutdatedState extends FlxState
{
	var outdatedText:FlxText;

	public static var leftState:Bool = false;

	override function create()
	{
		outdatedText = new FlxText(0, 0, FlxG.width,
			"Hello there:\n\n It looks like you're using an\n outdated version of the Universe Engine Launcher ("
			+ PlayState.versionString
			+ "), \n\n Please update to ("
			+ Main.updateVersion
			+ ") \n\n Press ESCAPE to proceed anyway.");
		outdatedText.setFormat(Paths.font('funkin.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		outdatedText.screenCenter(Y);
		add(outdatedText);
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			if (FlxG.keys.anyJustPressed([FlxKey.ENTER]))
			{
				leftState = true;
				CoolUtil.browserLoad("https://github.com/VideoBotYT/Universe-Engine-Launhcer/releases");
			}
			else if (FlxG.keys.anyJustPressed([FlxKey.ESCAPE]))
			{
				leftState = true;
			}

			if (leftState)
			{
				FlxG.sound.play(Paths.sound('confirm'));
				FlxTween.tween(outdatedText, {alpha: 0}, 1, {
					onComplete: function(twn:FlxTween)
					{
						FlxG.switchState(new PlayState());
					}
				});
			}
		}
		super.update(elapsed);
	}
}
