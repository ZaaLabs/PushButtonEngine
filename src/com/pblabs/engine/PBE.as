package com.pblabs.engine
{
	import com.pblabs.engine.core.IPBContext;
	import com.pblabs.engine.resource.ResourceBundle;
	import com.pblabs.engine.resource.ResourceManager;
	
	import flash.display.Stage;

	use namespace pb_internal;

	public class PBE
	{
		public static var IS_SHIPPING_BUILD:Boolean = false;
		
		public static function callLater(func:Function, args:Array = null):void
		{
			defaultContext.callLater(func, args);
		}
		
		public static function get mainStage():Stage
		{
			return defaultContext.mainStage;
		}
        
		public static function get mainClass():*
		{
			return defaultContext.mainClass;
		}

		public static function get resourceManager():ResourceManager
		{
			return defaultContext.resourceManager;
		}

		public static function registerType(type:Class):void
		{
			// Nop, forces a reference.
		}
		
		public static function addResources(rb:ResourceBundle):void
		{
			// Maybe we do stuff someday...
		}

		pb_internal static var contextList:Array = [];

		pb_internal static function registerContext(c:IPBContext):void
		{
			contextList.push(c);
		}
		
		pb_internal static function unregisterContext(c:IPBContext):void
		{
			var idx:int = contextList.indexOf(c);
			if(idx == -1)
				throw new Error("Context not found in master list.");
			contextList.splice(idx, 1);			
		}		

		pb_internal static function get defaultContext():IPBContext
		{
			if (contextList.length==0)
				return null;
			
			return contextList[0];
		}
	}
}