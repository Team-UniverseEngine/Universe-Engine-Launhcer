package options;

using StringTools;

class Options extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Launcher Options';
		rpcTitle = 'Launcher Options';

		var option:Option = new Option("SnapShots", "When enabled the version list will only show snapshot builds and not stable builds", "snapshot", "bool",
			false);
		addOption(option);

		var option:Option = new Option("Mute Sound", "When enabled the sound shall be muted.", "muteSound", "bool", false);
		addOption(option);

		super();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.pressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('confirm'));
		}
	}
}
