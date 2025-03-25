package;

import FlxUIDropDownMenuCustom;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUISpriteButton;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Http;
import lime.app.Application;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import options.OptionState;

using StringTools;

#if sys
import openfl.net.FileReference;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

class PlayState extends FlxState
{
	var bg:FlxSprite;
	var rings:FlxSprite;
	var dots:FlxBackdrop;
	var grid:FlxBackdrop;

	var playButton:FlxSprite;
	var version:FlxUIDropDownMenuCustom;
	var credits:FlxSprite;
	var optionsButton:FlxSprite;
	var versionFolder:FlxSprite;

	public static var versionString:String = "0.4.5";

	public static var versionsFolderPath:String = './versions/';

	public var online_url:String = "";

	var progBar_bg:FlxSprite;
	var progressBar:FlxBar;

	var http:Http;
	var versionList:String = '';
	var zip:URLLoader;

	var versionNumber:String = '';
	var downloadText:FlxText;

	var refreshList:FlxButton;

	public static var directoryText:FlxText;

	override public function create()
	{
		Prefs.initialize();
		if (Prefs.data.snapshot)
			http = new Http("https://raw.githubusercontent.com/VideoBotYT/Universe-Engine/refs/heads/snapshot/versionListSnaps");
		else
			http = new Http("https://raw.githubusercontent.com/VideoBotYT/Universe-Engine/refs/heads/main/versionList.txt");

		FlxG.sound.playMusic(Paths.music("Universe Launcher Menu Music"), 0.7);

		bg = new FlxSprite(0, 0).loadGraphic(Paths.image("bg"));
		bg.screenCenter();
		bg.setGraphicSize(bg.width * 1.5);
		add(bg);

		rings = new FlxSprite(0, 0).loadGraphic(Paths.image("rings"));
		rings.screenCenter();
		add(rings);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(20, 20);
		grid.alpha = 1;
		add(grid);

		dots = new FlxBackdrop(Paths.image("blackDots"));
		dots.velocity.set(10, 0);
		dots.alpha = 0.6;
		add(dots);

		playButton = new FlxSprite(FlxG.width / 2 + 200, FlxG.height / 2 - 200, Paths.image("playButton"));
		playButton.scale.set(0.8, 0.8);
		add(playButton);

		optionsButton = new FlxSprite(playButton.x, playButton.y + 100, Paths.image("optionsButton"));
		optionsButton.scale.set(0.8, 0.8);
		optionsButton.alpha = 0.6;
		add(optionsButton);

		versionFolder = new FlxSprite(playButton.x, playButton.y + 200, Paths.image("versionFolder"));
		versionFolder.scale.set(0.8, 0.8);
		versionFolder.alpha = 0.6;
		add(versionFolder);

		credits = new FlxSprite(0, 0).loadGraphic(Paths.image("credits"));
		add(credits);

		version = new FlxUIDropDownMenuCustom(0, 0, FlxUIDropDownMenuCustom.makeStrIdLabelArray(["Loading..."], true));
		version.screenCenter();
		add(version);

		http.onData = function(data:String)
		{
			var versions = data.split("\n").filter(function(line) return line.trim() != "");
			remove(version);
			version = new FlxUIDropDownMenuCustom(0, 0, FlxUIDropDownMenuCustom.makeStrIdLabelArray(versions, true));
			version.screenCenter();
			add(version);
		}

		http.onError = function(error)
		{
			trace('Error fetching version list: $error');
		}

		http.request();

		refreshList = new FlxButton(version.x, version.y - 20, "reload", function()
		{
			http.onData = function(data:String)
			{
				var versions = data.split("\n").filter(function(line) return line.trim() != "");
				remove(version);
				version = new FlxUIDropDownMenuCustom(0, 0, FlxUIDropDownMenuCustom.makeStrIdLabelArray(versions, true));
				version.screenCenter();
				add(version);
			}

			http.onError = function(error)
			{
				trace('Error fetching version list: $error');
			}

			http.request();
		});
		add(refreshList);

		#if sys
		zip = new URLLoader();
		zip.dataFormat = BINARY;
		zip.addEventListener(openfl.events.Event.COMPLETE, unzipGame);
		#end

		#if sys
		downloadText = new FlxText(0, 0, FlxG.width, 'Download Status: READY', 15);
		#else
		downloadText = new FlxText(0, 0, FlxG.width, 'Your system does NOT support the sys package, Downloads will not work.',
			15); // Changed the message to make more sense lmao.
		#end
		downloadText.alignment = RIGHT;
		downloadText.borderStyle = OUTLINE;
		downloadText.borderColor = 0xFF000000;
		downloadText.borderSize = 3;
		downloadText.y = FlxG.height - (downloadText.height + 5);
		add(downloadText);

		#if sys
		directoryText = new FlxText(0, 0, versionFolder.width - 100, 'Current Directory:\n$versionsFolderPath', 10);
		#else
		directoryText = new FlxText(0, 0, FlxG.width, '', 15);
		#end
		directoryText.alignment = RIGHT;
		directoryText.borderStyle = OUTLINE;
		directoryText.borderColor = 0xFF000000;
		directoryText.borderSize = 3;
		directoryText.x = versionFolder.x + 50;
		directoryText.y = versionFolder.y + versionFolder.height;
		add(directoryText);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 52, 0, "Launcher v: " + versionString, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('gaposiss.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		versionNumber = "/" + version.selectedLabel + "/";
		var generalMoved:Bool = (FlxG.mouse.justMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed);
		if (generalMoved)
		{
			playButton.alpha = 0.6;
			optionsButton.alpha = 0.6;
			versionFolder.alpha = 0.6;
		}
		if (pointerOverlaps(playButton))
		{
			playButton.alpha = 1;
			if (generalPressed)
			{
				#if sys
				prepareInstall(startGame);
				FlxG.sound.play(Paths.sound("confirm"));
				#end
			}
		}
		if (pointerOverlaps(versionFolder))
		{
			versionFolder.alpha = 1;
			if (generalPressed)
			{
				#if sys
				var fr:openfl.filesystem.File = new openfl.filesystem.File();
				fr.addEventListener(Event.SELECT, function(event:Event)
				{
					trace(fr.nativePath);
					Prefs.data.versionsFolder = fr.nativePath;
				});
				fr.browseForDirectory('Choose a versions folder to use!');
				#end
			}
		}
		if (pointerOverlaps(optionsButton))
		{
			optionsButton.alpha = 1;
			if (generalPressed)
			{
				FlxG.switchState(new OptionsState());
			}
		}
		super.update(elapsed);
	}

	function pointerOverlaps(obj:Dynamic)
	{
		return FlxG.mouse.overlaps(obj);
	}

	#if sys
	function startGame()
	{
		downloadText.text = 'Download Status: READY';
		var versionsPath = haxe.io.Path.directory(versionsFolderPath + versionNumber);
		try
		{
			// trace(versionsPath + '/Universe Engine 0.1.0/');
			if (version.selectedLabel == "0.1.0")
			{
				try
				{
					FileSystem.rename(versionsPath + '/Universe Engine 0.1.0/', versionsPath + '/ue1');
				}
				catch (e:Dynamic) {}
				versionsPath += '/ue1';
			}
		}
		catch (e:Dynamic)
		{
			trace(e);
		}

		var batch = "@echo on\n";
		batch += "setlocal enabledelayedexpansion\r\n";
		batch += 'cd $versionsPath\r\n';
		batch += "start UniverseEngine.exe\r\n";
		// batch += "endlocal";

		var path:String = haxe.io.Path.join([versionsPath, "start.bat"]);
		File.saveContent(path, batch);

		new Process(versionsPath + "/start.bat", []);
		var timer:FlxTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			FileSystem.deleteFile(path); // Don't need it post launch.
		});
	}

	// The following does a return on missing files after calling installGame() so that it can complete at the end of zipping files.
	function prepareInstall(endFunction:Void->Void)
	{
		online_url = "https://github.com/VideoBotYT/Universe-Engine/releases/download/" + version.selectedLabel + '/FNF-Universe-Engine-windows.zip';
		if (version.selectedLabel == "0.1.0")
			online_url = "https://github.com/VideoBotYT/Universe-Engine/releases/download/0.1.0/Universe.Engine.0.1.0.zip";
		// trace("download url: " + online_url);

		if (!FileSystem.exists(versionsFolderPath + '/' + version.selectedLabel + "/"))
		{
			trace("version folder not found, creating the directory...");
			FileSystem.createDirectory(versionsFolderPath + '/' + version.selectedLabel + "/");
			installGame();
			return;
		}
		else
		{
			var addition:String = '';
			if (version.selectedLabel == '0.1.0')
			{
				addition = '/ue1';
			}
			var path = '${versionsFolderPath + '/' + version.selectedLabel + addition}/UniverseEngine.exe';
			if (!FileSystem.exists(path))
			{
				trace('Likely malformed folder! Re-Installing');
				installGame();
				return;
			}
			// trace("version folder found");
			endFunction();
		}
	}

	var fatalError:Bool = false;
	var httpHandler:Http;

	public function installGame()
	{
		// trace("starting download process...");
		// So we can tell the user that it's downloading.
		downloadText.text = 'Download Status: Downloading';

		final url:String = requestUrl(online_url);
		if (url != null && url.indexOf('Not Found') != -1)
		{
			trace('File not found error!');
			fatalError = true;
		}

		zip.load(new URLRequest(online_url));
		if (fatalError)
		{
			// trace('File size is small! Assuming it couldn\'t find the url!');
			lime.app.Application.current.window.alert('Couldn\'t find the URL for the file! Cancelling download!');
			downloadText.text = 'Download Status: READY';
			return;
		}
	}

	// Unironically referenced UE's updater lmao.
	public function unzipGame(result:openfl.events.Event)
	{
		downloadText.text = 'Download Status: Unzipping, The launcher may freeze!'; // because stupid idiot me did a funny and forgot to change the text here.
		var timer = new FlxTimer().start(1, function(tmr:FlxTimer) // Timer to give it a literal second to update the text.
		{
			var path = './downloads/${version.selectedLabel}/';

			if (!FileSystem.exists(path))
			{
				FileSystem.createDirectory(path);
			}

			// trace('Loading Bytes!');
			var rawFILE:Bytes = cast zip.data;
			if (rawFILE == null)
			{
				trace("It's fuckin' NULL");
				return;
			}
			// trace('Saving Bytes!');
			File.saveBytes(path + 'FNF-Universe-Engine-windows.zip', rawFILE);
			// trace('UNZIPPING GAME');
			downloadText.text = 'Download Status: Unzipping';
			JSEZip.unzip(path + 'FNF-Universe-Engine-windows.zip', versionsFolderPath + '/' + version.selectedLabel + "/");
			// trace('DONE');

			// trace('Removing file and folder!');
			FileSystem.deleteFile('$path/FNF-Universe-Engine-windows.zip');
			FileSystem.deleteDirectory(path);

			startGame();
		});
	}

	public function requestUrl(url:String):String
	{
		httpHandler = new Http(url);
		var r = null;
		httpHandler.onData = function(d)
		{
			r = d;
		}
		httpHandler.onError = function(e)
		{
			trace("error while downloading file, error: " + e);
			fatalError = true;
		}
		httpHandler.request(false);
		return r;
	}
	#end
}
