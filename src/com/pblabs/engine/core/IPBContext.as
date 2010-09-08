package com.pblabs.engine.core
{
    import com.pblabs.engine.input.InputKey;
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.Resource;
    import com.pblabs.engine.resource.ResourceManager;
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
        
        function registerManager(clazz:Class, instance:Object = null, optionalName:String = null, suppressInject:Boolean = false):void;
        function getManager(clazz:Class, optionalName:String = null):*;
        
        function get rootGroup():PBGroup;
        function get currentGroup():PBGroup;
        function set currentGroup(value:PBGroup):void;

        function allocate(type:Class):*;
        function allocateEntity():IEntity;
		function injectInto(instance:*):void;
		
        function get mainClass():*;
        function findChild(childName:String):DisplayObject;
        
		function get flashVars():Object;
        function get hostingDomain():String;
		function get versionDetails():VersionDetails;

		function get mainStage():Stage;

        function get eventDispatcher():IEventDispatcher;
		
        // Name lookups.
        function lookup(name:String):*;
        function lookupEntity(name:String):IEntity;
        function lookupComponent(entityName:String, componentName:String):IEntityComponent;
    }
}