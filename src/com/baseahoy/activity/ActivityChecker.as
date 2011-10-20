package com.baseahoy.activity
{
	import com.baseahoy.events.ApiResultEvent;
	import com.baseahoy.events.NewActivitiesEvent;
	import com.baseahoy.persistence.PersistenceManager;
	import com.baseahoy.rpc.BaseCampApi;
	import com.baseahoy.utils.DateSortUtil;
	import com.baseahoy.utils.DateUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ObjectUtil;
	
	[Event(name = "newActivities", type = "com.baseahoy.events.NewActivitiesEvent")]
	[Event(name = "checkCancelled", type = "flash.events.Event")]
	
	public class ActivityChecker extends EventDispatcher
	{
		public function ActivityChecker()
		{
			super();
		}
		
		public static var newActivityCount:int = 0;
		
		public function beginCheck():void
		{
			//trace("beginCheck");
			
			//this.activityCheckTimer = new Timer(20 * 1000);
			this.activityCheckTimer = new Timer(PersistenceManager.refreshTime * 1000);
			this.activityCheckTimer.addEventListener(TimerEvent.TIMER, this.timerHandler);
			this.activityCheckTimer.start();
		}
		
		private var activityCheckTimer:Timer;
		private var api:BaseCampApi;
		private var newActivities:ArrayCollection;
		private var lastActivityTime:Date;
		private var updatedProjects:XMLListCollection;
		private var updatedProjectIndex:int;
		private var messagesInProject:XMLList;
		private var messageInProjectIndex:int;
		private var todoListsInProject:XMLList;
		private var todoListsInProjectIndex:int;
		private var newTodoListIDs:ArrayCollection;
		private var existingTodoListIDs:ArrayCollection;
		private var existingTodoListIDIndex:int;
		private var isCheckInProgress:Boolean = false;
		private var cancellationCount:int = 0;
		private var onlyUpdateDate:Boolean;
		
		private function timerHandler(event:Event):void
		{
			//trace(this.isCheckInProgress + ", " + cancellationCount);
			/*if(this.isCheckInProgress)
			{
			if(this.cancellationCount++ > 5)
			{
			//trace("Cancelled");
			this.activityCheckTimer.stop();
			this.activityCheckTimer.removeEventListener(TimerEvent.TIMER, this.timerHandler);
			this.dispatchEvent(new Event("checkCancelled"));
			return;
			}
			else
			{					
			//trace("End Cancelled");
			/*this.isCheckInProgress = false;
			this.cancellationCount = 0;*/
			/*}				
			}*/
			
			if(this.isCheckInProgress)
			{
				//trace("Cancelled");
				
				if(this.cancellationCount++ > 5)
				{
					//trace("restart");
					this.activityCheckTimer.stop();
					this.activityCheckTimer.removeEventListener(TimerEvent.TIMER, this.timerHandler);
					
					this.dispatchEvent(new Event("checkCancelled"));
				}
				
				return;
			}
			
			
			//trace("Check");
			
			this.isCheckInProgress = true;
			
			this.checkForNewActivities();
		}
		
		private function checkForNewActivities():void
		{			
			this.newActivities = new ArrayCollection();
			
			this.lastActivityTime = ObjectUtil.copy(PersistenceManager.latestActivityTime) as Date;
			
			this.api = new BaseCampApi();
			this.api.addEventListener(FaultEvent.FAULT, this.faultHandler);
			
			this.getProjects();
		}
		
		private function faultHandler(event:FaultEvent):void
		{
			//trace("cancelled");
			
			this.activityCheckTimer.stop();
			this.activityCheckTimer.removeEventListener(TimerEvent.TIMER, this.timerHandler);
			this.dispatchEvent(new Event("checkCancelled"));
			
		}
		
		private function getProjects():void
		{
			//trace("getProjects");
			this.api.sendRequest("projects.xml", this.getProjectsResultHandler);
		}
		
		private function getProjectsResultHandler(result:XML):void
		{
			var projects:XMLList = result.project;
			
			this.updatedProjects = new XMLListCollection();
			
			for(var nodeIndex:int = 0; nodeIndex < projects.length(); nodeIndex++)
			{
				var projectNode:XML = projects[nodeIndex];
				
				var lastChangedDate:Date = DateUtil.parseIsoDate(projectNode['last-changed-on']);
				
				if(lastChangedDate > this.lastActivityTime)
					this.updatedProjects.addItem(projectNode);
			}
			
			this.updatedProjectIndex = 0;
			
			if(this.updatedProjects.length == 0)
			{
				this.finishCheck();
				return;
			}
			
			this.checkProject();
		}
		
		
		private function checkProject():void
		{
			var projectNode:XML = this.updatedProjects[this.updatedProjectIndex];
			this.checkMessagesAndComments(projectNode['id'].toString());
		}
		
		private function checkMessagesAndComments(projectID:String):void
		{
			this.getMessages(projectID);
		}
		
		private function getMessages(projectID:String):void
		{			
			this.api.sendRequest("projects/" + projectID + "/posts.xml", this.getMessagesHandler);
		}
		
		private function getMessagesHandler(result:XML):void
		{
			this.messagesInProject = result.post;
			
			if(this.messagesInProject.length() == 0)
				this.finishCheckItems();
			else
			{
				this.messageInProjectIndex = 0;
				
				this.checkItem();
			}
		}
		
		private function checkItem():void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			
			var messageNode:XML = this.messagesInProject[this.messageInProjectIndex] as XML;
			var postedDate:Date = DateUtil.parseIsoDate(messageNode['posted-on'].toString());
			
			if(postedDate > this.lastActivityTime)
			{ 
				var newActivity:Activity = new Activity();
				newActivity.activityID = new Date().time.toString();
				newActivity.description = this.parseDescription(messageNode['title'] + ": " + messageNode['body']);
				newActivity.project = currentProject['name'];
				newActivity.user = messageNode['author-name'];
				newActivity.date = postedDate;
				newActivity.activityType = ActivityType.MESSAGE;
				newActivity.link = PersistenceManager.endpoint + "/projects/" + currentProject['id'] + "/posts/" + messageNode['id'];
				
				this.newActivities.addItem(newActivity);
				
				this.updateLatestActivityTime(postedDate);
			}
			
			this.checkItemComments(messageNode);
		}
		
		private function checkItemComments(messageNode:XML):void
		{			
			if(DateUtil.parseIsoDate(messageNode['commented-at'].toString()) > this.lastActivityTime)
				this.getComments(messageNode['id'].toString());
			else
				this.finishCheckItemComments();
		}
		
		private function getComments(itemID:String):void
		{
			this.api.sendRequest("posts/" + itemID + "/comments.xml", this.getCommentsHandler);
		}
		
		private function getCommentsHandler(result:XML):void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			var currentItem:XML = this.messagesInProject[this.messageInProjectIndex] as XML;
			
			var commentsInItem:XMLList = result.comment;
			
			for(var commentIndex:int = 0; commentIndex < commentsInItem.length(); commentIndex++)
			{
				var commentXML:XML = commentsInItem[commentIndex];
				
				var createdDate:Date = DateUtil.parseIsoDate(commentXML['created-at'].toString());
				
				if(createdDate <= this.lastActivityTime)
					continue;
				
				var newActivity:Activity = new Activity();
				newActivity.activityID = new Date().time.toString();
				newActivity.description = this.parseDescription(commentXML['body'].toString());
				newActivity.project = currentProject['name'];
				newActivity.user = commentXML['author-name'];
				newActivity.date = createdDate;
				newActivity.activityType = ActivityType.COMMENT;
				newActivity.link = PersistenceManager.endpoint + "/projects/" + currentProject['id'] + "/posts/" + currentItem['id'];
				
				this.newActivities.addItem(newActivity);
				this.updateLatestActivityTime(createdDate);				
			}
			
			this.finishCheckItemComments();
		}
		
		private function parseDescription(text:String):String
		{
			var tagsToRemove:Array = ["<div>", "</div>", "<br />", "<ul>", "</ul>", "<li>", "</li>", "&nbsp;", "<b>", "</b>", "<i>", "</i>"];
			
			for(var tagIndex:int = 0 ; tagIndex < tagsToRemove.length; tagIndex++)
				text = text.replace(tagsToRemove[tagIndex], "");
			
			return text;
		}
		
		private function finishCheckItemComments():void
		{
			this.gotoNextItem();
		}
		
		private function gotoNextItem():void
		{
			if(this.messageInProjectIndex == this.messagesInProject.length() - 1)
				this.finishCheckItems();
			else
			{
				this.messageInProjectIndex++;
				this.checkItem();
			}
		}
		
		private function finishCheckItems():void
		{			
			this.checkTodoLists();
		}
		
		private function checkTodoLists():void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			
			this.api.sendRequest("projects/" + currentProject['id'].toString() + "/todo_lists.xml", this.getTodoListsHandler);
		}
		
		private function getTodoListsHandler(result:XML):void
		{
			this.todoListsInProject = result['todo-list'];
			
			if(this.todoListsInProject.length() == 0)
				this.finishCheckTodoLists();
			else
			{
				this.todoListsInProjectIndex = 0;
				this.newTodoListIDs = new ArrayCollection();
				this.existingTodoListIDs = new ArrayCollection();
				
				this.checkTodoList();
			}
		}
		
		private function checkTodoList():void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			var todoListNode:XML = this.todoListsInProject[this.todoListsInProjectIndex] as XML;
			
			var todoListID:String = todoListNode['id'].toString();
			
			var dataToDoListIDs:ArrayCollection = PersistenceManager.todoListIDs;
			
			var isExistingList:Boolean = false;
			
			for(var idIndex:int = 0; idIndex < dataToDoListIDs.length; idIndex++)
			{
				if(todoListID == dataToDoListIDs[idIndex])
				{
					isExistingList = true;
					break;
				}
			}
			
			if(isExistingList)
			{
				this.onlyUpdateDate = false;
				this.getTodoListItems(todoListID);
			}
			else
			{				
				this.newTodoListIDs.addItem(todoListID);
				
				var newActivity:Activity = new Activity();
				newActivity.activityID = new Date().time.toString();
				newActivity.description = this.parseDescription(todoListNode['name']);
				newActivity.project = currentProject['name'];
				newActivity.user = null;
				newActivity.date = new Date();
				newActivity.activityType = ActivityType.TODO_NEW;
				newActivity.link = PersistenceManager.endpoint + "/projects/" + currentProject['id'] + "/todo_lists/" + todoListID;
				
				this.newActivities.addItem(newActivity);
				
				PersistenceManager.addTodoListID(todoListID);
								
				this.onlyUpdateDate = true;
				
				this.getTodoListItems(todoListID);
			}
		}
		
		private function getTodoListItems(todoListId:String):void
		{
			this.api.sendRequest("todo_lists/" + todoListId + "/todo_items.xml", this.getTodoListItemsHandler);			
		}
		
		private function getTodoListItemsHandler(result:XML):void
		{
			var todoItems:XMLList = result['todo-item'];
			
			//trace("Items coiunt: " + todoItems.length());
			for(var itemIndex:int = 0; itemIndex < todoItems.length(); itemIndex++)
			{
				var itemNode:XML = todoItems[itemIndex];
				
				var updatedDate:Date = DateUtil.parseIsoDate(itemNode['updated-at'].toString());
				
				var isToDoListUpdated:Boolean = false;
				
				if(updatedDate <= lastActivityTime)
					continue;
				else
				{
					var todoListNode:XML = this.todoListsInProject[this.todoListsInProjectIndex] as XML;
					var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
					
					var newActivity:Activity = new Activity();
					newActivity.activityID = new Date().time.toString();
					newActivity.description = this.parseDescription(todoListNode['name']);
					newActivity.project = currentProject['name'];
					newActivity.user = null;
					newActivity.date = null;
					newActivity.activityType = ActivityType.TODO_UPDATE;
					newActivity.link = PersistenceManager.endpoint + "/projects/" + currentProject['id'] + "/todo_lists/" + todoListNode['id'];
					
					if(!isToDoListUpdated && !this.onlyUpdateDate)
					{
						this.newActivities.addItem(newActivity);
						isToDoListUpdated = true;
					}
					
					this.updateLatestActivityTime(updatedDate);
				}
			}
			
			this.finishCheckTodoList();
		}
		
		private function finishCheckTodoList():void
		{			
			this.todoListsInProjectIndex++;
			
			if(this.todoListsInProjectIndex == this.todoListsInProject.length())
				this.finishCheckTodoLists();
			else
				this.checkTodoList();
		}
		
		private function finishCheckTodoLists():void
		{			
			this.checkFiles();
		}
		
		private function checkFiles():void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			
			this.api.sendRequest("projects/" + currentProject['id'].toString() + "/attachments.xml", this.checkFilesHandler);
		}
		
		private function checkFilesHandler(result:XML):void
		{
			var currentProject:XML = this.updatedProjects[this.updatedProjectIndex] as XML;
			
			var files:XMLList = result.attachment;
			
			for(var fileIndex:int = 0; fileIndex < files.length(); fileIndex++)
			{
				var fileXML:XML = files[fileIndex];
				
				var createdDate:Date = DateUtil.parseIsoDate(fileXML['created-on'].toString());
				
				if(createdDate <= this.lastActivityTime)
					continue;
				
				var newActivity:Activity = new Activity();
				newActivity.activityID = new Date().time.toString();
				newActivity.description = this.parseDescription(fileXML['description'].toString());
				newActivity.project = currentProject['name'];
				newActivity.user = null;
				newActivity.date = createdDate;
				newActivity.activityType = ActivityType.FILE;
				newActivity.link = PersistenceManager.endpoint + "/projects/" + currentProject['id'] + "/files";
				
				this.newActivities.addItem(newActivity);
				this.updateLatestActivityTime(createdDate);				
			}
			
			this.finishCheckFiles();
		}
		
		private function finishCheckFiles():void
		{
			this.gotoNextProject();
		}
		
		private function gotoNextProject():void
		{
			if(this.updatedProjectIndex == this.updatedProjects.length - 1)
				this.finishProjects();
			else
			{
				this.updatedProjectIndex++;
				this.checkProject();
			}
		}
		
		private function finishProjects():void
		{
			this.finishCheck();
		}
		
		private function updateLatestActivityTime(newLastActivityTime:Date):void
		{
			if(newLastActivityTime > PersistenceManager.latestActivityTime)
				PersistenceManager.latestActivityTime = newLastActivityTime;
		}
		
		private function finishCheck():void
		{
			this.isCheckInProgress = false;
			
			DateSortUtil.sortOnDates(this.newActivities, "date");
			
			if(this.newActivities.length > 5)
			{
				for(var activityIndex:int = this.newActivities.length - 1; activityIndex > 4; activityIndex--)
					this.newActivities.removeItemAt(activityIndex);
			}
			
			for(var newActivityIndex:int = this.newActivities.length - 1; newActivityIndex >= 0; newActivityIndex--)
				PersistenceManager.addNewActivity(this.newActivities[newActivityIndex] as Activity);
			
			newActivityCount += this.newActivities.length;
			
			PersistenceManager.saveXML();
			
			if(this.newActivities.length > 0)
				this.dispatchEvent(new NewActivitiesEvent(NewActivitiesEvent.NEW_ACTIVITIES, this.newActivities));
			
			//setTimeout(this.checkForNewActivities, PersistenceManager.refreshTime * 1000);
		}
	}
}