package com.baseahoy.events
{
	import flash.events.Event;
	
	public class AddAccountFinishEvent extends Event
	{
		public static const ADD_ACCOUNT_FINISH:String = "addAccountFinish";
		
		public var endpoint:String;
		public var token:String;
		
		public function AddAccountFinishEvent(type:String, endpoint:String, token:String)
		{
			super(type, false, false);
			
			this.endpoint = endpoint;
			this.token = token;
		}
		
		override public function clone():Event
		{
			return new AddAccountFinishEvent(this.type, this.endpoint, this.token);
		}
	}
}