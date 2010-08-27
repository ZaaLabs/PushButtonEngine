package com.pblabs.engine.core
{
    import com.pblabs.engine.debug.Logger;
    
    import flash.display.DisplayObject;
    import flash.utils.Dictionary;
    
    import org.swiftsuspenders.Injector;
    
    public class PBGameBase
    {
        protected var injector:Injector = new Injector();
        protected var _main:DisplayObject = null;
        protected var _contexts:Object = {};
        protected var _currentContext:IPBContext = null;
        private var _managers:Dictionary = new Dictionary();

        public function startup(main:DisplayObject):void
        {
            // Make sure PBE services are initialized.
            Logger.print(this, "Initializing game.");
            Logger.startup();
            
            // Note main class.
            _main = main;
            
            // Set up managers.
            initializeManagers();
        }

        protected function initializeManagers():void
        {
            // Nothing... For subclasses!
        }

        public function registerManager(clazz:Class, instance:* = null, name:String = null):void
        {
            var i:* = instance ? instance : new clazz(); 
            _managers[clazz + "|" + name] = i;
            injector.mapValue(clazz, i, name);
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
        
        public function switchContext(name:String):void
        {
            // Shutdown the old context.
            if(_currentContext)
            {
                _currentContext.shutdown();
                _currentContext = null;
            }
            
            // Startup the new context.
            _currentContext = _contexts[name];
            if(_currentContext)
            {
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
    }
}