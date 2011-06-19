package com.baseahoy.utils
{
	import mx.collections.Sort;
	import mx.utils.ObjectUtil;
	
	public class DateSort extends Sort
	{
		public function DateSort(dateField:String)
		{
			super();
			
			this.dateField = dateField;
			this.compareFunction = this.compareOnDates;
		}
		
		private var dateField:String;
		
		private function compareOnDates(a:Object, b:Object, fields:Array = null):int
		{
			return ObjectUtil.dateCompare(a[this.dateField] as Date, b[this.dateField] as Date);
		}
	}
}