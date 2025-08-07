package;

import flixel.FlxGame;
import haxe.Http;
import openfl.display.FPS;
import openfl.display.Sprite;

using StringTools;

class Main extends Sprite
{
	public static var fpsVar:FPS;

	public static var updateVersion:String = '';

	var mustUpdate:Bool = false;

	public function new()
	{
		fpsVar = new FPS(10, 3, 0x14FFFF);

		updater();
		super();
		if (mustUpdate)
		{
			addChild(new FlxGame(0, 0, OutdatedState, 60, 60, true));
		}
		else
		{
			addChild(new FlxGame(0, 0, PlayState, 60, 60, true));
		}
		addChild(fpsVar);
		if (fpsVar != null)
		{
			fpsVar.visible = true;
		}
	}

	function updater()
	{
		trace('checking for update');
		var http = new haxe.Http("https://raw.githubusercontent.com/VideoBotYT/Universe-Engine-Launhcer/refs/heads/main/gitVersion.txt");

		http.onData = function(data:String)
		{
			updateVersion = data.split('\n')[0].trim();
			var curVersion:String = PlayState.versionString.trim();
			trace('version online: ' + updateVersion + ', your version: ' + curVersion);
			if (updateVersion != curVersion)
			{
				trace('versions arent matching!');
				mustUpdate = true;
			}
		}

		http.onError = function(error)
		{
			trace('error: $error');
		}

		http.request();
	}
}
