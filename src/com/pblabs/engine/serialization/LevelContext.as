package com.pblabs.engine.serialization
{
    import com.pblabs.engine.core.PBContext;
    
    /**
     * Context which loads itself from a level XML file.
     */
    public class LevelContext extends PBContext
    {
        protected var _levelUrl:String;
        
        [Inject]
        public var templateManager:TemplateManager;
        
        public function LevelContext(name:String, levelUrl:String)
        {
            super(name);
            _levelUrl = levelUrl;
        }

        protected override function initializeManagers():void
        {
            super.initializeManagers();
            
            // Get our own template manager, separate from game.
            registerManager(TemplateManager);
            
            // After this function completes we get injected with our own injector.
        }
        
        public override function startup():void
        {
            super.startup();
            
            templateManager.addEventListener(TemplateManager.LOADED_EVENT, onLevelLoaded);
            templateManager.loadFile(_levelUrl);
        }
        
        protected function onLevelLoaded(e:*):void
        {
            // Instantiate the default group.
            templateManager.instantiateGroup("DefaultGroup");
        }
        
        public override function shutdown():void
        {
            // Nuke our root group.
            super.shutdown();
        }
    }
}