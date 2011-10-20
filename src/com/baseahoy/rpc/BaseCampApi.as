package com.baseahoy.rpc
{
	import com.baseahoy.events.ApiResultEvent;
	import com.baseahoy.persistence.PersistenceManager;
	
	import flash.events.EventDispatcher;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.Base64Encoder;

	[Event(name = "apiResult", "com.musigma.baseahoy.events.ApiResultEvent")]
	[Event(name = "fault", "mx.rpc.events.FaultEvent")]
	
	public class BaseCampApi extends EventDispatcher
	{		
		public function sendRequest(resource:String, callback:Function):void
		{
			this.callback = callback;
			
			var httpService:HTTPService = new HTTPService();
			httpService.addEventListener(ResultEvent.RESULT, this.httpServiceResultHandler);
			httpService.addEventListener(FaultEvent.FAULT, this.httpServiceFaultHandler);
			httpService.headers = getHeaders();
			httpService.resultFormat = "e4x";
			httpService.url = PersistenceManager.endpoint + "/" + resource;			
			httpService.send();
		}
		
		private var callback:Function;
		
		private function httpServiceResultHandler(event:ResultEvent):void
		{
			var result:XML = XML(event.result);
			
			this.callback.call(null, result);
			
			//this.dispatchEvent(new ApiResultEvent(ApiResultEvent.API_RESULT, result));
		}
		
		private function httpServiceFaultHandler(event:FaultEvent):void
		{
			this.dispatchEvent(event);
		}
		
		private function getHeaders():Object
		{
			var headers:Object = new Object();
			headers.Accept = "application/xml";
			headers["Content-Type"] = "application/xml";
			
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.insertNewLines = false;
			encoder.encode(PersistenceManager.userToken + ":oompaloompa");
			
			trace("Header: " +PersistenceManager.userToken + ":oompaloompa");
			
			headers.Authorization = "Basic " + encoder.toString(); 
			
			return headers;
		}
	}
}