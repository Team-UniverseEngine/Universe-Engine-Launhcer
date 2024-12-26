package;

import FlxUIDropDownMenuCustom;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Http;
import lime.app.Application;
import lime.utils.Bytes;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

class PlayState extends FlxState
{
	var bg:FlxSprite;

	var play:FlxButton;
	var version:FlxUIDropDownMenuCustom;
	var credits:FlxButton;

	public var online_url:String = "";

	var progBar_bg:FlxSprite;
	var progressBar:FlxBar;

	var http:Http;
	var versionList:String = '';
	var zip:URLLoader;

	var versionNumber:String = '';
	var downloadText:FlxText;

	override public function create()
	{
		http = new Http("https://raw.githubusercontent.com/VideoBotYT/Universe-Engine/refs/heads/main/versionList.txt");

		bg = new FlxSprite(0, 0).loadGraphic("assets/images/bg.png");
		bg.screenCenter();
		bg.setGraphicSize(bg.width * 1.5);
		add(bg);

		progBar_bg = new FlxSprite(FlxG.width / 2, FlxG.height / 2 + 50).makeGraphic(500, 20, FlxColor.BLACK);
		progBar_bg.x -= 250;
		progressBar = new FlxBar(progBar_bg.x + 5, progBar_bg.y + 5, LEFT_TO_RIGHT, Std.int(progBar_bg.width - 10), Std.int(progBar_bg.height - 10), this,
			"entire_progress", 0, 100);
		progressBar.numDivisions = 3000;
		progressBar.createFilledBar(0xFF8F8F8F, 0xFFAD4E00);

		play = new FlxButton(FlxG.width / 2 - 200, 0, "PLAY", function()
		{
			#if sys
			prepareInstall(startGame);
			#end
		});
		play.screenCenter(Y);
		add(play);

		credits = new FlxButton(play.x + 200, play.y, "CREDITS", function()
		{
			FlxG.switchState(new CreditsState());
		});
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

		#if sys
		zip = new URLLoader();
		zip.dataFormat = BINARY;
		zip.addEventListener(openfl.events.Event.COMPLETE, unzipGame);
		#end

		#if sys
		downloadText = new FlxText(0, 0, FlxG.width, 'Download Status: READY', 15);
		#else
		downloadText = new FlxText(0, 0, FlxG.width, 'Download Status: FAILED', 15);
		#end
		downloadText.alignment = RIGHT;
		downloadText.y = FlxG.height - (downloadText.height + 5);
		add(downloadText);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		versionNumber = "/" + version.selectedLabel + "/";
		super.update(elapsed);
	}

	#if sys
	function startGame()
	{
		downloadText.text = 'Download Status: READY';
		var exePath = Sys.programPath();
		var exeDir = haxe.io.Path.directory(exePath);
		var versionPath = haxe.io.Path.directory("/versions/");
		var versionsPath = haxe.io.Path.directory(exeDir + versionPath + versionNumber);
		try
		{
			// trace(versionsPath + '/Universe Engine 0.1.0/');
			if (version.selectedLabel == "0.1.0")
			{
				try
				{
					FileSystem.rename(versionsPath + '/Universe Engine 0.1.0/', versionsPath + '/ue1');
				}
				catch (e:Dynamic)
				{
					var yuh:String = 'yuh'; // lmao.
				}
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

		if (!FileSystem.exists("./versions/" + version.selectedLabel + "/"))
		{
			trace("version folder not found, creating the directory...");
			FileSystem.createDirectory("./versions/" + version.selectedLabel + "/");
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
			var path = './versions/${version.selectedLabel + addition}/UniverseEngine.exe';
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
		JSEZip.unzip(path + 'FNF-Universe-Engine-windows.zip', "./versions/" + version.selectedLabel + "/");
		// trace('DONE');

		// trace('Removing file and folder!');
		FileSystem.deleteFile('$path/FNF-Universe-Engine-windows.zip');
		FileSystem.deleteDirectory(path);

		startGame();
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
