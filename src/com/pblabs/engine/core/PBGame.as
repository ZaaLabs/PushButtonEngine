package com.pblabs.engine.core
{
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.ResourceBundle;
    import com.pblabs.engine.resource.ResourceManager;
    import com.pblabs.engine.serialization.Serializer;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ProcessManager;
    import com.pblabs.screens.ScreenManager;
    import com.pblabs.sound.ISoundManager;
    import com.pblabs.sound.SoundManager;
    
    import flash.events.EventDispatcher;

    public class PBGame extends PBGameBase
    {
        protected override function initializeManagers():void
        {
            super.initializeManagers();

            // Register ourselves.
            registerManager(PBGame, this);
            
            // Bring in the standard managers.
            var pm:ProcessManager = new ProcessManager();
            registerManager(IProcessManager, pm);
            
            registerManager(Serializer, new Serializer);
            registerManager(InputManager, new InputManager());
            registerManager(NameManager, new NameManager());
            registerManager(ResourceManager, new ResourceManager());
            registerManager(TemplateManager, new TemplateManager());
            
            var sm:SoundManager = new SoundManager();
            registerManager(ISoundManager, sm);
            pm.addTickedObject(sm, 100);
            
            registerManager(ScreenManager, new ScreenManager());
            
            registerManager(EventDispatcher, new EventDispatcher());
        }
        
        public function addResourceBundle(rb:ResourceBundle):void
        {
            rb.register(getManager(ResourceManager));
        }
        
        public function registerType(clazz:Class):void
        {
            // NOP - passing it is enough for it to be linked into the SWF.
        }
    }
}