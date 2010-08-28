package com.pblabs.engine.core
{
    import com.pblabs.engine.debug.Profiler;
    import com.pblabs.engine.input.InputManager;
    import com.pblabs.engine.resource.ResourceManager;
    import com.pblabs.engine.serialization.LevelManager;
    import com.pblabs.engine.serialization.Serializer;
    import com.pblabs.engine.serialization.TemplateManager;
    import com.pblabs.engine.time.IProcessManager;
    import com.pblabs.engine.time.ITickedObject;
    import com.pblabs.engine.time.ProcessManager;
    import com.pblabs.rendering.BasicSpatialManager;
    import com.pblabs.rendering.DisplayObjectScene;
    import com.pblabs.rendering.IScene;
    import com.pblabs.rendering.ISpatialManager;
    import com.pblabs.rendering.SceneAlignment;
    import com.pblabs.rendering.ui.IUITarget;
    import com.pblabs.screens.ScreenManager;
    import com.pblabs.sound.ISoundManager;
    import com.pblabs.sound.SoundManager;
    
    import flash.display.DisplayObject;
    
    import org.swiftsuspenders.Injector;

    public class PBContext extends PBContextBase
    {
		public var injector:Injector = new Injector();
		
		public function PBContext(mainInstance:DisplayObject = null, name:String = null):void
		{
			super(mainInstance, name);
		}

		public override function registerManager(clazz:Class, instance:Object, optionalName:String=null):void
		{
			injector.mapValue(clazz, instance, optionalName == null ? "" : optionalName);

			super.registerManager(clazz, instance, optionalName);
			
			injector.injectInto(instance);
			
			// Deal with startup callback.
			var m:IPBManager = instance as IPBManager;
			if(m)
				m.startup();
		}
		
        public function setInjectorParent(i:Injector)
        {
            injector.setParentInjector(i);
        }

        public override function inject(instance:*):void
		{
			injector.injectInto(instance);			
		}

		public override function allocate(type:Class):*
		{
			Profiler.enter("PBContext.allocate");
			
			var res:* = super.allocate(type);
			
			inject(res);
			
			Profiler.exit("PBContext.allocate");
			
			return res;
		}
    }
}