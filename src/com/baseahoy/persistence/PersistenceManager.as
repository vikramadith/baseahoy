package com.baseahoy.persistence
{
	import com.baseahoy.activity.Activity;
	import com.baseahoy.utils.DateUtil;
	import com.baseahoy.utils.FileUtil;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.controls.DateField;
	import mx.core.Application;
	
	
	public class PersistenceManager
	{	
		public static function get isSetup():Boolean
		{
			return (dataXML.userToken != null && dataXML.userToken.toString().length > 0)
		}
		
		public static function get endpoint():String
		{
			return dataXML.endpoint;
		}		
		public static function set endpoint(value:String):void
		{
			delete dataXML.endpoint;
			dataXML.endpoint = value;
		}
		
		public static function get userToken():String
		{
			return dataXML.userToken;
		}		
		public static function set userToken(value:String):void
		{
			delete dataXML.userToken;
			dataXML.userToken = value;
		}
		
		public static function get refreshTime():int
		{
			return dataXML.refreshTime;
		}		
		public static function set refreshTime(value:int):void
		{
			delete dataXML.refreshTime;
			dataXML.refreshTime = value;
		}
		
		public static function get latestActivityTime():Date
		{			
			var date:Date = new Date(Number(dataXML.latestActivityTime))
			
			return date;
		}		
		public static function set latestActivityTime(value:Date):void
		{
			delete dataXML.latestActivityTime;
			dataXML.latestActivityTime = value.time;
		}		
		
		public static function get todoListIDs():ArrayCollection
		{
			var xmlList:XMLList = dataXML.todoListIDs.todoListID;
			
			var items:ArrayCollection = new ArrayCollection();
			for(var nodeIndex:int = 0; nodeIndex < xmlList.length(); nodeIndex++)
				items.addItem(xmlList[nodeIndex].toString());
			
			return items;
		}		
		
		public static function addTodoListID(todoListID:String):void
		{
			(dataXML.todoListIDs[0] as XML).appendChild(<todoListID>{todoListID}</todoListID>);
		}
		
		/*public static function set todoListIDs(value:ArrayCollection):void
		{
			delete dataXML.todoListIDs.todoListID;
			
			for(var itemIndex:int = 0; itemIndex < value.length; itemIndex++)
				(dataXML.todoListIDs as XML).appendChild(<todoListID>{value}</todoListID>);
		}*/
		
		public static function getNewActivities():ArrayCollection
		{
			var xmlList:XMLList = dataXML.latestActivity.activity;
			
			var items:ArrayCollection = new ArrayCollection();
			for(var nodeIndex:int = 0; nodeIndex < xmlList.length(); nodeIndex++)
			{
				var node:XML = xmlList[nodeIndex] as XML;
				
				var activity:Activity = new Activity();
				activity.activityID = node.activityID;
				activity.description = node.description;
				activity.user = node.user;
				activity.project = node.project;
				
				if(node.date.toString() == "null")
					activity.date = null;
				else
					activity.date = new Date(Date.parse(node.date.toString()));
				
				activity.activityType = node.activityType;
				activity.link = node.link;
				
				/*if(node.viewed.toString() == "false")
				activity.viewed = false;
				else
				activity.viewed = true;*/
				
				items.addItem(activity);
			}
			
			return items;
		}		
		
		public static function addNewActivity(newActivity:Activity):void
		{			
			var activityXML:XML = <activity/>;
			activityXML.activityID = newActivity.activityID;
			activityXML.description = newActivity.description;
			activityXML.user = newActivity.user;
			activityXML.project = newActivity.project;
			activityXML.date = newActivity.date;
			activityXML.activityType = newActivity.activityType;
			activityXML.link = newActivity.link;
			activityXML.viewed = newActivity.viewed;
			
			var xmlList:XMLList = dataXML.latestActivity.activity;
			
			if(xmlList && xmlList.length() > 0)
			{
				if(xmlList.length() == 5)
					delete xmlList[xmlList.length() - 1];
				
				(dataXML.latestActivity[0] as XML).prependChild(activityXML);
			}
			else
			{
				(dataXML.latestActivity[0] as XML).appendChild(activityXML);
			}
		}
		
		public static function loadData():void
		{
			dataFile = File.applicationStorageDirectory;
			dataFile = dataFile.resolvePath("data.xml");
			
			if(!dataFile.exists)
			{
				var initDataFile:File = File.applicationDirectory.resolvePath("assets");
				initDataFile = initDataFile.resolvePath("data");
				initDataFile = initDataFile.resolvePath("data.xml");				
				
				var initXmlText:String = FileUtil.getFileContents(initDataFile);
				
				FileUtil.saveFile(initXmlText, dataFile);
			}				
			
			var xmlText:String = FileUtil.getFileContents(dataFile);	
			dataXML = XML(xmlText);
		}
		
		public static function saveXML():void
		{
			FileUtil.saveFile(dataXML.toString(), dataFile);
		}
		
		private static var dataFile:File; 
		private static var dataXML:XML;
	}
}