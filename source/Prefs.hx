package;

import flixel.FlxG;

/**
 * Alright, the basics are here for preferences stuff.
 */
class Prefs
{
	public static var versionsFolder(default, set):String;
	public static var snapshot:Bool = false;

	static var isInitialized:Bool = false;

	static function set_versionsFolder(folder:String):String
	{
		PlayState.versionsFolderPath = folder;
		versionsFolder = folder;

		if (isInitialized) // This is probs f'ing stupid to do but 🖕/j
			save();

		if (PlayState.directoryText != null)
			PlayState.directoryText.text = 'Current Directory:\n$folder';

		return versionsFolder;
	}

	/**
	 * Keeps track of FlxG.sound.muted
	 * 
	 * NOT IMPLEMENTED
	 */
	public static var muteSound(default, set):Bool = false;

	static function set_muteSound(value:Bool):Bool
	{
		//FlxG.sound.muted = value;
		muteSound = value;

		if (isInitialized) // This is probs f'ing stupid to do but 🖕/j
			save();

		return value;
	}

	/**
	 * This determines what goes before the version string e.g. "Universe Engine 5.5.0".
	 * 
	 * NOT IMPLEMENTED
	 */
	public static var nameBeforeVersion:String = '';

	public static function load():Void
	{
		if (FlxG.save.data.vf != null)
		{
			set_versionsFolder(FlxG.save.data.vf);
		}
		if (FlxG.save.data.ms != null)
		{
			muteSound = FlxG.save.data.ms;
		}
		if (FlxG.save.data.nbv != null)
		{
			nameBeforeVersion = FlxG.save.data.nbv;
		}
		if (FlxG.save.data.mute != null) {}
		if (FlxG.save.data.snapshot != null)
			snapshot = FlxG.save.data.snapshot;
	}

	public static function save():Void
	{
		FlxG.save.data.vf = versionsFolder;
		FlxG.save.data.ms = muteSound;
		FlxG.save.data.nbv = nameBeforeVersion;
		FlxG.save.data.snapshot = snapshot;

		FlxG.save.flush();
	}

	public static function initialize():Void
	{
		FlxG.save.bind('UE_Launcher', 'Video_Bot'); // PREFS NEED A HOME LMAO

		#if sys
		set_versionsFolder(haxe.io.Path.directory(haxe.io.Path.directory(Sys.programPath()) + "/versions/"));
		#else
		set_versionsFolder('./versions/');
		#end
		//FlxG.sound.playMusic(Paths.music('this_prevents_the_game_from_crashing'), 0);

		isInitialized = true;
		load();
	}
}