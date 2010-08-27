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
        
        protected override function initializeManagers():void
        {
			var pm:ProcessManager = new ProcessManager();
			registerManager(IProcessManager, pm);

			registerManager(Serializer, new Serializer);
            registerManager(InputManager, new InputManager());
            registerManager(NameManager, new NameManager());
            registerManager(ObjectTypeManager, new ObjectTypeManager());
            registerManager(LevelManager, new LevelManager());
            registerManager(ResourceManager, new ResourceManager());
            registerManager(TemplateManager, new TemplateManager());
            
            var sm:SoundManager = new SoundManager();
            registerManager(ISoundManager, sm);
            pm.addTickedObject(sm, 100);
            
			registerManager(ScreenManager, new ScreenManager());
        }

        /**
         * Helper function to set up a basic scene using default rendering         
		 * classes. Very useful for getting started quickly.
         */
        public function initializeScene(view:IUITarget, sceneName:String = "SceneDB", sceneClass:Class = null, spatialManagerClass:Class = null):IEntity
        {
            // You will notice this is almost straight out of lesson #2.
            var theScene:IEntity = allocateEntity();                                // Allocate our Scene entity
			theScene.initialize(sceneName);                                         // Register with the name "Scene"
            
            if(!spatialManagerClass)
                spatialManagerClass = BasicSpatialManager;
            
            var spatial:ISpatialManager = allocateComponent(spatialManagerClass);           // Allocate our Spatial DB component
			theScene.addComponent( spatial as IEntityComponent, "Spatial" );        // Add to Scene with name "Spatial"
                        
            if(!sceneClass)
                sceneClass = DisplayObjectScene;
            
            var sceneComponent:* = allocateComponent(sceneClass);               // Allocate our renderering component
			sceneComponent.sceneView = view;                 // Point the Renderer's SceneView at the view we just created.
			sceneComponent.sceneAlignment = SceneAlignment.DEFAULT_ALIGNMENT 			// Set default sceneAlignment
			theScene.addComponent( sceneComponent, "Scene" );   // Add our Renderer component to the scene entity with the name "Renderer"

            // Register as managers.
            registerManager( ISpatialManager, spatial );
            registerManager( IScene, sceneComponent );

            return theScene;
        }
    }
}