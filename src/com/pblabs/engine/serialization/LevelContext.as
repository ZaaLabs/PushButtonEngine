package com.pblabs.engine.serialization
{
    import com.pblabs.engine.core.PBContext;
    
    /**
     * Context which loads itself from a level XML file.
     */
    public class LevelContext extends PBContext
    {
        protected var _levelUrl:String;
        protected var _group:String = "DefaultGroup";
        
        [Inject]
        public var templateManager:TemplateManager;
        
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
            templateManager.instantiateGroup(_group);
        }
        
        public override function shutdown():void
        {
            // Nuke our root group.
            super.shutdown();
        }
    }
}