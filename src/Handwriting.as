package {

import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Timer;

public class Handwriting extends Sprite {
  private var canvasAreaShape:Shape = new Shape();
  private var ctx:Graphics = canvasAreaShape.graphics;
  private var drawingPath:Array = new Array();
  private var strokeX:Vector.<int>;
  private var strokeY:Vector.<int>;
  private var strokeZ:Vector.<int>;
  private var startTime:Number;
  private var isDrawing:Boolean = false;
  private var isStartStroke:Boolean = false;
  private var autoSendTimer:Timer;
  private var maxHeight:int;
  private var maxWidth:int;
  private var handWriteText:TextField;
  private var userLocale:String;
  private var end:Point = new Point();
  private var start:Point= new Point();
  private var movement:Number=0;
  private var nodes:Vector.<Node> = new Vector.<Node>();

  public function Handwriting() {
    stage.align = StageAlign.TOP_LEFT;
    stage.scaleMode = StageScaleMode.NO_SCALE;
    addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
  }

  private function onAddedToStage(event:Event):void {
    userLocale = Capabilities.language;
    trace("locale is " + userLocale);
    addChild(canvasAreaShape);

    handWriteText = new TextField();
    var textFormat:TextFormat = new TextFormat();
    textFormat.size = 26;
    handWriteText.defaultTextFormat = textFormat;
    handWriteText.autoSize = TextFieldAutoSize.LEFT;
    handWriteText.text = "Ready : ";
    handWriteText.x = 10;
    handWriteText.y = 10;
    addChild(handWriteText);

    stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

    autoSendTimer = new Timer(1000, 1);
  }

  private function onMouseDown(event:MouseEvent):void {
    strokeX = new Vector.<int>();
    strokeY = new Vector.<int>();
    strokeZ = new Vector.<int>();
    if (!isStartStroke) {
      ctx.clear();
      ctx.lineStyle(1, 0xa0a0a0);

      isStartStroke = true;
      startTime = new Date().getTime();
      trace("startTime: " + startTime);
      maxWidth = 0;
      maxHeight = 0;
    }

    ctx.moveTo(event.localX, event.localY);
    addStrokes(event);

    isDrawing = true;

    start.x = mouseX;
    start.y = mouseY;
    movement = 0;
    nodes.push(new Node(start.clone(), new Point));
  }

  private function onMouseMove(event:MouseEvent):void {
    if (isDrawing) {
      addStrokes(event);
      if (autoSendTimer.running) {
        trace("reset timer");
        autoSendTimer.reset();
      }
    }
  }

  private function addStrokes(event:MouseEvent):void {
    end.x=mouseX;
    end.y=mouseY;

    var time:Number = new Date().getTime();
    strokeX.push(event.localX as Number);
    strokeY.push(event.localY as Number);
    strokeZ.push(time - startTime);
    maxHeight = maxHeight > event.localY ? maxHeight : event.localY;
    maxWidth = maxWidth > event.localX ? maxHeight : event.localX;
    ctx.lineTo(event.localX, event.localY);

    start.x=end.x;
    start.y=end.y;
  }

  private function onMouseUp(event:MouseEvent):void {
    if (isDrawing) {
      isDrawing = false;
      addStrokes(event);
      drawingPath.push([strokeX, strokeY, strokeZ]);

      end.x = mouseX ; end.y = mouseY
      nodes.push(new Node(end.clone(), new Point))

      trace(JSON.stringify(drawingPath));
      autoSendTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
      autoSendTimer.start();
    }
  }

  private function onTimerComplete(event:TimerEvent):void {
    trace("complete");

    /*
     curl -X POST -H "Content-Type: application/json"
     -d '{"device":"Mozilla/5.0 (Linux; Android 4.0.4; GT-i9100 Build/IML74K) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.49 Mobile Safari/537.31 ApiKey/1.257","options":"enable_pre_space","requests":[{"writing_guide":{"writing_area_width":360,"writing_area_height":567},"ink":[[[98,118,141,192,200],[159,149,139,138,190],[0,1,2,3,4]],[[89,112,133,236],[254,248,242,217],[5,6,7,8]],[[202],[230],[9]],[[202,198,187,189,194],[230,248,322,384,424],[10,11,12,13,14]]],"language":"ko"}]}'
     https://www.google.com/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8
     */
    var loader:URLLoader = new URLLoader();
    var request:URLRequest = new URLRequest("https://www.google.com/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8");

    request.method = URLRequestMethod.POST;
    request.requestHeaders = [new URLRequestHeader("Content-type", "application/json")];
    request.data = '{"device":"Mozilla/5.0",' +
      '"options":"enable_pre_space","requests":[{"writing_guide":{"writing_area_width":' + maxWidth + ',"writing_area_height":' + maxHeight + '},' +
      '"ink":' + JSON.stringify(drawingPath) + ',"language":"' + userLocale + '"}]}'

    trace(request.data);
    loader.addEventListener(Event.COMPLETE, onRequestComplete);
    loader.load(request);
    drawingPath.length = 0;
    isStartStroke = false;
  }

  private function onRequestComplete(event:Event):void {
    trace("response");
    var response:Object = JSON.parse((event.target as URLLoader).data);
    trace(JSON.stringify(response));
    if (response[0] == "SUCCESS") {
      handWriteText.text += response[1][0][1][0];
    }
  }
}

}
