package com.baseahoy.activity
{
	import flash.display.Screen;
	import flash.events.*;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.TextArea;
	import mx.core.Window;
	import mx.events.FlexEvent;
	
	public class Notification extends Window
	{
		private var _showTimer:Timer;
		private var _delayTimer:Timer;
		private var _hideTimer:Timer;
		
		private var _delayTime:int;
		private var _message:String;
		private var _width:int;
		private var _height:int;
		
		public function Notification() {
			this.maximizable = false;
			this.resizable = false;
			this.minimizable = false;
			this.showTitleBar = false;
			this.showStatusBar = false;
			this.showGripper = false;
			this.alwaysInFront = true;
			
			// alternate, none, standard, utility
			this.systemChrome = "none";
			
			// lightweight, normal, utility
			this.type = "lightweight"
			
			this.addEventListener(FlexEvent.CREATION_COMPLETE, completeHandler);
		}
		
		public function completeHandler(event:FlexEvent):void {
			this.nativeWindow.x = Screen.mainScreen.bounds.width - (this.width + 20);
			this.nativeWindow.y = Screen.mainScreen.bounds.height - 50;
			
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";
			
			_showTimer = new Timer(10,0);
			_showTimer.addEventListener("timer", showTimerHandler);
			_showTimer.start();
		}
		
		public function show(message:String, title:String = "", delayTime:int=2, width:int=200, height:int=150): void {
			_delayTime = delayTime;
			
			this.width = width;
			this.height = height;
			
			var cnv:Canvas = new Canvas();
			cnv.width = width;
			cnv.height = height;
			cnv.horizontalScrollPolicy = "off";
			cnv.verticalScrollPolicy = "off";
			
			var ta:TextArea = new TextArea();
			ta.text = message;
			ta.width = width;
			ta.height = height;
			
			var btn:Button = new Button();
			btn.label = "My Message";
			btn.setStyle("right", "5");
			btn.setStyle("bottom", "45");
			
			cnv.addChild(ta);
			cnv.addChild(btn);
			
			this.addChild(cnv);
			
			this.open();
		}
		
		private function showTimerHandler(event:TimerEvent):void {
			this.nativeWindow.y -= 10;
			
			if(this.nativeWindow.y <= (Screen.mainScreen.bounds.height - (this.nativeWindow.height + 50))){
				_showTimer.stop();
				
				_delayTimer = new Timer(1000,_delayTime);
				_delayTimer.addEventListener("timer", delayTimerHandler);
				_delayTimer.start();
			}
		}
		
		private function delayTimerHandler(event:TimerEvent):void {
			var t:Timer = Timer(event.target);
			
			if(t.currentCount == _delayTimer.repeatCount){
				_hideTimer = new Timer(20,999);
				_hideTimer.addEventListener("timer", hideTimerHandler);
				_hideTimer.start();
			}
		}
		
		private function hideTimerHandler(event:TimerEvent):void {
			if(!this.nativeWindow.closed) {
				this.nativeWindow.y += 10;
				
				if(this.nativeWindow.y >= (Screen.mainScreen.bounds.height-50)){
					this.close();
					_hideTimer.stop();
				}
			} else {
				_hideTimer.stop();
			}
		}
	}
}