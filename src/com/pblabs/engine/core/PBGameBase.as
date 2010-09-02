package com.pblabs.engine.core
{
    import com.pblabs.engine.debug.Logger;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.utils.Dictionary;
    
    import org.swiftsuspenders.Injector;
    
    public class PBGameBase
    {
        protected var injector:Injector = new Injector();
        protected var _main:DisplayObjectContainer = null;
        protected var _contexts:Object = {};
        protected var _currentContext:IPBContext = null;
        private var _managers:Dictionary = new Dictionary();

        public function startup(main:DisplayObjectContainer):void
        {
            // Make sure PBE services are initialized.
            Logger.print(this, "Initializing " + this + ".");
            Logger.startup(main.stage);
            
            // Note main class.
            _main = main;
            
            // Set up managers.
            initializeManagers();
            
            // Inject into the main class.
            injectInto(_main);
        }

        protected function initializeManagers():void
        {
            // Mostly will come from subclasses.
        }

        public function registerManager(clazz:Class, instance:* = null, name:String = null):void
        {
            var i:* = instance ? instance : new clazz();
            name = name ? name : "";
            _managers[clazz + "|" + name] = i;
            injector.mapValue(clazz, i, name);
            injector.injectInto(i);
        }
        
        public function getManager(clazz:Class, name:String = null):*
        {
            return _managers[clazz + "|" + name];
        }
        
        public function unregisterManager(clazz:Class, name:String = null):void
        {
            _managers[clazz + "|" + name] = null;
            injector.unmap(clazz, name);
        }
        
        public function registerContext(ctx:IPBContext):void
        {
            if(_contexts[ctx.name])
                throw new Error("Cannot have two contexts with the same name!");
            
            // Store it and set up.
            _contexts[ctx.name] = ctx;
            var ctxObj:* = ctx;
            if(ctxObj['setInjectorParent'])
                ctxObj.setInjectorParent(injector);
        }
        
        public function unregisterContext(ctx:IPBContext):void
        {
            if(_contexts[ctx.name] == null)
                throw new Error("Unknown context '" + ctx.name + "'!");
            
            // Remove everything.
            var ctxObj:* = ctx;
            if(ctxObj['setInjectorParent'])
                ctxObj.setInjectorParent(null);
            _contexts[ctx.name] = null;
        }
        
        public function injectInto(object:*):void
        {
            injector.injectInto(object);
        }
        
        public function switchContext(name:String):void
        {
            // Shutdown the old context.
            if(_currentContext)
            {
                if(_currentContext is DisplayObject)
                    _main.removeChild(_currentContext as DisplayObject);
                _currentContext.shutdown();
                _currentContext = null;
            }
            
            // Startup the new context.
            _currentContext = _contexts[name];
            if(_currentContext)
            {
                if(_currentContext is DisplayObject)
                    _main.addChild(_currentContext as DisplayObject);
                _currentContext.startup();
            }
            else
            {
                Logger.warn(this, "switchContext", "No context '" + name + "'.");
            }
        }
        
        public function get currentContext():IPBContext
        {
            return _currentContext;
        }
        
        public function get mainStage():Stage
        {
            return _main.stage;   
        }
        
        public function get mainClass():*
        {
            return _main;
        }
        
    }
}