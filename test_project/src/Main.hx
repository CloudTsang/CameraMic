package ;

/**
 * ...
 * @author Josu Igoa
 */

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.Lib;

#if !mobile
class Main extends Sprite
{
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = openfl.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		var w = Lib.current.stage.stageWidth * .5;
		var h = Lib.current.stage.stageHeight * .5;
		var txt = new TextField();
		txt.autoSize = TextFieldAutoSize.LEFT;
		txt.defaultTextFormat = new TextFormat(null, 20, 0);
		txt.text = "This library only works on mobile";
		txt.x = (w - txt.width) * .5;
		txt.y = (h - txt.height) * .5;
		Lib.current.addChild(txt);
	}
}
#else
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import sys.FileSystem;

class Main extends Sprite 
{
	var inited:Bool;
	var _bg:Shape;
	var _recordingAlert:Sprite;
	var _cameraBtn:Btn;
	var _recBtn:Btn;
	var _playBtn:Btn;
	var _stopBtn:Btn;

	var _isRecording:Bool;
	var _audioPath:String;
	var _photoBmp:Bitmap;
	
	function resize(e) 
	{
		if (!inited) init();
	}
	
	function init() 
	{
		if (inited) return;
		inited = true;

		CameraMic.appFilesDirectory = "/.cameraMicTest";
		
		_bg = new Shape();
		_bg.graphics.beginFill(0, .7);
		_bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		_bg.graphics.endFill();
		
		_cameraBtn = new Btn("CAMERA");
		_cameraBtn.addEventListener(Btn.CLICK, onCameraClick);
		_cameraBtn.x = (stage.stageWidth - _cameraBtn.width) * .5;
		_cameraBtn.y = stage.stageHeight * .1;
		
		_isRecording = false;
		_recBtn = new Btn("REC");
		_recBtn.addEventListener(Btn.CLICK, onRecClick);
		_recBtn.x = (stage.stageWidth - _recBtn.width) * .5;
		_recBtn.y = _cameraBtn.y + _cameraBtn.height * 1.5;
		
		_playBtn = new Btn("PLAY");
		_playBtn.addEventListener(Btn.CLICK, onPlayClick);
		_playBtn.x = (stage.stageWidth - _playBtn.width) * .5;
		_playBtn.y = _recBtn.y + _recBtn.height * 1.5;
		_playBtn.alpha = .5;
		
		_recordingAlert = new Sprite();
		var w = stage.stageWidth * .5;
		var h = stage.stageHeight * .5;
		_recordingAlert.graphics.beginFill(0x330000);
		_recordingAlert.graphics.drawRect(0, 0, w, h);
		_recordingAlert.graphics.endFill();
		var txt = new TextField();
		txt.autoSize = TextFieldAutoSize.LEFT;
		txt.defaultTextFormat = new TextFormat(null, 20, 0xFFFFFF);
		txt.text = "Recording...";
		txt.x = (w - txt.width) * .5;
		txt.y = (h - txt.height) * .5;
		_recordingAlert.addChild(txt);
		_stopBtn = new Btn("STOP");
		_stopBtn.addEventListener(Btn.CLICK, onStopClick);
		_stopBtn.x = (w - _stopBtn.width) * .5;
		_stopBtn.y = h - _stopBtn.height - 5;
		_recordingAlert.addChild(_stopBtn);
		_recordingAlert.x = w - _recordingAlert.width * .5;
		_recordingAlert.y = h - _recordingAlert.height * .5;
		
		this.addChild(_cameraBtn);
		this.addChild(_recBtn);
		this.addChild(_playBtn);
	}
	
	private function onCameraClick(e:Event):Void
	{
		CameraMic.takePhoto(this, cameraPhotoCallback);
	}
	
	private function onRecClick(e:Event):Void 
	{
		addChild(_bg);
		addChild(_recordingAlert);
		#if mobile
		CameraMic.startRecordingAudio(this, recordAudioCallback);
		#end
	}
	
	private function onStopClick(e:Event):Void 
	{
		removeChild(_bg);
		removeChild(_recordingAlert);
		CameraMic.stopRecordingAudio();
	}
	
	private function onPlayClick(e:Event):Void 
	{
		trace("onPlayClick Haxe");
		CameraMic.playAudio(_audioPath);
	}
	
	public function cameraPhotoCallback(photoPath:String, ?remove):Void
	{
        //var input = BitmapData.loadFromBytes(openfl.utils.ByteArray.readFile(photoPath));
		if (photoPath == null)
		{
			trace("HX: photo cancelled");
			return;
		}
		
        trace("HX: " + photoPath + " exists: " + FileSystem.exists(photoPath));
		var input:BitmapData = BitmapData.load(photoPath);
		
        trace("input.width " + input.width);
        
		if (input.width > 0)
		{
			var photoY = _playBtn.y + _playBtn.height + 5;
			var maxH = stage.stageHeight - photoY - 5;
			var s:Float;
			if (input.width > input.height)
				s = stage.stageWidth * .95 / input.width;
			else
				s = maxH / input.height;
			
			var output:BitmapData = new BitmapData(Std.int(input.width * s), Std.int(input.height * s), true, 0x0000000);
			var matrix:Matrix = new Matrix();
			matrix.scale(s, s);
			output.draw(input, matrix, null, null, null, true);
			_photoBmp = new Bitmap(output);
			_photoBmp.x = (stage.stageWidth - _photoBmp.width) * .5;
			_photoBmp.y = photoY;
			addChild(_photoBmp);
		}
	}

	public function recordAudioCallback(audioPath:String, ?remove):Void
	{
		_audioPath = audioPath;
		
		trace("recordAudioCallback " + _audioPath + " exists: " + FileSystem.exists(_audioPath));
		if (_audioPath != null)// && FileSystem.exists(_audioPath))
		{
			_playBtn.alpha = 1;
			if(!_playBtn.hasEventListener(Btn.CLICK))
				_playBtn.addEventListener(Btn.CLICK, onPlayClick);
		}
		else
		{
			_playBtn.alpha = .5;
			if(_playBtn.hasEventListener(Btn.CLICK))
				_playBtn.removeEventListener(Btn.CLICK, onPlayClick);
		}
	}
	/* SETUP */

	public function new() 
	{
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = openfl.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
}
#end