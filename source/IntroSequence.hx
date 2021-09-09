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
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

#if desktop
import Discord.DiscordClient;
#end

using StringTools;

class IntroSequence extends MusicBeatState {
    var background:FlxSprite;
    var bgGradient:FlxSprite;
    var darkFadeIn:FlxSprite;
    
    var introParticleEmitter:FlxEmitter;
    var introText:FlxText;
    var introDataPath:String = Paths.txt("introStory");
    var introTextMoveSpeed:Float = 0.375;
    var storyLength:Float;
    
    var transitioning:Bool = false;

    var particleGraphic:String = Paths.image("intro/particle");

    override public function create():Void {
        #if desktop
		DiscordClient.initialize();
		#end

		Unlocks.init();

        // Initialize BPM.
		Conductor.changeBPM(99);

        // Load Background Sprites & Skip Button
        background = new FlxSprite().loadGraphic(Paths.image("intro/wideBG"));
        background.screenCenter();
        background.scrollFactor.set();

        bgGradient = new FlxSprite().loadGraphic(Paths.image("intro/coverGradient"));
        bgGradient.screenCenter();
        bgGradient.scrollFactor.set();

        var skipButton:FlxSprite = new FlxSprite().loadGraphic(Paths.image("intro/skipButton"));
        skipButton.screenCenter();
        skipButton.scrollFactor.set();
        
        add(background);
        add(skipButton);

        // Text Sequence
        var story = Assets.getText(introDataPath);
        // trace(story);

		introText = new FlxText(0, FlxG.height + 150, FlxG.width, story, 42);
		introText.setFormat(Paths.font("taxicab.ttf"), 42, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        introText.borderSize = 2;
        add(introText);
        // End Text Sequence

        // Add gradient AFTER, dumbass
        add(bgGradient);

        // Debug Purposes
        /*
            new FlxTimer().start(2.5, function(t:FlxTimer) {
                moveOn();
            });
        */

        // Add Black Fade In
        darkFadeIn = new FlxSprite().loadGraphic(Paths.image("intro/blackOverlay"));
        darkFadeIn.screenCenter();
        darkFadeIn.scrollFactor.set();

        add(darkFadeIn);

        // Do the actual fade
        FlxTween.tween(darkFadeIn, {alpha: 0}, 2, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
            darkFadeIn.kill();
        }});

        // Play the music
		FlxG.sound.playMusic(Paths.music('bcIntro'), 0, true);
		FlxG.sound.music.fadeIn(4, 0, 0.7);

        FlxG.mouse.visible = false;
    }

    override public function update(elapsed:Float) {
        if (introText != null && !transitioning) {
            introText.y -= introTextMoveSpeed;
            
            if (introText.y <= -introText.height + 50 && !transitioning) {
                trace(introText.y);
                trace(-introText.height);
                transitioning = true;
                moveOn();
            }
        }

        var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;
        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			if (gamepad.justPressed.START) pressedEnter = true;
			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}

        if (pressedEnter && !transitioning) {
            moveOn();
        }
    }

    function moveOn() {
        darkFadeIn.revive();
        FlxG.sound.music.fadeIn(1, 0.7, 0);

        FlxTween.tween(darkFadeIn, {alpha: 1}, 1, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
            FlxG.switchState(new TitleState());
        }});
    }
}