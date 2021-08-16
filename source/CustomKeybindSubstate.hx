import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;

class CustomKeybindSubstate extends MusicBeatSubstate
{
    public static var bindStrs:Array<String> = 
    [
        'LEFT',
        'DOWN',
        'UP',
        'RIGHT',
        'ACCEPT',
        'BACK',
        'RESET'
    ];

    private var bindNames:Array<FlxText>;
    private var currentKeyBinds:Array<FlxText>;
    private var keybindIndex:Int = 0;
    private var key:FlxKey;

    private var binding:Bool = false;
    private var skipbind:Bool = false;

    var menuBG:FlxSprite;

    public function new()
    {
        super();

        menuBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		menuBG.updateHitbox();
		menuBG.screenCenter();
        menuBG.alpha = 0;
		menuBG.antialiasing = true;
		add(menuBG);

        FlxTween.tween(menuBG, {alpha: 0.75}, 0.5, {ease: FlxEase.expoInOut});

        // space all lines by 70 pixels
        bindNames = new Array<FlxText>();
        for(i in 0...bindStrs.length)
        {
            var ptext:FlxText = new FlxText(0, 110 + i * 70, 0, bindStrs[i], 56);
                ptext.setFormat(Paths.font('taxicab.ttf'), 56, 0x00FFFFFF, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                ptext.borderSize = 4;
            bindNames.push(ptext);
        }

        for(spr in bindNames)
        {
            spr.x = 250;
            add(spr);
        }

        // make key x 500 pixels
        var tempindex:Int = -1;
        currentKeyBinds = new Array<FlxText>();

        var keybind:FlxKey = FlxG.save.data.KEY_LEFT;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_DOWN;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_UP;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_RIGHT;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_ACCEPT;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_BACK;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        var keybind:FlxKey = FlxG.save.data.KEY_RESET;
        currentKeyBinds.push(new FlxText(0, 175 + tempindex++ * 70, 400, keybind.toString(), 56));

        for(kb in currentKeyBinds)
        {
            kb.x = 610;
            kb.autoSize = false;
            kb.setFormat(Paths.font('taxicab.ttf'), 56, 0x00FFFFFF, 'right', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            kb.borderSize = 4;
            add(kb);
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        skipbind = false;

        if(key != FlxG.keys.firstPressed())
        {
            key = FlxG.keys.firstPressed();
        }

        for(i in 0...bindStrs.length)
        {
            if(i != keybindIndex)
            {
                bindNames[i].alpha = 0.6;
                currentKeyBinds[i].alpha = 0.6;
            }
            else 
            {
                bindNames[i].alpha = 1.0;
                currentKeyBinds[i].alpha = 1.0;
            }
        }
        if(FlxG.keys.justPressed.DOWN && !binding)
        {
            keybindIndex++;
        }
        if(FlxG.keys.justPressed.UP && !binding)
        {
            keybindIndex--;
        }
        if(keybindIndex < 0)
        {
            keybindIndex = bindStrs.length - 1;
        }
        if(keybindIndex >= bindStrs.length)
        {
            keybindIndex = 0;
        }
        
        if(FlxG.keys.justPressed.ESCAPE)
        {
            if(!binding)
            {
                var tempKeyIndex:Int = -1;
                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_LEFT = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_DOWN = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_UP = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_RIGHT = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_ACCEPT = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_BACK = key;

                key = currentKeyBinds[++tempKeyIndex].text;
                FlxG.save.data.KEY_RESET = key;

                controls.setKeyboardScheme(Controls.KeyboardScheme.None, true);

                controls.bindKeys(UP, [FlxG.save.data.KEY_UP, FlxKey.UP]);
                controls.bindKeys(LEFT, [FlxG.save.data.KEY_LEFT, FlxKey.LEFT]);
                controls.bindKeys(DOWN, [FlxG.save.data.KEY_DOWN, FlxKey.DOWN]);
                controls.bindKeys(RIGHT, [FlxG.save.data.KEY_RIGHT, FlxKey.RIGHT]);
                controls.bindKeys(ACCEPT, [FlxG.save.data.KEY_ACCEPT]);
                controls.bindKeys(BACK, [FlxG.save.data.KEY_BACK]);
                controls.bindKeys(RESET, [FlxG.save.data.KEY_RESET]);

                FlxTween.tween(menuBG, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
                close();
            }
        }

        if(FlxG.keys.justPressed.ENTER)
        {
            if(!binding)
            {
                binding = true;
                currentKeyBinds[keybindIndex].text = "_";
                skipbind = true;
            }
        }

        if(FlxG.keys.firstJustPressed() != -1 && binding && !skipbind)
        {
            binding = false;
            key = FlxG.keys.firstJustPressed();
            currentKeyBinds[keybindIndex].text = key.toString();
        }
    }
}
