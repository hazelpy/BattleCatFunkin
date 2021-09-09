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
import flixel.tweens.misc.ColorTween;

class TravelIconSubstate extends MusicBeatSubstate
{
    public static var iconPaths:Map<String, Array<String>> = 
    [
        'default' => [Paths.image('menu/ui/weekmap/travelIcon'), Paths.image('menu/ui/weekmap/travelIconActive')],
        'friend' => [Paths.image('menu/ui/weekmap/travelIcons/friend'), Paths.image('menu/ui/weekmap/travelIcons/friendActive')],
        'altBF' => [Paths.image('menu/ui/weekmap/travelIcons/altBF'), Paths.image('menu/ui/weekmap/travelIcons/altBFActive')],
        'butterdog' => [Paths.image('menu/ui/weekmap/travelIcons/butterdog'), Paths.image('menu/ui/weekmap/travelIcons/butterdogActive')],
        'rushtoxin' => [Paths.image('menu/ui/weekmap/travelIcons/rushtoxin'), Paths.image('menu/ui/weekmap/travelIcons/rushtoxinActive')]
    ];

    public static var pathNames:Array<String> = [
        'default',
        'friend',
        'altBF',
        'butterdog',
        'rushtoxin'
    ];

    var grpIcons:FlxTypedGroup<FlxSprite>;
    var grpUnknown:FlxTypedGroup<FlxSprite>;

    var iconShadow:FlxSprite;
    var menuBG:FlxSprite;

    var leftArrow:FlxSprite;
    var rightArrow:FlxSprite;

    var curIcon:Float = 0;

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
        
        iconShadow = new FlxSprite().loadGraphic(Paths.image('menu/ui/weekmap/travelIconShadow'));
        iconShadow.scale.set(4, 4);
        iconShadow.updateHitbox();
        iconShadow.screenCenter();
        iconShadow.alpha = 0;
        FlxTween.tween(iconShadow, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
        add(iconShadow);

        grpIcons = new FlxTypedGroup<FlxSprite>();
        add(grpIcons);

        grpUnknown = new FlxTypedGroup<FlxSprite>();
        add(grpUnknown);

        var i:Int = 0;
        for (v in 0...pathNames.length) {
            var key = pathNames[v];
            var tempIcon = new FlxSprite().loadGraphic(iconPaths.get(key)[0]);
                tempIcon.scale.set(4, 4);
                tempIcon.updateHitbox();
                tempIcon.screenCenter();
                tempIcon.ID = i;
                tempIcon.alpha = 0;
            FlxTween.tween(tempIcon, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});

            var unknown = new FlxSprite(0, 0).loadGraphic(Paths.image('menu/ui/weekmap/travelIconUnknown'));
                unknown.scale.set(2, 2);
                unknown.updateHitbox();
                unknown.screenCenter();
                unknown.y -= 10;
                unknown.ID = i;
                unknown.alpha = 0;

            if ((Unlocks.get('icons.' + key)) != 'nil') {
                if (!(Unlocks.get('icons.' + key))) {
                    trace("Icon " + key + " not owned!");
                    tempIcon.color = 0x00000000;
                    FlxTween.tween(unknown, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
                }
            }

            if (i != curIcon) tempIcon.visible = false;
            if (i != curIcon) unknown.visible = false;

            grpIcons.add(tempIcon);
            grpUnknown.add(unknown);
            i++;
        }

        // Add Selection Arrows
        // Position Left:  322, 300
        // Position Right: FlxG.width - 322, 300

        leftArrow = new FlxSprite(322, 275).loadGraphic(Paths.image('menu/ui/selectionArrow'));
        leftArrow.flipX = true;
        leftArrow.alpha = 0;
        add(leftArrow);
        
        FlxTween.tween(leftArrow, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
        // leftArrow.screenCenter(Y);

        rightArrow = new FlxSprite(FlxG.width - 322 - 93, 275).loadGraphic(Paths.image('menu/ui/selectionArrow'));
        rightArrow.alpha = 0;
        add(rightArrow);
        
        FlxTween.tween(rightArrow, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
        // rightArrow.screenCenter(Y);

        load();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.keys.justPressed.RIGHT) {
            if (curIcon < pathNames.length - 1) {
                curIcon += 1;
                iconBump(1);
            }

            updateIcon();
        }

        if(FlxG.keys.justPressed.LEFT) {
            if (curIcon > 0) {
                curIcon -= 1;
                iconBump(-1);
            }
            
            updateIcon();
        }

        if(FlxG.keys.justPressed.ESCAPE)
        {
            save();

            FlxTween.tween(menuBG, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            FlxTween.tween(iconShadow, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            FlxTween.tween(leftArrow, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            FlxTween.tween(rightArrow, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});

            for (v in grpIcons) {
                FlxTween.tween(v, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            }

            for (v in grpUnknown) {
                FlxTween.tween(v, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
            }

            new FlxTimer().start(0.5, function(t:FlxTimer) {
                close();
            });
        }
    }

    function save() {
        for (v in 0...pathNames.length) {
            if (v == curIcon) {
                if (Unlocks.get('icons.' + pathNames[v])) {
                    FlxG.save.data.travelIcon = pathNames[v];
                    FlxG.save.data.travelIconData = iconPaths.get(pathNames[v]);
                } else {
                    curIcon = 0;
                    FlxG.save.data.travelIcon = 'default';
                    FlxG.save.data.travelIconData = iconPaths.get('default');
                    updateIcon();
                }
            }
        }

        FlxG.save.flush();
    }

    function load() {
        if (FlxG.save.data.travelIconData == null) {
            curIcon = 0;
            return;
        } else {
            for (v in iconPaths.keys()) {
                if (iconPaths.get(v) == FlxG.save.data.travelIconData) {
                    curIcon = pathNames.indexOf(v);
                }
            }
            
            updateIcon();
        }
    }

    public static function resetIconData() {
        // EDGE CASE - RESET ICONS
        if (FlxG.save.data.travelIcon != null) { FlxG.save.data.travelIcon = null; }
        if (FlxG.save.data.travelIconData != null) { FlxG.save.data.travelIconData = null; }
    }

    function getMapLength(map:Map<String, Array<String>>):Int {
        var i:Int = 0;
        
        for (v in map.keys()) {
            i += 1;
        }

        return i;
    }

    function updateIcon() {
        var i:Int = 0;
        for (icon in grpIcons) {
            if (i != curIcon) icon.visible = false;
            else icon.visible = true;
            i++;
        }

        i = 0;
        for (icon in grpUnknown) {
            if (i != curIcon) icon.visible = false;
            else icon.visible = true;
            i++;
        }

        if (curIcon == 0) {
            leftArrow.color = 0x999999;
        } else {
            leftArrow.color = 0xFFFFFF;
        } 

        if (curIcon == pathNames.length - 1) {
            rightArrow.color = 0x999999;
        } else {
            rightArrow.color = 0xFFFFFF;
        } 
    }

    function iconBump(dir:Float = 1, intensity:Float = 25) {
        var xi = iconShadow.x;
        iconShadow.x += intensity * dir;
        iconShadow.updateHitbox();
        FlxTween.cancelTweensOf(iconShadow);
        FlxTween.tween(iconShadow, {x: xi}, 0.3, {
            ease: FlxEase.expoOut
        });

        for (icon in grpIcons) {
            icon.updateHitbox();
            icon.screenCenter(X);
            var x = icon.x;
            icon.x += intensity * dir;
            FlxTween.cancelTweensOf(icon);
            FlxTween.tween(icon, {x: x}, 0.3, {
                ease: FlxEase.expoOut
            });
        }

        for (icon in grpUnknown) {
            icon.updateHitbox();
            icon.screenCenter(X);
            var x = icon.x;
            icon.x += intensity * dir;
            FlxTween.cancelTweensOf(icon);
            FlxTween.tween(icon, {x: x}, 0.3, {
                ease: FlxEase.expoOut
            });
        }

        switch(dir) {
            case 1:
                var z = rightArrow.x;
                rightArrow.x += intensity * dir;
                rightArrow.updateHitbox();
                FlxTween.cancelTweensOf(rightArrow);
                FlxTween.tween(rightArrow, {x: z}, 0.3, {
                    ease: FlxEase.expoOut
                });
            case -1:
                var z = leftArrow.x;
                leftArrow.x += intensity * dir;
                leftArrow.updateHitbox();
                FlxTween.cancelTweensOf(leftArrow);
                FlxTween.tween(leftArrow, {x: z}, 0.3, {
                    ease: FlxEase.expoOut
                });
        }
    }
}
