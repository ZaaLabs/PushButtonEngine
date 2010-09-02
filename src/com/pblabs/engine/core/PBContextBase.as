package com.pblabs.engine.core
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.PBUtil;
    import com.pblabs.engine.debug.Console;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.pb_internal;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.util.version.VersionDetails;
    import com.pblabs.engine.util.version.VersionUtil;
    
    import flash.display.DisplayObject;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.utils.Dictionary;
    
    import org.swiftsuspenders.Injector;
    
    use namespace pb_internal;
    
    public class PBContextBase extends Sprite implements IPBContext
    {
        protected static var contextNameCounter:int = 0;
        
        private var _managers:Dictionary = new Dictionary();
        
        private var _rootGroup:PBGroup = null, _currentGroup:PBGroup = null;
        
        private var _versionDetails:VersionDetails;
        
        public function PBContextBase(_name:String = null):void
        {
            if (!name)
                initializeName();
            else
                name = _name;
        }
        
        protected function initializeName():void
        {
            contextNameCounter++;
            name = "Context" + contextNameCounter;
        }
        
        public function startup():void
        {
            Logger.print(this, "Initializing " + this + " '" + name + "'.");
            
            // Register ourselves.
            registerManager(IPBContext, this);
            
            // Do manager startup.
            initializeManagers();
            
            // Set up root and current group.
            var rg:PBGroup = allocate(PBGroup);
            rg.initialize("RootGroup");
            _currentGroup = _rootGroup = rg;
            
            // Allow injection on main class and ourselves, too.
            inject(this);
            
            Console.registerContext(this);
        }
        
        protected function initializeManagers():void
        {
            throw new Error("Child class should implement this.");
        }
        
        public function shutdown():void
        {
            // Subclasses could do something with the managers.
            
            // Tear down the simulation.
            _currentGroup = null;
            rootGroup.destroy();
            
            Console.unregisterContext(this);            
        }
        
        public function get started():Boolean
        {
            throw new Error("Always returning true, boss!");
            return true;
        }
        
        public function registerManager(clazz:Class, instance:Object = null, optionalName:String = null):void
        {
            if(!optionalName)
                optionalName = "";
            _managers[clazz + "|" + optionalName] = instance;
        }
        
        public function getManager(clazz:Class, optionalName:String = null):*
        {
            return _managers[clazz + "|" + optionalName];
        }
        
        public function inject(instance:*):void
        {
        }
        
        public function allocate(type:Class):*
        {
            var res:* = new type();
            
            var iec:IEntityComponent = res as IEntityComponent;
            var ipbo:PBObject = res as PBObject;
            
            if (iec)
                iec.context = this;
            else if (ipbo)
                ipbo.setContext(this);
            
            return res;
        }
        
        public function allocateEntity():IEntity
        {
            return allocate(Entity);
        }
        
        public function get rootGroup():PBGroup
        {
            return _rootGroup;
        }
        
        public function get currentGroup():PBGroup
        {
            return _currentGroup;
        }
        
        public function set currentGroup(value:PBGroup):void
        {
            if (value == null)
                throw new Error("You cannot set the currentGroup to null; it must always be a valid PBGroup.");
            
            if (value.context != this)
                throw new Error("Cannot mix objects between contexts.");
            
            _currentGroup = value;
        }
        
        pb_internal function register(object:IPBObject):void
        {
            // Register with the NameManager.
            getManager(NameManager).add(object);
            
            // Add to default group when appropriate.
            if (object.owningGroup == null)
            {
                if (_currentGroup)
                {
                    object.owningGroup = _currentGroup;
                }
                else
                {
                    if (_rootGroup)
                        throw new Error("Had null currentGroup while rootGroup is valid; currentGroup should always be a value, and should be rootGroup by default.");
                }
            }
        }
        
        pb_internal function unregister(object:IPBObject):void
        {
            // Clear out the NameManager.
            getManager(NameManager).remove(object);
        }
        
        public function get eventDispatcher():IEventDispatcher
        {
            return this as IEventDispatcher;
        }
        
        public function get mainClass():*
        {
            return this;
        }
        
        public function get mainStage():Stage
        {
            return this.stage;
        }
        
        public function get flashVars():Object
        {
            return LoaderInfo(this.loaderInfo).parameters;
        }
        
        public function get hostingDomain():String
        {
            // Get at the hosting domain.
            var urlString:String = mainStage.loaderInfo.url;
            var urlParts:Array = urlString.split("://");
            var wwwPart:Array = urlParts[1].split("/");
            if (wwwPart.length)
                return wwwPart[0];
            else
                return "[unknown]";
        }
        
        public function get versionDetails():VersionDetails
        {
            if (!_versionDetails)
                _versionDetails = VersionUtil.checkVersion(this);
            
            return _versionDetails;
        }
        
        public function findChild(name:String):DisplayObject
        {
            return PBUtil.findChild(name, mainClass);
        }

        public function lookup(name:String):*
        {
            return (getManager(NameManager) as NameManager).lookup(name);            
        }
        
        public function lookupEntity(name:String):IEntity
        {
            return (getManager(NameManager) as NameManager).lookup(name) as IEntity;            
        }
        
        public function lookupComponent(entityName:String, componentName:String):IEntityComponent
        {
            return (getManager(NameManager) as NameManager).lookupComponentByName(entityName, componentName);
        }
    }
}