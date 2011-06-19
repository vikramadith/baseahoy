package com.baseahoy.activity
{
	[Bindable]
	public class Activity
	{
		public var activityID:String;
		public var description:String;
		public var project:String;
		public var user:String;
		public var date:Date;
		public var activityType:int;
		public var link:String;	
		public var viewed:Boolean = true;
	}
}