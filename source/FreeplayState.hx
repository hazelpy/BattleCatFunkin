package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.utils.Assets;


#if desktop
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var screenDim:FlxSprite;
	var weekAlert:FlxText;
	var alertActive:Bool = false;
	
	var songWeekInfo:FlxText;
	var songNameText:FlxText;

	var songIconPaths:Map<String, String>;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var grpHighlights:FlxTypedGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		songIconPaths = [
			'cat' => 'cat',
			'macho' => 'macho',
			'mohawk' => 'mohawk',
			'tank' => 'tank',
			'wall' => 'wall',
			'eraser' => 'eraser',
			'gf' => 'gf',
			'default' => 'default',
			'locked' => 'locked'
		];

		// menu/ui/songselect/icons/icon name
		for (i in 0...initSonglist.length)
		{
			var songData = initSonglist[i];
			var splitList = songData.split(":");
			var songName = splitList[0];
			var songWeek = Std.int( Std.parseFloat(splitList[1]) );
			var songChar = splitList[2];
			
			var songLockData = Std.int( Std.parseFloat(splitList[3]) );
			var songLocked:Bool = false;

			switch(songLockData) {
				case 1:
					songLocked = false;
				case 2:
					songLocked = true;
			}

			songs.push(new SongMetadata(songName, songWeek, songChar, songLocked));
		}

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		 #if desktop
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Menus", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/ui/songselect/background'));
		add(bg);

		grpSongs = new FlxTypedGroup<FlxSprite>();
		add(grpSongs);

		grpHighlights = new FlxTypedGroup<FlxSprite>();
		add(grpHighlights);

		for (i in 0...12)
		{
			// songs[i].songName = song name
			// songs[i].songCharacter = song character (unused)
			// Make sure to use these values when putting together the grid !!
			// GRID TOP LEFT: x: 227, y: 149
			// GAPS: x: 141, y: 114

			if (i < songs.length) {
				var iconPath:String = songIconPaths.get("default");

				if ( songIconPaths.exists(songs[i].songCharacter) ) iconPath = songIconPaths.get(songs[i].songCharacter);
				if ( songs[i].locked ) iconPath = songIconPaths.get('locked');

				var songIcon:FlxSprite = new FlxSprite(227 + ( ( i % 6 ) * 141 ), 149 + ( Math.floor( i / 6 ) * 114) );
					songIcon.loadGraphic(Paths.image('menu/ui/songselect/icons/' + iconPath));
					songIcon.ID = i;
				grpSongs.add(songIcon);

				var songHighlight:FlxSprite = new FlxSprite(227 + ( ( i % 6 ) * 141 ), 149 + ( Math.floor( i / 6 ) * 114) );
					songHighlight.loadGraphic(Paths.image('menu/ui/songselect/icons/highlight'));
					songHighlight.ID = i;
					songHighlight.visible = false;
				grpHighlights.add(songHighlight);
			} else {
				var songIcon:FlxSprite = new FlxSprite(227 + ( ( i % 6 ) * 141 ), 149 + ( Math.floor( i / 6 ) * 114) );
					songIcon.loadGraphic(Paths.image('menu/ui/songselect/icons/empty'));
				grpSongs.add(songIcon);
			}

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(5, 65, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(0, 62).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);

		// Song Info Panel
		var infoPanel:FlxSprite = new FlxSprite(0, 0).loadGraphic( Paths.image("menu/ui/songselect/captionHolder") );
		add(infoPanel);

		// 244, 594 : Coordinates for lower text. 36 font.
		// 244, 470 : Coordinates for name text and locked text. 46 font.
		// 792 width for box width.
		songNameText = new FlxText(244, 455, 792, "Tutorial", 36);
		songNameText.setFormat(Paths.font('taxicab.ttf'), 36, FlxColor.WHITE, LEFT);

		songWeekInfo = new FlxText(244, 585, 792, "The tutorial song.", 36);
		songWeekInfo.setFormat(Paths.font('taxicab.ttf'), 36, FlxColor.WHITE, LEFT);

		add(songNameText);
		add(songWeekInfo);
		 updateSongInfo();

		// Borders & Version Shit. Added last.
		var menuBorders:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/menuBorders") );
		add(menuBorders);
	
		var menuBText:FlxSprite = new FlxSprite().loadGraphic( Paths.image("menu/songSelectText") );
		add(menuBText);

		// Screen Dim and Alert Overlay. Added after the borders to affect the whole screen.
		screenDim = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		screenDim.alpha = 0;
		add(screenDim);

		weekAlert = new FlxText(160, 96, 960, "", 56);
		weekAlert.setFormat(Paths.font('taxicab.ttf'), 56, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		weekAlert.alpha = 0;
		add(weekAlert);

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (!alertActive) {
			if (controls.LEFT_P)
			{
				changeSelection(-1);
			}
			if (controls.RIGHT_P)
			{
				changeSelection(1);
			}

			changeDiff(0);

			if (upP)
				changeDiff(-1);
			if (downP)
				changeDiff(1);

			if (controls.BACK)
			{
				FlxG.sound.playMusic(Paths.music('bcMenu'), 0);
				FlxG.switchState(new MainMenuState());
			}

			if (accepted)
			{
				if (!(songs[curSelected].locked)) {
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

					trace(poop);

					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;

					PlayState.storyWeek = songs[curSelected].week;
					trace('CUR WEEK' + PlayState.storyWeek);
					LoadingState.loadAndSwitchState(new PlayState());
				} else {
					songLockedCondition(songs[curSelected].week);
				}
			}
		}
	}

	function showScreenAlert(text:String = "Alert!", time:Float = 1) {
		alertActive = true;

		FlxTween.cancelTweensOf(screenDim); // Cancel tweens of dimming background
		FlxTween.cancelTweensOf(weekAlert); // Cancel tweens of alert text

		weekAlert.text = text;

		FlxTween.tween(screenDim, {alpha: 0.6}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(weekAlert, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
	
		new FlxTimer().start(time, function(t:FlxTimer) {
			alertActive = false;

			FlxTween.tween(screenDim, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
			FlxTween.tween(weekAlert, {alpha: 0}, 0.5, {ease: FlxEase.expoInOut});
		});
	}

	function songLockedCondition(weekNum:Int = 0) {
		// This code runs if a player tries to play a locked song.
		var weekString = "Week " + weekNum;
		
		if (weekNum == 0) 
			weekString = "the Tutorial";
		
		var weekAlertString = "This song is locked!\nPlease go and visit " + weekString + "\nto unlock this song in Song Select.\nThank you!";
		showScreenAlert(weekAlertString);
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if(songs[curSelected].songName.toLowerCase() == "galaxy-collapse")
		{
			if (curDifficulty < 2)
				curDifficulty = 5;
			if (curDifficulty > 5)
				curDifficulty = 2;
		}
		else 
		{
			if (curDifficulty < 0)
				curDifficulty = 2;
			if (curDifficulty > 2)
				curDifficulty = 0;
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
			case 3:
				diffText.text = "HARDER";
			case 4:
				diffText.text = "HARDEST";
			case 5:
				diffText.text = "CATACLYSMIC";
		}
	}

	function updateSongInfo() {
		var songData = songs[curSelected];

		if (songData.locked) {
			songNameText.text = "LOCKED";
			
			switch(songData.songName.toLowerCase()) {
				case 'Tutorial':
					songWeekInfo.text = "Play the Tutorial to unlock it here.";
				default:
					songWeekInfo.text = "Play through Week " + songData.week + " to unlock this song.";
			}
		} else {
			songNameText.text = songData.songName;
			
			switch(songData.songName.toLowerCase()) {
				case 'tutorial':
					songWeekInfo.text = "A basic tutorial song.";
				default:
					songWeekInfo.text = "This song is featured in Week " + songData.week + ".";
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		if (change != 0) { updateSongInfo(); }

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		// DON'T PLAY SONG IF LOCKED, NO SPOILERS! Just keep the previous one rollin'.
		if (!(songs[curSelected].locked)) {
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		}
		#end

		var bullShit:Int = 0;

		for (item in grpHighlights.members) {
			if (item.ID == curSelected) {
				item.visible = true;
			} else {
				item.visible = false;
			}
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var locked:Bool = false;

	public function new(song:String, week:Int, songCharacter:String, locked:Bool = false)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.locked = locked;
	}
}
