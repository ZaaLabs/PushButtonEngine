package com.pblabs.engine.core
{
    import com.pblabs.engine.input.InputKey;
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.Resource;
    import com.pblabs.engine.resource.ResourceManager;
    import com.pblabs.engine.serialization.LevelManager;
    import com.pblabs.engine.serialization.Serializer;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ProcessManager;
    import com.pblabs.engine.util.version.VersionDetails;
    import com.pblabs.rendering2D.DisplayObjectScene;
    import com.pblabs.rendering2D.ISpatialManager2D;
    import com.pblabs.screens.ScreenManager;
    import com.pblabs.sound.ISoundManager;
    
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.events.IEventDispatcher;

    public interface IPBContext
    {
        // Core.
        function startup():void;
        function shutdown():void;
        
		function get name():String;
		
        function get started():Boolean;
        
        function registerManager(clazz:Class, instance:Object, optionalName:String = null):void;
        function getManager(clazz:Class, optionalName:String = null):*;
        
        function get rootGroup():PBGroup;
        function get currentGroup():PBGroup;
        function set currentGroup(value:PBGroup):void;

        function allocate(type:Class):*;
        function allocateEntity():IEntity;
		function inject(instance:*):void;
		
        function get mainClass():*;
        
		function get flashVars():Object;
        function get hostingDomain():String;
		function get versionDetails():VersionDetails;

		function get mainStage():Stage;
        function pushStageQuality(newQuality:String):void;
        function popStageQuality():void;

		function get eventDispatcher():IEventDispatcher;
		
		/**
		 * Make a new instance of an entity, setting appropriate fields based
		 * on the parameters passed.
		 * 
		 * @param entityName Identifier by which to look up the entity on the 
		 *                                       TemplateManager.
		 * @param params     Properties to assign, by key/value. Keys can be
		 *                                       strings or PropertyReferences. Values can be any
		 *                                       type.
		 */
		function makeEntity(entityName:String, params:Object = null):IEntity
		
        // Convenience.
        function lookup(name:String):IPBObject;
        function lookupEntity(name:String):IEntity;
        function lookupComponent(entityName:String, componentName:String):IEntityComponent;
        
        function schedule(delay:Number, func:Function, args:Array):void;
        function callLater(func:Function, args:Array):void;
        
        function log(reporter:*, text:String):void;
        
        function load(filename:String, resourceType:Class, 
                        onLoaded:Function = null, onFailed:Function = null, 
                        forceReload:Boolean = false):Resource;
        
        function findChild(childName:String):DisplayObject;
        
        function isKeyDown(key:InputKey):Boolean;
        function wasKeyPressed(key:InputKey):Boolean;
        function wasKeyReleased(key:InputKey):Boolean;
        function isAnyKeyDown():Boolean;
    }
}