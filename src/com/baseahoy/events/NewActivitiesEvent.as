package com.baseahoy.events
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	
	public class NewActivitiesEvent extends Event
	{
		public static const NEW_ACTIVITIES:String = "newActivities";
		
		public var activities:ArrayCollection;
		
		public function NewActivitiesEvent(type:String, activities:ArrayCollection)
		{
			super(type, false, false);
			
			this.activities = activities;
		}
		
		override public function clone():Event
		{
			return new NewActivitiesEvent(this.type, this.activities);
		}
	}
}