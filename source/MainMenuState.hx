package;

import flixel.input.keyboard.FlxKey;
import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import io.newgrounds.NG;
import lime.app.Application;
import openfl.Assets;
import sys.io.Process;
import sys.thread.Thread;

#if desktop
import Discord.DiscordClient;
#end

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.display.SimpleButton;
using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'options'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#end

	var newGaming:FlxText;
	var newGaming2:FlxText;
	var diaText:FlxText;
	var newInput:Bool = true;

	var dragging:Bool = false;

	var item:FlxSprite;
	var doorLocked:Bool = false;
	var doorTrigger:Bool = false;
	var doorThreshold:Float = 665;
	var curSound:String = Paths.sound("big");
	var curSoundIsMusic:Bool = false;


	var eggs:Map<String, Array<String>> = ["big" => ['big', 'menu/chungus', '95'], "ooga" => ['booga', 'menu/ooga', '25'], "friend" => ["creepyMusic", "menu/friend", "5", "1"]];

	var rightDoor:FlxSprite;
	var lastX:Float = 640;

	public static var displayGameVer:String;
	public static var gameVer:String = "JK Engine v0.9";
	public static var firstEnter:Bool = false;
	public static var inSubstate:Bool = false;
	public static var recording = false;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		displayGameVer = gameVer;
		#if debug 
		displayGameVer += " DEBUG";
		#end

		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;

		if (firstEnter) {
			FlxG.sound.playMusic(Paths.music('bcMenu'));
			firstEnter = false;
		} else if (!FlxG.sound.music.playing) {
			FlxG.sound.playMusic(Paths.music('bcMenu'));
		}

		persistentDraw = persistentUpdate = true;

		// chungus
		item = new FlxSprite( 0, 0 ).loadGraphic( Paths.image("menu/chungus") );
		add(item);

		// BG stuff goes here.
		var leftDoor:FlxSprite = new FlxSprite( -7, 0 ).loadGraphic( Paths.image("menu/menuBackgroundLeft") );
			add(leftDoor);

		rightDoor = new FlxSprite( 640, 0 ).loadGraphic( Paths.image("menu/menuBackgroundRight") );
		FlxMouseEventManager.add(rightDoor, dragDoor, releaseDoor);
		add(rightDoor);
		// BG stuff end.

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite( 20, 80 + (i * 90) );
				menuItem.frames = Paths.getSparrowAtlas(("menu/ui/" + (optionShit[i].toLowerCase() + "_sheet")));
				menuItem.animation.addByPrefix('idle', 'idle', 24, true);
				menuItem.animation.addByPrefix('active', 'active', 24, true);
				menuItem.animation.play('idle');
				menuItem.ID = i;
				menuItem.setGraphicSize( Std.int(menuItem.width / 2) );
				menuItem.scrollFactor.set();
				menuItem.antialiasing = true;
			menuItems.add(menuItem);
		}

		// Add Idleing Cat
		var idleingCat:FlxSprite = new FlxSprite(820, 260);
			idleingCat.frames = Paths.getSparrowAtlas('menu/CatIdle');
			idleingCat.animation.addByPrefix('idle', 'IDLE_CAT', 24, true);
			idleingCat.animation.play('idle');
			idleingCat.setGraphicSize( Std.int(idleingCat.width * 1) );
			idleingCat.updateHitbox();
			idleingCat.flipX = true;
		add(idleingCat);
		
		// Dialogue Box & Text
		var diaBox:FlxSprite = new FlxSprite(15, 0).loadGraphic( Paths.image("menu/menuTextBox") );
		add(diaBox);

		// Font Size 28
		// 945, 155
		diaText = new FlxText(645, 120, 600, '', 28, false);
		diaText.setFormat(Paths.font('taxicab.ttf'), 36, 0x00FFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0x00000000);
		diaText.borderSize = 3;
		diaText.autoSize = false;
		setMainMenuText();
		add(diaText);

		// Borders & Version Shit. Added last.
		var menuBorders:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/menuBorders") );
		add(menuBorders);
	
		var menuBText:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/menuBorderText") );
		add(menuBText);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, gameVer, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diaText.borderSize = 7;
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		controls.setKeyboardScheme(Controls.KeyboardScheme.None, true);

		// Custom Keybinds
		controls.bindKeys(UP, [FlxG.save.data.KEY_UP, FlxKey.UP]);
		controls.bindKeys(LEFT, [FlxG.save.data.KEY_LEFT, FlxKey.LEFT]);
		controls.bindKeys(DOWN, [FlxG.save.data.KEY_DOWN, FlxKey.DOWN]);
		controls.bindKeys(RIGHT, [FlxG.save.data.KEY_RIGHT, FlxKey.RIGHT]);
		controls.bindKeys(ACCEPT, [FlxG.save.data.KEY_ACCEPT]);
		controls.bindKeys(BACK, [FlxG.save.data.KEY_BACK]);
		controls.bindKeys(RESET, [FlxG.save.data.KEY_RESET]);

		changeItem();
		loadLockedSongList();

		super.create();
	}

	public static function loadLockedSongList() {
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		FlxG.save.data.lockedSongs = [];

		// menu/ui/songselect/icons/icon name
		for (i in 0...initSonglist.length)
		{
			var songData = initSonglist[i];
			var splitList = songData.split(":");
			var songName = splitList[0];
			var songLockData = Std.int( Std.parseFloat(splitList[3]) );
			var songLocked:Bool = false;

			switch(songLockData) {
				case 1:
					songLocked = false;
				case 2:
					songLocked = true;
			}

			if (songLocked) FlxG.save.data.lockedSongs.push(songName.toLowerCase());

		}

		trace("Reloaded Locked Songs List! List: " + ( FlxG.save.data.lockedSongs.toString() ) );
		FlxG.save.flush();
	}

	function getRandomText(lines:Array<String>):String {
		var selection = FlxG.random.getObject(lines);

		while (selection.startsWith('*')) {
			selection = FlxG.random.getObject(lines);
		}

		return selection;
	}

	function getRandomSpecialText(lines:Array<String>):String {
		var selection:String;
		var specials:Array<String> = [];

		for (i in lines) {
			if (i.startsWith('*')) {
				var txt = i;
				var spl = txt.split('');
					spl.shift();
					txt = spl.join('');
				specials.push(txt);
			}
		}

		selection = FlxG.random.getObject(specials);
		return selection;
	}

	function setRandomEgg() {
		var names:Array<String> = [];
		var sounds:Array<String> = [];
		var images:Array<String> = [];
		var weights:Array<Float> = [];
		var indices:Map<String, Int> = [];
		var isMusic:Array<Bool> = [];

		var j = 0;
		for (i in eggs.keys()) {
			var egg = eggs.get(i);
			
			images.push(Paths.image(egg[1]));
			weights.push(Std.parseFloat(egg[2]));
			sounds.push(Paths.sound(egg[0]));
			indices.set(i, j);
			names.push(i);

			j += 1;
		}

		var res = FlxG.random.getObject(names, weights);
		var index = indices.get(res);

		trace(res + ", " + index);

		curSound = sounds[index];

		item.loadGraphic(images[index]);
		item.screenCenter();

		if (res == 'friend') {
			FlxG.sound.playMusic(Paths.music("creepyMusic"));
			doorLocked = true;
		}
	}

	function setMainMenuText() {
		var file:String = Assets.getText(Paths.txt('menuText'));
		var lines:Array<String> = file.split('\n');
		
		// Makes sure that on the first playthrough, the welcome text is shown.
		var selection:String;
		if (!recording) {
			selection = getRandomText(lines);
			if (FlxG.save.data.firstPlaythrough == null) {
				selection = lines[0];

				FlxG.save.data.firstPlaythrough = false;
				FlxG.save.flush();
			}
		} else {
			selection = getRandomSpecialText(lines);
		}

		var selectionLines = selection.split('|');
		var rejoined = selectionLines.join('\n');

		diaText.text = rejoined;
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin && !inSubstate)
		{
			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				FlxG.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					#if linux
					Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
					#else
					FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
					#end
				} else if (optionShit[curSelected] == 'options') {
					inSubstate = true;
					openSubState(new OptionsMenu());
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 1.3, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story mode':
										// Swap to StoryMapState, not StoryMenuState
										FlxG.switchState(new StoryMapState());
										trace("Story Map Selected");
									case 'freeplay':
										FlxG.switchState(new FreeplayState());

										trace("Freeplay Menu Selected");
								}
							});
						}
					});
				}
			}
		}

		if (!doorLocked) {
			if (!dragging) {
				rightDoor.x = 640;
				lastX = 640;
			} else {
				if (FlxG.mouse.screenX >= 640 && FlxG.mouse.screenX <= 2560) {
					rightDoor.x = 640 + ( (FlxG.mouse.screenX - 640) * 0.65 );

					if (!doorTrigger && lastX <= doorThreshold && rightDoor.x > doorThreshold) {
						doorTrigger = true;
						FlxG.sound.play(curSound);
					}

					lastX = rightDoor.x;
				}
			}
		} else {
			rightDoor.x = 960;
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.updateHitbox();
		});
	}

	function dragDoor(object:FlxObject) {
		if (!doorLocked && !inSubstate) {
			setRandomEgg();
			dragging = true;
		}
	}

	function releaseDoor(object:FlxObject) {
		dragging = false;
		doorTrigger = false;

		if (!doorLocked) {
			FlxG.sound.list.forEach(function(s:FlxSound) {
				s.stop();
			});
		}
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		
		menuItems.forEach(function(spr:FlxSprite) {
			if (spr.ID == curSelected) {
				spr.animation.play('active');
			} else spr.animation.play('idle');
		});
	}
}