package com.pblabs.engine.core
{
    import com.pblabs.engine.debug.Profiler;
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.ResourceManager;
    import com.pblabs.engine.serialization.Serializer;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ITickedObject;
    import com.pblabs.engine.time.ProcessManager;
    import com.pblabs.rendering2D.BasicSpatialManager2D;
    import com.pblabs.rendering2D.DisplayObjectScene;
    import com.pblabs.rendering2D.IScene2D;
    import com.pblabs.rendering2D.ISpatialManager2D;
    import com.pblabs.rendering2D.SceneAlignment;
    import com.pblabs.rendering2D.ui.IUITarget;
    import com.pblabs.screens.ScreenManager;
    import com.pblabs.sound.ISoundManager;
    import com.pblabs.sound.SoundManager;
    
    import flash.display.DisplayObject;
    
    import org.swiftsuspenders.Injector;

    public class PBContext extends PBContextBase
    {
		public var injector:Injector = new Injector();
		
		public function PBContext(name:String = null):void
		{
			super(name);
		}

		public override function registerManager(clazz:Class, instance:Object = null, optionalName:String=null):void
		{
            if(!instance)
                instance = allocate(clazz);
            if(!optionalName)
                optionalName = "";
            
			injector.mapValue(clazz, instance, optionalName);

			super.registerManager(clazz, instance, optionalName);
			
			injector.injectInto(instance);
			
			// Deal with startup callback.
			var m:IPBManager = instance as IPBManager;
			if(m)
				m.startup();
		}
		
        public function setInjectorParent(i:Injector):void
        {
            injector.setParentInjector(i);
        }

        public override function injectInto(instance:*):void
		{
			injector.injectInto(instance);			
		}

		public override function allocate(type:Class):*
		{
			Profiler.enter("PBContext.allocate");
			
			var res:* = super.allocate(type);
			
			injectInto(res);
			
			Profiler.exit("PBContext.allocate");
			
			return res;
		}
        
        protected override function initializeManagers():void
        {
        }   
    }
}