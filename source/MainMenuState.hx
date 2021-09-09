package;

import flixel.input.keyboard.FlxKey;
import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.system.FlxSound;
import io.newgrounds.NG;
import lime.app.Application;
import openfl.Assets;
import sys.io.Process;
import sys.thread.Thread;
import GameJolt.GameJoltAPI;

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
	var percentMouseDrag:Float = 0.35;
	var curSound:String = Paths.sound("big");
	var curSoundName:String = "big";
	var curSoundIsMusic:Bool = false;
	var menuBText:FlxSprite;
	var diaBox:FlxSprite;
	var idleingCat:FlxSprite;
	var fuckingBullshitTimer:FlxTimer;
	var versionShit:FlxText;

	public static var alertSignal:FlxTypedSignal<String->Void>;

	var eggs:Map<String, Array<String>> = [
		"big" => ['big', 'menu/chungus', '95'], 
		"ooga" => ['booga', 'menu/ooga', '25'], 
		"friend" => ["creepyMusic", "menu/friend", "5", "1"],
		"drip" => ["drip", "menu/drip", "25"]
	];

	var rightDoor:FlxSprite;
	var lastX:Float = 640;

	public static var displayGameVer:String;
	public static var gameVer:String = "JK Engine v0.9";
	public static var firstEnter:Bool = false;
	public static var inSubstate:Bool = false;
	public static var recording = false;

	var sfxPlaying:FlxSound;

	override function create()
	{
		alertSignal = new FlxTypedSignal<String->Void>();
		alertSignal.add(createAlertSubState);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		displayGameVer = gameVer;
		#if debug 
		displayGameVer += " DEBUG";
		#end

		// GAMEJOLT STUFF
		// For anyone trying to work with the code,
		// this line uses the GJKeys file that the FNF GameJolt integration requires.
		// For y'all, this is .gitignore'd. You'll have to make the file yourself.
		// GJKeys.trophies is a public static var of type Map<String, Int>.
		// Good luck!
		GameJoltAPI.getTrophy(GJKeys.trophies.get("thankYou"));

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
			var menuItem:FlxSprite = new FlxSprite( -640, 80 + (i * 90) ); // tween to 20 x
				menuItem.frames = Paths.getSparrowAtlas(("menu/ui/" + (optionShit[i].toLowerCase() + "_sheet")));
				menuItem.animation.addByPrefix('idle', 'idle', 24, true);
				menuItem.animation.addByPrefix('active', 'active', 24, true);
				menuItem.animation.play('idle');
				menuItem.ID = i;
				menuItem.setGraphicSize( Std.int(menuItem.width / 2) );
				menuItem.scrollFactor.set();
				menuItem.antialiasing = true;
			menuItems.add(menuItem);

			FlxTween.tween(menuItem, {x: 20}, 0.5, {ease: FlxEase.expoOut});
		}

		// Add Idleing Cat
		idleingCat = new FlxSprite(820, 1260); // tween to 260 y
		idleingCat.frames = Paths.getSparrowAtlas('menu/CatIdle');
		idleingCat.animation.addByPrefix('idle', 'IDLE_CAT', 24, true);
		idleingCat.animation.play('idle');
		idleingCat.setGraphicSize( Std.int(idleingCat.width * 1) );
		idleingCat.updateHitbox();
		idleingCat.flipX = true;
		add(idleingCat);

		FlxTween.tween(idleingCat, {y: 260}, 0.5, {
			ease: FlxEase.expoOut
		});

		// Dialogue Box & Text
		diaBox = new FlxSprite(15, -1000).loadGraphic( Paths.image("menu/menuTextBox") ); // tween to 0 y
		FlxMouseEventManager.add(diaBox, doTextChange);
		add(diaBox);

		FlxTween.tween(diaBox, {y: 0}, 0.5, {
			ease: FlxEase.expoOut
		});

		// Font Size 28
		// 945, 155
		diaText = new FlxText(645, -880, 600, '', 28, false); // tween to 120 y
		diaText.setFormat(Paths.font('taxicab.ttf'), 36, 0x00FFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0x00000000);
		diaText.borderSize = 3;
		diaText.autoSize = false;
		setMainMenuText();
		add(diaText);

		FlxTween.tween(diaText, {y: 120}, 0.5, {
			ease: FlxEase.expoOut
		});

		// Borders & Version Shit. Added last.
		var menuBorders:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/menuBorders") );
		add(menuBorders);
	
		menuBText = new FlxSprite(-640, 0).loadGraphic( Paths.image("menu/menuBorderText") );
		add(menuBText);

		FlxTween.tween(menuBText, {x:0}, 0.6, {
			ease: FlxEase.quadOut
		});

		versionShit = new FlxText(5, FlxG.height + 150, 0, gameVer, 12); // ease to FlxG.height - 18
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diaText.borderSize = 7;
		add(versionShit);

		FlxTween.tween(versionShit, {y: FlxG.height - 18}, 0.4, {ease: FlxEase.backOut});

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

	function createAlertSubState(txt:String) {
		openSubState(new AlertSubstate(txt));
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
		curSoundName = res;

		item.loadGraphic(images[index]);
		item.screenCenter();

		if (res == 'friend') {
			FlxG.sound.playMusic(Paths.music("creepyMusic"));
			lockDoor(960);
			GameJoltAPI.getTrophy(GJKeys.trophies.get("friendTrophy"));

			if (!Unlocks.get('icons.friend')) {
				alertSignal.dispatch("Unlocked a special Travel Icon!\nCheck the settings for more info.");
				Unlocks.unlock('icons.friend');
			}
		}
	}

	function doTextChange(object:FlxObject) { mainMenuTextBump(30); }
	function mainMenuTextBump(diaBumpDist:Float = 10) {
		// diaBox  = dialogue box
		// diaText = dialogue text
		// default Y values: 0, 120

		setMainMenuText();

		var tempHeights:FlxPoint = new FlxPoint(diaBox.y, diaText.y);

		diaBox.y = tempHeights.x - diaBumpDist;
		diaBox.setGraphicSize(Std.int(diaBox.width * 1), Std.int(diaBox.height * 1.05));
		diaBox.updateHitbox();

		diaText.y = tempHeights.y - diaBumpDist;

		FlxTween.cancelTweensOf(diaBox); 
		FlxTween.cancelTweensOf(diaText);
		FlxTween.tween(diaText, {y: 120}, 0.3, {ease: FlxEase.backOut});
		FlxTween.tween(diaBox, {y: 0, 'scale.y': 1}, 0.3, {ease: FlxEase.backOut, onComplete: function(twn:FlxTween) {
			diaBox.updateHitbox();
		}});
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
	var commaCount = 0;
	var commaTimer:FlxTimer = new FlxTimer();
	var devNames:Array<String> = [
		"butterdog", "rushtoxin"
	];

	override function update(elapsed:Float)
	{
		// im so shitty at coding
		diaBox.updateHitbox();
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin && !inSubstate)
		{
			// developer check
			if (FlxG.keys.justPressed.COMMA) {
				if (!commaTimer.active) {
					commaTimer.cancel();
				}

				if (commaCount < 5) {
					commaCount++;

					commaTimer.start(1.5, function(t:FlxTimer) {
						// End Combo
						commaCount = 0;
					});
				} else {
					GameJoltAPI.getTrophy(GJKeys.trophies.get("whatTheDogDoinTrophy"));

					if (Unlocks.get('devIcons') != 'nil') {
						if(!Unlocks.get('devIcons')) {
							Unlocks.unlock('devIcons', false);
							alertSignal.dispatch("Unlocked Developer Travel Icons!\nCheck the settings for more info.");
						}
					} else {
						Unlocks.set('devIcons', true);
						Unlocks.save();
							
						alertSignal.dispatch("Unlocked Developer Travel Icons!\nCheck the settings for more info.");
					}

					for (i in devNames) {
						if (Unlocks.get('icons.' + i) == 'nil') {
							Unlocks.set('icons.' + i, true);
						} else {
							if (!Unlocks.get('icons.' + i)) {
								Unlocks.unlock('icons.' + i, true);
							}
						}
					}

					commaCount = 0;
				}
			}

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
				FlxG.camera.fade();
				FlxG.sound.music.fadeIn(1, 0.7, 0);
				
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					FlxG.switchState(new TitleState());
				});
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

					if (doorLocked || dragging) {
						dragging = false;
						doorLocked = false;

						// Move the door back
						FlxTween.tween(rightDoor, {x: 640}, 0.75, {
							ease: FlxEase.expoInOut
						});
					}

					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							new FlxTimer().start(0.2, function(tmr:FlxTimer) {
								FlxTween.tween(spr, {x: -FlxG.width / 1.5}, 1, {
									ease: FlxEase.quadIn,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
							});
						}
						else
						{
							/*
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
							}); */

							var choice:String = optionShit[curSelected];
							if (choice == 'freeplay') FlxG.sound.music.fadeIn(0.8, 0.7, 0);
							dragging = false;
							doorLocked = true;

							// Move Out Obstructions ... 
							FlxTween.tween(idleingCat, {y: 1260}, 0.5, {
								ease: FlxEase.quadIn
							});

							FlxTween.tween(menuBText, {x:-640}, 0.8, {
								ease: FlxEase.quadIn
							});

							FlxTween.tween(diaBox, {y: -1000}, 0.5, {
								ease: FlxEase.expoIn
							});

							FlxTween.tween(diaText, {y: -880}, 0.5, {
								ease: FlxEase.expoIn
							});

							// Flicker Selection
							flickerColor(spr, 1, 0.06, 0xffffff, 0x000000, 0xffffff, null, function() {
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

							new FlxTimer().start(0.3, function(tmr:FlxTimer) {
								FlxTween.tween(versionShit, {y: FlxG.height + 150}, 0.4, {ease: FlxEase.backIn});
								FlxTween.tween(spr, {x: -FlxG.width / 1.5}, 1, {
									ease: FlxEase.quadIn,
									onComplete: function(twn:FlxTween)
									{
										spr.kill();
									}
								});
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
					rightDoor.x = 640 + ( (FlxG.mouse.screenX - 640) * percentMouseDrag );

					if (!doorTrigger && lastX <= doorThreshold && rightDoor.x > doorThreshold) {
						doorTrigger = true;

						switch(curSoundName) {
							case 'big':
								GameJoltAPI.getTrophy(GJKeys.trophies.get("chungusTrophy"));
						}

						sfxPlaying = FlxG.sound.play(curSound);
					}

					lastX = rightDoor.x;
				}
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.updateHitbox();
		});
	}

	function flickerColor(sprite:FlxSprite, dur:Float = 1, interval:Float = 0.04, firstColor:FlxColor = FlxColor.BLACK, secondColor:FlxColor = FlxColor.WHITE, endColor:FlxColor = FlxColor.BLACK, ?colorChangeCallback:FlxColor -> Void, ?completionCallback:Void -> Void) {
		var colorToggle:Bool = false;

		var flicker:FlxTimer = new FlxTimer().start(interval, function(tmr:FlxTimer) {
			if (colorToggle) { sprite.color = secondColor; } else { sprite.color = firstColor; } colorToggle = !colorToggle;
			if (colorChangeCallback != null) colorChangeCallback(sprite.color);
		}, Math.ceil(dur / interval));

		var progress:FlxTimer = new FlxTimer().start(dur, function(tmr:FlxTimer) {
			flicker.cancel();

			sprite.color = endColor;
			if (completionCallback != null) completionCallback();
		});
	}

	function dragDoor(object:FlxObject) {
		if (!doorLocked && !inSubstate) {
			setRandomEgg();
			dragging = true;
		}
	}

	function releaseDoorAndLock() {
		dragging = false;
		doorTrigger = false;
		
		if (!doorLocked) {
			FlxG.sound.list.forEach(function(s:FlxSound) {
				s.stop();
			});
		}
		
		lockDoor();
	}

	function lockDoor(x:Float = 640) {
		dragging = false;
		doorLocked = true;
		rightDoor.x = x;
	}

	function releaseDoor(?object:FlxObject) {
		dragging = false;
		doorTrigger = false;

		if (fuckingBullshitTimer != null)
		if (fuckingBullshitTimer.active) fuckingBullshitTimer.cancel();

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