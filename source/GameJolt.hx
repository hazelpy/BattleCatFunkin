/*
REQUIREMENTS:

I will be editing the API for this, meaning you have to download a git:
haxelib git tentools https://github.com/TentaRJ/tentools.git
UPDATED SEPT.6.2021

You need to download and rebuild SysTools, I think you only need it for Windows but just get it *just in case*:
haxelib git systools https://github.com/haya3218/systools
haxelib run lime rebuild systools [windows, mac, linux]

SETUP:
To add your game's keys, you will need to make a file in the source folder named GJKeys.hx (filepath: ../source/GJKeys.hx)

In this file, you will need to add the GJKeys class with two public static variables, id:Int and key:String

Example:

package;
class GJKeys
{
    public static var id:Int = 	0; // Put your game's ID here
    public static var key:String = ""; // Put your game's private API key here
}

You can find your game's API key and ID code within the game page's settngs under the game API tab.

Hope this helps! -tenta

USAGE:
To start up the API, the two commands you want to use will be:
GameJoltAPI.connect();
GameJoltAPI.authDaUser(FlxG.save.data.gjUser, FlxG.save.data.gjToken);
*You can't use the API until this step is done!*

FlxG.save.data.gjUser & gjToken are the save values for the username and token, used for logging in once someone already logs in.
Save values (gjUser & gjToken) are deleted when the player signs out with GameJoltAPI.deAuthDaUser(); and are replaced with "".

To open up the login menu, switch the state to GameJoltLogin.
Exiting the login menu will throw you back to Main Menu State. You can change this in the GameJoltLogin class.

The session will automatically start on login and will be pinged every 30 seconds.
If it isn't pinged within 120 seconds, the session automatically ends from GameJolt's side.
Thanks GameJolt, makes my life much easier! Not sarcasm!

You can give a trophy by using:
GameJoltAPI.getTrophy(trophyID);
Each trophy has an ID attached to it. Use that to give a trophy. It could be used for something like a week clear...

Hope this helps! -tenta

And yes, I run Mac. A fate worse than death.
*/

import flixel.tile.FlxTile;
import haxe.ds.ReadOnlyArray;
import tentools.api.FlxGameJolt as GJApi;

import openfl.display.BitmapData;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxButtonPlus;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import lime.system.System;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import Sys;

import openfl.filters.BlurFilter;
import openfl.geom.Rectangle;
import openfl.geom.Point;

// Unused
// class GameJoltGameData
// {
//     public static var trophyArray:Array<Int> = [147704, 148024]; /* Place your game's trophies here if you want them to count for the completion bar */
// }

class GameJoltAPI // Connects to tentools.api.FlxGameJolt
{
    static var userLogin:Bool = false;
    public static var totalTrophies:Float = GJApi.TROPHIES_ACHIEVED + GJApi.TROPHIES_MISSING;
    public static function getUserInfo(username:Bool = true):String /* Grabs user data and returns as a string, true for Username, false for Token */
    {
        if(username)return GJApi.username;
        else return GJApi.usertoken;
    }
    public static function getStatus():Bool /* Checks to see if the user has signed in */
    {
        return userLogin;
    }
    public static function connect() /* Sets the game ID and game key */
    {
        trace("Grabbing API keys...");
        GJApi.init(Std.int(GJKeys.id), Std.string(GJKeys.key), false);
    }

    public static function authDaUser(in1, in2, ?loginArg:Bool = false) /* Logs the user in */
    {
        if(!userLogin)
        {
        GJApi.authUser(in1, in2, function(v:Bool)
            {
                // trace("user: "+(in1 == "" ? "n/a" : in1));
                // trace("token:"+in2);
                if(v)
                    {
                        trace("User authenticated!");
                        FlxG.save.data.gjUser = in1;
                        FlxG.save.data.gjToken = in2;
                        FlxG.save.flush();
                        userLogin = true;
                        startSession();
                        // bro this was confusing me why did you do this
                        // FlxG.sound.play(Paths.sound('confirmMenu'));
                        if(loginArg)
                        {
                            GameJoltLogin.login=true;
                            FlxG.switchState(new GameJoltLogin());
                        }
                    }
                else 
                    {
                        if(loginArg)
                        {
                            GameJoltLogin.login=true;
                            FlxG.switchState(new GameJoltLogin());
                        }
                        trace("User login failure!");
                        // FlxG.switchState(new GameJoltLogin());
                    }
            });
        }
    }
    public static function deAuthDaUser() /* Logs the user out and closes the game */
    {
        closeSession();
        userLogin = false;
        // trace(FlxG.save.data.gjUser + FlxG.save.data.gjToken);
        FlxG.save.data.gjUser = "";
        FlxG.save.data.gjToken = "";
        FlxG.save.flush();
        // trace(FlxG.save.data.gjUser + FlxG.save.data.gjToken);
        trace("Logged out!");
        GameJoltLogin.restart();
    }

    public static function getTrophy(trophyID:Int) /* Awards a trophy to the user! */
    {
        if(userLogin)
        {
            GJApi.addTrophy(trophyID, function(){trace("Unlocked a trophy with an ID of "+trophyID);});
        }
    }

    // public static function isTropheyCollected(id:Int):Bool
    // {
    //     var value:Bool;
    //     GJApi.fetchTrophy(id, function(data:Map<String, String>)
    //         {
    //             if (Std.string(data.get("achieved")) != "false")
    //                 value=true;
    //             else
    //                 value=false;

    //             trace(id+""+value);

    //         });
    //     return value;
    // }
    // public static function fetchAllTrophies()
    // {
    //     new FlxTimer().start(0.05, function(tmr:FlxTimer){trophyArray=[];});
    //     new FlxTimer().start(0.2, function(tmr:FlxTimer)
    //         {GJApi.fetchTrophy(0, function(trophy:Map<String, String>)
    //             {
    //                 trophyArray.push(trophy.get('id').toString());
    //             });
    //         });
    //     new FlxTimer().start(1, function(tmr:FlxTimer){trace(trophyArray.length); trace(trophyArray);});
    // }
    // public static function getScore(score:Float, songName:String, difficulty:String) /* Submit your high scores to a leaderboard! Wow, innovative! */
    // {
    //     var tableID:Int = getSongID(songName, difficulty);
    //     GJApi.addScore(Std.string(score + " score - Achived on " + Date.now()), score, tableID);
    // }
    // public static function getProfileImage():BitmapData /* Gets the user's profile picture */
    // {
    //     var image;
    //     GJApi.fetchAvatarImage(function(data:BitmapData){image = data;});
    //     return image;
    // }
    public static function startSession() /*Starts the session */
    {
        GJApi.openSession(function()
            {
                trace("Session started!");
                new FlxTimer().start(20, function(tmr:FlxTimer){pingSession();}, 0);
            });
    }
    public static function pingSession() /* Pings GameJolt to show the session is still active */
    {
        GJApi.pingSession(true, function(){trace("Ping!");});
    }
    public static function closeSession() /* Closes the session, used for signing out */
    {
        GJApi.closeSession(function(){trace('Closed out the session');});
    }
    // public static function getSongID(song:String, difficulty:String):Int
    // {
    //     return 0;
    // }
}

class GameJoltInfo extends FlxSubState
{
    public static var version:String = "1.0.2 Public Beta";
}

class GameJoltLogin extends MusicBeatSubstate
{
    var gamejoltText:FlxText;
    var loginTexts:FlxTypedGroup<FlxText>;
    var loginBoxes:FlxTypedGroup<FlxUIInputText>;
    var loginButtons:FlxTypedGroup<FlxButtonPlus>;
    var usernameText:FlxText;
    var tokenText:FlxText;
    var usernameBox:FlxUIInputText;
    var tokenBox:FlxUIInputText;
    var signInBox:FlxButtonPlus;
    var helpBox:FlxButtonPlus;
    var logOutBox:FlxButtonPlus;
    var cancelBox:FlxButtonPlus;
    var profileIcon:FlxSprite;
    var username:FlxText;
    var gamename:FlxText;
    var trophy:FlxBar;
    var trophyText:FlxText;
    var missTrophyText:FlxText;
    public static var charBop:FlxSprite;
    var icon:FlxSprite;
    var baseX:Int = -460;

    var versionText:FlxText;
    var creditsText:FlxText;
    
    public static var login:Bool = false;
    static var trophyCheck:Bool = false;

    override function create()
    {
//         if(!login)
//             {
//                 FlxG.sound.playMusic(Paths.music('freakyMenu'),0);
//                 FlxG.sound.music.fadeIn(2, 0, 0.85);
// 		Conductor.changeBPM(102);
//             }

        trace("init? " + GJApi.initialized);   

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gamejolt/loginBackground', 'preload'));
		bg.setGraphicSize(FlxG.width);
		bg.antialiasing = true;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

        charBop = new FlxSprite(FlxG.width - 400, 250);
		charBop.frames = Paths.getSparrowAtlas('BOYFRIEND', 'shared');
		charBop.animation.addByPrefix('idle', 'BF idle dance', 24, false);
        charBop.animation.addByPrefix('loggedin', 'BF HEY', 24, false);
        charBop.setGraphicSize(Std.int(charBop.width * 1.4));
		charBop.antialiasing = true;
        charBop.flipX = false;
		add(charBop);

        // Constant for utility
        var textColor = FlxColor.fromRGB(106, 212, 185);

        gamejoltText = new FlxText(0, 25, 0, "GameJolt Integration", 16);
        gamejoltText.setFormat(Paths.font('taxicab.ttf'), 32, 0x00FFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0x00000000);
        gamejoltText.screenCenter(X);
        gamejoltText.x = 25;
        gamejoltText.borderSize = 2;
        gamejoltText.color = textColor;
        add(gamejoltText);

        versionText = new FlxText(5, FlxG.height - 18, 0, "Game ID: " + GJKeys.id + " API: " + GameJoltInfo.version , 12);
        creditsText = new FlxText(5, FlxG.height - 18, 0, "GameJolt Integration developed by TentaRJ", 12);

        #if debug
        add(versionText);
        #else
        add(creditsText);
        #end

        loginTexts = new FlxTypedGroup<FlxText>(2);
        add(loginTexts);

        usernameText = new FlxText(0, 125, 300, "Username:", 30);
        usernameText.setFormat(Paths.font('taxicab.ttf'), 30, textColor, 'left', FlxTextBorderStyle.OUTLINE, 0x00000000);

        tokenText = new FlxText(0, 235, 300, "Token:", 30);
        tokenText.setFormat(Paths.font('taxicab.ttf'), 30, textColor, 'left', FlxTextBorderStyle.OUTLINE, 0x00000000);

        loginTexts.add(usernameText);
        loginTexts.add(tokenText);
        loginTexts.forEach(function(item:FlxText){
            item.screenCenter(X);
            item.x += baseX;
        });

        loginBoxes = new FlxTypedGroup<FlxUIInputText>(2);
        add(loginBoxes);

        usernameBox = new FlxUIInputText(0, 175, 300, null, 32, textColor, FlxColor.fromRGB(27, 40, 46));
        usernameBox.setFormat(Paths.font('taxicab.ttf'), 32, textColor, 'left', FlxTextBorderStyle.OUTLINE, 0x00000000);
        tokenBox = new FlxUIInputText(0, 285, 300, null, 32, textColor, FlxColor.fromRGB(27, 40, 46));
        tokenBox.setFormat(Paths.font('taxicab.ttf'), 32, textColor, 'left', FlxTextBorderStyle.OUTLINE, 0x00000000);
        tokenBox.passwordMode = true;

        loginBoxes.add(usernameBox);
        loginBoxes.add(tokenBox);

        loginBoxes.forEach(function(item:FlxUIInputText){
            item.screenCenter(X);
            item.x += baseX;
        });

        if(GameJoltAPI.getStatus())
        {
            remove(loginTexts);
            remove(loginBoxes);
        }

        loginButtons = new FlxTypedGroup<FlxButtonPlus>(3);
        add(loginButtons);

        var btnNatural:FlxSprite = new FlxSprite().loadGraphic(Paths.image("gamejolt/btnNatural", "preload"));
        var btnHover:FlxSprite = new FlxSprite().loadGraphic(Paths.image("gamejolt/btnHover", "preload"));

        signInBox = new FlxButtonPlus(0, 400, function() {
            //trace(usernameBox.text);
            //trace(tokenBox.text);
            GameJoltAPI.authDaUser(usernameBox.text,tokenBox.text,true);
        }, "Sign In", 240, 60);

        signInBox.loadButtonGraphic(btnNatural, btnHover);
        signInBox.textHighlight.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.BLACK, 'center');
        signInBox.textNormal.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.WHITE, 'center');

        helpBox = new FlxButtonPlus(0, 500, function() {
            openLink('https://www.youtube.com/watch?v=T5-x7kAGGnE');
        }, "GameJolt Token", 240, 60);
        
        helpBox.loadButtonGraphic(btnNatural, btnHover);
        helpBox.textHighlight.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.BLACK, 'center');
        helpBox.textNormal.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.WHITE, 'center');

        logOutBox = new FlxButtonPlus(0, 600, function() {
            // GameJoltAPI.fetchAllTrophies();
            GameJoltAPI.deAuthDaUser();
        }, "Log Out & Restart", 240, 60);

        logOutBox.loadButtonGraphic(btnNatural, btnHover);
        logOutBox.textHighlight.setFormat(Paths.font('taxicab.ttf'), 30, FlxColor.BLACK, 'center');
        logOutBox.textNormal.setFormat(Paths.font('taxicab.ttf'), 30, FlxColor.WHITE, 'center');

        #if !windows
        logOutBox.text = "Log Out & Close";
        #end

        cancelBox = new FlxButtonPlus(0, 600, function() {
            FlxG.switchState(new MainMenuState());
        }, "Not Right Now", 240, 60);

        cancelBox.loadButtonGraphic(btnNatural, btnHover);
        cancelBox.textHighlight.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.BLACK, 'center');
        cancelBox.textNormal.setFormat(Paths.font('taxicab.ttf'), 32, FlxColor.WHITE, 'center');

        if(!GameJoltAPI.getStatus())
        {
            loginButtons.add(signInBox);
            loginButtons.add(helpBox);
        }
        else
        {
            cancelBox.y = 500;
            cancelBox.text = "Continue";
            loginButtons.add(logOutBox);
        }
        loginButtons.add(cancelBox);

        loginButtons.forEach(function(item:FlxButtonPlus){
            item.screenCenter(X);
            item.x += baseX - 31;
        });

        if(GameJoltAPI.getStatus())
        {
            username = new FlxText(25, 75, 0, "Signed in as " + GameJoltAPI.getUserInfo(true), 40);
            username.setFormat(Paths.font('taxicab.ttf'), 40, 0x00FFFFFF, 'left', FlxTextBorderStyle.OUTLINE, 0x00000000);
            add(username);

            // if (GameJoltGameData.trophyArray.length != 0)
            // {
            //     trophyText=new FlxText(0, 200, 0, "Loading...", 48);
            //     trophyText.alignment = CENTER;
            //     trophyText.screenCenter(X);
            //     trophyText.x += baseX;
            //     add(trophyText);
            // }
        }

        FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float)
    {
        // if (GameJoltGameData.trophyArray.length != 0 && !trophyCheck)
        // {
        //     var value:Int = 0;
        //     for (i in 0...GameJoltGameData.trophyArray.length)
        //     {
        //         new FlxTimer().start(0.8, function(tmr:FlxTimer){if (GameJoltAPI.isTropheyCollected(GameJoltGameData.trophyArray[i])){value ++; trophyText.text = "Trophies Collected:\n"+value+" out of "+GameJoltGameData.trophyArray.length ;}});
        //     }
        //     trophyCheck=true;
        // }


        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if (!FlxG.sound.music.playing)
        {
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
        }

        if (FlxG.keys.justPressed.ESCAPE)
        {
            FlxG.mouse.visible = false;
            FlxG.switchState(new MainMenuState());
        }

        super.update(elapsed);
    }

    override function beatHit()
    {
        super.beatHit();
        charBop.animation.play((GameJoltAPI.getStatus() ? "loggedin" : "idle"));
    }

    public static function restart()
    {
        #if windows
        var os = Sys.systemName();
        var args = "Test.hx";
        var app = "";
        var workingdir = Sys.getCwd();

        FlxG.log.add(app);

        app = Sys.programPath();

        // Launch application:
        var result = systools.win.Tools.createProcess(app // app. path
            , args // app. args
            , workingdir // app. working directory
            , false // do not hide the window
            , false // do not wait for the application to terminate
        );
        // Show result:
        if (result == 0)
        {
            FlxG.log.add('SUS');
            System.exit(1337);
        }
        else
            throw "Failed to restart";
        #else
        System.exit(0);
        #end
    }
    function openLink(url:String)
    {
        #if linux
        Sys.command('/usr/bin/xdg-open', [url, "&"]);
        #else
        FlxG.openURL(url);
        #end
    }
}
