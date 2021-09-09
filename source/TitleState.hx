package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.effects.FlxFlicker;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import io.newgrounds.NG;
import lime.app.Application;
import openfl.Assets;
import sys.io.Process;
import sys.thread.Thread;
import GameJolt.GameJoltAPI;
import GameJolt.GameJoltLogin;

#if desktop
import Discord.DiscordClient; 
#end

using StringTools;

class TitleState extends MusicBeatState
{
	public var initialized:Bool = false;
	public var opening:Bool = true;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var jkEngineGroup:Array<FlxSprite>;
	var jkEngineIndex:Int;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	var startBtn:FlxSprite;

	var curWacky:Array<String> = [];
	var wackyImage:FlxSprite;

	var obsProcessNames:Array<String> = ["obs64.exe", "obs32.exe", "Streamlabs OBS.exe"];

	var scrollSpeed:Float = 0.75;
	var playBtn:FlxSprite;
	var bgGroup:FlxGroup;

	override public function create():Void
	{
		#if polymod
		polymod.Polymod.init({modRoot: "mods", dirs: ['introMod']});
		#end

		#if windows
		sys.thread.Thread.create(() -> {
			var output = new Process('tasklist').stdout.readAll().toString();
			var split = output.split("\n");

			for (i in split) {
				for (j in obsProcessNames) {
					if (i.toLowerCase().contains(j.toLowerCase())) {
						MainMenuState.recording = true;
					}
				}
			}
		});
		#end

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		super.create();

		// NGio.noLogin(APIStuff.API);

		#if ng
		var ng:NGio = new NGio(APIStuff.API, APIStuff.EncKey);
		trace('NEWGROUNDS LOL');
		#end

		FlxG.save.bind('funkin', 'ninjamuffin99');

		JKEngineData.initSave();

		Highscore.load();

		if (FlxG.save.data.weekUnlocked != null) {
			StoryMapState.weekUnlocked = FlxG.save.data.weekUnlocked;

			if (StoryMapState.weekUnlocked.length < 1)
				StoryMapState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!StoryMapState.weekUnlocked[0])
				StoryMapState.weekUnlocked[0] = true;
		}

		if (FlxG.save.data.weekCompleted != null) {
			StoryMapState.weekCompleted = FlxG.save.data.weekCompleted;

			if (StoryMapState.weekCompleted.length < 1)
				StoryMapState.weekCompleted.insert(0, false);
		}

		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		#else
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var startCvr:FlxSprite;
	var fnfYPosition:Float;
	var fnfXPosition:Float;
	var logoYPosition:Float;
	var logoBumpin:FlxSprite;
	var FNFlogoBumpin:FlxSprite;

	function startIntro()
	{
		/*
		if (!initialized)
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();
		}*/

		FlxG.sound.playMusic(Paths.music('bcMainTheme'), 0);
		FlxG.sound.music.fadeIn(4, 0, 0.7);
		
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

		transIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
		new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		
		transOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
		{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

		Conductor.changeBPM(140);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// bg.antialiasing = true;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		// logoBl = new FlxSprite(-150, -100);
		// logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		// logoBl.antialiasing = true;
		// logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		// logoBl.animation.play('bump');
		// logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		// gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		// gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		// gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		// gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		// gfDance.antialiasing = true;
		// add(gfDance);
		// add(logoBl);

		// titleText = new FlxSprite(100, FlxG.height * 0.8);
		// titleText.frames = Paths.getSparrowAtlas('titleEnter');
		// titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		// titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		// titleText.antialiasing = true;
		// titleText.animation.play('idle');
		// titleText.updateHitbox();
		// titleText.screenCenter(X);
		// add(titleText);

		// var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		// logo.screenCenter();
		// logo.antialiasing = true;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		bgGroup = new FlxGroup();
		add(bgGroup);

		for (i in 0...3) {
			var temp:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/titleBGBlur'));
				temp.x = (i - 1) * 1279;
				temp.antialiasing = true;
				temp.updateHitbox();
			if (i % 2 == 1) temp.flipX = true;
			bgGroup.add(temp);
		}

		// LOGO
		fnfXPosition = 25; // (FlxG.width / 14);
		fnfYPosition = -25;
		FNFlogoBumpin = new FlxSprite(fnfXPosition, -750).loadGraphic(Paths.image('menu/FNFBCLogo'));
		FNFlogoBumpin.antialiasing = true;
		FNFlogoBumpin.setGraphicSize(Std.int(FNFlogoBumpin.width/1.4));
		FNFlogoBumpin.updateHitbox();
		FNFlogoBumpin.screenCenter(X);
		add(FNFlogoBumpin);

		// ADD BUTTON HERE
		startBtn = new FlxSprite();
		startBtn.frames = Paths.getSparrowAtlas(("menu/ui/story mode_sheet"));
		startBtn.animation.addByPrefix('idle', 'idle', 24, true);
		startBtn.animation.addByPrefix('active', 'active', 24, true);
		startBtn.animation.play('idle');
		startBtn.setGraphicSize( Std.int(startBtn.width / 2) );
		startBtn.screenCenter();
		startBtn.y += 225;
		startBtn.scrollFactor.set();
		startBtn.antialiasing = true;
		add(startBtn);

		startCvr = new FlxSprite();
		startCvr.frames = Paths.getSparrowAtlas(("menu/ui/story mode_sheet"));
		startCvr.animation.addByPrefix('idle', 'idle', 24, true);
		startCvr.animation.addByPrefix('active', 'active', 24, true);
		startCvr.animation.play('idle');
		startCvr.setGraphicSize( Std.int(startCvr.width / 2) );
		startCvr.screenCenter();
		startCvr.y += 225;
		startCvr.scrollFactor.set();
		startCvr.antialiasing = true;
		startCvr.color = 0x00FFFFFF;
		startCvr.visible = false;
		add(startCvr);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function bumpLogo() {
		try {
			var FNFscaleX = FNFlogoBumpin.scale.x;
			var FNFscaleY = FNFlogoBumpin.scale.y;

			FNFlogoBumpin.scale.set(FNFscaleX * 1.2, FNFscaleY * 1.2);
			FNFlogoBumpin.updateHitbox();
			FNFlogoBumpin.x = fnfXPosition;
			FNFlogoBumpin.screenCenter(X);
			FNFlogoBumpin.y = fnfYPosition;

			FlxTween.tween(FNFlogoBumpin, {"scale.x": FNFscaleX, "scale.y": FNFscaleY}, 0.2, {
				ease: FlxEase.expoOut
			});
		} catch(e) {}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (bgGroup != null) {
			bgGroup.forEachOfType(FlxSprite, function(spr:FlxSprite) {
				spr.x -= scrollSpeed;
				if (spr.x < -1279) {
					spr.x = 1279;
				}
			});
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			GameJoltAPI.connect();
			GameJoltAPI.authDaUser(FlxG.save.data.gjUser, FlxG.save.data.gjToken);

			#if !switch
			NGio.unlockMedal(60960);

			// If it's Friday according to da clock
			if (Date.now().getDay() == 5)
				NGio.unlockMedal(61034);
			#end

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			if (startBtn != null && startCvr != null) {
				startBtn.animation.play('active');
				FlxFlicker.flicker(startCvr, 2, 0.12, false, false);
			}

			transitioning = true;
			// FlxG.sound.music.stop();

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				MainMenuState.firstEnter = true;
				FlxG.switchState(new GameJoltLogin());
			});
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		try {
			if (opening) {
				switch (curBeat)
				{
					case 1:
						createCoolText(['FNF', 'Battle', 'Cats', 'Team']);
					case 3:
						deleteCoolText();
						createCoolText(['Presents']);
					case 4:
						deleteCoolText();
						createCoolText([curWacky[0]]);
					case 5:
						addMoreText(curWacky[1]);
					case 7:
						deleteCoolText();
						addMoreText('FNF Battle Cats!');
					case 8:
						deleteCoolText();
						skipIntro();
						opening = false;
				}
			} else {
				skipIntro();
				opening = false;
			}
		} catch(e) {}

		if (skippedIntro) {
			bumpLogo();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);

			jkEngineGroup = new Array<FlxSprite>();
			jkEngineIndex = 0;
			for(i in 1...5)
			{
				var jkfile:String = "jkengine" + i;
				var newsprite:FlxSprite = new FlxSprite(44, 410).loadGraphic(Paths.image(jkfile));
				newsprite.visible = false;
				add(newsprite);
				jkEngineGroup.push(newsprite);
			}

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
