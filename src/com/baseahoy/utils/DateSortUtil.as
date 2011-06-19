package com.baseahoy.utils
{
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.core.ComponentDescriptor;
	import mx.utils.ObjectUtil;

	public class DateSortUtil
	{
		public static function sortOnDates(collection:ArrayCollection, dateField:String):void
		{
			datePropertyName = dateField
			var dateSort:Sort = new Sort();
			dateSort.compareFunction = compareOnDates;
			
			collection.sort = dateSort;
			collection.refresh();
		}
		
		private static var datePropertyName:String;
		
		private static function compareOnDates(a:Object, b:Object, fields:Array = null):int
		{
			return ObjectUtil.dateCompare(a[datePropertyName] as Date, b[datePropertyName] as Date) * -1;
		}
	}
}