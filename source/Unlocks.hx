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

class Unlocks {
    private static var unlocks:Map<String, Bool>;

    public static function init(debug:Bool = false) {
        trace("Initializing Unlocks System");
        if (FlxG.save.data.unlocks != null) {
            trace("Lock datasave already exists! Loading...");
            unlocks = FlxG.save.data.unlocks;
            trace("Loaded lock datasave successfully!");
        } else {
            trace("Lock datasave not present, creating new...");

            reset(debug);
            
            FlxG.save.flush();
            trace("Successfully created new datasave! Try Unlocks.print() to see defaults!");
        }
    }

    public static function reset(debug:Bool = false) {
        if (debug) trace('Resetting unlocks file...');
        
        unlocks = new Map<String, Bool>();

        unlocks.set('devIcons', false);
        
        unlocks.set('icons.friend', false);
        unlocks.set('icons.altBF', false);
        unlocks.set('icons.butterdog', false);
        unlocks.set('icons.rushtoxin', false);

        if (debug) trace('Data reset! Saving...');
        save();
    }

    public static function unlock(name:String, doSave:Bool = true):Dynamic {
        trace("Attempting to unlock lock {" + name + "}...");
        if (unlocks.exists(name)) {
            if (unlocks.get(name)) {
                trace("Lock {" + name + "} already unlocked!");
                return 0;
            } else {
                unlocks.set(name, true);
                trace("Lock {" + name + "} unlocked!");
                if (doSave) save();
                return 1;
            }
        } else {
            trace("Error: No lock exists with the key {" + name + "}.");
            // This makes things work *too* well.
            set(name, true);
            trace("Finished edge case procedure! All set and ready to go.");

            return 0;
        }
    }

    public static function set(name:String, value:Bool = false) {
        trace("Attempting to set new value...");
        unlocks.set(name, value);
        trace("New lock set! Name: '" + name + "', value: '" + (value?'TRUE':'FALSE') + "'.");
        return 1;
    }

    public static function lock(name:String, doSave:Bool = true):Dynamic {
        trace("Attempting to lock lock {" + name + "}...");
        if (unlocks.exists(name)) {
            if (!unlocks.get(name)) {
                trace("Lock {" + name + "} already locked!");
                return 0;
            } else {
                unlocks.set(name, false);
                if (doSave) save();
                trace("Lock {" + name + "} locked!");
                return 1;
            }
        } else {
            trace("Error: No lock exists with the key {" + name + "}.");
            return 0;
        }
    }

    public static function print(debug:Bool = false):Dynamic {
        trace("PRINTING LOCK DATA BELOW:");
        var callback:Bool = false;

        for (key in unlocks.keys()) {
            try {
                trace("LOCK {" + key + "} UNLOCKED: " + (unlocks.get(key) ? "TRUE" : "FALSE") + ";");
            } catch(e) {
                trace("ERROR OCCURED WHILE PRINTING LOCK DATA");
                if (debug) trace(e);
                
            }
        }

        if (!callback) {
            trace("SUCCESSFULLY PRINTED LOCK DATA");
            return 1;
        } else {
            trace("FAILED TO PRINT LOCK DATA ENTIRELY");
            return 0;
        }
    }

    public static function get(name:String):Dynamic {
        if (unlocks.exists(name)) { 
            return unlocks.get(name);
        } else {
            return 'nil';
        }
    }

    public static function save(debug:Bool = false):Dynamic {
        trace("Attempting to save data...");
        
        if (debug) {
            trace("DEBUG: PRINTING DATA;");
            print();
        }

        try {
            FlxG.save.data.unlocks = unlocks;
            FlxG.save.flush();

            trace("Lock data saved successfully!");
            return 1;
        } catch(e) {
            trace("Error saving lock data!");
            return e;
        }
    }
}