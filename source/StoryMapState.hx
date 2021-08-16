package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.shapes.FlxShapeLine;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lime.net.curl.CURLCode;

#if desktop
import Discord.DiscordClient;
#end

using StringTools;

class StoryMapState extends MusicBeatState
{
	var scoreText:FlxText;

	var weekData:Array<Dynamic> = [
		['Tutorial'],
		['Bopeebo', 'Fresh', 'Dadbattle'],
		['Spookeez', 'South', "Monster"]
	];
	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [true, false, false];
	public static var weekCompleted:Array<Bool> = [false, false, false];

	var weekNames:Array<String> = [
		"Tutorial",
		"Cat Week",
		"Defenses"
	];

	var weekPositions:Array<FlxPoint> = [
		new FlxPoint(383, 320),
		new FlxPoint(496, 345),
		new FlxPoint(617, 293)
	];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;

	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var travelIcon:FlxSprite;
	var travelIconShadow:FlxSprite;

	var gameCamera:FlxCamera;
	var uiCamera:FlxCamera;
	var mainCamera:FlxCamera;

	var locations:FlxTypedGroup<FlxSprite>;
	var clears:FlxTypedGroup<FlxSprite>;

	var camFollow:FlxObject;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('bcMenu'));
		}


		gameCamera = new FlxCamera();
		mainCamera = new FlxCamera();
		uiCamera = new FlxCamera();

		FlxG.cameras.reset(gameCamera);
		FlxG.cameras.add(mainCamera);
		FlxG.cameras.add(uiCamera);

		mainCamera.bgColor.alpha = 0;
		uiCamera.bgColor.alpha = 0;
		gameCamera.zoom = 2;
		
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow); // ... and adding it, of course.
		
		gameCamera.follow(camFollow, null, 0.60 * (60 / FlxG.save.data.fpsCap));

		FlxCamera.defaultCameras = [gameCamera];
		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(FlxG.width - 415, 7, 400, "SCORE: 49324858", 36);
		scoreText.setFormat(Paths.font("taxicab.ttf"), 32, FlxColor.BLACK, RIGHT);
		scoreText.cameras = [uiCamera];

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 7, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		txtWeekTitle.cameras = [uiCamera];

		// MAP FIRST
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/ui/weekmap/worldMapOG'));
			bg.scrollFactor.set(1, 1);
		add(bg);

		// NEXT DOTTED LINES
		for (i in 0...weekData.length) {
			if (i < weekData.length - 1) {
				var aPos = new FlxPoint(weekPositions[i].x + 12.5, weekPositions[i].y + 12.5);
				var bPos = new FlxPoint(weekPositions[i + 1].x + 12.5, weekPositions[i + 1].y + 12.5);

				/* DRAWS LINE, old but good
				var dotLine = FlxSpriteUtil.drawLine(bg, weekPositions[i].x + 12.5, 
															  weekPositions[i].y + 12.5, 
															  weekPositions[i + 1].x + 12.5, 
															  weekPositions[i + 1].y + 12.5, {
					thickness: 5,
					color: FlxColor.WHITE,
					jointStyle: 'round',
					capsStyle: 'round'
				}, {
					smoothing: true
				}); */

				if (weekUnlocked[i + 1]) {
					var line = drawDottedLine(aPos, bPos);
					add(line);
				} // commented for testing purposes
			}
		}

		// NEXT DOTS
		for (i in 0...weekData.length) {
			// Do all week math here !!
			var tempDot = new FlxSprite(weekPositions[i].x, weekPositions[i].y);

			if (!weekUnlocked[i]) {
				tempDot.loadGraphic(Paths.image('menu/ui/weekmap/dotDim'));
			} else {
				tempDot.loadGraphic(Paths.image('menu/ui/weekmap/dot'));
			}
			
			add(tempDot);
		}

		// THEN TRAVEL ICON
		travelIcon = new FlxSprite().loadGraphic(Paths.image('menu/ui/weekmap/travelIcon'));
		travelIconShadow = new FlxSprite().loadGraphic(Paths.image('menu/ui/weekmap/travelIconShadow'));
		
		add(travelIconShadow);
		add(travelIcon);

		travelIconHop();

		// LOCATIONS:
		// Tutorial: California
		// Week 1: New Mexico
		// Weel 2: Wisconsin

		// CENTER: (FlxG.width / 2) - 76
		// DIST FROM CENTER: 
		// GAP: 171
		// Y GAP: 30
		locations = new FlxTypedGroup<FlxSprite>();
		add(locations);

		clears = new FlxTypedGroup<FlxSprite>();
		add(clears);

		// -3, -2
		for (i in 0...weekData.length) {
			var tempLocation = new FlxSprite(0, 100).loadGraphic(Paths.image('menu/ui/weekmap/locations/week' + i));
				// tempLocation.screenCenter(x);
				// tempLocation.x += ((i - curWeek) * 313);
				tempLocation.setGraphicSize(Std.int(tempLocation.width * 2));
				tempLocation.ID = i;
				tempLocation.cameras = [uiCamera];

				tempLocation.screenCenter(X);	
				var diff = 304 / (152 * tempLocation.scale.x);
				tempLocation.x += ((i - curWeek) * ((304 * diff) + 10));
			locations.add(tempLocation);

			var cleared = new FlxSprite(0, 100).loadGraphic(Paths.image('menu/ui/weekmap/locations/weekClear'));
				// tempLocation.screenCenter(x);
				// tempLocation.x += ((i - curWeek) * 313);
				cleared.setGraphicSize(Std.int(cleared.width * 2));
				cleared.ID = i;
				cleared.cameras = [uiCamera];

				cleared.screenCenter(X);	
				var diff = 304 / (152 * cleared.scale.x);
				cleared.x += ((i - curWeek) * ((304 * diff) + 10));
				cleared.x += 68;
				cleared.y += 21;
			clears.add(cleared);

			if (i == curWeek) {
				FlxTween.tween(tempLocation, {alpha: 1}, 0.2, {
					ease: FlxEase.expoInOut
				});

				FlxTween.tween(cleared, {alpha: 1}, 0.2, {
					ease: FlxEase.expoInOut
				});
			} else {
				FlxTween.tween(tempLocation, {alpha: 0.4}, 0.2, {
					ease: FlxEase.expoInOut
				});

				FlxTween.tween(cleared, {alpha: 0.4}, 0.2, {
					ease: FlxEase.expoInOut
				});
			}

			if (!weekCompleted[i]) cleared.visible = false;
			if (!weekUnlocked[i]) tempLocation.visible = false;

			trace("Week " + i + " icon position: (" + tempLocation.x + ", " + tempLocation.y + ").");
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		// 419 = x position, and add 453 = 872
		// y = 510

		leftArrow = new FlxSprite(806, 515);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.cameras = [uiCamera];
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');
		sprDifficulty.cameras = [uiCamera];
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.cameras = [uiCamera];
		difficultySelectors.add(rightArrow);

		/*
		var txtTrackBG = new FlxSprite(0, 450).makeGraphic(316, 1280-450, FlxColor.BLACK);
			txtTrackBG.alpha = 0.6;
			txtTrackBG.cameras = [uiCamera];
		add(txtTrackBG);
		*/

		txtTracklist = new FlxText((FlxG.width * 0.05) - 70, 475, 0, "Tracks", 32);
		txtTracklist.setFormat(Paths.font("taxicab.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txtTracklist.borderSize = 3;
		txtTracklist.cameras = [uiCamera];

		add(txtTracklist);

		updateText();
		MainMenuState.loadLockedSongList();

		// Borders & Version Shit. Added last.
		var menuBorders:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/menuBordersDark") );
			menuBorders.cameras = [uiCamera];
		add(menuBorders);
	
		var menuBText:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/storyMapText") );
			menuBText.cameras = [uiCamera];
		add(menuBText);

		add(scoreText);

		super.create();
	}

	function drawDottedLine(aPos:FlxPoint, bPos:FlxPoint):FlxTypedGroup<FlxSprite> {
		trace("Start Drawing Line from (" + aPos.x + ", " + aPos.y + ") to (" + bPos.x + ", " + bPos.y + ").");
		var line:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		var dotSprite = Paths.image("menu/ui/weekmap/lineDot");
		var gap:Float = 11;

		var dist:FlxPoint = new FlxPoint(bPos.x - aPos.x, bPos.y - aPos.y);
		var realDist = aPos.distanceTo(bPos);
		var pointCount = Math.floor(realDist / gap);

		for (i in 0...pointCount) {
			var curDotX = aPos.x + ((dist.x / gap) * i);
			var curDotY = aPos.y + ((dist.y / gap) * i);
			var dot = new FlxSprite(curDotX, curDotY).loadGraphic(dotSprite);
			line.add(dot);

			trace('Adding a dot at: (' + dot.x + ", " + dot.y + ')');
		}

		trace("Finalize Line");
		return line;
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = weekUnlocked[curWeek];

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UP_P)
				{
					changeWeek(-1);
				}

				if (controls.DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P)
					changeDifficulty(1);
				if (controls.LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		for (i in locations) {
			i.updateHitbox();	
			clears.members[i.ID].x = i.x + 68;
			clears.members[i.ID].y = i.y + 21;
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				stopspamming = true;
			}

			PlayState.storyPlaylist = weekData[curWeek];
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "";

			switch (curDifficulty)
			{
				case 0:
					diffic = '-easy';
				case 2:
					diffic = '-hard';
			}

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			
			activateTravelIcon();

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		sprDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0:
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		var old = curWeek;

		if (curWeek + change < (weekData.length) && curWeek + change >= 0)
		curWeek += change;

		if (weekUnlocked[curWeek] && curWeek != old) FlxG.sound.play(Paths.sound('scrollMenu'));
		else curWeek = old;

		var bullShit:Int = 0;

		if (Math.abs(change) != change) {
			travelIconHop(true);
		} else {
			travelIconHop();
		}

		for (i in locations) {
			FlxTween.cancelTweensOf(i);
			i.screenCenter(X);	
			//304, 102

			var diff = 304 / (152 * i.scale.x);
			i.x += ( (i.ID - curWeek) * ( (304 * diff) + 10) );

			if (i.ID == curWeek) {
				FlxTween.tween(i, {alpha: 1}, 0.2, {
					ease: FlxEase.expoInOut
				});

				FlxTween.tween(clears.members[i.ID], {alpha: 1}, 0.2, {
					ease: FlxEase.expoInOut
				});
			} else {
				FlxTween.tween(i, {alpha: 0.4}, 0.15, {
					ease: FlxEase.expoInOut
				});

				FlxTween.tween(clears.members[i.ID], {alpha: 0.4}, 0.15, {
					ease: FlxEase.expoInOut
				});
			}
		}

		updateText();
	}

	function travelIconHop(flipX:Bool = false) {
		travelIcon.flipX = flipX;

		FlxTween.cancelTweensOf(travelIcon);
		FlxTween.tween(travelIcon, {x: weekPositions[curWeek].x - 7.5, y: weekPositions[curWeek].y - 30}, 0.3, {
			ease: FlxEase.expoOut
		});

		FlxTween.cancelTweensOf(travelIconShadow);
		FlxTween.tween(travelIconShadow, {x: weekPositions[curWeek].x - 7.5, y: weekPositions[curWeek].y - 30}, 0.3, {
			ease: FlxEase.expoOut
		});

		FlxTween.cancelTweensOf(camFollow);
		FlxTween.tween(camFollow, {x: ((weekPositions[curWeek].x - 7.5) + 20), y: ((weekPositions[curWeek].y - 30) + 25)}, 0.3, {
			ease: FlxEase.expoOut
		});
	}

	function activateTravelIcon(jumpDuration:Float = 0.4) {
		var travelIconPos = new FlxPoint(travelIcon.x, travelIcon.y);
		var travelIconScale = new FlxPoint(travelIcon.scale.x, travelIcon.scale.y);

		travelIcon.loadGraphic(Paths.image('menu/ui/weekmap/travelIconActive'));

		FlxTween.tween(travelIcon, {y: travelIconPos.y - 10}, jumpDuration / 2, {
			ease: FlxEase.expoOut
		});

		FlxTween.tween(travelIcon, {"scale.x": (travelIconScale.x * 0.8)}, jumpDuration / 4, {
			ease: FlxEase.expoInOut
		});

		FlxTween.tween(travelIcon, {"scale.y": (travelIconScale.y * 1.2)}, jumpDuration / 4, {
			ease: FlxEase.expoInOut
		});

		
		new FlxTimer().start(jumpDuration / 6, function(t:FlxTimer) {
			FlxTween.tween(travelIcon, {"scale.x": (travelIconScale.x)}, jumpDuration / 2, {
				ease: FlxEase.expoIn
			});
	
			FlxTween.tween(travelIcon, {"scale.y": (travelIconScale.y)}, jumpDuration, {
				ease: FlxEase.bounceOut
			});
		});
		

		new FlxTimer().start(jumpDuration / 2, function(t:FlxTimer) {
			FlxTween.tween(travelIcon, {y: travelIconPos.y}, jumpDuration * 1.5, {
				ease: FlxEase.bounceOut
			});
		});
	}

	function updateText()
	{
		txtTracklist.text = "Tracks";

		var stringThing:Array<String> = weekData[curWeek];

		if (weekUnlocked[curWeek]) {
			for (i in stringThing)
			{
				txtTracklist.text += "\n" + i;
			}
		} else {
			txtTracklist.text += "\nLOCKED";
		}

		txtTracklist.text = txtTracklist.text.toUpperCase() + "\n";

		txtTracklist.x = 4;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}
}
