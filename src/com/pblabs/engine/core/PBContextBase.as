package com.pblabs.engine.core
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.PBUtil;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.pb_internal;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.util.version.VersionDetails;
    import com.pblabs.engine.util.version.VersionUtil;
    
    import flash.display.DisplayObject;
    import flash.display.LoaderInfo;
    import flash.display.Stage;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.utils.Dictionary;
    
    import org.swiftsuspenders.Injector;
    
    use namespace pb_internal;
    
    public class PBContextBase extends EventDispatcher implements IPBContext
    {
        protected static var contextNameCounter:int = 0;
        
        protected var _main:DisplayObject = null;
        
        private var _managers:Dictionary = new Dictionary();
        
        private var _rootGroup:PBGroup = null, _currentGroup:PBGroup = null;
        
        private var _versionDetails:VersionDetails;
        
        private var _name:String = null;
        
        public function PBContextBase(name:String = null):void
        {
            _name = name;
        }
        
        protected function initializeName():void
        {
            contextNameCounter++;
            _name = "Context" + contextNameCounter;
        }
        
        public function get name():String
        {
            return _name;
        }
        
        public function startup(mainInstance:DisplayObject, name:String = null):void
        {
            if (!name)
                initializeName();
            else
                _name = name;
            
            _main = mainInstance;
            
            Logger.print(this, "Initializing PushButton Engine Context '" + _name + "'.");
            
            PBE.registerContext(this);
            
            Logger.startup();
            
            // Register ourselves.
            registerManager(IPBContext, this);
            
            // Do manager startup.
            initializeManagers();
            
            // Set up root and current group.
            var rg:PBGroup = allocate(PBGroup);
            rg.initialize("RootGroup");
            _currentGroup = _rootGroup = rg;
            
            // Allow injection on main class and ourselves, too.
            inject(mainInstance);
            inject(this);
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
        }
        
        public function get started():Boolean
        {
            return _main != null;
        }
        
        public function registerManager(clazz:Class, instance:Object, optionalName:String = null):void
        {
            _managers[clazz + "" + optionalName] = instance;
        }
        
        public function getManager(clazz:Class, optionalName:String = null):*
        {
            return _managers[clazz + "" + optionalName];
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
            return _main;
        }
        
        public function get mainStage():Stage
        {
            return _main.stage;
        }
        
        public function get flashVars():Object
        {
            return LoaderInfo(_main.loaderInfo).parameters;
        }
        
        public function get hostingDomain():String
        {
            // Get at the hosting domain.
            var urlString:String = _main.stage.loaderInfo.url;
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
                _versionDetails = VersionUtil.checkVersion(_main);
            
            return _versionDetails;
        }
        
        public function findChild(name:String):DisplayObject
        {
            return PBUtil.findChild(name, mainClass);
        }
        
        
        public function schedule(delay:Number, func:Function, args:Array):void
        {
            //processManager.schedule(delay, null, func, arg);
        }
        
        
        public function log(reporter:*, text:String):void
        {
            Logger.print(reporter, text);
        }
        
        public function makeEntity(entityName:String, params:Object = null):IEntity
        {
            // Create the entity.
            var entity:IEntity = getManager(TemplateManager).instantiateEntity(entityName);
            if (!entity)
                return null;
            
            if (!params)
                return entity;
            
            // Set all the properties.
            for (var key:* in params)
            {
                if (key is PropertyReference)
                {
                    // Fast case.
                    entity.setProperty(key, params[key]);
                }
                else if (key is String)
                {
                    // Slow case.
                    // Special case to allow "@foo": to assign foo as a new component... named foo.
                    if (String(key).charAt(0) == "@" && String(key).indexOf(".") == -1)
                    {
                        entity.addComponent(IEntityComponent(params[key]), String(key).substring(1));
                    }
                    else
                    {
                        entity.setProperty(new PropertyReference(key), params[key]);
                    }
                }
                else
                {
                    // Error case.
                    Logger.error(PBE, "MakeEntity", "Unexpected key '" + key + "'; can only handle String or PropertyReference.");
                }
            }
            
            // Finish deferring.
            if (entity.deferring)
                entity.deferring = false;
            
            // Give it to the user.
            return entity;
        }
        
    }
}