package;

import flixel.input.gamepad.FlxGamepad;
import Controls.KeyboardScheme;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.utils.Assets;
import lime.app.Application;

class OptionsMenu extends MusicBeatSubstate
{
	//var selector:FlxText;
	var curSelected:Int = 0;

	var controlsStrings:Array<String> = [];

	var grpControls:FlxTypedGroup<FlxSprite>;
	var grpHighlights:FlxTypedGroup<FlxSprite>;
	var versionShit:FlxText;
	var description:FlxText;
	var doUpdate = false;

	var blackScreen:FlxSprite;

	public static var inSubState:Bool = false;
	var controlsPaths:Array<String>;
	var descriptions:Array<String>;
	var optionsBG:FlxSprite;
	var iconSettings:FlxSprite;
	
	override function create()
	{
		controlsPaths = [
			"fullscreen",
			"keybinds",
			"accuracy",
			"song position",
			"left arrows",
			"downscroll",
			"center arrows"
		];

		descriptions = [
			"Toggle fullscreen mode.",
			"Customize your keybinds.",
			"Whether or not your accuracy shows while playing.",
			"Whether or not song position shows while playing.",
			"Toggle opponent's arrows.",
			"Change the side of the screen the judgement line is on.",
			"Center your side during gameplay."
		];

		var controlsOffsets:Array<FlxPoint> = [
			new FlxPoint(0, 0),
			new FlxPoint(479, 0),
			new FlxPoint(0, 131),
			new FlxPoint(479, 131), // 264
			new FlxPoint(0, 264),
			new FlxPoint(299, 264),
			new FlxPoint(597, 264)
		];

		var controlsSizes:Array<String> = [
			"Wide",
			"Wide",
			"Wide",
			"Wide",
			"Narrow",
			"Narrow",
			"Narrow"
		];

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackScreen.alpha = 0;
		add(blackScreen);
		FlxTween.tween(blackScreen, {alpha: 0.5}, 0.5, {ease: FlxEase.expoInOut});

		optionsBG = new FlxSprite(160, 85).loadGraphic(Paths.image('menu/options/optionsBG'));
		optionsBG.alpha = 0;
		FlxTween.tween(optionsBG, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
		add(optionsBG);

		grpControls = new FlxTypedGroup<FlxSprite>();
		add(grpControls);

		grpHighlights = new FlxTypedGroup<FlxSprite>();
		add(grpHighlights);

		for (i in 0...controlsPaths.length)
		{
			var controlLabel:FlxSprite = new FlxSprite(44, 109);
				controlLabel.updateHitbox();
				controlLabel.x += 160 + controlsOffsets[i].x;
				controlLabel.y += 85 + controlsOffsets[i].y;
				controlLabel.ID = i;
				controlLabel.frames = Paths.getSparrowAtlas('menu/options/' + controlsPaths[i] + '_sheet');
				controlLabel.animation.addByPrefix('active', 'active', 24, true);
				controlLabel.animation.addByPrefix('inactive', 'inactive', 24, true);
				controlLabel.animation.play('active');
			grpControls.add(controlLabel);
			
			var controlHL:FlxSprite = new FlxSprite(44, 109).loadGraphic(Paths.image('menu/options/btnHighlight' + controlsSizes[i]));
				controlHL.updateHitbox();
				controlHL.x += 160 + controlsOffsets[i].x;
				controlHL.y += 85 + controlsOffsets[i].y;
				controlHL.ID = i;
				controlHL.visible = false;
			grpHighlights.add(controlHL);
		}
		
		// Icons menu substate
		iconSettings = new FlxSprite(178, 555).loadGraphic(Paths.image('menu/options/travelSelect'));
		FlxMouseEventManager.add(iconSettings, openIconSettings);
		add(iconSettings);

		versionShit = new FlxText(5, FlxG.height - 18, 0, "Offset (Left, Right): " + FlxG.save.data.offset, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		description = new FlxText(320, FlxG.height - 18, 640, "" + FlxG.save.data.offset, 12);
		description.autoSize = false;
		description.scrollFactor.set();
		description.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(description);
		
		fadeOptions('in');

		new FlxTimer().start(0.3, function(t:FlxTimer) {
			doUpdate = true;
		});

		super.create();

		changeSelection();
		updateButtons();
	}

	function openIconSettings(obj:FlxObject) {
		inSubState = true;
		openSubState(new TravelIconSubstate());
	}

	override function update(elapsed:Float)
	{
		if (doUpdate) {
			if (controls.BACK) {
				FlxTween.tween(optionsBG, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(blackScreen, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
				fadeOptions('out');

				new FlxTimer().start(0.5, function(t:FlxTimer) {
					MainMenuState.inSubstate = false;
					close();
				});
			}
			if (controls.UP_P)
				changeSelection(-1);
			if (controls.DOWN_P)
				changeSelection(1);
			
			if (controls.RIGHT_P)
			{
				FlxG.save.data.offset++;
				versionShit.text = "Offset (Left, Right): " + FlxG.save.data.offset;
			}

			if (controls.LEFT_P)
			{
				FlxG.save.data.offset--;
				versionShit.text = "Offset (Left, Right): " + FlxG.save.data.offset;
			}

			if (FlxG.keys.justPressed.PERIOD) {
				TravelIconSubstate.resetIconData();
				Unlocks.reset();
				openSubState(new AlertSubstate("Successfully reset all unlocks!"));
			}

			if (controls.ACCEPT)
			{
				switch(curSelected) {
					default:
						FlxG.fullscreen = !FlxG.fullscreen;
						// Do sprite change
					case 1:
						// Keybind State
						inSubState = true;
						openSubState(new CustomKeybindSubstate());
					case 2:
						FlxG.save.data.accuracyDisplay = !FlxG.save.data.accuracyDisplay;
						// Do sprite change
					case 3:
						FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
						// Do sprite change
					case 4:
						FlxG.save.data.showLeftArrows = !FlxG.save.data.showLeftArrows;
						// Do sprite change
					case 5:
						FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
						// Do sprite change
					case 6:
						FlxG.save.data.centerArrows = !FlxG.save.data.centerArrows;
						// Do sprite change
				}

				FlxG.save.flush();
			}
		}

		updateButtons();
		super.update(elapsed);
	}

	function fadeOptions(way:String = 'in') {
		for (i in grpControls) {
			switch(way) {
				case 'in':
					i.alpha = 0;
					FlxTween.tween(i, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
				case 'out':
					FlxTween.tween(i, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
			}
		}

		for (i in grpHighlights) {
			if (i.ID == curSelected) {
				switch(way) {
					case 'in':
						i.alpha = 0;
						FlxTween.tween(i, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
					case 'out':
						FlxTween.tween(i, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
				}
			}
		}

		switch(way) {
			case 'in':
				description.alpha = 0;
				iconSettings.alpha = 0;
				FlxTween.tween(description, {alpha:1}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(iconSettings, {alpha:1}, 0.5, {ease: FlxEase.expoInOut});
			case 'out':
				FlxTween.tween(description, {alpha:0}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(iconSettings, {alpha:0}, 0.5, {ease: FlxEase.expoInOut});
		}
	}

	var isSettingControl:Bool = false;

	function updateButtons() {
		for (i in grpControls) {
			switch(i.ID) {
				default:
					// Fullscreen
					// FlxG.fullscreen = !FlxG.fullscreen;
					if (FlxG.fullscreen) i.animation.play('active');
					else i.animation.play('inactive');
				case 1:
					// Keybind
					i.animation.play('active');
				case 2:
					// Accuracy
					// FlxG.save.data.accuracyDisplay = !FlxG.save.data.accuracyDisplay;
					if (FlxG.save.data.accuracyDisplay) i.animation.play('active');
					else i.animation.play('inactive');
				case 3:
					// Song position
					// FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
					if (FlxG.save.data.songPosition) i.animation.play('active');
					else i.animation.play('inactive');
				case 4:
					// Left Arrows 
					// FlxG.save.data.showLeftArrows = !FlxG.save.data.showLeftArrows;
					if (FlxG.save.data.showLeftArrows) i.animation.play('active');
					else i.animation.play('inactive');
				case 5:
					// Downscroll
					// FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
					if (FlxG.save.data.downscroll) i.animation.play('active');
					else i.animation.play('inactive');
				case 6:
					// Center arrows
					// FlxG.save.data.centerArrows = !FlxG.save.data.centerArrows;
					if (FlxG.save.data.centerArrows) i.animation.play('active');
					else i.animation.play('inactive');
			}	
		}

		for (i in grpHighlights) {
			if ((i.ID) == curSelected) {
				i.visible = true;
			} else {
				i.visible = false;
			}
		}

		description.text = descriptions[curSelected];
	}
	
	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		if(change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = controlsPaths.length;
		if (curSelected >= controlsPaths.length)
			curSelected = 0;

		updateButtons();

		// selector.y = (70 * curSelected) + 30;
	}
}
