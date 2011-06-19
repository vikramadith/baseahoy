package com.baseahoy.events
{
	import flash.events.Event;
	
	public class OnLoadSettingChangeEvent extends Event
	{
		public static const ON_LOAD_SETTING_CHANGE:String = "onLoadSettingChange";
		
		public var onLoad:Boolean;
		
		public function OnLoadSettingChangeEvent(type:String, onLoad:Boolean)
		{
			super(type, false, false);
			
			this.onLoad = onLoad;
		}
		
		override public function clone():Event
		{
			return new OnLoadSettingChangeEvent(this.type, this.onLoad);
		}
	}
}