package com.pblabs.engine.serialization
{
    import com.pblabs.engine.core.PBContext;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ProcessManager;
    
    /**
     * Context which loads itself from a level XML file.
     */
    public class LevelContext extends PBContext
    {
        protected var _levelUrl:String;
        protected var _group:String = "DefaultGroup";
        
        [Inject]
        public var templateManager:TemplateManager;
        
        [Inject]
        public var processManager:IProcessManager;
        
        public function LevelContext(name:String, levelUrl:String, group:String = null)
        {
            super(name);
            _levelUrl = levelUrl;
            
            if(group)
                _group = group;
        }

        protected override function initializeManagers():void
        {
            super.initializeManagers();
            
            // Get our own template manager, separate from game.
            registerManager(TemplateManager, new TemplateManager());
            
            // After this function completes we get injected with our own injector.
        }
        
        public override function startup():void
        {
            super.startup();
            
            // Pause the game until the level is loaded.
            processManager.timeScale = 0;
            
            // Load the level.
            templateManager.addEventListener(TemplateManager.LOADED_EVENT, onLevelLoaded);
            templateManager.loadFile(_levelUrl);
        }
        
        protected function onLevelLoaded(e:*):void
        {
            Logger.print(this, "Loaded " + _levelUrl + ", now instantiating " + _group);
            templateManager.removeEventListener(TemplateManager.LOADED_EVENT, onLevelLoaded);
            
            // Instantiate the default group.
            templateManager.instantiateGroup(this, _group);

            // And resume time.
            processManager.timeScale = 1;
        
        }
        
        public override function shutdown():void
        {
            templateManager.unloadFile(_levelUrl);
            
            // Nuke our root group.
            super.shutdown();
        }
    }
}