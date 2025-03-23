package;

import flixel.FlxG;

class Data
{
	public var versionsFolder(default, set):String;
	public var snapshot:Bool = false;

	function set_versionsFolder(folder:String):String
	{
		PlayState.versionsFolderPath = folder;
		versionsFolder = folder;

		if (Prefs.isInitialized) // This is probs f'ing stupid to do but 🖕/j
			Prefs.save();

		if (PlayState.directoryText != null)
			PlayState.directoryText.text = 'Current Directory:\n$folder';

		return versionsFolder;
	}

	/**
	 * Keeps track of FlxG.sound.muted
	 * 
	 * NOT IMPLEMENTED
	 */

	/**
	 * This determines what goes before the version string e.g. "Universe Engine 5.5.0".
	 * 
	 * NOT IMPLEMENTED
	 */
	public var nameBeforeVersion:String = '';

	public function new()
	{
		#if sys
		set_versionsFolder(haxe.io.Path.directory(haxe.io.Path.directory(Sys.programPath()) + "/versions/"));
		#else
		set_versionsFolder('./versions/');
		#end
	}
}

/**
 * Alright, the basics are here for preferences stuff.
 */
class Prefs
{
	// Swapping it to Psych 0.7+ like data management because it's being fucky-wucky.
	public static var data:Data = null;
	public static var defaultData:Data = null;

	public static var isInitialized:Bool = false;

	public static function load():Void
	{
		if (data == null)
			data = new Data();
		if (defaultData == null)
			defaultData = new Data();

		for (key in Reflect.fields(data))
		{
			Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
		}
		isInitialized = true;
	}

	public static function save():Void
	{
		for (key in Reflect.fields(data))
		{
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.flush();
	}

	public static function initialize():Void
	{
		FlxG.save.bind('UE_Launcher', 'Video_Bot'); // PREFS NEED A HOME LMAO
		load();
	}
}