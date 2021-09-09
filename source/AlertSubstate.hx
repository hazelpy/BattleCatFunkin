package;

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class AlertSubstate extends MusicBeatSubstate
{
    public function new(txt:String) {
        super();

		var niceTry = new FlxText(10, FlxG.height, 480, txt, 56);
			niceTry.setFormat(Paths.font('taxicab.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			niceTry.alpha = 0;
            // niceTry.y -= niceTry.height;

        var dimBG = new FlxSprite(0, FlxG.height).makeGraphic(Std.int(Math.ceil(niceTry.width)), Std.int(Math.ceil(niceTry.height)), FlxColor.BLACK);
            dimBG.alpha = 0;

        add(dimBG);
		add(niceTry);

        if (StoryMapState.inAlert) {
            niceTry.cameras = [StoryMapState.uiCamera];
            dimBG.cameras = [StoryMapState.uiCamera];
        }

		FlxTween.cancelTweensOf(dimBG);
		FlxTween.cancelTweensOf(niceTry);

		FlxTween.tween(dimBG, {alpha: 0.6}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(niceTry, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});

        new FlxTimer().start(0.2, function(t:FlxTimer) {
            FlxTween.tween(dimBG, {y: (dimBG.y - niceTry.height)}, 0.5, {ease: FlxEase.expoOut});
            FlxTween.tween(niceTry, {y: (niceTry.y - niceTry.height)}, 0.5, {ease: FlxEase.expoOut});
        });

        new FlxTimer().start(1, function(t:FlxTimer) {
            FlxTween.tween(dimBG, {y: FlxG.height}, 1, {ease: FlxEase.expoIn});
            FlxTween.tween(niceTry, {y: FlxG.height}, 1, {ease: FlxEase.expoIn});
        });

        new FlxTimer().start(1.5, function(t:FlxTimer) {

            FlxTween.tween(dimBG, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            FlxTween.tween(niceTry, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});

            new FlxTimer().start(1, function(z:FlxTimer) {
                if (StoryMapState.inAlert) StoryMapState.inAlert = false;
                close();
            });
		});
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
    }
}