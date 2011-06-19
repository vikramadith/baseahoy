package com.baseahoy.events
{
	import flash.events.Event;
	
	public class ApiResultEvent extends Event
	{
		public static const API_RESULT:String = "apiResult";
		
		public var result:XML;
		
		public function ApiResultEvent(type:String, result:XML)
		{
			super(type, false, false);
			
			this.result = result;
		}
		
		override public function clone():Event
		{
			return new ApiResultEvent(this.type, this.result);
		}
	}
}